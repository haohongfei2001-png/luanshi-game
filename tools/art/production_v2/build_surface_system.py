"""Whole fort construction hierarchy, same external envelope/route contract.
No old Ground. No exposure compensation. Preserve professional frames and source.
Blender --python this -- V2_MOTHER.blend V2_CONTRACT.json GROUND_SOURCE_DIR OUTPUT
"""
import bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Vector
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'gate_structure'))
from solid_orientation import orient_closed
from export_runtime_architecture import export_runtime
args=sys.argv[sys.argv.index('--')+1:];mother,contractfile,groundroot,out=map(Path,args[:4]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(mother),load_ui=False)
contract=json.loads(contractfile.read_text());source=json.loads((groundroot/'SOURCE.json').read_text())['brown_mud_dry']
diff=Path(args[4]) if len(args)>4 else groundroot/'brown_mud_dry.jpg';normal=groundroot/'brown_mud_dry_nor_gl.jpg'
assert hashlib.md5(diff.read_bytes()).hexdigest()==source['md5'];assert hashlib.md5(normal.read_bytes()).hexdigest()==source['normal']['md5']
textures=out/'derived_materials';textures.mkdir(exist_ok=True)
im=bpy.data.images.load(str(diff),check_existing=True);a=np.empty(len(im.pixels),dtype=np.float32);im.pixels.foreach_get(a);rgba=a.reshape((-1,4));srgb=rgba[:,:3].clip(0,1);linear=np.where(srgb<=.04045,srgb/12.92,((srgb+.055)/1.055)**2.4);lum=linear@np.array([.2126,.7152,.0722]);median=float(np.median(lum));variation=np.clip((lum/max(median,.001))**.35,.65,1.35)
rgb=variation[:,None]*np.array([.19,.17,.125]);rgba[:,:3]=np.where(rgb<=.0031308,rgb*12.92,1.055*rgb**(1/2.4)-.055);rgba[:,3]=1
image=bpy.data.images.new('V2_MineralWall_Derivative',width=im.size[0],height=im.size[1],alpha=True,float_buffer=False);image.colorspace_settings.name='sRGB';image.pixels.foreach_set(a);image.filepath_raw=str(textures/'mineral_wall.png');image.file_format='PNG';image.save();image.pack()
core=bpy.data.materials.new('wall_core');core.use_nodes=True;nodes=core.node_tree.nodes;links=core.node_tree.links;bsdf=nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.95;uv=nodes.new('ShaderNodeUVMap');uv.uv_map='MaterialUV_Metre';tex=nodes.new('ShaderNodeTexImage');tex.image=image;links.new(uv.outputs['UV'],tex.inputs['Vector']);links.new(tex.outputs['Color'],bsdf.inputs['Base Color']);nt=nodes.new('ShaderNodeTexImage');nt.image=bpy.data.images.load(str(normal),check_existing=True);nt.image.colorspace_settings.name='Non-Color';links.new(uv.outputs['UV'],nt.inputs['Vector']);nm=nodes.new('ShaderNodeNormalMap');nm.uv_map='MaterialUV_Metre';nm.inputs['Strength'].default_value=.12;links.new(nt.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bsdf.inputs['Normal'])
plaster=bpy.data.materials.new('hall_mineral_plaster');plaster.use_nodes=True;bsdf=plaster.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.34,.32,.27,1);bsdf.inputs['Roughness'].default_value=.96
stone=bpy.data.materials['masonry'];wood=bpy.data.materials['timber']
# Accurate selected source convention is2m, not former1.5m coarse box projection.
# Source maps remain byte-identical. Only the authored material UV is rescaled.
for ob in bpy.data.objects:
 if ob.type!='MESH':continue
 if any(m and m.name=='masonry' for m in ob.data.materials) and 'MaterialUV_Metre' in ob.data.uv_layers:
  for v in ob.data.uv_layers['MaterialUV_Metre'].data:v.uv*=.75
# Hall infill is mineral plaster between mature structural wood, not pale-painted
# loadbearing wood. Source columns/frames/rafters remain untouched.
# Current infill groups remain physically separate construction panels and their
# 8mm grooves are retained until integrated camera determines a topology rewrite.
plaster_count=0
for ob in bpy.data.objects:
 if ob.type=='MESH' and ob.name.startswith(('FortHallRearBoard','FortHallEndBoard','FortHallWindowApron','FortHallDoorSide')):
  ob.data.materials.clear();ob.data.materials.append(plaster);plaster_count+=1
F=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
reports=[]
def make_cell(name,vs,parent,mat,along,across):
 faces,audit=orient_closed(vs,F);data=bpy.data.meshes.new(name);data.from_pydata(vs,[],faces);data.materials.append(mat);data.update();ob=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(ob);ob.parent=parent
 original=data.uv_layers.new(name='UVMap');uv=data.uv_layers.new(name='MaterialUV_Metre');scale=2.0 if mat==stone else 1.3
 for p in data.polygons:
  for i in p.loop_indices:
   v=data.vertices[data.loops[i].vertex_index].co
   if abs(p.normal.z)>.75:coords=(v.dot(along),v.dot(across))
   elif abs(p.normal.dot(along))>.70:coords=(v.dot(across),v.z)
   else:coords=(v.dot(along),v.z)
   original.data[i].uv=coords;uv.data[i].uv=(coords[0]/scale,coords[1]/scale)
 ob['construction_role']='stone foundation/coping/end bond' if mat==stone else 'mineral earth wall core';reports.append({'object':name,'components':audit,'material':mat.name})
 return ob
original_envelopes=[]
for ob in list(bpy.data.objects):
 iswall=ob.type=='MESH' and (('_wall_' in ob.name or '_rear_return' in ob.name) and not any(t in ob.name for t in ['_parapet','_merlon']))
 if not iswall:continue
 assert len(ob.data.vertices)==8,('unexpected source wall topology',ob.name)
 p=[ob.matrix_world@v.co for v in ob.data.vertices];along=p[1]-p[0];along.z=0;length=along.length;along.normalize();across=Vector((-along.y,along.x,0))
 def point(u,t,side):
  base=p[0].lerp(p[1],u) if side==0 else p[3].lerp(p[2],u)
  top=p[4].lerp(p[5],u) if side==0 else p[7].lerp(p[6],u)
  return base.lerp(top,t)
 # Full-volume subdivision, not pasted surface strips: stone foundation reaches
 # 1.3m above terrain; central body mineral core; coping and construction joints
 # remain stone. Every point lies on or within unchanged battered outer shell.
 us=[0,min(.8/length,.25),max(1-.8/length,.75),1];ts=[0,2.1/6.6,6.15/6.6,1]
 original_envelopes.append({'name':ob.name,'vertices':[[float(x) for x in v] for v in p]})
 for i,(u0,u1) in enumerate(zip(us,us[1:])):
  for j,(t0,t1) in enumerate(zip(ts,ts[1:])):
   vs=[point(u0,t0,0),point(u1,t0,0),point(u1,t0,1),point(u0,t0,1),point(u0,t1,0),point(u1,t1,0),point(u1,t1,1),point(u0,t1,1)]
   make_cell(ob.name+'_construction_%d_%d'%(i,j),vs,ob.parent,core if i==1 and j==1 else stone,along,across)
 bpy.data.objects.remove(ob,do_unlink=True)
# Lower-scatter normal remains true source normal; do not use albedo AO darkening.
for n in stone.node_tree.nodes:
 if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.30
# Preserve originals/derivatives and exact topology contract in the output.
contract['surface_system']={'status':'EXPERIMENTAL_NOT_ACCEPTED','layers':'stone foundation/bond ends/coping, mineral wall body, timber skeleton and pale mineral hall infill, cool matte tile','source':source,'source_diffuse_sha256':hashlib.sha256(diff.read_bytes()).hexdigest(),'derivation':'sRGB decode; source luminance normalized by median, pow.35 clamp.65..1.35 times linear(.19,.17,.125), sRGB encode; original preserved','source_linear_luminance_median':median,'texture_scale_m':{'stone':2,'mineral_body':1.3},'normal_strength':{'stone':.30,'mineral_body':.12},'route_and_solid_contract':'UNCHANGED','plaster_infill_objects':plaster_count}
(out/'architecture-contract.json').write_text(json.dumps(contract,indent=2));(out/'construction-audit.json').write_text(json.dumps({'cells':reports,'prior_wall_envelopes':original_envelopes,'status':'closed cells inside prior outer shell; not gameplay/art acceptance'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(out/'architecture-mother.blend'))
# New PBR family also uses primaryUV in Godot. Exporter preserves secondary source UV.
for m in bpy.data.materials:
 if not m.use_nodes:continue
 for n in m.node_tree.nodes:
  if n.type in ['UVMAP','NORMAL_MAP'] and n.uv_map=='MaterialUV_Metre':n.uv_map='UVMap'
export_runtime(out/'architecture.glb')
print('V2_CONSTRUCTION_SYSTEM_BUILT_NOT_ACCEPTED',len(original_envelopes),len(reports),plaster_count)
