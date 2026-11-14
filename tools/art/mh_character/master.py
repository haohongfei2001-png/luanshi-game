"""Complete natural MakeHuman male, original 163-bone rig and same-ecosystem garments.
No UBC geometry, 16-bone slices, voxel shell, or source weight truncation.
Run Blender --disable-autoexec. Source locations are explicit arguments.
"""
import bpy,json,pathlib,sys,math,hashlib,gzip
from mathutils import Vector
from mathutils.bvhtree import BVHTree
args=sys.argv[sys.argv.index('--')+1:]
out,core,selected,robe=map(lambda p:pathlib.Path(p).resolve(),args[:4]);out.mkdir(parents=True,exist_ok=True);(out/'source').mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=120

def obj_data(path,group=None):
 points=[];uv=[];faces=[];uvfaces=[];active=''
 for line in path.read_text().splitlines():
  f=line.split()
  if not f:continue
  if f[0]=='v':points.append(Vector(tuple(map(float,f[1:4]))))
  elif f[0]=='vt':uv.append(tuple(map(float,f[1:3])))
  elif f[0]=='g':active=' '.join(f[1:])
  elif f[0]=='f' and (group is None or active==group):
   split=[x.split('/') for x in f[1:]];faces.append([int(x[0])-1 for x in split]);uvfaces.append([int(x[1])-1 for x in split])
 return points,uv,faces,uvfaces
base=core/'makehuman_data_3dobjs_base.obj'
points,body_uv,body_faces,body_uvfaces=obj_data(base,'body')
# Official macro rule: male=1, young=1(age .5 ->25y), asian=1, average size/muscle/weight.
target=core/'makehuman_data_targets_macrodetails_asian-male-young.target'
for line in target.read_text().splitlines():
 f=line.split()
 if f and not f[0].startswith('#'):points[int(f[0])]+=Vector(tuple(map(float,f[1:4])))
body_ids=sorted({i for f in body_faces for i in f});floor=min(points[i].y for i in body_ids)
def convert(p):return Vector((p.x*.1,-p.z*.1,(p.y-floor)*.1))
world=[convert(p) for p in points]
r=json.loads((core/'makehuman_data_rigs_default.mhskel').read_text());raw_weights=json.loads((core/'makehuman_data_rigs_default_weights.mhw').read_text())['weights']
weights=[{} for _ in points]
for bone,items in raw_weights.items():
 for i,w in items:
  if w>0:weights[i][bone]=w
for w in weights:
 total=sum(w.values())
 if total:
  for bone in w:w[bone]/=total

def joint(name):
 ids=r['joints'][name];return sum((world[i] for i in ids),Vector())/len(ids)
arm=bpy.data.armatures.new('MakeHuman original default163');rig=bpy.data.objects.new('MH163',arm);bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,spec in r['bones'].items():
 bone=arm.edit_bones.new(name);bone.head=joint(spec['head']);bone.tail=joint(spec['tail'])
 assert (bone.tail-bone.head).length>1e-7,name
 plane=r['planes'].get(spec.get('rotation_plane'))
 if plane:
  a,b,c=[joint(n) for n in plane];normal=(b-a).cross(c-a)
  if normal.length>1e-8:bone.align_roll(normal.normalized())
for name,spec in r['bones'].items():
 if spec.get('parent'):arm.edit_bones[name].parent=arm.edit_bones[spec['parent']]
bpy.ops.object.mode_set(mode='OBJECT');assert len(arm.bones)==163

def material(name,image,rough=.85,alpha=False):
 mat=bpy.data.materials.new(name);mat.use_nodes=True;shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=rough
 texture=mat.node_tree.nodes.new('ShaderNodeTexImage');texture.image=bpy.data.images.load(str(image));mat.node_tree.links.new(texture.outputs['Color'],shader.inputs['Base Color'])
 if alpha:
  mat.node_tree.links.new(texture.outputs['Alpha'],shader.inputs['Alpha']);mat.surface_render_method='DITHERED'
 return mat
skin=material('Original CC0 young Asian male diffuse',selected/'skins/young_asian_male/young_lightskinned_male_diffuse3.png',.72)
report={'status':'FULL163_SOURCE_PROTOTYPE','visual_pass':False,'source_bones':163,'macro':{'gender':1,'age':.5,'asian':1,'muscle':.5,'weight':.5,'height':.5,'proportions':.5},'source_points':len(points),'source_render_body_faces':len(body_faces),'source_floor_y':floor,'body_height_m':max(world[i].z for i in body_ids),'parts':[],'high_influence_vertices':[]}
runtime=[];source_ids_by_name={}
def mesh(name,positions,faces,uv,uvfaces,vertex_weights,mat):
 used=sorted({i for f in faces for i in f});mapping={old:i for i,old in enumerate(used)};m=bpy.data.meshes.new(name);m.from_pydata([positions[i] for i in used],[],[[mapping[i] for i in f] for f in faces]);m.update()
 o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o);m.materials.append(mat);layer=m.uv_layers.new(name='Original source UV')
 for poly,tx in zip(m.polygons,uvfaces):
  poly.use_smooth=True
  for li,ui in zip(poly.loop_indices,tx):layer.data[li].uv=uv[ui]
 groups={n:o.vertex_groups.new(name=n) for n in arm.bones.keys()}
 for old,i in mapping.items():
  w=vertex_weights[old];assert sum(w.values())>.99,(name,old,w)
  for bone,value in w.items():groups[bone].add([i],value,'REPLACE')
  if len(w)>8:report['high_influence_vertices'].append({'part':name,'source_vertex':old,'influences':len(w),'beyond8_weight':sum(sorted(w.values(),reverse=True)[8:])})
 mod=o.modifiers.new('Original complete163 deformation','ARMATURE');mod.object=rig;o.parent=rig
 report['parts'].append({'name':name,'vertices':len(used),'faces':len(faces),'max_weights':max(len(vertex_weights[i]) for i in used)})
 source_ids_by_name[name]=used;runtime.append(o);return o
full_body=mesh('Body_SourceFull',world,body_faces,body_uv,body_uvfaces,weights,skin)
full_body.hide_render=True;full_body.hide_set(True);runtime.remove(full_body)

def proxy_data(path):
 lines=path.read_text().splitlines();props={};scales=[1.,1.,1.];refs=[];deletes=set();reading=False;delete_mode=False
 for line in lines:
  f=line.split()
  if not f or f[0].startswith('#'):continue
  if f[0] in ['x_scale','y_scale','z_scale']:
   axis='xyz'.index(f[0][0]);scales[axis]=abs(points[int(f[1])][axis]-points[int(f[2])][axis])/float(f[3]);continue
  if f[0]=='verts':reading=True;delete_mode=False;continue
  if f[0]=='delete_verts':reading=False;delete_mode=True;continue
  if reading:
   try:
    if len(f)==1:refs.append(([(int(f[0]),1.)],Vector()))
    elif len(f)==9:refs.append(([(int(f[k]),float(f[k+3])) for k in range(3)],Vector(tuple(map(float,f[6:9])))))
    else:reading=False
   except ValueError:reading=False
  if delete_mode:
   try:
    cursor=0
    while cursor<len(f):
     if cursor+2<len(f) and f[cursor+1]=='-':deletes.update(range(int(f[cursor]),int(f[cursor+2])+1));cursor+=3
     else:deletes.add(int(f[cursor]));cursor+=1
   except ValueError:delete_mode=False
  if not reading and not delete_mode:props[f[0]]=' '.join(f[1:])
 positions=[];pw=[]
 for indices,offset in refs:
  p=sum((points[i]*v for i,v in indices),Vector())+Vector(tuple(offset[k]*scales[k] for k in range(3)));positions.append(convert(p));w={}
  for i,factor in indices:
   for b,value in weights[i].items():w[b]=w.get(b,0)+value*factor
  total=sum(w.values());assert total>0
  pw.append({b:v/total for b,v in w.items() if v>1e-10})
 return props,positions,pw,deletes
hidden=set()
items=[('Cross-front robe',robe/'mindfront_kimono.mhclo',robe/'f_kimono.obj',robe/'F_Kimono_COL.png',False),('Wool trousers',selected/'clothes/toigo_wool_pants/toigo_wool_pants.mhclo',selected/'clothes/toigo_wool_pants/pants_wool.obj',selected/'clothes/toigo_wool_pants/Pants_wool.png',False),('Medieval boots',selected/'clothes/punkduck_medieval_boots/punkduck_medieval_boots.mhclo',selected/'clothes/punkduck_medieval_boots/medievalboots.obj',selected/'clothes/punkduck_medieval_boots/medievalboots.png',False),('Eyes',core/'makehuman_data_eyes_high-poly_high-poly.mhclo',core/'makehuman_data_eyes_high-poly_high-poly.obj',core/'makehuman_data_eyes_materials_brown_eye.png',False)]
for name,proxy,objpath,image,alpha in items:
 _,uv,faces,uvfaces=obj_data(objpath);props,p,w,mask=proxy_data(proxy);assert len(p)==max(i for f in faces for i in f)+1,(name,len(p));hidden|=mask
 mesh(name,p,faces,uv,uvfaces,w,material('Original '+name,image,.3 if name=='Eyes' else .85,alpha))
for category,dirname in [('eyebrows','eyebrow001'),('eyelashes','eyelashes01')]:
 folder=selected/category/dirname;proxy=next(folder.glob('*.mhclo'));props,p,w,mask=proxy_data(proxy);objpath=folder/props['obj_file'];_,uv,faces,uvfaces=obj_data(objpath)
 matfile=folder/props['material'];texture=next(l.split()[1] for l in matfile.read_text().splitlines() if l.startswith('diffuseTexture '));hidden|=mask
 mesh(dirname,p,faces,uv,uvfaces,w,material('Original '+dirname,folder/texture,.8,True))
visible=[i for i,f in enumerate(body_faces) if not any(v in hidden for v in f)]
mesh('Body_AuthorGarmentOcclusion',world,[body_faces[i] for i in visible],body_uv,[body_uvfaces[i] for i in visible],weights,skin)
report['author_hidden_body_vertices']=len(hidden)
# Layer-aware rest fitting: the mature robe was authored over skin, not over these trousers.
# Correct actual solid intersections, not alpha masking or deletion of garment topology.
robe_object=bpy.data.objects['Cross-front robe'];corrections=[]
for collider_name in ['Wool trousers','Body_SourceFull']:
 collider=bpy.data.objects[collider_name]
 tree=BVHTree.FromPolygons([v.co.copy() for v in collider.data.vertices],[tuple(p.vertices) for p in collider.data.polygons])
 moved=0;maximum=0.
 for vertex in robe_object.data.vertices:
  location,normal,index,distance=tree.find_nearest(vertex.co)
  if location is None or distance>.06:continue
  gap=(vertex.co-location).dot(normal)
  if gap<.009:
   delta=normal*(.009-gap);vertex.co+=delta;moved+=1;maximum=max(maximum,delta.length)
 corrections.append({'collider':collider_name,'vertices_adjusted':moved,'max_displacement_m':maximum})
robe_object.data.update();report['layer_fit']=corrections

# Exact source vertex identifiers survive glTF seam splitting/reordering in unused second UV.
# Integers 0..255 remain exact even in half-float channels; original author UV is untouched.
sidecar={'format':'mh-full-influences-v1','vertex_id_channel':'TEXCOORD_1 / Godot UV2','vertex_id_encoding':'glTF/Godot=(low8,high8) raw integer floats; Blender UV=(low8,1-high8) compensates exporter V flip','bone_names':list(arm.bones.keys()),'parts':[]}
for obj in runtime:
 m=obj.data;assert len(m.uv_layers)==1,(obj.name,'no unused UV2 slot')
 original_uv=[list(loop.uv) for loop in m.uv_layers[0].data]
 ids=m.uv_layers.new(name='SourceVertexID');assert len(m.vertices)<65536
 for loop in m.loops:ids.data[loop.index].uv=(float(loop.vertex_index&255),float(1-(loop.vertex_index>>8)))
 m.uv_layers.active_index=0;m.uv_layers[0].active_render=True
 assert [list(loop.uv) for loop in m.uv_layers[0].data]==original_uv
 vertices=[]
 for vertex in m.vertices:
  entries=sorted([[obj.vertex_groups[g.group].name,float(g.weight)] for g in vertex.groups if g.weight>0])
  vertices.append({'id':vertex.index,'source_id':source_ids_by_name[obj.name][vertex.index],'position':list(vertex.co),'weights':entries})
 sidecar['parts'].append({'node':obj.name,'mesh':m.name,'vertices':vertices,'polygons':[list(p.vertices) for p in m.polygons],'loop_uv':original_uv})
blob=json.dumps(sidecar,separators=(',',':')).encode();(out/'full-influences.json').write_bytes(blob)
with gzip.GzipFile(filename=str(out/'full-influences.json.gz'),mode='wb',mtime=0) as stream:stream.write(blob)
report['source_id_sidecar']={'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest(),'channel':'TEXCOORD_1','weights_truncated':False}
# Keep the complete editable body in the master, but omit the hidden duplicate from runtime export.
for text in list(bpy.data.texts):bpy.data.texts.remove(text)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'source/mh_natural_editable.blend'))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for o in runtime:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out/'mh_natural_fullweights.glb'),export_format='GLB',use_selection=True,export_skins=True,export_all_influences=True,export_def_bones=True,export_animations=False)
sys.path.insert(0,str(pathlib.Path(__file__).parent))
from export_weights import update as update_runtime_weights
report['source_id_sidecar']=update_runtime_weights(out/'mh_natural_fullweights.glb',out/'full-influences.json')
(out/'master-report.json').write_text(json.dumps(report,indent=2)+'\n');print('MH163_MASTER',json.dumps({k:v for k,v in report.items() if k!='high_influence_vertices'}))
