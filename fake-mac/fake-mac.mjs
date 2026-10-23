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
  return [
    base(
      "card-merge-1",
      "Merge the settings page change?",
      "<p>The <strong>settings page</strong> change is green and ready.</p><p>It touches <code>src/settings.ts</code> only.</p><ul><li>Checks passed</li><li>Risk: low</li></ul>",
      [
        { id: "merge", label: "Merge", variant: "primary", default: true, effect: { kind: "settle", mode: "merge" } },
        { id: "later", label: "Not now", variant: "ghost" },
      ],
      { taskId: "task-1", author: "crewmate", priority: 2 },
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
    modelLabel: "Sonnet", intent: null, rigor: "standard", deliverable: "change", basis: null, skippedPlanBecause: null,
    brief: "Group the toggles.", outcome: null, cards: [], events: [], activityLog: [], plan: null, closing: null, problem: null, asks: [],
  };
}

function fixtureCrew(now) {
  const at = (n) => now - n * 60_000;
  return [
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
  const state = { cards: fixtureCards(now), threads: new Map(), board: fixtureBoard(now), feed: fixtureFeed(now), crew: fixtureCrew(now) };
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

  function push(channel, payload) {
    assertValid(pushSchema(channel), payload, `push ${channel}`);
    const frame = { t: "push", seq: (journal.at(-1)?.seq ?? 0) + 1, channel, payload };
    journal.push(frame);
    for (const connection of connections) if (connection.welcomed) send(connection.ws, frame);
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
    "inf:feed:recent": () => state.feed,
    "inf:tasks:detail": ([taskId]) => {
      if (taskId !== "task-1") throw new Error("There is no such task.");
      return fixtureDetail(now);
    },
    "inf:tasks:crewmate": ([taskId]) => ({ taskId, earlier: 0, lines: [...state.crew], revision: `r${state.crew.length}` }),
    "inf:tasks:crewmate:live": ([taskId]) => ({ taskId, text: "Running the tests for the settings page.", since: AT() }),
    "inf:task:steer": ([taskId, text]) => {
      record({ ev: "steer", taskId, text });
      state.crew.push({ kind: "sent", id: `l${state.crew.length + 1}`, at: AT(), from: "captain", text, queued: false, via: "other" });
      return { ok: true };
    },
    "inf:conversation:last-turn": () => state.lastTurn ?? null,
    "inf:cards:thread": ([cardId]) => ({ cardId, messages: [...(state.threads.get(cardId) ?? [])] }),
    "inf:cards:act": ([cardId, actionId]) => {
      const card = state.cards.find((c) => c.id === cardId);
      if (!card) throw new Error("There is no such card.");
      const action = card.actions.find((a) => a.id === actionId);
      if (!action) throw new Error("That card has no such action.");
      record({ ev: "card-acted", cardId, actionId });
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
      setTimeout(() => {
        thread.push({ id: nextMessageId++, cardId, who: "firstmate", text: `Noted: ${text}`, at: AT() });
        push("inf:cards:thread", { cardId, messages: [...thread] });
      }, 50);
      return result;
    },
    "inf:converse": ([input]) => {
      const text = typeof input === "string" ? input : (input.text ?? "");
      record({ ev: "converse", text, images: input.images?.length ?? 0, files: input.files?.length ?? 0 });
      state.feed = [...state.feed, { kind: "you", text, at: AT(), event: "replied" }];
      state.lastTurn = { you: text, reply: { text: `Got it: ${text}`, eligibility: "completed" } };
      setTimeout(() => push("inf:event", { type: "firstmate_reply", text: `Got it: ${text}`, eligibility: "completed" }), 30);
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
          catchUp: replay ? "replay" : "reload", access: connection.access, name: pairName, spellings: ["fm"],
        });
        if (replay) for (const missed of journal.filter((p) => p.seq > cursor.seq)) send(ws, missed);
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
