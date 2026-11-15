extends Node3D
## Production-v2 WIP: standard shared mesh/material resources, per-instance skeleton.
## No evaluated vertex cache, no Battle writes. Scene/animation quality remains unaccepted.
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var clip_names:Dictionary={}
var last_receipt:Dictionary={}
const CLIPS={"idle":["Spear_Idle_V2_DRAFT"],"walk":["Spear_Walk_V2_DRAFT"],"jog":["Spear_Jog_V2_DRAFT"],"sprint":["Spear_Sprint_V2_DRAFT"],"thrust":["Spear_Thrust_V2_DRAFT"],"hit_chest":["Hit_Chest"],"hit_head":["Hit_Head"],"death":["Death01"]}
func setup(packed:PackedScene)->Error:
 if model!=null or packed==null:return ERR_INVALID_PARAMETER
 model=packed.instantiate() as Node3D
 if model==null:return ERR_FILE_CORRUPT
 add_child(model)
 for node in model.find_children("*","Skeleton3D",true,false):
  if skeleton!=null:return ERR_INVALID_DATA
  skeleton=node
 for node in model.find_children("*","AnimationPlayer",true,false):
  if player!=null:return ERR_INVALID_DATA
  player=node
 if skeleton==null or skeleton.get_bone_count()!=163 or player==null:return ERR_INVALID_DATA
 player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for semantic in CLIPS:
  for candidate in CLIPS[semantic]:
   if player.has_animation(candidate):clip_names[semantic]=candidate;break
  if not clip_names.has(semantic):return ERR_DOES_NOT_EXIST
 # Do not mutate shared imported Animation resources: loop sampling is explicit.
 return OK
func sample(semantic:String,phase:float,delta:float)->Dictionary:
 if player==null or not clip_names.has(semantic) or not is_finite(phase):return {"supported":false,"reason":"missing_or_invalid_clip"}
 var clip:String=clip_names[semantic];var animation:=player.get_animation(clip)
 if player.current_animation!=clip:player.play(clip,.08)
 player.advance(maxf(delta,0.0))
 var time:=clampf(phase,0.0,1.0)*animation.length
 player.seek(time,true,true)
 last_receipt={"supported":true,"clip":clip,"semantic":semantic,"phase":phase,"actual_animation_seconds":player.current_animation_position,"skeleton_bones":skeleton.get_bone_count(),"representation":"shared_skinned_GLTF_not_vertex_pose_cache","art_status":"WIP_NOT_ACCEPTED"}
 return last_receipt
func clip_seconds(semantic:String)->float:
 return player.get_animation(clip_names[semantic]).length if player!=null and clip_names.has(semantic) else 0.0
