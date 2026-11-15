"""Immutable parent-source amendment: gate landmark is not a leaf rotation axis."""
import json,hashlib,struct,sys,shutil
from pathlib import Path
from topology_identity import topology_digest
src,out=map(Path,sys.argv[1:3]);out.mkdir(exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for p in src.glob('*.py'):shutil.copy2(p,out/p.name)
shutil.copy2(src/'author-world.json',out/'author-world.json')
patch=Path(__file__);shutil.copy2(patch,out/patch.name)
canonical=out/'topology_identity_with_gate_anchor.py';shutil.copy2(patch.with_name('topology_identity.py'),canonical)
m=json.loads((src/'mother-manifest.json').read_text());m['parent_source_sha256']=m['authored_source_sha256'];m['parent_visual_glb_sha256']=m['visual_glb_sha256']
m['gate_dynamic'].update({'pivot':[14.8,1.2,0],'pivot_semantics':'ground landmark at actual door-plane center, not either leaf hinge','leaf_hinges':[[14.8,1.2,-3.1],[14.8,1.2,3.1]]})
m['topology_revision']=4;m['topology_sha256']=topology_digest(m)
m['sources'] += [{'path':str(out/patch.name),'sha256':sha(out/patch.name),'role':'explicit actual geometry ground-anchor correction'},{'path':str(canonical),'sha256':sha(canonical),'role':'canonical identity includes runtime-consumed gate landmark'}]
m['authored_source_sha256']=hashlib.sha256((''.join(s['sha256'] for s in m['sources'])+m['topology_sha256']).encode()).hexdigest()
with (src/'river-valley-hf01.glb').open('rb') as f:
 magic,ver,size=struct.unpack('<III',f.read(12));n,typ=struct.unpack('<II',f.read(8));g=json.loads(f.read(n));bin_header=f.read(8)
 for node in g['nodes']:
  if 'map_id' in node.get('extras',{}):
   for key in ['topology_revision','topology_sha256','authored_source_sha256']:node['extras'][key]=m[key]
 js=json.dumps(g,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
 with (out/'river-valley-hf01.glb').open('wb') as w:
  w.write(struct.pack('<III',magic,ver,size-n+len(js)));w.write(struct.pack('<II',len(js),typ));w.write(js);w.write(bin_header);shutil.copyfileobj(f,w,4*1024*1024)
m['visual_glb_sha256']=sha(out/'river-valley-hf01.glb');m['status']='FROZEN_GATE_ANCHOR_CORRECTION_NOT_ART_ACCEPTED'
(out/'mother-manifest.json').write_text(json.dumps(m,separators=(',',':')))
(out/'RECOVER.txt').write_text('Frozen parent HF05 + exact amendment script: python repair_gate_anchor.py PARENT NEW_OUTPUT\nNo visual geometry or material changes. GLB BIN chunk unchanged. Native canonical identity must include pivot.\n')
print(json.dumps({k:m[k] for k in ['topology_revision','topology_sha256','authored_source_sha256','visual_glb_sha256']}))
