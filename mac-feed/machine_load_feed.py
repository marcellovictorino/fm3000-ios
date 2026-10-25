#!/usr/bin/env python3
"""Samples this Mac's CPU, GPU and memory every few seconds and serves the latest reading as JSON on 127.0.0.1.

`tailscale serve` publishes that port to the tailnet only (see install.sh). GPU and memory use the same methods as the
desktop's machine-load panel (machine-load/server.ts): ioreg's IOAccelerator "Device Utilization %", and active plus
wired pages from vm_stat over hw.memsize. CPU is the busy share of host_statistics ticks between two samples.
"""
import ctypes
import json
import re
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8787
INTERVAL_S = 3.0
PATH = "/machine-load.json"

_libc = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
_libc.mach_host_self.restype = ctypes.c_uint


def cpu_ticks():
    """Cumulative (user, system, idle, nice) ticks across all cores."""
    ticks = (ctypes.c_uint * 4)()
    count = ctypes.c_uint(4)
    # HOST_CPU_LOAD_INFO = 3
    status = _libc.host_statistics(_libc.mach_host_self(), 3, ticks, ctypes.byref(count))
    return tuple(ticks) if status == 0 else None


def cpu_percent(before, after):
    if not before or not after:
        return None
    delta = [b - a for a, b in zip(before, after)]
    total = sum(delta)
    return None if total <= 0 else round(100 * (total - delta[2]) / total, 1)


def run(args):
    return subprocess.run(args, capture_output=True, text=True, timeout=3, check=True).stdout


def gpu_percent():
    try:
        match = re.search(r'"Device Utilization %"=(\d+)', run(["/usr/sbin/ioreg", "-r", "-d", "1", "-c", "IOAccelerator"]))
        return min(100, int(match.group(1))) if match else None
    except Exception:
        return None


def memory():
    try:
        out = run(["/usr/bin/vm_stat"])
        page = int(re.search(r"page size of (\d+) bytes", out).group(1))
        pages = lambda label: int(re.search(label + r":\s+(\d+)", out).group(1))
        total = int(run(["/usr/sbin/sysctl", "-n", "hw.memsize"]))
        return {"usedBytes": (pages("Pages active") + pages("Pages wired down")) * page, "totalBytes": total}
    except Exception:
        return None


latest = None
lock = threading.Lock()


def sample_forever():
    global latest
    before = cpu_ticks()
    while True:
        time.sleep(INTERVAL_S)
        after = cpu_ticks()
        reading = {"at": int(time.time() * 1000), "intervalMs": int(INTERVAL_S * 1000),
                   "cpu": cpu_percent(before, after), "gpu": gpu_percent(), "memory": memory()}
        before = after
        with lock:
            latest = reading


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        with lock:
            reading = latest
        if self.path.split("?")[0] != PATH:
            self.send_error(404)
        elif reading is None:
            self.send_error(503, "no reading yet")
        else:
            body = json.dumps(reading).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    threading.Thread(target=sample_forever, daemon=True).start()
    try:
        ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
    except OSError as error:
        sys.exit(f"cannot listen on 127.0.0.1:{PORT}: {error}")
