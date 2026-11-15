"""Structural checks of original author output, not artistic or runtime acceptance."""
import hashlib,json,struct,sys
from pathlib import Path
from topology_identity import topology_digest
out=Path(sys.argv[1]);m=json.loads((out/'mother-manifest.json').read_text());p=out/'river-valley-hf01.glb'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
with p.open('rb') as f:
 magic,version,size=struct.unpack('<III',f.read(12));n,t=struct.unpack('<II',f.read(8));j=json.loads(f.read(n))
assert magic==0x46546c67 and version==2 and size==p.stat().st_size
assert m['topology_sha256']==topology_digest(m)
assert m['visual_glb_sha256']==sha(p)
ids=['map_id','topology_revision','topology_sha256','visual_revision','authored_source_sha256']
root=[n['extras'] for n in j['nodes'] if 'map_id'in n.get('extras',{})];assert len(root)==1
assert all(root[0][k]==m[k] for k in ids)
assert len([n for n in j['nodes'] if n.get('extras',{}).get('gate_id')=='gate_main'])==1
assert not any('NOT_GAME'in n.get('name','') or 'Pose18_'in n.get('name','') for n in j['nodes'])
assert not j.get('animations') and not j.get('skins')
lights=j['extensions']['KHR_lights_punctual']['lights'];assert len(lights)==1 and lights[0]['type']=='directional'
assert abs(lights[0]['intensity']-2.7)<.0001,lights
normal_count=0
for mesh in j['meshes']:
 for q in mesh['primitives']:
  mat=j['materials'][q['material']] if 'material'in q else {}
  if 'normalTexture'in mat:
   normal_count+=1;assert {'POSITION','NORMAL','TANGENT'}.issubset(q['attributes'])
   assert 'TEXCOORD_'+str(mat['normalTexture'].get('texCoord',0)) in q['attributes']
for s in m['surfaces']:
 assert s['walkable'] and len(s['vertices'])>2 and len(s['triangles'])>0
 for tri in s['triangles']:assert len(tri)==3 and all(0<=i<len(s['vertices']) for i in tri)
sources=[]
local_map=json.loads((out/'local-source-map.PRIVATE.json').read_text()) if (out/'local-source-map.PRIVATE.json').exists() else {}
for source in m['sources']:
 orig=Path(source['path']);choices=[Path(local_map.get(source['path'],source['path'])),out/orig.name]
 found=next((p for p in choices if p.exists() and sha(p)==source['sha256']),None)
 assert found is not None,{'changed_or_missing_source':source}
 sources.append({'name':orig.name,'role':source['role'],'sha256':source['sha256']})
report={'status':'AUTHOR_SOURCE_STRUCTURE_PASS_NOT_ART_OR_GAME','glb_sha256':sha(p),'bytes':p.stat().st_size,'identity':{k:m[k] for k in ids},'nodes':len(j['nodes']),'unique_meshes':len(j['meshes']),'materials':len(j['materials']),'normal_mapped_primitives_with_tangents':normal_count,'source_inputs_verified':len(sources),'surfaces':{s['id']:len(s['triangles']) for s in m['surfaces']},'solids':len(m['solids']),'sun_unitless_energy':lights[0]['intensity'],'artist_verdict':'ART_REVIEW_REQUIRED; no automatic artistic verdict','runtime_verdict':'REQUIRES_INDEPENDENT_NATIVE_ENTRY_MUSTER_AND_IMAGE','M5':'DEVICE_NOT_RUN'}
(out/'author-source-validation.json').write_text(json.dumps(report,indent=2));(out/'source-provenance-public.json').write_text(json.dumps(sources,indent=2));print(json.dumps(report,indent=2))
