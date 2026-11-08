import { type Card, cardAnswersSchema, cardQuestionsSchema, isPreviewBody, splitSettleFacts, takesTaskFacts } from "../../../src/shared/cards";
import { demoSources, viewablePictures } from "../../../src/shared/cardPictures";
import { ACTION_VALUE_MAX_BYTES, frameMessageSchema, frameRequestSchema, type FrameAnswers } from "../../../src/shared/plugins/bridge";
import { FRAME_SANDBOX, frameCsp } from "../../../src/shared/plugins/containment";
import { buildFrameDocument, type FrameTheme } from "../../../src/shared/plugins/frameDocument";
import { isSafeCardHref } from "../../../src/shared/linkify";
import { taskKeysIn } from "../../../src/shared/taskKeys";
import { cardBodyMarkup, cardStylesheet } from "../../../src/renderer/src/cards/prototypeSrcdoc";

/** INF-64 piece 4: trusted WK parent, never the agent-authored frame. Native chrome owns effects. */
interface NativeHost { postMessage(value: unknown): Promise<unknown> }
declare global {
  interface Window {
    webkit: { messageHandlers: { cardHost: NativeHost } };
    phoneCard: { mount(input: Input): Promise<void>; collect(): Promise<FrameAnswers>; theme(value: FrameTheme): void; ping(seq: number): void };
  }
}
/**
 * INF-1524: `marks` are the starts of the parts new since the captain last saw the card, `keys` the recorded tasks other
 * than the card's own, and `card` what decides whether the body's last fact strip stands apart, as on the Mac.
 */
type Input = {
  body: string; theme: FrameTheme; fill: unknown; readOnly: boolean; actions: string[]; width: "regular" | "wide" | "full";
  marks?: number[]; keys?: string[]; card?: Pick<Card, "actions" | "reviewTaskId" | "risk">;
};
const native = (message: unknown) => window.webkit.messageHandlers.cardHost.postMessage(message);
let frame: HTMLIFrameElement | undefined;
let documentID: string | undefined;
let input: Input;
let linked: string[] = [];
/** The captain's own press in the body, as a picture's viewer asks: only then does a link, draft or key leave it. */
const pressed = () => document.hasFocus() && navigator.userActivation.isActive;
let next = 0;
const collections = new Map<number, { resolve: (answers: FrameAnswers) => void; reject: (error: Error) => void; timer: ReturnType<typeof setTimeout> }>();
const send = (message: object) => frame?.contentWindow?.postMessage({ fm: 2, ...message }, "*");
const fail = (message: string) => new Error(message);

window.addEventListener("message", (event: MessageEvent) => {
  if (!frame || event.source !== frame.contentWindow) return;
  const parsed = frameMessageSchema.safeParse(event.data);
  if (!parsed.success) return;
  const message = parsed.data;
  if (message.type === "ready") {
    if (documentID || !message.document) return;
    documentID = message.document;
    // INF-1338: the body can answer a ping from here on, so the native watchdog starts counting its own answers.
    void native({ type: "ready" }).catch(() => {});
    send({ type: "form", fill: cardAnswersSchema.parse(input.fill ?? []), readOnly: input.readOnly });
    send({ type: "keys", pictures: true, escape: false });
    send({ type: "width", width: input.width });
    if (linked.length > 0) send({ type: "tasks", keys: linked });
    // INF-1562: a picture comes over the connection and waits while the computer is out of reach, so the body draws
    // and takes its height without it; WebKit's fonts.ready alone would wait for every picture.
    send({ type: "initialize", document: documentID, latePictures: true });
    return;
  }
  if (!documentID || ("document" in message && message.document && message.document !== documentID)) return;
  switch (message.type) {
    case "answers": {
      const { questions: raw, ...reading } = message;
      const questions = cardQuestionsSchema.safeParse(raw);
      const answers = { ...reading, ...(questions.success ? { questions: questions.data } : { questionsGap: "invalid" as const }) };
      void native({ type: "answers", reading: answers }).catch(() => {});
      if (message.seq !== undefined) {
        const collection = collections.get(message.seq);
        if (collection) { clearTimeout(collection.timer); collections.delete(message.seq); collection.resolve(answers); }
      }
      break;
    }
    case "resize":
      // The phone owns one scrolling WebView. The iframe grows within it, not a second scroller.
      frame.style.height = `${Math.max(48, Math.min(1_000_000, message.height))}px`;
      if (message.initialized) void native({ type: "drawn", height: message.height }).catch(() => {});
      break;
    case "pong": void native({ type: "pong", seq: message.seq }).catch(() => {}); break;
    case "request": {
      const request = frameRequestSchema.safeParse(message);
      const reply = (ok: boolean, value: unknown) => send({ type: "response", document: documentID, id: message.id,
        ...(ok ? { ok, result: value } : { ok, error: { code: "refused", message: String(value) } }) });
      if (!request.success || request.data.verb !== "action" || input.readOnly || !input.actions.includes(request.data.action)) {
        reply(false, "This card cannot do that."); return;
      }
      const value = request.data.value;
      if (value !== undefined && new TextEncoder().encode(JSON.stringify(value)).length > ACTION_VALUE_MAX_BYTES) { reply(false, "The answer is too large."); return; }
      // No chrome source, arbitrary request channel, close, reply, or navigation can cross this bridge.
      void native({ type: "action", id: request.data.action, value: value ?? null })
        .then((result) => reply(true, result), (error) => reply(false, error));
      break;
    }
    case "image": {
      if (!document.hasFocus() || !navigator.userActivation.isActive) return;
      const set = viewablePictures(message.index, message.pictures);
      if (set) void native({ type: "image", ...set }).catch(() => {});
      break;
    }
    case "demo":
      if (document.hasFocus() && navigator.userActivation.isActive && demoSources(input.body).has(message.src) && viewablePictures(0, [message.poster]))
        void native({ type: "demo", src: message.src, poster: message.poster, caption: message.caption, play: message.play }).catch(() => {});
      break;
    // INF-1524: a link opens in the phone's own browser, a draft goes to the message box and a key opens its record.
    case "link":
      if (pressed() && isSafeCardHref(message.href)) void native({ type: "link", href: message.href }).catch(() => {});
      break;
    case "draft":
      if (pressed()) void native({ type: "draft", text: message.text }).catch(() => {});
      break;
    case "task":
      if (message.gesture === "open" && linked.includes(message.key)) void native({ type: "task", key: message.key }).catch(() => {});
      break;
    case "entry":
      void native({ type: "mac-only" }).catch(() => {}); break;
  }
});

window.phoneCard = {
  async mount(value) {
    input = value;
    // The Mac's split: a settle card's fact strip stands beside its choices, and the body shows the rest.
    const split = value.card && takesTaskFacts(value.card) ? splitSettleFacts(value.body) : undefined;
    const marks = (value.marks ?? []).map((mark) => (split && mark > split.at ? mark - split.facts.length : mark));
    linked = value.keys?.length ? taskKeysIn(value.body).filter((key) => value.keys!.includes(key)) : [];
    void native({ type: "mounted", facts: split?.facts ?? null, preview: isPreviewBody(value.body) }).catch(() => {});
    // DOMParser is inert. Hash the script text the browser actually parses, never an event attribute.
    const body = cardBodyMarkup(split?.body ?? value.body, marks).html;
    const parsed = new DOMParser().parseFromString(body, "text/html");
    const scripts = Array.from(parsed.querySelectorAll("script:not([src])"), (script) => script.textContent ?? "");
    const hashes = await native({ type: "hash", scripts }) as string[];
    const document = buildFrameDocument({ csp: `${frameCsp(hashes)}; base-uri 'none'; form-action 'none'`,
      theme: value.theme, style: cardStylesheet(), html: body });
    frame = window.document.createElement("iframe");
    frame.title = "Card body";
    frame.setAttribute("sandbox", FRAME_SANDBOX);
    frame.style.cssText = "display:block;width:100%;height:48px;border:0";
    // INF-1263 / INF-1651: native code keeps the web view out of reach and out of accessibility until it holds the
    // drawn body's height. Hiding the frame here would stick on iOS 27.0, which never exposes the body again.
    frame.srcdoc = document;
    window.document.body.replaceChildren(frame);
  },
  collect() {
    if (!documentID) return Promise.reject(fail("This card is still drawing. Try again once it is ready."));
    const seq = ++next;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { collections.delete(seq); reject(fail("This card did not answer. Your choice was not sent.")); }, 3000);
      collections.set(seq, { resolve, reject, timer });
      send({ type: "collect", seq, focusUnpicked: true });
    });
  },
  theme(value) { send({ type: "theme", theme: value }); },
  ping(seq) { send({ type: "ping", seq }); },
};
