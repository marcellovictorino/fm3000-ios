#!/usr/bin/env bash
# End-to-end: the app's own model (via fm-probe) against the fake Mac, over real TLS 1.3 and a real WebSocket.
# Uses a scratch HOME and scratch keychain file; never touches your keychains. No sign-ins, no network beyond 127.0.0.1.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
[ -d fake-mac/node_modules ] || (cd fake-mac && npm ci --silent)
swift build --product fm-probe 2>&1 | grep -E "error|Build complete" || true
PROBE="$(swift build --show-bin-path)/fm-probe"

WORK="$(mktemp -d)"
trap 'rc=$?; if [ $rc -ne 0 ]; then echo "--- fake Mac log (tail) ---"; tail -8 "$WORK/fake.log" | cut -c1-300; fi; kill "${FAKE_PID:-0}" 2>/dev/null || true; rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"
LOG="$WORK/fake.log"
node fake-mac/server.mjs --state "$WORK/fake-state" --invites 4 --heartbeat-ms 400 >"$LOG" &
FAKE_PID=$!
for _ in $(seq 1 100); do grep -q '"ev":"link","index":3' "$LOG" 2>/dev/null && break; sleep 0.1; done
link() { grep '"ev":"link","index":'"$1" "$LOG" | node -e 'process.stdin.on("data",d=>process.stdout.write(JSON.parse(d).link))'; }
pass=0; fail=0
check() { if "$@"; then echo "PASS $DESC"; pass=$((pass+1)); else echo "FAIL $DESC"; fail=$((fail+1)); fi; }

# 1. A link whose key is not the Mac's: refused before anything is sent.
BAD="$(link 0 | sed "s/key=[A-Za-z0-9_-]*/key=$(printf '%043d' 0 | tr 0 A)/")"
DESC="wrong pin is refused and nothing reaches /pair"
out="$("$PROBE" --state "$WORK/bad" pair "$BAD" || true)"
check bash -c "[[ \"$out\" == *'does not match'* ]] && ! grep -q '\"ev\":\"pair\"' '$LOG'"

# 2. The good link pairs, then the full scenario runs; the same link then is spent.
GOOD="$(link 1)"
DESC="pairs with a valid link"
out="$("$PROBE" --state "$WORK/phone" pair "$GOOD")"
check bash -c "[[ '$out' == *PAIRED* ]]"
DESC="MVP scenario: cards, act, reply, converse, board, feed, pushes, reconnect with replay, unpair"
"$PROBE" --state "$WORK/phone" scenario --fake-pid "$FAKE_PID" | tee "$WORK/scenario.out" | sed 's/^/    /'
check grep -q "SCENARIO OK" "$WORK/scenario.out"
DESC="a spent link is refused as used"
out="$("$PROBE" --state "$WORK/phone2" pair "$GOOD" || true)"
check bash -c "[[ '$out' == *'used already'* ]]"

# 3. What the fake Mac saw.
sleep 0.3
node --input-type=module -e '
import { readFileSync } from "node:fs";
const events = readFileSync(process.argv[1], "utf8").split("\n").filter((l) => l.startsWith("{")).map((l) => JSON.parse(l));
const by = (ev) => events.filter((e) => e.ev === ev);
const checks = [
  ["pair carried window:true, system ios and joined as view over TLSv1.3", by("pair").some((e) => e.window && e.system === "ios" && e.kind === "view" && e.tls === "TLSv1.3")],
  ["hello was protocol 12.0.0, as view, system ios, chip arm64", by("hello").every((e) => e.protocolVersion === "12.0.0" && e.as === "view" && e.system === "ios" && e.chip === "arm64")],
  ["no connection carried an Origin header", by("hello").length >= 2 && by("hello").every((e) => e.hasOrigin === false)],
  ["every connection was TLSv1.3", by("upgrade").length >= 2 && by("upgrade").every((e) => e.tls === "TLSv1.3")],
  ["the second hello asked to catch up and got a replay", by("hello").some((e) => e.cursor && e.catchUp === "replay")],
  ["no invoke was refused for its shape", by("invoke-refused").length === 0],
  ["the words typed beside a choice went with it, as the Mac footer sends them", by("card-acted").some((e) => e.words === "Ship it after lunch")],
  ["the phone left", by("left").length === 1],
];
let bad = 0;
for (const [name, ok] of checks) { console.log((ok ? "PASS " : "FAIL ") + name); if (!ok) bad++; }
process.exit(bad ? 1 : 0);
' "$LOG" | tee "$WORK/mac.out" || true
pass=$((pass + $(grep -c '^PASS' "$WORK/mac.out" || true)))
fail=$((fail + $(grep -c '^FAIL' "$WORK/mac.out" || true)))
echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
