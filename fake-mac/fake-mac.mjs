// A fake Firstmate 3000 home. It follows the published contract
// (docs/contract.json and docs/connection.md of Firstmate 3000 0.1.30) so the
// iPhone app can be validated without the captain's real Mac:
//   - TLS 1.3 only, the home's own self-signed ECDSA P-256 key, a client
//     certificate asked for but not chain-checked (the pin is the trust);
//   - POST /pair with a one-use, ten-minute code; refusals as the contract's
//     { refused, reason } with its statuses; an Origin is refused with 403;
//   - WebSocket /connection: Origin -> 403, other path -> 404, not an upgrade
//     -> 426, unknown device -> 401; first frame must be `hello`; the home
//     answers `welcome`, then invoke/result and numbered pushes.
// Every argument list a client sends and every answer this file gives is
// checked against the JSON Schema in docs/contract.json, so a fixture that
// drifts from the contract fails here instead of in the app.
import { createHash, randomBytes, X509Certificate } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { createServer } from "node:https";
import { join } from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import { WebSocketServer } from "ws";

export const DEFAULT_CONTRACT =
  "/Applications/Infinitary.app/Contents/Resources/self-source/docs/contract.json";

const b64url = (buffer) => Buffer.from(buffer).toString("base64url");
const sha256 = (buffer) => createHash("sha256").update(buffer).digest();

/** SHA-256 over a certificate's SubjectPublicKeyInfo, base64url (docs/devices.md, "Keys"). */
export function pinOfCertificate(der) {
  const spki = new X509Certificate(der).publicKey.export({ type: "spki", format: "der" });
  return b64url(sha256(spki));
}

/** Makes (or reads) the home's key and self-signed certificate with openssl. */
export function homeIdentity(stateDir) {
  mkdirSync(stateDir, { recursive: true });
  const keyPath = join(stateDir, "home-key.pem");
  const certPath = join(stateDir, "home-cert.pem");
  if (!existsSync(keyPath) || !existsSync(certPath)) {
    execFileSync("openssl", [
      "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-pkeyopt", "ec_param_enc:named_curve", "-nodes",
      "-keyout", keyPath, "-out", certPath, "-days", "3650", "-subj", "/CN=fake-firstmate-home",
    ], { stdio: "ignore" });
  }
  const cert = readFileSync(certPath);
  return { key: readFileSync(keyPath), cert, pin: pinOfCertificate(new X509Certificate(cert).raw) };
}

const AT = () => Date.now();

function fixtureCards(now) {
  const base = (id, title, body, actions, extra = {}) => ({
    id, author: "firstmate", priority: 1, title, meta: "Fake home", body, actions,
    status: "ready", createdAt: now, ...extra,
  });
  const cards = [
    base(
      "card-merge-1",
      "Merge the settings page change?",
      "<p>The <strong>settings page</strong> change is green and ready.</p><p>It touches <code>src/settings.ts</code> only.</p><ul><li>Checks passed</li><li>Risk: low</li></ul><h2>What changed</h2><p>One screen, <mark>no new dependency</mark>.</p><figure aria-label=\"flow\"><svg viewBox=\"0 0 300 60\" width=\"100%\"><rect x=\"4\" y=\"14\" width=\"80\" height=\"32\" rx=\"8\" fill=\"none\" stroke=\"var(--line-2)\"/><text x=\"44\" y=\"34\" text-anchor=\"middle\">Branch</text><path d=\"M84 30h50\" stroke=\"var(--accent)\" stroke-width=\"2\"/><rect x=\"134\" y=\"14\" width=\"80\" height=\"32\" rx=\"8\" fill=\"var(--accent-dim)\" stroke=\"var(--accent)\"/><text x=\"174\" y=\"34\" text-anchor=\"middle\" fill=\"var(--fg-1)\">Checks</text><path d=\"M214 30h40\" stroke=\"var(--ok)\" stroke-width=\"2\"/><circle cx=\"270\" cy=\"30\" r=\"12\" fill=\"var(--ok-dim)\" stroke=\"var(--ok)\"/></svg><figcaption>Where it stands</figcaption></figure><table><tr><th>Check</th><th>Result</th></tr><tr><td>Tests</td><td>Passed</td></tr></table>",
      [
        { id: "merge", label: "Merge", variant: "primary", default: true, effect: { kind: "settle", mode: "merge" } },
        { id: "later", label: "Not now", variant: "ghost" },
      ],
      { taskId: "task-1", author: "crewmate", priority: 2, model: "claude-sonnet-5-5" },
    ),
    base(
      "card-question-1",
      "Which name should the new panel use?",
      "<p>Pick a name, or reply with your own.</p>",
      [
        { id: "radar", label: "Radar", variant: "secondary" },
        { id: "bridge", label: "Bridge", variant: "secondary", default: true },
      ],
      { asking: true },
    ),
  ];
  // FM_PUT_ASIDE=1 starts with two cards already put aside, to try the Put aside chip on a phone or simulator.
  if (process.env.FM_PUT_ASIDE) {
    cards.push(
      base("card-later-1", "Rename the build script?", "<p>The script is called <code>go.sh</code> today.</p>", [{ id: "yes", label: "Rename it", variant: "primary", default: true }, { id: "no", label: "Keep it", variant: "secondary" }], { author: "crewmate", taskId: "task-2", createdAt: now - 3_600_000, minimized: true }),
      base("card-later-2", "Which icon for the new tab?", "<p>Pick one when you have a minute.</p>", [{ id: "a", label: "Tray", variant: "secondary" }, { id: "b", label: "Clock", variant: "secondary" }], { createdAt: now - 7_200_000, minimized: true }),
    );
  }
  return cards;
}

function fixtureBoard(now) {
  return {
    seq: 1,
    at: now,
    projects: [
      {
        id: "project-1", key: "FM", name: "Fake project",
        repo: { name: "fake/repo", delivery: "local-only", autonomy: false },
        archived: false,
        counts: { needsYou: 2, waitingOnYou: 0, open: 1, active: 1, doneRecent: 0 },
      },
    ],
    tasks: [
      {
        id: "task-1", key: "FM-1", projectId: "project-1", parentId: null, kind: "work",
        title: "Tidy the settings page", goal: "Group the toggles", priority: 2, status: "active",
        activity: "running", closedReason: null, startPolicy: "when-ready",
        flags: { blocked: false, held: false, needsYou: true, ready: false }, blockedBy: [], blocks: [], children: { total: 0, closed: 0 }, assignee: "crewmate",
        model: "sonnet", tier: "medium", repo: { name: "fake/repo", branch: "fm/task-1" }, delivery: { mode: "local-only", ci: "no-pr" },
        outcomeSummary: null, waitingCardId: "card-merge-1", createdAt: now, updatedAt: now,
        startedAt: now, closedAt: null,
      },
      ...[["task-2", "FM-2", "Add the pictures to cards"], ["task-3", "FM-3", "Check the landscape layout"]].map(([id, key, title], index) => ({
        id, key, projectId: "project-1", parentId: null, kind: "work",
        title, goal: title, priority: 2, status: "open",
        activity: null, closedReason: null, startPolicy: "when-ready",
        flags: { blocked: false, held: false, needsYou: false, ready: true }, blockedBy: [], blocks: [], children: { total: 0, closed: 0 }, assignee: null,
        model: null, tier: "medium", repo: { name: "fake/repo", branch: "fm/" + key.toLowerCase() }, delivery: { mode: "local-only", ci: "no-pr" },
        outcomeSummary: null, waitingCardId: null, createdAt: now - 1000 * (index + 1), updatedAt: now - 1000 * (index + 1),
        startedAt: null, closedAt: null,
      })),
    ],
    links: [],
  };
}

function fixtureDetail(now) {
  const t = fixtureBoard(now).tasks[0];
  return {
    ...t, goal: "Group the toggles on the settings page", workPosture: { state: "active", reason: "turn" },
    delivery: { mode: "direct-pr", prNumber: 42, prUrl: "https://example.com/fake/repo/pull/42", ci: "green",
      runChecks: { runId: 7, name: "CI / test", state: "passed", at: now } },
    modelLabel: "Claude Sonnet 5.5", reasoning: { level: "medium" }, intent: null, rigor: "standard", deliverable: "change", basis: null, skippedPlanBecause: null,
    brief: "Group the toggles.", outcome: null, cards: [], events: [], activityLog: [], plan: null, closing: null, problem: null, asks: [],
  };
}

function fixtureCrew(now) {
  const at = (n) => now - n * 60_000;
  // FM_LONG_CREW=n pads the thread with n older lines, to try a long history on a phone or simulator.
  const filler = Array.from({ length: Number(process.env.FM_LONG_CREW ?? 0) }, (_, i) => ({ kind: "said", id: `f${i}`, at: at(100 + i), text: `Earlier note ${i + 1}: working through the settings page step by step.` })).reverse();
  return [
    ...filler,
    { kind: "brief", id: "l1", at: at(30), text: "Group the toggles on the settings page." },
    { kind: "said", id: "l2", at: at(20), text: "I found the toggles in SettingsView and will group them under three headings." },
    { kind: "card", id: "l3", at: at(10), title: "Merge the settings page change?", cardId: "card-merge-1" },
    { kind: "report", id: "l4", at: at(5), summary: "Settings grouped", text: "Three headings, tests green." },
  ];
}

function fixtureFeed(now) {
  return [
    { kind: "info", text: "FM-1 started.", at: now - 60_000, taskKey: "FM-1", event: "dispatched" },
    { kind: "ok", text: "FM-1 checks passed.", at: now - 30_000, taskKey: "FM-1", event: "ci" },
  ];
}

export async function startFakeMac(options = {}) {
  const {
    host = "127.0.0.1",
    port = 0,
    stateDir,
    contractPath = DEFAULT_CONTRACT,
    pairName = "fake home",
    heartbeatMs = 30_000,
    helloTimeoutMs = 60_000,
    log = () => {},
  } = options;
  const contract = JSON.parse(readFileSync(contractPath, "utf8"));
  const home = homeIdentity(stateDir);
  const ajv = new Ajv2020({ strict: false, validateFormats: false, allErrors: false });
  const compile = (schema) => ajv.compile(schema);
  const validate = {
    pairRequest: compile(contract.connection.pair.request),
    clientFrame: compile(contract.connection.clientFrame),
  };
  const channelSchemas = new Map();
  const schemaFor = (channel) => {
    if (!channelSchemas.has(channel)) {
      const entry = contract.requests[channel];
      channelSchemas.set(
        channel,
        entry ? { args: compile(entry.request), response: compile(entry.response), entry } : null,
      );
    }
    return channelSchemas.get(channel);
  };
  const pushSchema = (channel) => {
    const key = `push:${channel}`;
    if (!channelSchemas.has(key)) channelSchemas.set(key, compile(contract.pushes[channel].payload));
    return channelSchemas.get(key);
  };
  const [homeMajor] = contract.protocolVersion.split(".").map(Number);
  const majorsBehind = contract.versionRule.majorsBehind ?? 1;

  const events = [];
  const record = (event) => {
    const entry = { at: AT(), ...event };
    events.push(entry);
    log(entry);
  };

  // What the home holds.
  const now = AT();
  const state = { cards: fixtureCards(now), threads: new Map(), board: fixtureBoard(now), feed: fixtureFeed(now), crew: fixtureCrew(now),
    lastTurn: { you: "Tidy the settings page", reply: { text: "Started FM-1: grouping the toggles under three headings.", eligibility: "completed" } } };
  for (const card of state.cards) state.threads.set(card.id, []);
  let nextMessageId = 1;
  const links = new Map(); // sha256(code) -> { kind, expiresAt, used }
  const devices = new Map(); // pin -> { deviceId, kind, name }
  const epoch = b64url(randomBytes(9));
  const journal = [];
  const connections = new Set();

  const assertValid = (validator, value, what) => {
    if (!validator(value)) {
      throw new Error(`fake home would break the contract in ${what}: ${JSON.stringify(validator.errors)}`);
    }
  };
  // A fixture must fit the contract before it is ever served.
  assertValid(schemaFor("inf:cards:list").response, state.cards, "inf:cards:list fixture");
  assertValid(schemaFor("inf:tasks:board").response, state.board, "inf:tasks:board fixture");
  assertValid(schemaFor("inf:feed:recent").response, state.feed, "inf:feed:recent fixture");
  assertValid(schemaFor("inf:tasks:detail").response, fixtureDetail(now), "inf:tasks:detail fixture");
  assertValid(schemaFor("inf:tasks:crewmate").response, { taskId: "task-1", earlier: 0, lines: state.crew, revision: "r1" }, "inf:tasks:crewmate fixture");

  function invite(kind = "mac", { ttlMs = 10 * 60_000 } = {}) {
    const code = b64url(randomBytes(32));
    links.set(b64url(sha256(code)), { kind, expiresAt: AT() + ttlMs, used: false });
    return code;
  }

  function linkFor(code, { at, also, key = home.pin } = {}) {
    const address = at ?? `${host}:${server.address().port}`;
    const query = new URLSearchParams({ as: "mac", at: address, ...(also ? { also } : {}), key, code });
    return `firstmate3000://join?${query}`;
  }

  function send(ws, frame) {
    ws.send(JSON.stringify(frame));
  }

  // A device whose hello does not say it reads `inf` is from before the rename: the Mac writes its pushes under `fm:` names.
  const respelled = (frame, connection) =>
    connection.readsInf ? frame : { ...frame, channel: frame.channel.replace(/^inf:/, "fm:") };

  function push(channel, payload) {
    assertValid(pushSchema(channel), payload, `push ${channel}`);
    const frame = { t: "push", seq: (journal.at(-1)?.seq ?? 0) + 1, channel, payload };
    journal.push(frame);
    for (const connection of connections) if (connection.welcomed) send(connection.ws, respelled(frame, connection));
    record({ ev: "push", channel, seq: frame.seq });
  }

  const refusal = (refused, reason) => ({ refused, reason });
  const STATUS = contract.connection.pair.refusalStatus;

  function readBody(request, limit) {
    return new Promise((resolve, reject) => {
      const chunks = [];
      let size = 0;
      request.on("data", (chunk) => {
        size += chunk.length;
        if (size > limit) reject(Object.assign(new Error("too big"), { status: 413 }));
        else chunks.push(chunk);
      });
      request.on("end", () => resolve(Buffer.concat(chunks)));
      request.on("error", reject);
    });
  }

  async function pair(request, response) {
    const reply = (status, body) => {
      response.writeHead(status, {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
        Connection: "close",
      });
      response.end(JSON.stringify(body));
    };
    const plain = (status) => response.writeHead(status, { Connection: "close" }).end();
    if (request.headers.origin !== undefined) {
      record({ ev: "pair-refused", why: "origin" });
      return plain(403);
    }
    if (request.method !== "POST") return plain(405);
    if (!String(request.headers["content-type"] ?? "").startsWith("application/json")) return plain(415);
    let body;
    try {
      body = await readBody(request, contract.connection.pair.maxBodyBytes);
    } catch (error) {
      return plain(error.status ?? 400);
    }
    let parsed;
    try {
      parsed = JSON.parse(body.toString("utf8"));
    } catch {
      return reply(STATUS.malformed, refusal("malformed", "That is not a request to join."));
    }
    if (!validate.pairRequest(parsed)) {
      record({ ev: "pair-refused", why: "malformed", errors: validate.pairRequest.errors });
      return reply(STATUS.malformed, refusal("malformed", "That is not a request to join."));
    }
    const clientCert = request.socket.getPeerCertificate(true);
    if (!clientCert || !clientCert.raw) {
      return reply(STATUS.unproven, refusal("unproven", "The device showed no key of its own."));
    }
    const link = links.get(b64url(sha256(parsed.code)));
    if (!link) return reply(STATUS.unknown, refusal("unknown", "No open link has that code."));
    if (link.used) return reply(STATUS.used, refusal("used", "That link was used already."));
    if (link.expiresAt < AT()) return reply(STATUS.expired, refusal("expired", "That link has expired."));
    // Infinitary 11: a device that runs work must name its user; only a phone (system ios) may omit it.
    if (parsed.kind !== "view" && parsed.system !== "ios" && !parsed.user) {
      return reply(STATUS.malformed, refusal("malformed", "The request to join is not one this home reads."));
    }
    if (link.kind !== parsed.kind) return reply(STATUS.kind, refusal("kind", "That link is for another kind."));
    const pin = pinOfCertificate(clientCert.raw);
    if (devices.has(pin)) return reply(STATUS.paired, refusal("paired", "That device is paired already."));
    link.used = true;
    const device = { deviceId: `device-${b64url(randomBytes(6))}`, kind: parsed.system === "ios" ? "view" : parsed.kind, name: parsed.name };
    devices.set(pin, device);
    record({ ev: "pair", deviceId: device.deviceId, kind: device.kind, name: device.name, window: parsed.window === true, system: parsed.system, tls: request.socket.getProtocol(), pin });
    reply(201, { deviceId: device.deviceId, kind: device.kind });
  }

  const handlers = {
    "inf:cards:list": () => state.cards,
    "inf:tasks:board": () => state.board,
    "inf:quota:snapshot": () => {
      const now = Date.now(), win = (id, label, left, seconds) => ({ id, label, percentRemaining: left, windowSeconds: seconds, resetsAtMs: now + seconds * 1000 * 0.4, pace: "on_pace" });
      return { generatedAt: new Date(now).toISOString(), fetchedAt: now, providers: [
        { provider: "claude", label: "Claude", plan: "team", status: "ok", stale: false, measuredAt: now, windows: [win("five_hour", "session", 78, 18000), win("seven_day", "week", 44, 604800)] },
        { provider: "codex", label: "Codex", plan: "team", status: "ok", stale: false, measuredAt: now, windows: [win("five_hour", "session", 98, 18000), win("weekly", "week", 96, 604800)] },
      ] };
    },
    "inf:feed:recent": () => state.feed,
    "inf:plugins:db": ([query]) => {
      if (query.op !== "get" || query.extensionId !== "open-prs" || query.key !== "prs") return { value: null };
      const day = 24 * 3600_000, ago = (ms) => new Date(Date.now() - ms).toISOString();
      const pr = (number, project, title, checks, opened, extra = {}) => ({ host: "github.com", project, number, label: `#${number}`, title, url: `https://example.com/${project}/pull/${number}`, draft: false, checks, updatedAt: ago(opened / 2), createdAt: ago(opened), ...extra });
      return { value: { status: "ok", changes: [
        pr(42, "fake/repo", "Group the toggles on the settings page", "passed", 2 * 3600_000),
        pr(41, "fake/repo", "Add the Others tab", "passed", 3 * day),
        pr(40, "fake/ios", "Draft: card pictures", "passed", day * 2, { draft: true }),
        pr(38, "fake/ios", "Fix the keyboard trap in the composer", "failed", 5 * day),
        pr(35, "fake/tools", "Bump the toolchain", "pending", 12 * day),
        pr(30, "fake/tools", "Rewrite the release script", "none", 40 * day, { label: null }),
      ] } };
    },
    "inf:plugins:invoke": ([id, name]) => {
      if (id === "machine-load" && name === "sample") return { ok: true, result: { gpu: 18 + Math.round(((Date.now() / 1000) % 20)), memory: { usedBytes: 13.4 * 1024 ** 3, totalBytes: 24 * 1024 ** 3 } } };
      if (id === "open-prs" && name === "refresh") return { ok: true, result: null };
      return { ok: false, error: "There is no such panel action." };
    },
    "inf:computers:resources": () => {
      const gib = 1024 ** 3, wobble = (Date.now() / 3000) % 1;
      return { computers: [{ computerId: null, label: "This computer", reading: { status: "fresh", ageMs: 400, memoryUsedBytes: Math.round((11 + wobble) * gib),
        observation: { epoch: "00000000-0000-0000-0000-000000000000", sequence: 1, status: "sampled", sampleMs: 1000,
          cpu: { logicalCpus: 12, idleFraction: 0.62 - wobble / 10 },
          memory: { totalBytes: 24 * gib, freeBytes: 2 * gib, availableBytes: 9 * gib, purgeableBytes: gib, fileBackedBytes: 4 * gib, inactiveBytes: 3 * gib, memoryPressure: "normal" } } } },
        { computerId: "dev-2", label: "Mac mini", reading: { status: "unknown", reason: "out-of-reach" } }] };
    },
    "inf:tasks:detail": ([taskId]) => {
      if (taskId !== "task-1") throw new Error("There is no such task.");
      return fixtureDetail(now);
    },
    "inf:tasks:crewmate": ([taskId]) => ({ taskId, earlier: 0, lines: [...state.crew], revision: `r${state.crew.length}` }),
    "inf:tasks:crewmate:live": ([taskId]) => ({ taskId, text: "Running the tests for the settings page.", since: AT() }),
    "inf:task:run": ([taskId, verb]) => {
      record({ ev: "run", taskId, verb });
      const task = state.board.tasks.find((t) => t.id === taskId);
      if (!task || verb !== "start-task") return { ok: false, text: "That is not something this fake Mac does." };
      task.status = "active"; task.assignee = "crewmate"; task.activity = "running";
      return { ok: true };
    },
    "inf:task:steer": ([taskId, text]) => {
      const task = state.board.tasks.find((t) => t.id === taskId);
      if (task && task.status === "open" && !task.assignee) return { ok: false, text: `${task.key} has not started, so no crewmate can read this.` };
      record({ ev: "steer", taskId, text });
      state.crew.push({ kind: "sent", id: `l${state.crew.length + 1}`, at: AT(), from: "captain", text, queued: false, via: "other" });
      return { ok: true };
    },
    "inf:conversation:last-turn": () => state.lastTurn ?? null,
    "inf:cards:thread": ([cardId]) => ({ cardId, messages: [...(state.threads.get(cardId) ?? [])] }),
    "inf:cards:close": ([cardId]) => {
      record({ ev: "close", cardId });
      state.cards = state.cards.filter((c) => c.id !== cardId);
      return { ok: true };
    },
    // Put aside (the Mac's Minimize): one optional fact on the card, kept for every device. `false` removes it.
    "inf:cards:minimize": ([cardId, minimized]) => {
      const card = state.cards.find((c) => c.id === cardId);
      if (!card) throw new Error("There is no such card.");
      record({ ev: "card-minimized", cardId, minimized });
      const { minimized: _old, ...rest } = card;
      state.cards = state.cards.map((c) => (c.id === cardId ? (minimized ? { ...rest, minimized: true } : rest) : c));
      queueMicrotask(() => push("inf:cards", state.cards));
      return { ok: true };
    },
    "inf:cards:act": ([cardId, actionId, , value]) => {
      const card = state.cards.find((c) => c.id === cardId);
      if (!card) throw new Error("There is no such card.");
      const action = card.actions.find((a) => a.id === actionId);
      if (!action) throw new Error("That card has no such action.");
      record({ ev: "card-acted", cardId, actionId, words: value?.answers?.find((a) => a.name === "anything_else")?.written ?? null });
      if (!action.keepsOpen) {
        state.cards = state.cards.filter((c) => c.id !== cardId);
        queueMicrotask(() => push("inf:cards", state.cards));
      }
      state.feed = [...state.feed, { kind: "you", text: `You chose ${action.label}.`, at: AT(), event: "decided" }];
      return {};
    },
    "inf:cards:reply": ([cardId, payload]) => {
      const card = state.cards.find((c) => c.id === cardId);
      if (!card) throw new Error("There is no such card.");
      const text = typeof payload === "string" ? payload : (payload.text ?? "");
      const thread = state.threads.get(cardId) ?? [];
      thread.push({ id: nextMessageId++, cardId, who: "captain", text, at: AT() });
      state.threads.set(cardId, thread);
      record({ ev: "card-replied", cardId, text, images: payload.images?.length ?? 0, files: payload.files?.length ?? 0 });
      const result = { cardId, messages: [...thread] };
      // The author owes an answer: the card says so (`awaiting`) until the answer is written, as on the Mac.
      const answering = (c) => ({ ...c, awaiting: "answer", sentBackAt: AT() });
      state.cards = state.cards.map((c) => (c.id === cardId ? answering(c) : c));
      queueMicrotask(() => push("inf:cards", state.cards));
      setTimeout(() => {
        thread.push({ id: nextMessageId++, cardId, who: "firstmate", text: `Noted: ${text}`, at: AT() });
        push("inf:cards:thread", { cardId, messages: [...thread] });
        // The author changed the card: a put-aside card comes back by itself at the end of its turn (INF-926).
        state.cards = state.cards.map((c) => {
          if (c.id !== cardId) return c;
          const { minimized: _m, awaiting: _a, sentBackAt: _s, ...rest } = c;
          return rest;
        });
        push("inf:cards", state.cards);
      }, 150);
      return result;
    },
    "inf:converse": ([input]) => {
      const text = typeof input === "string" ? input : (input.text ?? "");
      record({ ev: "converse", text, images: input.images?.length ?? 0, files: input.files?.length ?? 0 });
      state.feed = [...state.feed, { kind: "you", text, at: AT(), event: "replied" }];
      const answer = { you: text, reply: { text: `Got it: ${text}`, eligibility: "completed" } };
      // "quiet:" is a reply that no push announces: only the saved last turn has it, as when a push misses a phone.
      if (text.startsWith("quiet:")) setTimeout(() => { state.lastTurn = answer; }, 300);
      else {
        state.lastTurn = answer;
        setTimeout(() => push("inf:event", { type: "firstmate_reply", text: `Got it: ${text}`, eligibility: "completed" }), 30);
      }
      setTimeout(() => {
        const card = {
          id: `card-answer-${nextMessageId++}`, author: "firstmate", priority: 1,
          title: "Firstmate answered", meta: "Fake home", body: `<p>You said: ${text.replace(/</g, "&lt;")}</p>`,
          actions: [{ id: "ok", label: "Thanks", variant: "primary", default: true }],
          status: "ready", createdAt: AT(),
        };
        state.cards = [...state.cards, card];
        state.threads.set(card.id, []);
        push("inf:cards", state.cards);
      }, 50);
      return { ok: true };
    },
  };

  function hasFullAccess(clientVersion) {
    const [major] = clientVersion.split(".").map(Number);
    return major === homeMajor || major === homeMajor - majorsBehind;
  }

  function serve(ws, request, device) {
    const connection = { ws, device, welcomed: false, alive: true };
    connections.add(connection);
    const closeProtocol = (reason) => ws.close(contract.connection.close.protocol, reason);
    const helloTimer = setTimeout(() => closeProtocol("no hello"), helloTimeoutMs);
    const beat = setInterval(() => {
      if (!connection.alive) return ws.terminate();
      connection.alive = false;
      ws.ping();
    }, heartbeatMs);
    ws.on("pong", () => (connection.alive = true));
    ws.on("close", () => {
      clearTimeout(helloTimer);
      clearInterval(beat);
      connections.delete(connection);
      record({ ev: "closed", deviceId: device.deviceId });
    });
    ws.on("message", (data, isBinary) => {
      if (isBinary) return closeProtocol("binary");
      let frame;
      try {
        frame = JSON.parse(data.toString("utf8"));
      } catch {
        return closeProtocol("not json");
      }
      if (!validate.clientFrame(frame)) return closeProtocol("bad frame");
      if (frame.t === "hello") {
        if (connection.welcomed) return closeProtocol("second hello");
        clearTimeout(helloTimer);
        connection.welcomed = true;
        connection.readsInf = Array.isArray(frame.spellings) && frame.spellings.includes("inf");
        connection.access = hasFullAccess(frame.protocolVersion) ? "full" : "read";
        const cursor = frame.cursor;
        const oldest = journal[0]?.seq ?? (journal.at(-1)?.seq ?? 0) + 1;
        const newest = journal.at(-1)?.seq ?? 0;
        const replay = cursor && cursor.epoch === epoch && cursor.seq <= newest && cursor.seq >= oldest - 1;
        record({
          ev: "hello", deviceId: device.deviceId, protocolVersion: frame.protocolVersion, as: frame.as,
          system: frame.system, chip: frame.chip, hasOrigin: request.headers.origin !== undefined,
          tls: request.socket.getProtocol(), cursor: cursor ?? null, catchUp: replay ? "replay" : "reload",
        });
        send(ws, {
          t: "welcome", protocolVersion: contract.protocolVersion, epoch, seq: newest,
          catchUp: replay ? "replay" : "reload", access: connection.access, name: pairName, spellings: ["fm", "inf"],
        });
        if (replay) for (const missed of journal.filter((p) => p.seq > cursor.seq)) send(ws, respelled(missed, connection));
        return;
      }
      if (!connection.welcomed) return closeProtocol("request before hello");
      if (frame.t === "leave") {
        for (const [pin, d] of devices) if (d === device) devices.delete(pin);
        record({ ev: "left", deviceId: device.deviceId });
        return ws.close(contract.connection.close.unpaired, "unpaired");
      }
      if (frame.t !== "invoke") return;
      const reply = (body) => send(ws, { t: "result", id: frame.id, ...body });
      const schemas = schemaFor(frame.channel);
      if (!schemas) return reply({ ok: false, error: "That is not a request this home answers." });
      if (schemas.entry.reach !== "views") return reply({ ok: false, error: "That is not a request this home answers." });
      if (connection.access === "read" && schemas.entry.effect === "change") {
        return reply({ ok: false, error: "This app must be updated before it can change anything." });
      }
      if (!schemas.args(frame.args)) {
        record({ ev: "invoke-refused", channel: frame.channel, errors: schemas.args.errors });
        return reply({ ok: false, error: "That request is not shaped as the contract says." });
      }
      const handler = handlers[frame.channel];
      if (!handler) return reply({ ok: false, error: "This fake home does not answer that channel." });
      try {
        const value = handler(frame.args);
        assertValid(schemas.response, value, `answer of ${frame.channel}`);
        record({ ev: "invoke", channel: frame.channel });
        reply({ ok: true, value });
      } catch (error) {
        reply({ ok: false, error: error.message });
      }
    });
  }

  const server = createServer({
    key: home.key,
    cert: home.cert,
    minVersion: "TLSv1.3",
    maxVersion: "TLSv1.3",
    requestCert: true,
    rejectUnauthorized: false,
    sessionTimeout: 0,
  });
  server.keepAliveTimeout = 0;
  // A session is never resumed (docs/devices.md, "Keys").
  server.on("request", (request, response) => {
    const path = new URL(request.url, "https://home").pathname;
    if (path === contract.connection.pair.path) return void pair(request, response);
    response.writeHead(path === contract.connection.path ? 426 : 404, { Connection: "close" }).end();
  });
  const wss = new WebSocketServer({ noServer: true, maxPayload: contract.connection.maxFrameBytes });
  server.on("upgrade", (request, socket, head) => {
    const refuse = (status, why) => {
      record({ ev: "upgrade-refused", status, why });
      socket.end(`HTTP/1.1 ${status}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`);
    };
    const path = new URL(request.url, "https://home").pathname;
    if (request.headers.origin !== undefined) return refuse(403, "origin");
    if (path !== contract.connection.path) return refuse(404, "path");
    const peer = request.socket.getPeerCertificate(true);
    const device = peer?.raw ? devices.get(pinOfCertificate(peer.raw)) : undefined;
    if (!device) {
      record({ ev: "upgrade-unknown-device", hasCert: Boolean(peer?.raw), pin: peer?.raw ? pinOfCertificate(peer.raw) : null, headers: request.headers });
      return refuse(401, "unpaired");
    }
    record({ ev: "upgrade", deviceId: device.deviceId, tls: request.socket.getProtocol(), origin: null });
    wss.handleUpgrade(request, socket, head, (ws) => serve(ws, request, device));
  });

  await new Promise((resolve) => server.listen(port, host, resolve));

  return {
    home,
    events,
    state,
    devices,
    port: () => server.address().port,
    address: () => `${host}:${server.address().port}`,
    invite,
    link: (code, linkOptions) => linkFor(code, linkOptions),
    push,
    /** Removes every device, as Remove in Settings > Devices does, closing their sockets. */
    removeAll() {
      devices.clear();
      for (const connection of connections) connection.ws.close(contract.connection.close.unpaired, "unpaired");
    },
    dropConnections() {
      for (const connection of connections) connection.ws.terminate();
    },
    async stop() {
      for (const connection of connections) connection.ws.terminate();
      await new Promise((resolve) => server.close(resolve));
    },
  };
}
