"""Preserve real process output and fail promptly on Godot script/shader errors."""
import os,selectors,signal,subprocess,sys,time
from pathlib import Path
log=Path(sys.argv[1]);limit=float(sys.argv[2]);args=sys.argv[4:];assert sys.argv[3]=='--' and args
log.parent.mkdir(parents=True,exist_ok=True)
p=subprocess.Popen(args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
sel=selectors.DefaultSelector();sel.register(p.stdout,selectors.EVENT_READ)
deadline=time.monotonic()+limit;pending=b'';failure=None
with log.open('wb') as f:
 try:
  while sel.get_map():
   if time.monotonic()>=deadline:failure='CAPTURE_TIMEOUT';break
   for key,_ in sel.select(.5):
    data=os.read(key.fd,65536)
    if not data:sel.unregister(key.fileobj);continue
    f.write(data);f.flush();pending=(pending+data)[-131072:]
    if any(marker in pending for marker in [b'SCRIPT ERROR',b'SHADER ERROR',b'ERROR:']):failure='GODOT_ERROR';break
   if failure:break
 finally:
  if failure and p.poll() is None:os.killpg(p.pid,signal.SIGTERM)
  try:p.wait(timeout=5)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
  f.write(('\nCAPTURE_PROCESS_RESULT '+str({'reason':failure,'exit':p.returncode})+'\n').encode());f.flush()
print('CAPTURE_PROCESS_RESULT',failure,p.returncode,flush=True)
raise SystemExit(1 if failure else p.returncode)
