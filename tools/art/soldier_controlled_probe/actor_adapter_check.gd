extends SceneTree
func _initialize():call_deferred("run")
func check(value:bool):
 if not value:
  push_error("AUTHOR_ACTOR_CHECK_FAILED");quit(1)
func run():
 var actor=load("res://scripts/field/experimental/controlled_author_actor.gd").new();root.add_child(actor)
 actor.position=Vector3(13,2,7);actor.rotation.y=.7
 var saved=actor.transform
 check(actor.configure_author_oracle(OS.get_environment("SOLDIER_CACHE"))==OK)
 check(actor.get_child_count()==43)
 check(actor.configure_author_oracle(OS.get_environment("SOLDIER_CACHE"))==ERR_ALREADY_IN_USE)
 for clip in ["walk","thrust"]:
  for phase in [0.,.5,1.]:check(actor.apply_author_phase(clip,phase)==OK)
 check(actor.apply_author_phase("unavailable_attack",.5)==ERR_DOES_NOT_EXIST)
 check(actor.apply_author_phase("walk",-1.)==ERR_INVALID_PARAMETER)
 check(actor.transform==saved)
 for child in actor.get_children():check(child is MeshInstance3D)
 print("AUTHOR_ACTOR_ADAPTER_CHECK ",JSON.stringify(actor.receipt()));quit()
