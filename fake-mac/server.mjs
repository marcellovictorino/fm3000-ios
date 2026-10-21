// Runs the fake home on a port and prints pairing links, one JSON object per line.
//   node server.mjs --state <dir> [--host 127.0.0.1] [--port 47623] [--invites 3]
// Events follow as JSON lines (pair, hello, invoke, push ...). Stop with Ctrl-C.
// SIGUSR1 drops every connection, then raises a card the dropped phones missed, so
// their next hello (with its cursor) must be answered with a replay.
import { parseArgs } from "node:util";
import { startFakeMac } from "./fake-mac.mjs";

const { values } = parseArgs({
  options: {
    state: { type: "string" },
    host: { type: "string", default: "127.0.0.1" },
    port: { type: "string", default: "0" },
    invites: { type: "string", default: "1" },
    contract: { type: "string" },
  },
});
if (!values.state) {
  console.error("usage: node server.mjs --state <dir> [--host h] [--port p] [--invites n]");
  process.exit(2);
}
const out = (value) => process.stdout.write(`${JSON.stringify(value)}\n`);
const mac = await startFakeMac({
  host: values.host,
  port: Number(values.port),
  stateDir: values.state,
  ...(values.contract ? { contractPath: values.contract } : {}),
  log: (event) => out(event),
});
out({ ev: "ready", pid: process.pid, address: mac.address(), pin: mac.home.pin });
for (let index = 0; index < Number(values.invites); index += 1) {
  out({ ev: "link", index, link: mac.link(mac.invite("mac")) });
}
process.on("SIGUSR1", () => {
  mac.dropConnections();
  setTimeout(() => {
    mac.state.cards = [
      ...mac.state.cards,
      {
        id: "card-missed", author: "firstmate", priority: 1, title: "While you were away", meta: "Fake home",
        body: "<p>Raised while the phone was offline.</p>",
        actions: [{ id: "ok", label: "Got it", variant: "primary", default: true }],
        status: "ready", createdAt: Date.now(),
      },
    ];
    mac.state.threads.set("card-missed", []);
    mac.push("fm:cards", mac.state.cards);
  }, 200);
});
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    await mac.stop();
    process.exit(0);
  });
}
