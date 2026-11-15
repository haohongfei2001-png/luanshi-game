#!/usr/bin/env python3
"""Measure one actual child process even when SIGKILLed. Linux ru_maxrss is KiB."""
import argparse,json,os,resource,signal,subprocess,time
from pathlib import Path
ap=argparse.ArgumentParser();ap.add_argument('--timeout',type=float,default=240);ap.add_argument('--json',type=Path,required=True);ap.add_argument('command',nargs=argparse.REMAINDER);args=ap.parse_args();command=args.command[1:] if args.command and args.command[0]=='--' else args.command
if not command:raise SystemExit('No child command')
t0=time.monotonic();p=subprocess.Popen(command,start_new_session=True);timed_out=False
try:code=p.wait(timeout=args.timeout)
except subprocess.TimeoutExpired:
 timed_out=True;os.killpg(p.pid,signal.SIGTERM)
 try:code=p.wait(timeout=5)
 except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);code=p.wait()
r=resource.getrusage(resource.RUSAGE_CHILDREN)
report={'command':command,'returncode':code,'signal':signal.Signals(-code).name if code<0 else None,'timeout_triggered':timed_out,'elapsed_seconds':time.monotonic()-t0,'max_rss_kib':r.ru_maxrss,'user_cpu_seconds':r.ru_utime,'system_cpu_seconds':r.ru_stime,'measurement':'fresh parent RUSAGE_CHILDREN, child reaped; Linux RSS KiB','cause_limit':'SIGKILL does not alone prove OOM'}
args.json.parent.mkdir(parents=True,exist_ok=True);args.json.write_text(json.dumps(report,indent=2));print('CHILD_RESOURCE_RESULT',json.dumps(report),flush=True);raise SystemExit(124 if timed_out else code if code>=0 else 128-code)
