"""Keep actual derivative hashes and discrepancies; never label them original bd9 bytes."""
import hashlib,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
reference=json.loads((Path(__file__).with_name('expected.json')).read_text())
rows=[]
for e in reference['entries']:
    p=ROOT/e['path']
    if not p.exists():raise ValueError('Missing reconstructed file: '+e['path'])
    data=p.read_bytes(); actual=hashlib.sha256(data).hexdigest()
    rows.append({'path':e['path'],'expected_sha256':e['sha256'],'actual_sha256':actual,'bytes':len(data),'identical':actual==e['sha256']})
out=ROOT/'docs/evidence/river-pass-master/hosted-reconstruction.json'
out.write_text(json.dumps({'seed_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'local_reference_commit':reference['original_commit'],'local_reference_tree':reference['original_tree'],'identical_files':sum(r['identical'] for r in rows),'total_files':len(rows),'files':rows,'art':'NOT_REVIEWED','M5':'DEVICE_NOT_RUN','note':'Godot resource UIDs and Blender output can differ. This records the actual generated source; it is not a claim of tree equality.'},indent=2)+'\n')
# Stage only the explicit source/baked asset manifest, not importer caches, logs,
# transient access URLs, checkout credentials, or all untracked workspace files.
subprocess.run(['git','add','--',*[e['path'] for e in reference['entries']],str(out.relative_to(ROOT))],cwd=ROOT,check=True)
print('RECONSTRUCTED_SOURCE',len(rows),'identical',sum(r['identical'] for r in rows),'different',[r['path'] for r in rows if not r['identical']])
