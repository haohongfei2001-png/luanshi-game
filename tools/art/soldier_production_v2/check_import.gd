extends SceneTree
func _initialize():
 var packed=load('res://spearman-v2-wip.glb') as PackedScene
 assert(packed != null)
 var actor=packed.instantiate()
 root.add_child(actor)
 var skeleton:Skeleton3D=actor.find_child('*',true,false) as Skeleton3D
 var skels=actor.find_children('*','Skeleton3D',true,false)
 assert(skels.size()==1)
 skeleton=skels[0]
 assert(skeleton.get_bone_count()==163)
 var players=actor.find_children('*','AnimationPlayer',true,false)
 assert(players.size()==1)
 var player:AnimationPlayer=players[0]
 print('ACTUAL_ANIMATIONS ',player.get_animation_list())
 var expected_duration={'Idle':2.5,'Walk':1.3333333,'Sprint':0.6666667,'Death01':2.4}
 for name in expected_duration:
  if abs(player.get_animation(name).length-expected_duration[name])>0.025:
   push_error('Wrong source FPS/duration: '+name+' '+str(player.get_animation(name).length))
   quit(3)
   return
 for clip in ['Idle','Walk','Jog_Fwd','Sprint','Hit_Chest','Hit_Head','Death01']:
  if not player.has_animation(clip):
   print('MISSING ',clip)
   quit(2)
   return
  player.play(clip)
  player.advance(player.get_animation(clip).length*0.4)
  for bone in skeleton.get_bone_count():
   assert(skeleton.get_bone_global_pose(bone).is_finite())
 var surfaces=0
 var meshes=actor.find_children('*','MeshInstance3D',true,false)
 var normal_mats=0
 for instance in meshes:
  assert(instance.mesh != null)
  surfaces+=instance.mesh.get_surface_count()
  for i in instance.mesh.get_surface_count():
   var mat=instance.mesh.surface_get_material(i)
   if mat is BaseMaterial3D and mat.normal_enabled:
    assert(mat.normal_texture!=null)
    normal_mats+=1
 print(JSON.stringify({'status':'HEADLESS_IMPORT_AND_ANIMATION_PASS_NOT_VISUAL','bones':skeleton.get_bone_count(),'animations':player.get_animation_list(),'mesh_nodes':meshes.size(),'surfaces':surfaces,'normal_material_instances':normal_mats,'gpu':'NOT_RUN','art_acceptance':false}))
 quit(0)
