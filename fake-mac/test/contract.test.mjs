// Intent: the fake home must behave as docs/contract.md and docs/connection.md say,
// so that the iPhone app validated against it is validated against the contract.
// A Node reference client (not the app) pairs and connects the way the spec describes.
import assert from "node:assert/strict";
import { generateKeyPairSync, createPrivateKey } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync } from "node:fs";
import { request as httpsRequest } from "node:https";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, describe, test } from "node:test";
import { connect } from "node:tls";
import WebSocket from "ws";
import { pinOfCertificate, startFakeMac } from "../fake-mac.mjs";

let mac;
let device;
before(async () => {
  const dir = mkdtempSync(join(tmpdir(), "fake-mac-test-"));
  mac = await startFakeMac({ stateDir: join(dir, "home") });
  const keyPath = join(dir, "key.pem");
  const certPath = join(dir, "cert.pem");
  execFileSync("openssl", ["req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-nodes", "-keyout", keyPath, "-out", certPath, "-days", "30", "-subj", "/CN=device"], { stdio: "ignore" });
  device = { key: readFileSync(keyPath), cert: readFileSync(certPath) };
});
after(() => mac.stop());

const tls = (extra = {}) => ({ host: "127.0.0.1", port: mac.port(), rejectUnauthorized: false, minVersion: "TLSv1.3", servername: "", ...extra });

function postPair(body, { origin, identity = device } = {}) {
  return new Promise((resolve, reject) => {
    const req = httpsRequest({ ...tls(), ...(identity ?? {}), method: "POST", path: "/pair", headers: { "Content-Type": "application/json", ...(origin ? { Origin: origin } : {}) }, agent: false }, (res) => {
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve({ status: res.statusCode, body: chunks.length ? JSON.parse(Buffer.concat(chunks)) : null, pin: pinOfCertificate(res.socket.getPeerCertificate(true).raw) }));
    });
    req.on("error", reject);
    req.end(JSON.stringify(body));
  });
}

function dial({ origin, identity = device, path = "/connection" } = {}) {
  return new Promise((resolve) => {
    const ws = new WebSocket(`wss://127.0.0.1:${mac.port()}${path}`, { ...tls(), ...(identity ?? {}), ...(origin ? { origin } : {}), createConnection: (o) => connect({ ...o, ...tls(), ...(identity ?? {}) }) });
    const frames = [];
    ws.on("message", (d) => frames.push(JSON.parse(d.toString())));
    ws.on("open", () => resolve({ ws, frames, opened: true }));
    ws.on("unexpected-response", (_req, res) => resolve({ status: res.statusCode, opened: false }));
    ws.on("error", () => {});
  });
}
const until = async (predicate) => { for (let i = 0; i < 100; i++) { if (predicate()) return; await new Promise((r) => setTimeout(r, 20)); } assert.fail("timeout"); };
const hello = { t: "hello", protocolVersion: "11.0.0", as: "view", system: "ios", chip: "arm64" };

describe("pairing", () => {
  test("pins the home by its SPKI hash", () => {
    assert.match(mac.home.pin, /^[A-Za-z0-9_-]{43}$/);
  });
  test("refuses a request carrying an Origin with 403", async () => {
    const code = mac.invite("mac");
    const res = await postPair({ code, kind: "mac", name: "iPhone", system: "ios" }, { origin: "https://evil.example" });
    assert.equal(res.status, 403);
  });
  test("refuses unknown, malformed and wrong-kind requests with the contract's statuses", async () => {
    assert.equal((await postPair({ code: "A".repeat(43), kind: "mac", name: "iPhone", system: "ios" })).status, 401);
    assert.equal((await postPair({ code: "short", kind: "mac", name: "iPhone", system: "ios" })).status, 400);
    assert.equal((await postPair({ code: mac.invite("work"), kind: "mac", name: "iPhone", system: "ios" })).status, 409);
  });
  test("refuses an expired code with 410", async () => {
    const code = mac.invite("mac", { ttlMs: -1 });
    const res = await postPair({ code, kind: "mac", name: "iPhone", system: "ios" });
    assert.deepEqual([res.status, res.body.refused], [410, "expired"]);
  });
  test("a phone that does not say system ios is refused as malformed, as the Mac now does (the bug the captain hit)", async () => {
    const res = await postPair({ code: mac.invite("mac"), kind: "mac", name: "iPhone", window: true });
    assert.deepEqual([res.status, res.body.refused], [400, "malformed"]);
  });
  test("pairs once: 201 with deviceId and kind, then 410 used", async () => {
    const code = mac.invite("mac");
    const first = await postPair({ code, kind: "mac", name: "iPhone", system: "ios", window: true });
    assert.equal(first.status, 201);
    assert.equal(first.body.kind, "view", "a phone joins as a view whichever link it used (docs/devices.md, Joining)");
    assert.equal(first.pin, mac.home.pin, "the home showed the pinned key");
    const again = await postPair({ code, kind: "mac", name: "iPhone", system: "ios" });
    assert.deepEqual([again.status, again.body.refused], [410, "used"]);
  });
});

describe("connection", () => {
  test("refuses an unpaired key with 401, an Origin with 403, another path with 404", async () => {
    const { key, cert } = (() => {
      const dir = mkdtempSync(join(tmpdir(), "stranger-"));
      execFileSync("openssl", ["req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1", "-nodes", "-keyout", join(dir, "k"), "-out", join(dir, "c"), "-days", "2", "-subj", "/CN=s"], { stdio: "ignore" });
      return { key: readFileSync(join(dir, "k")), cert: readFileSync(join(dir, "c")) };
    })();
    assert.equal((await dial({ identity: { key, cert } })).status, 401);
    assert.equal((await dial({ origin: "https://evil.example" })).status, 403);
    assert.equal((await dial({ path: "/elsewhere" })).status, 404);
  });
  test("hello gets welcome, then requests are answered and pushes are numbered", async () => {
    const conn = await dial();
    assert.ok(conn.opened);
    conn.ws.send(JSON.stringify(hello));
    await until(() => conn.frames.some((f) => f.t === "welcome"));
    const welcome = conn.frames.find((f) => f.t === "welcome");
    assert.equal(welcome.access, "full");
    assert.equal(welcome.catchUp, "reload");
    conn.ws.send(JSON.stringify({ t: "invoke", id: 1, channel: "inf:cards:list", args: [] }));
    await until(() => conn.frames.some((f) => f.t === "result" && f.id === 1));
    const list = conn.frames.find((f) => f.id === 1);
    assert.equal(list.ok, true);
    assert.ok(list.value.length >= 1);
    conn.ws.send(JSON.stringify({ t: "invoke", id: 2, channel: "inf:converse", args: ["hello fake"] }));
    await until(() => conn.frames.some((f) => f.t === "push" && f.channel === "inf:cards"));
    const pushFrame = conn.frames.find((f) => f.t === "push");
    assert.ok(pushFrame.seq >= 1);
    conn.ws.close();
  });
  test("a client written for a major two behind reads, and its change is refused", async () => {
    const conn = await dial();
    conn.ws.send(JSON.stringify({ ...hello, protocolVersion: "5.0.0" }));
    await until(() => conn.frames.some((f) => f.t === "welcome"));
    assert.equal(conn.frames[0].access, "read");
    conn.ws.send(JSON.stringify({ t: "invoke", id: 1, channel: "inf:converse", args: ["x"] }));
    await until(() => conn.frames.some((f) => f.t === "result"));
    assert.equal(conn.frames.find((f) => f.t === "result").ok, false);
    conn.ws.close();
  });
  test("arguments the contract does not admit are refused", async () => {
    const conn = await dial();
    conn.ws.send(JSON.stringify(hello));
    await until(() => conn.frames.some((f) => f.t === "welcome"));
    conn.ws.send(JSON.stringify({ t: "invoke", id: 9, channel: "inf:cards:act", args: ["only-one"] }));
    await until(() => conn.frames.some((f) => f.t === "result" && f.id === 9));
    assert.equal(conn.frames.find((f) => f.id === 9).ok, false);
    conn.ws.close();
  });
  test("a request before hello closes the socket as protocol 4400", async () => {
    const conn = await dial();
    const closed = new Promise((resolve) => conn.ws.on("close", (code) => resolve(code)));
    conn.ws.send(JSON.stringify({ t: "invoke", id: 1, channel: "inf:cards:list", args: [] }));
    assert.equal(await closed, 4400);
  });
  test("a returning cursor replays the pushes it missed", async () => {
    const first = await dial();
    first.ws.send(JSON.stringify(hello));
    await until(() => first.frames.some((f) => f.t === "welcome"));
    const { epoch, seq } = first.frames[0];
    first.ws.close();
    mac.push("inf:cards", mac.state.cards);
    const second = await dial();
    second.ws.send(JSON.stringify({ ...hello, cursor: { epoch, seq } }));
    await until(() => second.frames.some((f) => f.t === "push"));
    assert.equal(second.frames[0].catchUp, "replay");
    assert.equal(second.frames[1].seq, seq + 1);
    second.ws.close();
  });
});
