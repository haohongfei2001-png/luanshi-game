"""Repair actual garment support discontinuities; preserve the full body and rig.
Original complete source remains separate. No relaxed motion-gate thresholds.
"""
import bpy,bmesh,sys,pathlib,json,math,numpy as np
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.data.pose_position='REST'
def smooth(a,b,x):t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def weights(o,v,w):
 for i in [g.group for g in v.groups]:o.vertex_groups[i].remove([v.index])
 total=sum(w.values())
 for name,value in w.items():
  if value>1e-8:(o.vertex_groups.get(name) or o.vertex_groups.new(name=name)).add([v.index],value/total,'REPLACE')
coat=bpy.data.objects['V2_complete_coat_runtime'];bm=bmesh.new();bm.from_mesh(coat.data)
# Make a real continuous center walking seam rather than centroid face deletion.
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(0,0,.83),plane_no=(0,0,1))
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(0,0,0),plane_no=(1,0,0))
seam=[e for e in bm.edges if all(abs(v.co.x)<1e-6 and v.co.z<.830001 for v in e.verts) and abs(sum(v.co.y for v in e.verts)/2+.02)>.04]
bmesh.ops.split_edges(bm,edges=seam)
for v in bm.verts:
 if abs(v.co.x)<1e-6 and v.co.z<.83 and abs(v.co.y+.02)>.04 and v.link_faces:
  sign=1 if sum(f.calc_center_median().x for f in v.link_faces)>=0 else -1;v.co.x=sign*.0008
bm.to_mesh(coat.data);bm.free()
for v in coat.data.vertices:
 p=v.co
 if p.z<.995 and abs(p.x)<.26:
  t=max(0,min(1,(.995-p.z)/.345));left=(1 if p.x>=0 else 0) if p.z<.83 else smooth(-.06,.06,p.x)
  weights(coat,v,{'root':1-t,'upperleg01.L':t*left,'upperleg01.R':t*(1-left)})
# The backing remains flexible over the whole panel length, not an abrupt 8cm
# root-to-thigh transition. Actual separate left/right panels never share legs.
for o in bpy.data.objects:
 if o.name.startswith('V3 supported split skirt'):
  side='L' if sum(v.co.x for v in o.data.vertices)>=0 else 'R'
  for v in o.data.vertices:
   t=max(0,min(1,(.995-v.co.z)/.345));weights(o,v,{'root':1-t,'upperleg01.'+side:t})
 if o.name.startswith('V3 supported shoulder'):
  side='L' if ' L ' in o.name else 'R';support={'spine01':.45,'clavicle.'+side:.55} if o.name.endswith('root') else {'upperarm01.'+side:1}
  for v in o.data.vertices:weights(o,v,support)
# Original proxy trousers already contain a sharp crotch transition: x=0 is
# ~78% spine05 while a neighbor 13mm away is ~69% thigh. Diffuse that inherited
# discontinuity locally without moving or deleting any trouser/body vertex.
pants=bpy.data.objects['Wool trousers'];names=[g.name for g in pants.vertex_groups];w=np.zeros((len(pants.data.vertices),len(names)))
for v in pants.data.vertices:
 for g in v.groups:w[v.index,g.group]=g.weight
neighbors=[set() for _ in pants.data.vertices]
for e in pants.data.edges:a,b=e.vertices;neighbors[a].add(b);neighbors[b].add(a)
mask=np.array([(1-smooth(.025,.085,abs(v.co.x)))*smooth(.63,.69,v.co.z)*(1-smooth(.83,.90,v.co.z)) for v in pants.data.vertices])
for step in range(16):
 nw=w.copy()
 for i,nb in enumerate(neighbors):
  if nb and mask[i]>0:nw[i]=w[i]*(1-.65*mask[i])+np.mean(w[list(nb)],axis=0)*(.65*mask[i])
 w=nw
for v in pants.data.vertices:
 if mask[v.index]>0:weights(pants,v,{name:float(value) for name,value in zip(names,w[v.index]) if value>1e-8})
bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1;bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-editable.blend'))
(out/'support-repair.json').write_text(json.dumps({'status':'REQUIRES_SAME_UNRELAXED_MOTION_GATE','real_center_seam_m':.0016,'full_length_panel_support_m':.345,'trouser_vertices_locally_reskinned':int(np.sum(mask>0)),'trouser_smoothing_iterations':16,'body_vertices_changed':0,'original_animation_count':len(bpy.data.actions),'visual_pass':False},indent=2)+'\n')
