#!/usr/bin/env python3
"""Stream a hosted recording. Abort on a missing real gameplay milestone, not ordinary frame jitter."""
import argparse
import os
import selectors
import signal
import subprocess
import sys
import time

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--idle",type=float,required=True)
    parser.add_argument("--limit",type=float,required=True)
    parser.add_argument("command",nargs=argparse.REMAINDER)
    a=parser.parse_args()
    command=a.command[1:] if a.command[:1]==["--"] else a.command
    if not command or min(a.idle,a.limit)<=0: parser.error("A command and positive time budgets are required.")
    proc=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
    start=last=time.monotonic()
    last_tick=-1
    last_stage=-1
    buf=b""
    def stop():
        try: os.killpg(proc.pid,signal.SIGTERM)
        except ProcessLookupError: pass
        try: proc.wait(timeout=4)
        except subprocess.TimeoutExpired:
            try: os.killpg(proc.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            proc.wait()
    try:
        with selectors.DefaultSelector() as events:
            events.register(proc.stdout,selectors.EVENT_READ)
            while True:
                now=time.monotonic()
                if now-last>a.idle or now-start>a.limit:
                    sys.stderr.write(f"Journey recorder expired: elapsed={now-start:.1f}s without simulation or UI progress={now-last:.1f}s tick={last_tick} stage={last_stage}\n")
                    stop()
                    return 124
                if not events.select(timeout=min(2.0,a.idle,a.limit)): continue
                block=os.read(proc.stdout.fileno(),65536)
                if not block: break
                sys.stdout.buffer.write(block); sys.stdout.buffer.flush()
                buf+=block
                while b"\n" in buf:
                    line,buf=buf.split(b"\n",1)
                    if line.startswith(b"JOURNEY_PROGRESS tick="):
                        number=int(line.split(b"=",1)[1].split(None,1)[0])
                        if number>last_tick: last_tick=number;last=time.monotonic()
                    elif line.startswith(b"JOURNEY_STAGE "):
                        number=int(line.split(None,1)[1].split(b"-",1)[0])
                        if number>last_stage: last_stage=number;last=time.monotonic()
        return proc.wait()
    finally:
        if proc.poll() is None: stop()
        proc.stdout.close()

if __name__=="__main__": raise SystemExit(main())
