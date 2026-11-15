import os,sys,subprocess,json,time,shutil,struct,tempfile,math
from pathlib import Path
editor,project,out,res,mode=sys.argv[1:]
out=Path(out).resolve();out.mkdir(parents=True,exist_ok=True)
video=res.startswith('2560') and mode in ['combat','traversal']
env=os.environ.copy();env.update(LUANSHI_25D_EXPERIMENT='1',LUANSHI_25D_OUT=str(out),LUANSHI_25D_RENDER_SIZE=res,LUANSHI_25D_STILLS_ONLY='1' if res.startswith('3840') else '0',LUANSHI_25D_RECORD_JPEG='1' if video else '0')
packed=os.environ.get('LUANSHI_25D_PACKED')=='1'
method='mobile' if packed else 'gl_compatibility'
args={'traversal':['--traversal'],'control':['--pose-control'],'timing':['--timing-window']}.get(mode,[])
cmd=[editor]+([] if packed else ['--path',project,'--script','app.gd'])+['--resolution',res,'--rendering-method',method]+(['--rendering-driver','metal'] if packed else [])+['--audio-driver','Dummy','--']+args
cwd=tempfile.mkdtemp(prefix='empty-game-cwd-',dir=out) if packed else project
t0=time.monotonic()
with (out/'run.log').open('w') as log:
 try:r=subprocess.run(cmd,cwd=cwd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=150)
 except subprocess.TimeoutExpired:(out/'process.json').write_text(json.dumps({'timeout':150,'command':cmd}));raise
(out/'process.json').write_text(json.dumps({'returncode':r.returncode,'wall_seconds':time.monotonic()-t0,'command':cmd},indent=2))
if r.returncode or not(out/'result.json').exists():raise SystemExit('CAPTURE FAILED; original log preserved')
result=json.loads((out/'result.json').read_text());trace=result['trace']
if result['setup']['error']!=0 or result['active_invalid']:raise SystemExit('Real setup or support failed; never accept a blank frame')
if packed and (result['rendering']['method']!='mobile' or not 'Metal' in (out/'run.log').read_text()):raise SystemExit('Native Metal not observed')
if any(any(v is None or not math.isfinite(v) for v in t['hero_position']) for t in trace):raise SystemExit('Nonfinite actual footpoint')
if mode!='timing':
 first=out/('still-00000.png' if video else 'frame-00000.png')
 actual=struct.unpack('>II',first.read_bytes()[16:24]);expected=tuple(map(int,res.split('x')))
 if actual!=expected:raise SystemExit(f'PIXEL CONTRACT FAIL: requested {expected}, actually {actual}; no resizing performed')
if shutil.which('ffmpeg') and len(trace)>1:
 rows=[]
 for i,row in enumerate(trace):
  rows.append(f"file '{row['file']}'")
  if i+1<len(trace):rows.append(f"duration {max(.001,trace[i+1]['wall_seconds']-row['wall_seconds']):.6f}")
 rows.append(f"file '{trace[-1]['file']}'")
 (out/'walltime.txt').write_text('\n'.join(rows)+'\n')
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(out/'walltime.txt'),'-fps_mode','vfr','-c:v','libx264','-pix_fmt','yuv420p','-crf','19',str(out/'actual-walltime.mp4')],check=True)
 # All original JPEGs and few PNG stills retained; no invented nominal FPS.
print(json.dumps({'out':str(out),'result':r.returncode,'frames':len(trace),'renderer':result['rendering'],'no_readback':mode=='timing','process_frame_count':result['process_frame_count'],'simulated_seconds':result['simulated_seconds'],'wall_seconds':result['elapsed_seconds']},indent=2))
