#!/usr/bin/env python3
"""Run a shell command on the gateway's serial console and print its output.

Usage: gw.py '<command>' [timeout_seconds]
Password is read from the GW_PASS env var, used only if a login prompt appears.
Port defaults to /dev/ttyUSB0; set GW_PORT to use another adapter.
"""
import os, re, sys, time, serial

PORT, BAUD = os.environ.get("GW_PORT", "/dev/ttyUSB0"), 115200
PROMPT = re.compile(rb"root@[^\s:]+:[^#]*# ?$")
MARK = "__GW_DONE__"

def read_until(s, pattern, timeout):
    buf, end = b"", time.time() + timeout
    while time.time() < end:
        chunk = s.read(4096)
        if chunk:
            buf += chunk
            if re.search(pattern, buf):
                return buf
    return buf

def main():
    cmd = sys.argv[1]
    timeout = float(sys.argv[2]) if len(sys.argv) > 2 else 30
    with serial.Serial(PORT, BAUD, timeout=0.2) as s:
        # Drain stale input by reading; reset_input_buffer() sends a CP210x
        # purge (request 0x12) that times out and can hang the adapter.
        while s.read(4096):
            pass
        s.write(b"\r")
        buf = read_until(s, rb"(login: ?$|Password: ?$|# ?$)", 5)
        if re.search(rb"login: ?$", buf):
            s.write(b"root\r")
            buf = read_until(s, rb"Password: ?$", 5)
        if re.search(rb"Password: ?$", buf):
            s.write(os.environ["GW_PASS"].encode() + b"\r")
            buf = read_until(s, PROMPT, 10)
        if not re.search(rb"# ?$", buf):
            sys.exit("no root prompt; got: " + buf[-200:].decode(errors="replace"))
        # Disable paging/colour noise, run command, then echo a marker.
        # Quote-split the marker so the echoed command line doesn't match it.
        s.write(f"stty -echo 2>/dev/null; {cmd}; echo __GW_''DONE__\r".encode())
        out = read_until(s, (MARK + r"\r?\n").encode(), timeout).decode(errors="replace")
        s.write(b"stty echo\r")
        out = out.split(MARK)[0] if MARK in out else out + "\n[timed out]"
        print(out.replace("\r", ""))

if __name__ == "__main__":
    main()
