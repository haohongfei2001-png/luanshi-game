"""Shared cut topology plus explicit hard/soft garment supports, NOT visual PASS.
No limb removal, no outward barrel dilation. Original editable input stays intact.
"""
import bpy,bmesh,sys,pathlib,math,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.data.pose_position='REST';rig.animation_data_clear();bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1
coat=bpy.data.objects['V2_complete_coat_runtime'];pants=bpy.data.objects['Wool trousers'];armor=bpy.data.materials['V2 continuous lamellar cuirass'];linen=bpy.data.materials['V2 warm linen binding']
old=[]
for o in list(bpy.data.objects):
 if o.name.startswith(('V2 continuous wrapped cuirass','V2 bound short skirt gore','V2 continuous bound shoulder mantle','V2 linen calf wrap')):
  old.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
def smooth(a,b,x):t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def set_weights(o,v,w,amount=1):
 old={o.vertex_groups[g.group].name:g.weight for g in v.groups};combined={k:value*(1-amount) for k,value in old.items()}
 for k,value in w.items():combined[k]=combined.get(k,0)+value*amount
 for index in [g.group for g in v.groups]:o.vertex_groups[index].remove([v.index])
 total=sum(combined.values())
 for k,value in combined.items():
  if value>1e-8:
   group=o.vertex_groups.get(k) or o.vertex_groups.new(name=k);group.add([v.index],value/total,'REPLACE')
def lower_support(p):
 leg='upperleg01.'+('L' if p.x>=0 else 'R');t=1-smooth(.89,.975,p.z);return {'root':1-t,leg:t}
# Reduce only excessive padded shoulder volume against the actual natural body.
full_body=bpy.data.objects['Body_SourceFull'];body_bvh=BVHTree.FromPolygons([v.co for v in full_body.data.vertices],[list(p.vertices) for p in full_body.data.polygons])
for v in coat.data.vertices:
 p=v.co.copy()
 if .10<abs(p.x)<.30 and p.z>1.205:
  q,n,i,d=body_bvh.find_nearest(p);blend=smooth(.10,.13,abs(p.x))*(1-smooth(.26,.30,abs(p.x)))*smooth(1.205,1.24,p.z)
  if q is not None and .008<d<.10:v.co=p.lerp(q,.30*blend)
coat.data.update()
# Stiff supporting cloth under chest groups, flexible at arm/neck/waist boundaries.
for v in coat.data.vertices:
 p=v.co
 if p.z<.985 and abs(p.x)<.26:set_weights(coat,v,lower_support(p),1-smooth(.975,1.0,p.z))
 elif abs(p.x)<.188 and 1.0<p.z<1.315:
  blend=(1-smooth(.165,.20,abs(p.x)))*smooth(.995,1.025,p.z)*(1-smooth(1.29,1.325,p.z));set_weights(coat,v,{'spine01':.85,'spine02':.15},blend)
# Stable shoulder interiors with a short flexible overlap, not blanket skinning.
for v in coat.data.vertices:
 p=v.co;side='L' if p.x>=0 else 'R'
 if .095<abs(p.x)<.29 and p.z>1.205 and v.normal.z>-.35:
  t=smooth(.175,.20,abs(p.x));set_weights(coat,v,{'spine01':.45*(1-t),'clavicle.'+side:.55*(1-t),'upperarm01.'+side:t})
 a=rig.data.bones['lowerarm01.'+side].head_local;b=rig.data.bones['wrist.'+side].head_local;axis=b-a;t=(p-a).dot(axis)/axis.length_squared;radius=(p-(a+axis*t)).length
 if .55<t<1.0 and radius<.10 and abs(p.x)>.27:set_weights(coat,v,{'lowerarm01.'+side:1},smooth(.55,.60,t)*(1-smooth(.96,1.0,t)))
# Puttee-support cloth is shin-driven, never a mixture with foot flexion.
for v in pants.data.vertices:
 side='L' if v.co.x>=0 else 'R';a=rig.data.bones['lowerleg01.'+side].head_local;b=rig.data.bones['foot.'+side].head_local;axis=a-b;t=(v.co-b).dot(axis)/axis.length_squared
 if .10<t<.86:set_weights(pants,v,{'lowerleg01.'+side:1},smooth(.10,.14,t)*(1-smooth(.81,.86,t)))
sash=bpy.data.objects.get('V2 continuous soft waist sash')
if sash:
 for modifier in sash.modifiers:
  if modifier.type=='SOLIDIFY':modifier.thickness=.0025
 for v in sash.data.vertices:set_weights(sash,v,{'root':1})
parts=[]
def derive(name,source,planes,selector,material,offset,rigid=None,uv_mode='torso'):
 o=source.copy();o.data=source.data.copy();o.name=name;bpy.context.collection.objects.link(o);o.hide_render=False;o.hide_set(False)
 for m in list(o.modifiers):o.modifiers.remove(m)
 bm=bmesh.new();bm.from_mesh(o.data)
 for point,normal,keep_positive in planes:
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=point,plane_no=normal,clear_inner=keep_positive,clear_outer=not keep_positive)
 if selector:
  bmesh.ops.delete(bm,geom=[f for f in bm.faces if not selector(f.calc_center_median(),f.normal)],context='FACES')
 bm.normal_update();bm.to_mesh(o.data);bm.free()
 if not o.data.polygons:raise RuntimeError('Empty cut '+name)
 for v in o.data.vertices:
  v.co+=v.normal*offset
  if rigid:set_weights(o,v,rigid)
 o.data.update();o.data.materials.clear();o.data.materials.append(material)
 # Keep original editable UV; explicit active render UV describes plate courses.
 uv=o.data.uv_layers.new(name='LamellarPatternUV')
 for p in o.data.polygons:
  p.material_index=0;p.use_smooth=True;angles=[]
  for li in p.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co;angles.append((math.atan2(v.x,-(v.y+.02))/math.tau)%1)
  if max(angles)-min(angles)>.5:angles=[a+1 if a<.5 else a for a in angles]
  for li,a in zip(p.loop_indices,angles):
   v=o.data.vertices[o.data.loops[li].vertex_index].co
   if uv_mode.startswith('shoulder:'):
    side=uv_mode.split(':')[1];origin=rig.data.bones['upperarm01.'+side].head_local;axis=(rig.data.bones['lowerarm01.'+side].head_local-origin).normalized();front=Vector((0,-1,0));front=(front-axis*front.dot(axis)).normalized();up=axis.cross(front).normalized()
    if up.z<0:up=-up
    rel=v-origin;along=rel.dot(axis);radial=rel-axis*along;angle=math.atan2(radial.dot(front),radial.dot(up))/math.tau
    uv.data[li].uv=(angle*10,along/.060)
   elif uv_mode.startswith('puttee:'):
    side=uv_mode.split(':')[1];origin=rig.data.bones['foot.'+side].head_local;axis=(rig.data.bones['lowerleg01.'+side].head_local-origin).normalized();rel=v-origin;along=rel.dot(axis);angle=math.atan2(rel.x,rel.y)/math.tau
    uv.data[li].uv=(angle,along/.045+angle)
   else:uv.data[li].uv=(a*28,(v.z-.65)/.070)
 uv.active_render=uv_mode!='source';o.data.uv_layers.active_index=(0 if uv_mode=='source' else len(o.data.uv_layers)-1)
 if uv_mode=='source':o.data.uv_layers[0].active_render=True
 thick=o.modifiers.new('True bound sheet thickness','SOLIDIFY');thick.thickness=.0014 if 'puttee' in name else .0025;thick.offset=0
 bevel=o.modifiers.new('Physical turned edge','BEVEL');bevel.width=.0007;bevel.segments=2;bevel.limit_method='ANGLE'
 skin=o.modifiers.new('Explicit natural body support','ARMATURE');skin.object=rig;o.parent=rig
 parts.append({'name':name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'rigid_support':rigid,'source':source.name,'offset_m':offset});return o
# Four overlapping torso courses: relative-rigid chest support with real edges.
for row in range(4):
 lo=1.0+row*.075;hi=lo+.079
 derive('V3 supported chest course '+str(row),coat,[((0,0,lo),(0,0,1),True),((0,0,hi),(0,0,1),False),((-.185,0,0),(1,0,0),True),((.185,0,0),(1,0,0),False)],None,armor,.004,{'spine01':.85,'spine02':.15})
# Trim only the excess facing hidden beneath the chest armor: the continuous
# original inner coat remains. Do not expose long crossing collar tails.
for ob in [o for o in bpy.data.objects if o.name.startswith('V2 continuous crossing collar')]:
 bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(0,0,1.285),plane_no=(0,0,1),clear_inner=True,clear_outer=False);bm.to_mesh(ob.data);bm.free()
# Actual segmented shoulder coverage from the same complete sewn shoulder cloth.
for side,sign in [('L',1),('R',-1)]:
 for inner in [True,False]:
  lo,hi=(.095,.192) if inner else (.181,.29);planes=[((sign*lo,0,0),(sign,0,0),True),((sign*hi,0,0),(sign,0,0),False),((0,0,1.205),(0,0,1),True)]
  weights={'spine01':.45,'clavicle.'+side:.55} if inner else {'upperarm01.'+side:1}
  if inner:derive('V3 supported shoulder '+side+' root',coat,planes,lambda p,n:n.z>-.25,armor,.004,None,uv_mode='shoulder:'+side)
  else:
   origin=rig.data.bones['upperarm01.'+side].head_local;axis=(rig.data.bones['lowerarm01.'+side].head_local-origin).normalized();split=origin+axis*.065
   for course in range(2):
    bounds=planes+[(split+axis*(.003 if course==0 else -.003),axis,course==1)]
    derive('V3 supported shoulder '+side+' course '+str(course),coat,bounds,lambda p,n:n.z>-.25,armor,.0045,None,uv_mode='shoulder:'+side)
# Six real cloth-supported walking panels, with cuts inherited in the same mesh.
for panel in range(6):
 a0=panel*math.tau/6+.045;a1=(panel+1)*math.tau/6-.045;center=(0,-.02,0)
 planes=[((0,0,.65),(0,0,1),True),((0,0,.989),(0,0,1),False),(center,(math.cos(a0),math.sin(a0),0),True),(center,(math.cos(a1),math.sin(a1),0),False)]
 derive('V3 supported split skirt '+str(panel),coat,planes,lambda p,n:p.x*p.x+(p.y+.02)**2<.26**2,armor,.004)
# Bound wrist cloth is cut from actual fitted sleeves and retains their relief.
cuff_mat=coat.data.materials[0].copy();cuff_mat.name='V3 real folded woven wrist cloth';cb=cuff_mat.node_tree.nodes.get('Principled BSDF');cb.inputs['Base Color'].default_value=(.09,.105,.11,1);cb.inputs['Roughness'].default_value=.92
for old_cuff in [o for o in list(bpy.data.objects) if o.name.startswith('V2 fitted woven wrist binding')]:bpy.data.objects.remove(old_cuff,do_unlink=True)
for side,sign in [('L',1),('R',-1)]:
 a=rig.data.bones['lowerarm01.'+side].head_local;b=rig.data.bones['wrist.'+side].head_local;axis=(b-a).normalized()
 def sleeve_only(p,n,a=a,b=b):
  ax=(b-a).normalized();q=p-a;return abs(p.x)>.27 and (q-ax*q.dot(ax)).length<.10
 derive('V3 source bound wrist '+side,coat,[(a.lerp(b,.60),axis,True),(a.lerp(b,.96),axis,False)],sleeve_only,cuff_mat,.0015,{'lowerarm01.'+side:1},uv_mode='source')
# Explicit physical overlapping-wrap relief, not random dirt or painted shine.
import numpy as np
size=128;yy,xx=np.mgrid[0:size,0:size]/size;height=.0006*(1-yy)**10;dy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))/(2*.045/size);nn=np.stack([np.zeros_like(xx),-dy,np.ones_like(xx)],axis=-1);nn/=np.linalg.norm(nn,axis=-1)[:,:,None];rgba=np.concatenate([nn*.5+.5,np.ones((size,size,1))],axis=-1)
image=bpy.data.images.new('Authored linen strip overlap tangent normal',width=size,height=size,alpha=True);image.colorspace_settings.name='Non-Color';image.pixels.foreach_set(rgba.astype('float32').ravel());image.filepath_raw=str(out/'linen-overlap-normal.png');image.file_format='PNG';image.save();image.pack()
linen=linen.copy();linen.name='V3 thin wrapped linen with physical overlap';ln=linen.node_tree.nodes;ll=linen.node_tree.links;lb=ln.get('Principled BSDF');lb.inputs['Roughness'].default_value=.96;tex=ln.new('ShaderNodeTexImage');tex.image=image;normal=ln.new('ShaderNodeNormalMap');ll.new(tex.outputs['Color'],normal.inputs['Color']);ll.new(normal.outputs['Normal'],lb.inputs['Normal'])
# Cloth strips use the actual trouser topology, all shin-bound, no hidden limbs.
for side,sign in [('L',1),('R',-1)]:
 a=rig.data.bones['lowerleg01.'+side].head_local;b=rig.data.bones['foot.'+side].head_local;axis=(a-b).normalized()
 planes=[((0,0,0),(sign,0,0),True),(b.lerp(a,.14),axis,True),(b.lerp(a,.81),axis,False)]
 derive('V3 source bound puttee '+side,pants,planes,None,linen,.0025,{'lowerleg01.'+side:1},uv_mode='puttee:'+side)
# The original medieval boot has a raised cuff that intersects the puttee.
# Make a real ankle-height cloth-shoe derivative, preserving complete source.
boots=bpy.data.objects['Medieval boots'];backup=boots.copy();backup.data=boots.data.copy();backup.name='Boots_SourceComplete';bpy.context.collection.objects.link(backup);backup.hide_render=True;backup.hide_set(True)
bm=bmesh.new();bm.from_mesh(boots.data)
# Fit the surviving shoe upper to the ankle rather than keep the old flared boot cuff.
for v in boots.data.vertices:
 side='L' if v.co.x>=0 else 'R';b=rig.data.bones['foot.'+side].head_local;k=rig.data.bones['lowerleg01.'+side].head_local
 if v.co.z>b.z-.005:
  t=(v.co.z-b.z)/(k.z-b.z);center=b.lerp(k,t);radial=v.co-center;radial.z=0
  if radial.length>1e-7:
   direction=radial.normalized();point,n,i,d=body_bvh.ray_cast(center,direction,.20)
   if point is not None:
    wanted=(point-center).length+.005
    if radial.length>wanted:v.co-=radial*(1-wanted/radial.length)*smooth(b.z-.005,b.z+.02,v.co.z)
boots.data.update();bm.free();bm=bmesh.new();bm.from_mesh(boots.data)
cut_z=max(rig.data.bones['foot.L'].head_local.z,rig.data.bones['foot.R'].head_local.z)+.025
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(0,0,cut_z),plane_no=(0,0,1),clear_outer=True,clear_inner=False)
bm.to_mesh(boots.data);bm.free();boots.name='V3 source cut ankle cloth shoes'
# Metal and soft textile remain physically distinct, not universal plastic.
iron=bpy.data.materials['V2 controlled slate iron'].node_tree.nodes.get('Principled BSDF');iron.inputs['Roughness'].default_value=.62;iron.inputs['Metallic'].default_value=.62
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-editable.blend'))
(out/'structure-report.json').write_text(json.dumps({'status':'STRUCTURAL_DERIVATIVE_REQUIRES_FULL_DYNAMIC_REVIEW','removed':old,'parts':parts,'original_input_unchanged':True,'limbs_removed':False,'barrel_expansion':False,'source_animation_fps':120,'visual_acceptance':False},indent=2)+'\n')
