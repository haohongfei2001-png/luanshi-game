"""Verify original archives and reconstruct selected evidence without new GPU work."""
import argparse,hashlib,json,subprocess,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('archive_dir',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
man=json.loads(Path(__file__).with_name('archive-manifest.json').read_text())
for row in man:
 f=a.archive_dir/(row['name']+'.zip')
 if not f.is_file():raise SystemExit(f"Missing {f.name}; download existing artifact {row['artifact_page']}, not a new CI")
 if hashlib.sha256(f.read_bytes()).hexdigest()!=row['zip_sha256']:raise SystemExit('Archive hash mismatch: '+f.name)
 z=zipfile.ZipFile(f);expected={x['path']:x for x in row['members']}
 if set(z.namelist())!=set(expected):raise SystemExit('Archive member set differs')
 for n in z.namelist():
  data=z.read(n);record=expected[n]
  if len(data)!=record['bytes'] or hashlib.sha256(data).hexdigest()!=record['sha256']:raise SystemExit('Member hash mismatch: '+n)
  if n.endswith(('.json','.log','.txt')) or (row['name']=='metal-corrected-gpu' and n.startswith('2560-') and n.endswith('.jpg')) or 'pose-control/frame-00000.png' in n or n in ['2560-combat/still-00047.png','2560-traversal/still-00048.png','3840-combat/frame-00003.png']:
   dest=a.output/row['name']/n;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
for mode in ['2560-combat','2560-traversal']:
 folder=a.output/'metal-corrected-gpu'/mode;trace=json.loads((folder/'result.json').read_text())['trace'];lines=[]
 for i,row in enumerate(trace):
  lines.append("file '%s'"%row['file'])
  if i+1<len(trace):lines.append('duration %.6f'%max(.001,trace[i+1]['wall_seconds']-row['wall_seconds']))
 lines.append("file '%s'"%trace[-1]['file']);(folder/'walltime.txt').write_text('\n'.join(lines)+'\n')
 subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(folder/'walltime.txt'),'-fps_mode','vfr','-c:v','libx264','-pix_fmt','yuv420p','-crf','19',str(folder/'actual-walltime.mp4')],check=True)
print('Original bytes verified; movies retain original wall intervals. Encoding byte identity depends on ffmpeg build.')
