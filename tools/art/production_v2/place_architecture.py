"""Blender rigid placement of ONE complete mother plus same-matrix map sidecar.
No GPU/render. Never moves independent visual/physics parts or alters source.
"""
import argparse,bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
from placement_contract import matrix,write_sidecar
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'gate_structure'))
from export_runtime_architecture import export_runtime
p=argparse.ArgumentParser();p.add_argument('mother',type=Path);p.add_argument('contract',type=Path);p.add_argument('output',type=Path);p.add_argument('--yaw-degrees',type=float,default=0);p.add_argument('--translation',nargs=3,type=float,default=[0,0,0]);a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);a.output.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(a.mother),load_ui=False);root=bpy.data.objects.get('ProductionV2Architecture')
if root is None or root.parent is not None:raise ValueError('Expected sole unparented complete architectural mother root')
if any(abs(root.matrix_world[i][j]-(1 if i==j else 0))>1e-6 for i in range(4) for j in range(4)):raise ValueError('Mother already transformed: use unplaced immutable source')
for ob in bpy.data.objects:
 if ob.type!='MESH':continue
 n=ob
 while n is not None and n!=root:n=n.parent
 if n is None:raise ValueError('Visual mesh outside single complete mother: '+ob.name)
placed=write_sidecar(a.contract,a.output/'architecture-contract.json',a.yaw_degrees,a.translation)
(a.output/'author-local-contract.json').write_bytes(a.contract.read_bytes())
# Exact basis conjugation, not a hand-tuned negative angle/coordinate swap.
B=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)));M=Matrix(matrix(a.yaw_degrees,a.translation));root.matrix_world=B@M@B.inverted();root['placement_json']=json.dumps(placed['placement'])
# Markers keep their local transforms beneath the one parent. Their embedded
# semantic JSON contains the same final map-world coordinates as the sidecar.
for surface in placed['walk_surfaces']:
 node=bpy.data.objects.get(surface['id'])
 if node is None:raise ValueError('Missing semantic surface '+surface['id'])
 node['contract_json']=json.dumps(surface)
for g in ['gate_entry','gate_exit','fort_rear_exit','bridge_west','bridge_east']:
 if bpy.data.objects.get(g) is None:raise ValueError('Missing portal marker '+g)
(a.output/'placement-source.json').write_text(json.dumps({'source_mother_sha256':hashlib.sha256(a.mother.read_bytes()).hexdigest(),'source_contract_sha256':hashlib.sha256(a.contract.read_bytes()).hexdigest(),'placement':placed['placement'],'status':'PLACEMENT_NOT_ART_OR_GAMEPLAY_ACCEPTED'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(a.output/'architecture-mother.blend'),compress=True)
export_runtime(a.output/'architecture.glb')
print('ONE_PARENT_PLACEMENT_EXPORTED',a.yaw_degrees,a.translation)
