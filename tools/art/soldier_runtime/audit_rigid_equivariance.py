"""Read-only proof for whole-object, one-original-bone equipment only.
Post-Armature Solidify/Bevel are evaluated, never silently discarded.
"""
import bpy,sys,pathlib,json,hashlib,numpy as np
src,expected,out=sys.argv[sys.argv.index('--')+1:];src=pathlib.Path(src);out=pathlib.Path(out);assert hashlib.sha256(src.read_bytes()).hexdigest()==expected
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
scene=bpy.context.scene;action=bpy.data.objects['rig'].animation_data.action;first,last=map(float,action.frame_range)
def points(mesh):return np.array([v.co[:] for v in mesh.vertices])
def normals(mesh):return np.array([n.vector[:] for n in mesh.corner_normals])
def world_points(p,m):return np.c_[p,np.ones(len(p))]@np.array(m).T
accepted=[];excluded=[]
for o in scene.objects:
 if o.type!='MESH' or not o.visible_get() or o.hide_render:continue
 mods=[m for m in o.modifiers if m.show_viewport]
 if not mods or mods[0].type!='ARMATURE' or any(m.type not in ['SOLIDIFY','BEVEL'] for m in mods[1:]):excluded.append(o.name);continue
 arm=mods[0].object;deform={b.name for b in arm.data.bones if b.use_deform};groups=[[(o.vertex_groups[g.group].name,g.weight) for g in v.groups if o.vertex_groups[g.group].name in deform and g.weight>0] for v in o.data.vertices];bs={g[0] for gs in groups for g in gs}
 if not groups or len(bs)!=1 or not all(len(gs)==1 and abs(gs[0][1]-1)<1e-7 for gs in groups):excluded.append(o.name);continue
 bone=next(iter(bs));scene.frame_set(int(first));mods[0].show_viewport=False;bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=o.evaluated_get(dg);me=ev.to_mesh();p=points(me);n=normals(me);uv=np.array([x.uv[:] for x in me.uv_layers.active.data]);loops=[x.vertex_index for x in me.loops];ev.to_mesh_clear();mods[0].show_viewport=True;bpy.context.view_layer.update();rows=[]
 for phase in [.013,.13,.317,.47,.683,.83,.987]:
  frame=first+(last-first)*phase;scene.frame_set(int(frame),subframe=frame%1);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=o.evaluated_get(dg);ae=arm.evaluated_get(dg);me=ev.to_mesh();M=ae.matrix_world.inverted()@ev.matrix_world;T=ev.matrix_world@M.inverted()@ae.pose.bones[bone].matrix@arm.data.bones[bone].matrix_local.inverted()@M
  same=len(me.vertices)==len(p) and [x.vertex_index for x in me.loops]==loops
  row=dict(phase=phase,identical_topology=same)
  if same:
   pred=world_points(p,T)[:,:3];ref=world_points(points(me),ev.matrix_world)[:,:3];err=np.linalg.norm(pred-ref,axis=1)
   pn=n@np.linalg.inv(np.array(T)[:3,:3]);rn=normals(me)@np.linalg.inv(np.array(ev.matrix_world)[:3,:3]);pn/=np.linalg.norm(pn,axis=1)[:,None];rn/=np.linalg.norm(rn,axis=1)[:,None];angle=np.degrees(np.arccos(np.clip((pn*rn).sum(1),-1,1)))
   row.update(max_position_m=float(err.max()),max_normal_degrees=float(angle.max()),UV_identical=bool(np.array_equal(uv,np.array([x.uv[:] for x in me.uv_layers.active.data]))),max_UV_abs_error=float(np.max(np.abs(uv-np.array([x.uv[:] for x in me.uv_layers.active.data])))),normal_corners_over_one_degree=int((angle>1).sum()),p95_normal_degrees=float(np.percentile(angle,95)))
  rows.append(row);ev.to_mesh_clear()
 accepted.append(dict(name=o.name,bone=bone,source_bones=len(arm.data.bones),source_vertices=len(o.data.vertices),post_modifier_vertices=len(p),post_modifier_corners=len(n),all_original_weights_one=True,modifiers=[m.type for m in mods],rows=rows))
r=dict(source_sha256=expected,source_unchanged=hashlib.sha256(src.read_bytes()).hexdigest()==expected,parts=accepted,excluded=excluded,scope='Only whole-object single-original-bone final Solidify/Bevel geometry; no mixed-weight equipment, cloth, hands or artistic acceptance',gpu_tested=False)
out.write_text(json.dumps(r,indent=2)+'\n');print('RIGID_SOURCE_AUDIT',len(accepted),'parts',sum(len(x['rows']) for x in accepted),'pose checks',flush=True)
