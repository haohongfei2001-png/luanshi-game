"""Unified v2 architectural mother; explicit new scene contract, not legacy patch.
Blender --python this -- FROZEN_PROFESSIONAL_MOTHER.blend LAYOUT.json OUTPUT.
Retains licensed roof/frame and native deck UV, rebuilds whole new passage.
"""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'gate_structure'))
from solid_orientation import orient_closed
from projection_axes import dominant_axis
source,layoutfile,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
layout=json.loads(layoutfile.read_text());(out/'scene-layout-snapshot.json').write_text(json.dumps(layout,indent=2));assert layout['map_id']=='luanshi.river_gate.production_v2'
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
retained=[]
keep_objects=set()
for ob in list(bpy.data.objects):
 keep=ob.type=='MESH' and (ob.name.startswith(('Roof_','RoofLongPurlin','RoofRidgeCap','NativeRoofFrame','HallNative')) or (ob.name.startswith('ProfessionalDeck_') and ob.parent and ob.parent.name=='GateBridge'))
 if keep:keep_objects.add(ob)
for ob in list(bpy.data.objects):
 if ob in keep_objects:
  ob.data=ob.data.copy();mat=ob.matrix_world.copy();ob.parent=None;ob.matrix_world=mat
  # Bake unchanged source transforms before moving the whole professional system.
  for v in ob.data.vertices:v.co=mat@v.co
  ob.matrix_world.identity();retained.append(ob)
 else:bpy.data.objects.remove(ob,do_unlink=True)
root=bpy.data.objects.new('ProductionV2Architecture',None);bpy.context.collection.objects.link(root)
def group(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=root;return o
hall=group('GateHall');door=group('GateDoor');walls=group('WallWalk');bridge=group('GateBridge');unused=group('WestBridge')
for ob in retained:
 if ob.name.startswith('ProfessionalDeck_'):
  for v in ob.data.vertices:v.co=Vector(((v.co.x-24)*14/11.9,v.co.y*7.2/7.52,v.co.z+.87))
  ob.parent=bridge
 else:
  for v in ob.data.vertices:v.co+=Vector((-20.05,-3,1.27))
  ob.parent=hall
materials={k:bpy.data.materials[k] for k in ['masonry','timber','timber_cut','tile','iron']}
# Non-destructive derived structural wood: preserve source files and grain, but
# make a declared whole-scene palette instead of furniture-black broad facades.
# Blender image pixels expose source sRGB values; explicitly decode to linear,
# derive, and re-encode into an sRGB byte image. Save derived asset through
# Blender's image encoder; no screenshot or exposure manipulation is involved.
import numpy as np
texdir=out/'derived_materials';texdir.mkdir(exist_ok=True)
derivation=[]
for name in ['timber','timber_cut']:
 material=materials[name]
 bsdf=next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 node=bsdf.inputs['Base Color'].links[0].from_node
 original=node.image
 if name=='timber':
  data=np.empty(len(original.pixels),dtype=np.float32);original.pixels.foreach_get(data);a=data.reshape((-1,4));srgb=a[:,:3].clip(0,1);linear=np.where(srgb<=.04045,srgb/12.92,((srgb+.055)/1.055)**2.4);rgb=linear**.66;lum=rgb@np.array([.2126,.7152,.0722]);rgb=lum[:,None]+.65*(rgb-lum[:,None]);a[:,:3]=np.where(rgb<=.0031308,12.92*rgb,1.055*rgb**(1/2.4)-.055);a[:,3]=1
  derived=bpy.data.images.new('V2WeatheredStructuralTimber',width=original.size[0],height=original.size[1],alpha=True,float_buffer=False)
  derived.colorspace_settings.name='sRGB';derived.pixels.foreach_set(data);derived.filepath_raw=str(texdir/'structural_timber.png');derived.file_format='PNG';derived.save();derived.pack()
  derivation.append({'family':'structural timber','source_image':original.filepath,'method':'sRGB decode; linear RGB pow(0.66), saturation0.65 about Rec709 luminance; sRGB encode; opaque','purpose':'mid-value coherent timber for normal-pixel hall/bridge readability, no global exposure change','source_preserved':True,'path':'derived_materials/structural_timber.png'})
 node.image=derived
# World material UVs are authored independently; source UVMap is retained.
solids=[];walk=[];supports=[];audits=[]
def pt(x,y,z):return (x,-z,y)
def mesh(name,verts,faces,mat,parent):
 faces,a=orient_closed(verts,faces);audits.append({'name':name,'components':a})
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(materials[mat]);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.parent=parent
 uv=d.uv_layers.new(name='UVMap');pbr=d.uv_layers.new(name='MaterialUV_Metre') if mat in ['masonry','timber','timber_cut'] else None
 lo=[min(v.co[k] for v in d.vertices) for k in range(3)];hi=[max(v.co[k] for v in d.vertices) for k in range(3)];grain=max(range(3),key=lambda k:hi[k]-lo[k])
 for p in d.polygons:
  axis=dominant_axis(p.normal);axes=[k for k in range(3) if k!=axis]
  if mat.startswith('timber') and grain in axes:axes=[k for k in axes if k!=grain]+[grain]
  for i in p.loop_indices:
   v=d.vertices[d.loops[i].vertex_index].co;uv.data[i].uv=(v[axes[0]],v[axes[1]])
   if pbr:pbr.data[i].uv=(v[axes[0]]/(1.5 if mat=='masonry' else .6),v[axes[1]]/(1.5 if mat=='masonry' else .6))
 return o
F=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def box(name,c,s,mat,parent,bevel=.02):
 x,y,z=c;a,b,d=[n/2 for n in s]
 o=mesh(name,[pt(x+i*a,y+j*b,z+k*d) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]],F,mat,parent)
 if bevel:
  mod=o.modifiers.new('structural edge bevel','BEVEL');mod.width=bevel;mod.segments=2;bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
 return o
def beam(name,a,b,w,d,mat,parent):
 va,vb=Vector(pt(*a)),Vector(pt(*b));axis=(vb-va).normalized();side=axis.cross(Vector((0,0,1)))
 if side.length<.01:side=axis.cross(Vector((0,1,0)))
 side.normalize();up=axis.cross(side).normalized();vs=[tuple(p+side*i*w/2+up*j*d/2) for p in [va,vb] for i,j in [(-1,-1),(1,-1),(1,1),(-1,1)]]
 return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,parent)
def obstacle(id,polygon,y0,y1,role):
 solids.append({'id':id,'tag':'solid_obstacle','xz_polygon':polygon,'min_y':y0,'max_y':y1,'role':role})
def prism(name,poly,bottom,top,mat,parent):
 n=len(poly);v=[pt(x,y,z) for y in [bottom,top] for x,z in poly];faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 return mesh(name,v,faces,mat,parent)
# Entire load-bearing six-metre-deep gateway, no old wall-walk tunnel slicing.
# Clear aperture Z[-.2,6.2], floor1.2, lintel underside6.6.
for sign,z0,z1 in [(-1,-7,-.2),(1,6.2,13)]:
 p=[[27,z0],[33,z0],[33,z1],[27,z1]]
 prism('GateLoadBearingPier',p,.2,7.05,'masonry',hall)
 # Conservative obstacle includes dressed front edge extent, but never narrows aperture.
 lowz=z0-.15 if sign<0 else z0;highz=z1 if sign<0 else z1+.15
 collision=[[26.78,lowz],[33,lowz],[33,highz],[26.78,highz]]
 obstacle('gate_pier_'+str(sign),collision,.2,7.05,'full gate pier and dressed front edge')
 supports.append({'id':'gate_pier_'+str(sign),'xz_polygon':p,'ground_y':1.2,'foundation_bottom':.2})
 for z in [z0,z1]:box('GatePierDressedEdge',(26.91,4.1,(-.36 if abs(z+.2)<.001 else 6.36 if abs(z-6.2)<.001 else z)),(.25,5.8,.3),'masonry',hall)
# A real long timber lintel system bears on the piers across the full tunnel.
for x in [27.22,28.35,29.45,30.55,31.65,32.78]:beam('TunnelLintel',(x,6.83,-.65),(x,6.83,6.65),.44,.46,'timber_cut',hall)
box('GateHallBearingFloor',(30,7.125,3),(6.2,.15,20.2),'masonry',hall)
# Three-bay actual hall with front gallery; broad panels and honest openings.
from author_fortified_enclosure import build_upper_hall
# That helper's native x50.05/z0 system is applied in a temporary local group,
# then rigidly translated: no old walls, ground or layout are imported.
temp=group('TemporaryHallJoinery');build_upper_hall(box,beam,temp,7.2,9.4,[-7.09,-2.363333333,2.363333333,7.09])
for o in list(temp.children):
 for v in o.data.vertices:v.co+=Vector((-20.05,-3,0))
 o.parent=hall
bpy.data.objects.remove(temp,do_unlink=True)
# Defensive wings follow the authored terrain narrowing; not an old rectangle.
paths={'north':[[30,1.2,-7]]+layout['fort_join_anchors']['north'],'south':[[30,1.2,13]]+layout['fort_join_anchors']['south']}
def wallsegment(id,a,b):
 ax,ay,az=a;bx,by,bz=b;length=math.hypot(bx-ax,bz-az);nx=-(bz-az)/length;nz=(bx-ax)/length
 poly=[[ax+nx*2.5,az+nz*2.5],[bx+nx*2.5,bz+nz*2.5],[bx-nx*2.5,bz-nz*2.5],[ax-nx*2.5,az-nz*2.5]]
 # Battered outside faces: full foundation, narrower loadbearing top.
 bottom=[pt(x,(ay if i in [0,3] else by)-.8,z) for i,(x,z) in enumerate(poly)]
 upper=[pt(x,y+5.8,z) for x,y,z in [(ax+nx*1.9,ay,az+nz*1.9),(bx+nx*1.9,by,bz+nz*1.9),(bx-nx*1.9,by,bz-nz*1.9),(ax-nx*1.9,ay,az-nz*1.9)]]
 mesh(id,bottom+upper,F,'masonry',walls);obstacle(id,poly,min(ay,by)-.8,max(ay,by)+5.8,'battered defensive wall')
 supports.append({'id':id,'xz_polygon':poly,'axis_endpoints':a+b,'foundation_embed_m':.8,'top_above_local_ground':5.8})
 count=max(1,round(length/2.1));outer=-1 if id.startswith('north') else 1
 # Strong continuous parapet and repeated substantial merlons, subordinate to mass.
 beam(id+'_parapet',(ax+outer*nx*1.47,ay+6.25,az+outer*nz*1.47),(bx+outer*nx*1.47,by+6.25,bz+outer*nz*1.47),.75,.9,'masonry',walls)
 for j in range(count):
  t=(j+.5)/count;x=ax+(bx-ax)*t+outer*nx*1.47;z=az+(bz-az)*t+outer*nz*1.47;y=ay+(by-ay)*t+6.95
  # Aligned beams avoid disconnected square teeth at each turning wall.
  dx=(bx-ax)/length*.48;dz=(bz-az)/length*.48
  beam(id+'_merlon',(x-dx,y,z-dz),(x+dx,y,z+dz),.78,.55,'masonry',walls)
for side,path in paths.items():
 for i,(a,b) in enumerate(zip(path,path[1:])):wallsegment(side+'_wall_'+str(i),a,b)
 # Solid round-ended bastion at the outer shoulder, not a thin pasted panel.
 a=path[1];poly=[[a[0]+3.05*math.cos(i*math.tau/8),a[2]+3.05*math.sin(i*math.tau/8)] for i in range(8)]
 prism(side+'_shoulder_bastion',poly,a[1]-.8,a[1]+5.8,'masonry',walls);obstacle(side+'_bastion',poly,a[1]-.8,a[1]+5.8,'turning defense shoulder');supports.append({'id':side+'_bastion','xz_polygon':poly,'ground_y':a[1],'foundation_bottom':a[1]-.8})
# Rear route stays genuinely open at X76, width8. No fictional locked rear door.
for side,end in [('north',[76,1.2,-1.2]),('south',[76,1.2,7.2])]:wallsegment(side+'_rear_return',paths[side][-1],end)
# Single dynamic doorway with independent visual group and blocker, never whole-map swap.
for sign in [-1,1]:
 for i in range(10):box('GateLeafBoard',(30,3.85,3+sign*(.16+i*.318)),(.22,5.3,.308),'timber',door)
 for y in [2,3.8,5.6]:box('GateLeafCrossRail',(30.17,y,3+sign*1.59),(.16,.20,3.12),'timber_cut',door)
for o in door.children:
 for v in o.data.vertices:v.co-=Vector(pt(30,1.2,3))
door.location=pt(30,1.2,3);door['gate_id']='gate_main';door['tag']='gate_dynamic'
# Professional board geometry/UV already retained; assemble complete timber bridge.
for z in [-3.35,-1.12,1.12,3.35]:beam('BridgeLongStringer',(-7,.65,z),(7,.65,z),.28,.45,'timber',bridge)
for x in [-4.5,4.5]:
 beam('BridgeBentCrosshead',(x,.25,-3.75),(x,.25,3.75),.42,.46,'timber',bridge)
 for z in [-3.1,0,3.1]:
  beam('BridgePile',(x,-3,z),(x,.3,z),.42,.42,'timber',bridge)
  for sign in [-1,1]:beam('BridgeKneeBrace',(x,-.9,z),(x+sign*1.05,.58,z),.22,.22,'timber',bridge)
for sign in [-1,1]:
 z=sign*3.8
 for i in range(11):box('BridgeRailPost',(-6.8+i*1.36,1.62,z),(.22,1.3,.22),'timber',bridge)
 for y in [1.5,2.16]:beam('BridgeSafetyRail',(-7,y,z),(7,y,z),.15,.17,'timber',bridge)
 p=[[-7,z-.15],[7,z-.15],[7,z+.15],[-7,z+.15]];obstacle('bridge_rail_'+str(sign),p,.95,2.3,'bridge side barrier')
for x in [-7,7]:
 box('BridgeStoneAbutment',(x,-.1,0),(1.2,2.2,8.2),'masonry',bridge)
 supports.append({'id':'bridge_abutment_'+str(x),'xz_polygon':[[x-.6,-4.1],[x+.6,-4.1],[x+.6,4.1],[x-.6,4.1]],'top_y':1,'foundation_bottom':-1.2})
walk=[{'id':'bridge_main_deck','tag':'walk_surface','xz_polygon':[[-7,-3.6],[7,-3.6],[7,3.6],[-7,3.6]],'y':1,'priority':'explicit deck, never roof ray','clear_height':99},{'id':'gate_tunnel','tag':'walk_surface','xz_polygon':[[27,-.2],[33,-.2],[33,6.2],[27,6.2]],'y':1.2,'clear_height':5.4}]
gate_contract={'id':'gate_main','tag':'gate_dynamic','visual_group':'GateDoor','pivot':[30,1.2,3],'entry':[27,1.2,3],'exit':[33,1.2,3],'width':6.4,'clear_height':5.4,'closed_blocker':{'xz_polygon':[[29.82,-.2],[30.18,-.2],[30.18,6.2],[29.82,6.2]],'min_y':1.2,'max_y':6.6},'open_action':'disable only this blocker; preserve all other navigation, identity and positions','hp_binding':'existing gate HP through stable gate_id; actual runtime NOT_RUN'}
for row in walk:
 marker=group(row['id']);marker['tag']='walk_surface';marker['contract_json']=json.dumps(row)
for label,pos in [('gate_entry',[27,1.2,3]),('gate_exit',[33,1.2,3]),('fort_rear_exit',[76,1.2,3]),('bridge_west',[-7,1,0]),('bridge_east',[7,1,0])]:
 marker=group(label);marker.location=pt(*pos);marker['tag']='portal'
root['map_id']=layout['map_id'];root['status']='AUTHORING_NOT_ACCEPTED_NOT_DEFAULT'
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
report={'map_id':layout['map_id'],'layout_sha256':hashlib.sha256(layoutfile.read_bytes()).hexdigest(),'source_mother_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'coordinates':'authoring Godot metres XZ/Yup, Blender stored (x,-z,y), exported once glTF Y-up','walk_surfaces':walk,'solid_obstacles':solids,'support_profiles':supports,'gate_dynamic':gate_contract,'retreat_portal':layout['rear_service_portal'],'upper_routes_walkable':False,'material_derivation':derivation,'status':'NOT_GAMEPLAY_OR_ART_ACCEPTED','professional_source':'VVayToyek CC0 native roof/frame + Rico Cilliers PolyHaven CC0 deck; prior editable source UV preserved','ordinary_count_per_side':512,'muster_status':'NOT_RUN'}
(out/'architecture-contract.json').write_text(json.dumps(report,indent=2));(out/'solid-audit.json').write_text(json.dumps(audits,indent=2));bpy.ops.wm.save_as_mainfile(filepath=str(out/'architecture-mother.blend'))
from export_runtime_architecture import export_runtime
export_runtime(out/'architecture.glb')
print('PRODUCTION_V2_ARCHITECTURE_BUILT_NOT_ACCEPTED',len(solids),len(supports))
