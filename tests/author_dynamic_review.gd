extends SceneTree
const Harness=preload("res://scripts/review/author_dynamic_review.gd")
const Battle=preload("res://scripts/field/battle.gd")
const Actions=preload("res://scripts/input_actions.gd")
class ProbeActor extends Node3D:
	var metadata:Dictionary={}
	func apply_author_phase(_clip:String,_phase:float)->Error:return OK
class ProbeView extends RefCounted:
	var review_hidden_actor_id := -1
class ProbeField extends Node:
	var battle=Battle.new()
	var paused := false
	var follow := false
	var view=ProbeView.new()
class ProbeRecorder extends Node:
	var active := true
	var rows:Array=[]
	var reason := ""
	func write(row:Dictionary)->void:rows.append(row.duplicate(true))
	func stop(value:String)->void:reason=value;active=false
func _initialize()->void:
	call_deferred("_run")
func _run()->void:
	Actions.install()
	var source={"source_files":{"thrust":{"sha256":"exact-source"}}}
	assert(Harness.validated_peak(source,{"animation_source_sha256":"old-source","peak_phase":0.5}) == -1.0)
	assert(Harness.validated_peak(source,{"animation_source_sha256":"exact-source","peak_phase":0.5}) == 0.5)
	assert(Harness.validated_peak(source,{"animation_source_sha256":"exact-source","peak_phase":INF}) == -1.0)
	assert(Harness.validated_peak(source,{}) == -1.0)
	assert(Harness.intent(0).stage=="natural_idle_fallback")
	assert(Harness.intent(2000000).move)
	assert(not Harness.intent(7000000).move)
	assert(Harness.intent(9000000).attack)
	assert(not Harness.intent(9200000).attack)
	assert(not Harness.intent(14000000).attack)
	var field=ProbeField.new();field.battle.setup(20);field.battle.start()
	var actor=ProbeActor.new();var recorder=ProbeRecorder.new();var h=Harness.new()
	root.add_child(field);root.add_child(actor);root.add_child(recorder);root.add_child(h)
	var snapshot=var_to_bytes(preload("res://scripts/field/save.gd").snapshot(field.battle))
	# Refuse another hide-slot owner without changing it or stealing input.
	field.view.review_hidden_actor_id=123
	assert(h.begin(field,actor,recorder,224000000)==ERR_ALREADY_IN_USE)
	assert(field.view.review_hidden_actor_id==123)
	field.view.review_hidden_actor_id=-1
	assert(h.begin(field,actor,recorder,224000000)==OK)
	assert(field.follow)
	h.set_inputs(true,true)
	assert(Input.is_action_pressed("move_right"))
	assert(Input.is_physical_key_pressed(KEY_J))
	var movement:=Input.get_vector("move_left","move_right","move_up","move_down")
	assert(movement.x>0.0 and movement.x<0.8)
	h.binding.hidden_unit_id=field.battle.hero.id;field.view.review_hidden_actor_id=field.battle.hero.id
	h.finish("test_cancel")
	assert(not Input.is_action_pressed("move_right") and not Input.is_physical_key_pressed(KEY_J))
	assert(field.view.review_hidden_actor_id==-1 and not field.follow and not actor.visible)
	assert(recorder.reason=="test_cancel")
	assert(var_to_bytes(preload("res://scripts/field/save.gd").snapshot(field.battle))==snapshot)
	# Unload while holding input follows the same release contract.
	var h2=Harness.new();var r2=ProbeRecorder.new();root.add_child(h2);root.add_child(r2)
	assert(h2.begin(field,actor,r2,224000000)==OK);h2.set_inputs(true,true)
	h2.free()
	assert(not Input.is_action_pressed("move_right") and not Input.is_physical_key_pressed(KEY_J))
	assert(field.view.review_hidden_actor_id==-1 and r2.reason=="harness_unloaded")
	h.free();actor.free();field.free();recorder.free();r2.free()
	print("AUTHOR_DYNAMIC_BOUNDARY_PASS stages input_release cancel unload no_battle_writes; LIVE_CONTROLLER_GPU_NOT_RUN")
	quit()
