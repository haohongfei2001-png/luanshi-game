import os,sys,subprocess,json,time,shutil,struct
from pathlib import Path
editor,project,out,res,mode=sys.argv[1:]
out=Path(out).resolve();out.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env.update(LUANSHI_25D_EXPERIMENT='1',LUANSHI_25D_OUT=str(out),LUANSHI_25D_STILLS_ONLY='1' if res.startswith('3840') else '0')
cmd=[editor,'--path',project,'--resolution',res,'--rendering-method','gl_compatibility','--audio-driver','Dummy','--script','app.gd','--']+(['--traversal'] if mode=='traversal' else [])
t0=time.monotonic()
with (out/'run.log').open('w') as log:
 try:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=150)
 except subprocess.TimeoutExpired:(out/'process.json').write_text(json.dumps({'timeout':150,'command':cmd}));raise
(out/'process.json').write_text(json.dumps({'returncode':r.returncode,'wall_seconds':time.monotonic()-t0,'command':cmd},indent=2))
if r.returncode or not(out/'result.json').exists():raise SystemExit('CAPTURE FAILED; original log preserved')
result=json.loads((out/'result.json').read_text());trace=result['trace']
actual=struct.unpack('>II',(out/'frame-00000.png').read_bytes()[16:24]);expected=tuple(map(int,res.split('x')))
if actual!=expected:raise SystemExit(f'PIXEL CONTRACT FAIL: requested {expected}, actually {actual}; no resizing performed')
if shutil.which('ffmpeg') and len(trace)>15:
 # Actual recorded wall-time intervals, never assumed simulation or frame rate.
 rows=[]
 for i,row in enumerate(trace):
  rows.append(f"file 'frame-{row['frame']:05d}.png'")
  if i+1<len(trace):rows.append(f"duration {max(.001,trace[i+1]['wall_seconds']-row['wall_seconds']):.6f}")
 (out/'walltime.txt').write_text('\n'.join(rows)+'\n')
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(out/'walltime.txt'),'-vsync','vfr','-c:v','libx264','-pix_fmt','yuv420p','-crf','19',str(out/'actual-walltime.mp4')],check=True)
 # Retain original first/quarter/mid/three-quarter/last plus every25th frame.
 keep={0,len(trace)-1,len(trace)//4,len(trace)//2,3*len(trace)//4}|set(range(0,len(trace),25))
 (out/'retained-frames.json').write_text(json.dumps({'retained_original_indices':sorted(keep),'video_uses_actual_wall_clock':True,'other_intermediate_pngs_removed_after_successful_encoding':True}))
 for i in range(len(trace)):
  if i not in keep:(out/f'frame-{i:05d}.png').unlink()
print(json.dumps({'out':str(out),'result':r.returncode,'frames':len(trace),'renderer':result['rendering']},indent=2))
