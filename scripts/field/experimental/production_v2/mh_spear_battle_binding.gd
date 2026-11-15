extends RefCounted
## Opt-in only. Read actual ordinary spear state; never change Battle/HP/AI/positions.
const Battle=preload("res://scripts/field/battle.gd")
var ground_point:Callable # New mother-scene authoritative world-height resolver, no old-map fallback.
var enabled:=false
var last_tick:=-1
var previous_state:=-1
var state_started_tick:=0
var previous_pos:=Vector2.ZERO
var movement_phase:=0.0
var idle_seconds:=0.0
var death_presentation_seconds:=0.0
var last_receipt:Dictionary={}
# Exact imported GLB blade timing, not Guardian or a hardcoded author frame.
var thrust_peak:=-1.0
# Initial source-locomotion estimates; not a foot-slip/stride quality acceptance.
var stride_m:Dictionary={"walk":1.45,"jog":2.0,"sprint":2.6}
# glTF converts authored Blender -Y forward into Godot +Z; shaft offset is explicit.
var author_aim_yaw:=0.0
func configure_timing(metadata:Dictionary,actual_glb_sha:String)->Error:
 if actual_glb_sha.is_empty() or metadata.get("glb_sha256","")!=actual_glb_sha:return ERR_INVALID_DATA
 var peak:=float(metadata.get("thrust_peak_phase",-1.0))
 if not is_finite(peak) or peak<=0. or peak>=1.:return ERR_INVALID_DATA
 thrust_peak=peak;author_aim_yaw=float(metadata.get("author_aim_yaw_radians",0.0));return OK
func update(battle,actor:Node3D,presentation_delta:float=0.0,interpolation_alpha:float=1.0)->Dictionary:
 if not enabled or actor==null:return {"supported":false,"reason":"disabled"}
 if not ground_point.is_valid():return {"supported":false,"reason":"new_scene_ground_resolver_missing"}
 var unit=battle.hero
 # Presentation interpolation never updates unit positions or advances Battle.
 actor.position=ground_point.call(unit.before.lerp(unit.pos,clampf(interpolation_alpha,0.,1.)))
 actor.rotation.y=atan2(unit.facing.x,unit.facing.y)-author_aim_yaw
 var dead:bool=unit.hp<=0 or unit.state==Battle.State.DEAD
 if dead:death_presentation_seconds+=maxf(presentation_delta,0.)
 if battle.tick==last_tick and not dead:return last_receipt
 if unit.kit!=Battle.Arms.Kit.SPEAR or unit.mounted or battle.vehicle!=0:
  last_receipt={"supported":false,"reason":"nonfoot_spear_outside_scope"};return last_receipt
 var steps:=maxi(1,battle.tick-last_tick) if last_tick>=0 else 1
 var delta:=steps*Battle.DT;var moved:float=unit.pos.distance_to(previous_pos) if last_tick>=0 else 0.
 if unit.state!=previous_state:state_started_tick=battle.tick
 var elapsed:=maxf(0.,(battle.tick-state_started_tick)*Battle.DT)
 var semantic:="idle";var phase:=0.;var supported:=true;var reason:="actual_idle"
 if dead:
  semantic="death";phase=clampf(death_presentation_seconds/maxf(.001,actor.clip_seconds(semantic)),0.,1.);reason="actual_death"
 elif unit.state==Battle.State.STAGGER:
  semantic="hit_chest";phase=clampf(elapsed/maxf(.001,actor.clip_seconds(semantic)),0.,1.);reason="actual_stagger_hit_location_unspecified"
 elif unit.state in [Battle.State.WINDUP,Battle.State.RECOVER]:
  if unit.move_slot!=0 or unit.stock_strike or unit.charging_strike or unit.duration<=0 or thrust_peak<=0:
   supported=false;reason="skill_alternate_attack_without_new_clip"
  else:
   semantic="thrust";var progress:=clampf(1.-unit.timer/unit.duration,0.,1.)
   phase=progress*thrust_peak if unit.state==Battle.State.WINDUP else lerpf(thrust_peak,1.,progress)
   reason="actual_ordinary_spear_release_aligned_to_MH_axis_peak"
 elif unit.state==Battle.State.MARCH:
  if moved>.0001:
   if (unit.pos-previous_pos).normalized().dot(unit.facing.normalized())<.8:
    supported=false;reason="directional_strafe_or_backward_clip_missing"
   else:
    semantic="sprint" if unit.visual_run else "walk"
    movement_phase=fposmod(movement_phase+moved/float(stride_m[semantic]),1.);phase=movement_phase;reason="actual_forward_motion_stride_uncalibrated"
  else:
   idle_seconds+=delta;phase=fposmod(idle_seconds/maxf(.001,actor.clip_seconds("idle")),1.)
 else:
  supported=false;reason="state_without_complete_new_clip"
 # Transform writes are presentation only, never Unit coordinates.
 if supported:last_receipt=actor.sample(semantic,phase,presentation_delta if presentation_delta>0. else delta)
 else:last_receipt={"supported":false,"reason":reason,"representation":"new_actor_pose_held_UNSUPPORTED_not_faked_action"}
 last_receipt.merge({"tick":battle.tick,"state":unit.state,"unit_id":unit.id,"reason":reason,"actual_impacts":unit.impacts,"actual_hp":unit.hp,"stride_calibrated":false},true)
 last_tick=battle.tick;previous_state=unit.state;previous_pos=unit.pos
 return last_receipt
