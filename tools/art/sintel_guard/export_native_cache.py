"""Single-actor source-deformation playback oracle, NOT general runtime skinning.
Keeps full rig names/rest/pose records and original loop UVs. All source files unchanged.
"""
import bpy,pathlib,sys,json,hashlib,numpy as np,math
from mathutils import Matrix
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True)
sha=hashlib.sha256(src.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];C=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
def matrix(m):return [float(m[r][c]) for c in range(4) for r in range(3)]
bones=list(rig.data.bones);ids={b.name:i for i,b in enumerate(bones)}
# Explicit whole-object LOD recipe; retain source topology, not decimation/body slicing.
meshes=[ob for ob in bpy.context.scene.objects if ob.type=='MESH' and ob.visible_get() and not ob.hide_render]
for ob in meshes:
 for m in ob.modifiers:
  if m.type=='MULTIRES':m.levels=1
  elif m.type=='SUBSURF':m.levels=0
  elif m.type=='PARTICLE_SYSTEM':m.show_viewport=False # mesh scalp retained, particle hair unsupported in cache
meta={'kind':'native source cache oracle, not general skeletal character','source_sha256':sha,'fps':24,'frames':49,'duration':2.,'godot':False,'default_enabled':False,'source_rig_bones':len(bones),'source_deform_bones':sum(b.use_deform for b in bones),'limitations':['Synthetic FK diagnostic, not authored walk/combat motion','Particle hair not exported; scalp meshes remain','Source skin materials unresolved: diagnostic clay','Source-cache memory/performance unsuitable for unmeasured armies'],'bones':[{'name':b.name,'parent':ids.get(b.parent.name,-1) if b.parent else -1,'rest_global':matrix(C@rig.matrix_world@b.matrix_local@C.inverted())} for b in bones],'meshes':[],'poses':[]}
records={}
for frame in range(49):
 t=frame/24.;wave=math.sin(math.pi*t)**2
 for side,sign in [('L',1),('R',-1)]:
  rig.pose.bones['hand_ik.'+side]['ik']=0.;rig.pose.bones['foot_ik.'+side]['ik']=0.
  for name,angle in [('upper_arm.',-.6*sign*wave),('forearm.',.9*sign*wave),('thigh.',.2*sign*wave),('shin.',-.25*sign*wave)]:
   p=rig.pose.bones.get(name+side)
   if p:p.rotation_mode='XYZ';p.rotation_euler=(angle if name in ['thigh.','shin.'] else 0,0,angle if name not in ['thigh.','shin.'] else 0)
 bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
 meta['poses'].append([matrix(C@rig.matrix_world@rig.pose.bones[b.name].matrix@C.inverted()) for b in bones])
 for k,ob in enumerate(meshes):
  ev=ob.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();loop_ids=np.array([l.vertex_index for l in me.loops],dtype=np.int32)
  world=C@ev.matrix_world;normal_matrix=world.to_3x3().inverted().transposed()
  pos=np.array([tuple(world@v.co) for v in me.vertices],dtype=np.float32)[loop_ids]
  normal=np.array([tuple((normal_matrix@n.vector).normalized()) for n in me.corner_normals],dtype=np.float32)
  if frame==0:
   uv=np.array([tuple(l.uv) for l in me.uv_layers.active.data],dtype=np.float32) if me.uv_layers.active else np.zeros((len(loop_ids),2),dtype=np.float32)
   indices=np.array([i for tr in me.loop_triangles for i in tr.loops],dtype=np.int32).reshape(-1,3)[:,[0,2,1]].reshape(-1)
   entry={'name':ob.name,'vertices':len(pos),'indices':indices.tolist(),'uv':uv.tolist(),'positions_file':f'mesh-{k}-positions.rgba32f','normals_file':f'mesh-{k}-normals.rgba32f'}
   meta['meshes'].append(entry);records[k]={'ids':loop_ids,'pos':[],'normal':[]}
  assert np.array_equal(records[k]['ids'],loop_ids) and np.isfinite(pos).all() and np.isfinite(normal).all()
  records[k]['pos'].append(np.column_stack((pos,np.ones(len(pos),dtype=np.float32))).astype('<f4'))
  records[k]['normal'].append(np.column_stack((normal,np.ones(len(pos),dtype=np.float32))).astype('<f4'))
  ev.to_mesh_clear()
 if frame%12==0:print('NATIVE_CACHE_FRAME',frame,flush=True)
for k,r in records.items():
 for key,filename in [('pos','positions_file'),('normal','normals_file')]:np.stack(r[key]).astype('<f4').tofile(out/meta['meshes'][k][filename])
meta['source_unchanged']=hashlib.sha256(src.read_bytes()).hexdigest()==sha
meta['cache_bytes']=sum(p.stat().st_size for p in out.glob('*.rgba32f'))
(out/'character.json').write_text(json.dumps(meta,separators=(',',':'))+'\n');print('CACHE_BYTES',meta['cache_bytes'],flush=True)
