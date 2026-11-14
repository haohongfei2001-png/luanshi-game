"""Encode actual captured monotonic PTS, never fixed24 simulation-labelled-as-realtime."""
import pathlib,json,sys,subprocess
p=pathlib.Path(sys.argv[1]);d=json.loads((p/'report.json').read_text());frames=[f for f in d['frames'] if 'image' in f];assert len(frames)>1
lines=[]
for a,b in zip(frames,frames[1:]):
 dt=(b['rendered_monotonic_usec']-a['rendered_monotonic_usec'])/1e6;assert dt>0
 lines.extend(["file '"+a['image']+"'",f'duration {dt:.9f}'])
lines.append("file '"+frames[-1]['image']+"'");(p/'monotonic.ffconcat').write_text('\n'.join(lines)+'\n')
subprocess.run(['ffmpeg','-y','-f','concat','-safe','0','-i',str(p/'monotonic.ffconcat'),'-fps_mode','vfr','-c:v','libx264','-crf','18','-pix_fmt','yuv420p',str(p/'actual-monotonic.mp4')],check=True)
