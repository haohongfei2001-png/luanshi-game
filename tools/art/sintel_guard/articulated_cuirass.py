"""Independent full cuirass: neck/armhole bearing rim and separately articulated skirt.
Retains rebuilt complete cloth and rig; guarded re-authoring of owned armor only.
"""
import pathlib
p=pathlib.Path(__file__).with_name('soldier_whole_layer_system.py');code=p.read_text()
def edit(a,b):
 global code
 if code.count(a)!=1:raise RuntimeError('Armor generator changed: '+a[:60])
 code=code.replace(a,b)
edit("if o.name.startswith(('KIT ','SOURCE lamella')):","if o.name.startswith(('KIT ','SOURCE lamella','REBUILD ')):")
edit("coat.data.materials.clear();coat.data.materials.append(cloth)","# Preserve the rebuilt sewn ivory collar facing and source cloth materials.\nif not coat.data.materials:coat.data.materials.append(cloth)")
edit("return 1.69-.22*abs(math.sin(a))**12","return 1.69+.095*math.sin(2*a)**2-.16*abs(math.sin(a))**12")
edit("make('REBUILD whole contoured breast back and side carrier',points,faces,weights,carrier,uv,.003)","""make('REBUILD whole contoured breast back and side carrier',points,faces,weights,carrier,uv,.0045)
# Entire sewn/riveted bearing edge is continuous around neck/armhole opening.
# Broad enough for normal view, not a noisy line of decorative micro-holes.
for label in ['upper','lower']:
 rp=[];rw=[];rf=[];ru=[]
 for j in range(4):
  for i in range(N):
   a=i*math.tau/N;z=(upper(a)-.018+j*.006) if label=='upper' else (1.35+j*.005)
   rp.append(surface(a,z,.021));rw.append(spine_weights(z));ru.append((i/N,j/3))
 for j in range(3):
  for i in range(N):k=(i+1)%N;rf.append((j*N+i,j*N+k,(j+1)*N+k,(j+1)*N+i))
 make('REBUILD continuous '+label+' bearing welt',rp,rf,rw,carrier,ru,.003)
""")
# Shorter scales retain their staggered overlap but no longer collide with the bound opening.
edit("if z+.032>upper(a):continue","if z+.038>upper(a)-.019:continue")
edit("iron=mat('Rebuild matte weathered iron',(.13,.155,.165),.74,.35)","iron=mat('Rebuild matte weathered iron',(.105,.125,.13),.86,.25)")
# Exact plate surfaces are not smoothed together with thin walls, preventing inflated pillows.
edit("f.use_smooth=True","f.use_smooth=not any(term in name for term in ['lamellar','tasset','overlapping rows'])")
edit("for row in range(6):", "for row in range(9):")
edit("if z+.038>upper(a)-.019:continue", "if z-.020>upper(a)-.019:continue")
edit("p=surface(a+xx*math.tau/40,z+zz*.068,offset)", "aa=a+xx*math.tau/40;p=surface(aa,min(z+zz*.068,upper(aa)-.019),offset)")
# Replace the old world-axis arched yoke entirely with source-arm-frame support.
start=code.index('# Broad contoured shoulder yokes')
end=code.index('# Entire defined waist band',start)
code=code[:start]+r'''# Complete shoulder panels fitted to the actual professional sleeve in source pose.
for sign,side in [(1,'L'),(-1,'R')]:
 bone=rig.pose.bones['DEF-upper_arm.'+side+'.01'];origin=rig.matrix_world@bone.head;axis=(rig.matrix_world.to_3x3()@(bone.tail-bone.head)).normalized()
 front=Vector((0,-1,0));front=(front-axis*front.dot(axis)).normalized();outer=axis.cross(front).normalized()
 if outer.x*sign<0:outer=-outer
 def shoulder(t,a,offset):
  center=origin+axis*(-.075+.25*t);n=(outer*math.cos(a)+front*math.sin(a)).normalized();hit=bvh.ray_cast(center+n*.20,-n)
  if hit[0] is None or (hit[0]-center).length>.185:raise RuntimeError('Missing actual source-arm sleeve support')
  return hit[0]+n*offset
 points=[];weights=[];faces=[];uv=[];nr=8;nc=18
 for j in range(nr+1):
  t=j/nr
  for i in range(nc+1):
   a=-1.35+2.7*i/nc;points.append(shoulder(t,a,.008));weights.append({'DEF-spine.04':1-t,'DEF-upper_arm.'+side+'.01':t});uv.append((t,i/nc))
 for j in range(nr):
  for i in range(nc):k=j*(nc+1)+i;faces.append((k,k+1,k+nc+2,k+nc+1))
 make('REBUILD source fitted shoulder foundation '+side,points,faces,weights,carrier,uv,.003)
 pp=[];ww=[];ff=[];uu=[]
 for row in range(4):
  for col in range(10):
   k=len(pp)
   for dt,da in [(-.12,-.12),(.12,-.12),(.12,.12),(-.12,.12)]:
    t=max(0,min(1,(row+.5)/4+dt));a=-1.20+(col+.5)*.24+da;pp.append(shoulder(t,a,.015+row*.002));ww.append({'DEF-spine.04':1-t,'DEF-upper_arm.'+side+'.01':t});uu.append((dt+.12,da+.12))
   ff.append((k,k+1,k+2,k+3))
 make('REBUILD fitted shoulder overlapping rows '+side,pp,ff,ww,iron,uu,.002)
'''+code[end:]
edit("vs.append(M.inverted()@Vector(p))", "vs.append(Vector(p) if 'shoulder' in name else M.inverted()@Vector(p))")
edit("a=o.modifiers.new('Complete source rig, new weighted armor','ARMATURE');a.object=rig;a.use_deform_preserve_volume=False", """if 'shoulder' in name:
  cage=next(m.object for m in coat.modifiers if m.type=='MESH_DEFORM')
  hidden=cage.hide_get();cage.hide_set(False);bpy.context.view_layer.update()
  ce=cage.evaluated_get(bpy.context.evaluated_depsgraph_get());cm=ce.to_mesh();neutral=[v.co.copy() for v in cm.vertices];ce.to_mesh_clear()
  raw=cage.data;snapshot=raw.copy();cage.data=snapshot
  for v,q in zip(snapshot.vertices,neutral):v.co=q
  states=[(m,m.show_viewport,m.show_render) for m in cage.modifiers]
  for m,_,_ in states:m.show_viewport=False;m.show_render=False
  bpy.context.view_layer.update();bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
  md=o.modifiers.new('Full source cloth support, not arbitrary two-bone shoulder blend','MESH_DEFORM');md.object=cage;md.precision=5;bpy.ops.object.meshdeform_bind(modifier=md.name)
  if not md.is_bound:raise RuntimeError('Source shoulder cage binding failed')
  cage.data=raw
  for m,v,r in states:m.show_viewport=v;m.show_render=r
  cage.hide_set(hidden);bpy.data.meshes.remove(snapshot);bpy.context.view_layer.update()
 else:
  a=o.modifiers.new('Complete source rig, new weighted armor','ARMATURE');a.object=rig;a.use_deform_preserve_volume=False""")
exec(compile(code,str(p),'exec'))
