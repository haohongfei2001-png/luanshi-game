"""Exact evaluated triangle intersections: hard shoulder versus original soft coat.
Candidate penetration evidence, not a collision solver, garment or visual PASS.
Original full author rigs/modifiers remain unchanged; no point correction.
"""
import bpy,sys,pathlib,json,hashlib
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2])
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];coat=bpy.data.objects.get('GEO-topLT-recut')
if coat is None:raise RuntimeError('Exact new sewn coat missing')
parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('PATTERN ') and any(x in o.name for x in ['lamella','leaf'])]
if not parts:raise RuntimeError('No independent shoulder armor found')
original={p.name:p.matrix_basis.copy() for p in rig.pose.bones}
rows=[]
def tree(obj):
 ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles()
 points=[ev.matrix_world@v.co for v in me.vertices];faces=[tuple(t.vertices) for t in me.loop_triangles]
 result=BVHTree.FromPolygons(points,faces,all_triangles=True);ev.to_mesh_clear();return result,len(faces)
for name,upper,fore in [('source',0,0),('half_raise',.475,.375),('raised',.95,.75)]:
 for p in rig.pose.bones:p.matrix_basis=original[p.name]
 if name!='source':
  for side,sign in [('L',1),('R',-1)]:
   rig.pose.bones['hand_ik.'+side]['ik']=0.
   for stem,angle in [('upper_arm.',-upper*sign),('forearm.',fore*sign)]:
    p=rig.pose.bones[stem+side];p.rotation_mode='XYZ';p.rotation_euler[2]=angle
 bpy.context.view_layer.update();cloth,n=tree(coat);hits=[]
 for o in parts:
  armor,m=tree(o);pairs=armor.overlap(cloth)
  if pairs:hits.append({'part':o.name,'intersecting_triangle_pairs':len(pairs),'armor_triangle_count':m,'distinct_armor_triangles':len(set(x for x,y in pairs))})
 rows.append({'pose':name,'cloth_triangles':n,'intersections':hits,'total_pairs':sum(x['intersecting_triangle_pairs'] for x in hits)})
r={'source_sha256':hashlib.file_digest(src.open('rb'),'sha256').hexdigest(),'hard_parts_tested':len(parts),'sampled_poses':rows,'art_pass':False,'contact_pass':False,'limitations':['Triangle intersection candidates only; no enclosed-volume test or penetration depth','No interpolated full walk/thrust evidence','Original author modifier evaluation, not Godot runtime collision','Armor-to-armor overlaps are intentional and excluded here']}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(r,indent=2));print('SHOULDER_SURFACE_INTERSECTIONS',[(x['pose'],x['total_pairs']) for x in rows])
