extends Node
## Opt-in 18s live-controller diagnostic. Never steps or edits Battle.
## Parent provides an already configured actor and started wall-clock recorder.
const Binding = preload("res://scripts/field/experimental/author_unit_binding.gd")
const Contract = preload("res://scripts/field/experimental/author_phase_contract.gd")
var field: Node
var actor: Node3D
var recorder: Node
var binding = Binding.new()
var active := false
var started_us := 0
var held_action := false
var held_attack := false
var _previous_stage := ""
var _initial_impacts := 0
var _initial_attacks := 0
var _previous_tick := -1
var _previous_state := -1
var releases_observed := 0
var _prior_follow := false
var _owns_slot := false
var _last_body_frame := -1
var actual_attack_keydowns := 0
var observed_key_held_ticks := 0
const DURATION_US := 18000000

static func intent(elapsed_us: int) -> Dictionary:
	var seconds := float(elapsed_us)/1000000.0
	if seconds < 2.0:return {"stage":"natural_idle_fallback","move":false,"attack":false}
	if seconds < 7.0:return {"stage":"slow_forward_walk_diagnostic","move":true,"attack":false}
	if seconds < 9.0:return {"stage":"natural_stop_fallback","move":false,"attack":false}
	if seconds < 14.0:
		# Discrete 120ms J presses, never fabricate a Battle release or hit.
		return {"stage":"ordinary_spear_input","move":false,"attack":fposmod(seconds-9.0,1.5)<0.12}
	return {"stage":"final_stop_fallback","move":false,"attack":false}

static func validated_peak(metadata: Dictionary, evidence: Dictionary) -> float:
	# Geometry-derived timing belongs to its exact source, not a later costume/pose.
	var source: String = metadata.get("source_files",{}).get("thrust",{}).get("sha256","")
	var peak: float = float(evidence.get("peak_phase",-1.0))
	if source.is_empty() or evidence.get("animation_source_sha256","") != source:return -1.0
	if not is_finite(peak) or peak<=0.0 or peak>=1.0:return -1.0
	return peak

func begin(game_field: Node, configured_actor: Node3D, wall_recorder: Node, cache_bytes: int, phase_evidence: Dictionary = {}) -> Error:
	if active:return ERR_ALREADY_IN_USE
	if not is_instance_valid(game_field) or not is_instance_valid(configured_actor) or not is_instance_valid(wall_recorder):return ERR_INVALID_PARAMETER
	if not wall_recorder.active or not game_field.battle.started or game_field.paused or game_field.battle.result != "":return ERR_UNAVAILABLE
	if game_field.battle.vehicle != 0 or game_field.battle.hero.kit != Contract.Arms.Kit.SPEAR:return ERR_INVALID_PARAMETER
	if game_field.view.review_hidden_actor_id != -1:return ERR_ALREADY_IN_USE
	# Never release input belonging to a user or another diagnostic.
	for name in ["move_left","move_right","move_up","move_down","attack","field_sprint"]:
		if Input.is_action_pressed(name):return ERR_ALREADY_IN_USE
	field=game_field;actor=configured_actor;recorder=wall_recorder
	binding.enabled=true;binding.thrust_peak=validated_peak(actor.metadata,phase_evidence)
	_previous_stage="";_previous_tick=-1;_previous_state=-1;releases_observed=0;binding.walk_phase=0.0;actual_attack_keydowns=0;observed_key_held_ticks=0;_last_body_frame=-1
	_prior_follow=field.follow;field.follow=true
	process_priority=field.process_priority-1
	process_physics_priority=field.process_physics_priority+1
	_initial_impacts=field.battle.hero.impacts;_initial_attacks=field.battle.attacks
	started_us=Time.get_ticks_usec();active=true;_owns_slot=true
	recorder.write({"kind":"author_dynamic_contract","monotonic_us":started_us,"duration_us":DURATION_US,"cache_payload_bytes":cache_bytes,"cache_size_note":"actual external evaluated cache around224MB, not35MB source blend; caller must pass measured bytes","scope":"ONE_REAL_HERO_MIXED_OLD_NEW_DIAGNOSTIC_NOT_FULL_NEW_CHARACTER_ACCEPTANCE","source_peak":binding.thrust_peak,"thrust_timing_source_verified":binding.thrust_peak>0.0,"source_known_failures":["spear_torso_intersection","feet_ground","stride_speed_uncalibrated"],"input":"InputEventAction move_right strength0.8 through real Input.get_vector; actual J keys; pointer events","camera":"existing projection/size unchanged; real follow enabled","performance":"READBACK_INSTRUMENTED_NOT_BENCHMARK","initial_tick":field.battle.tick})
	return OK

func _physics_process(_delta: float) -> void:
	if not active or not is_instance_valid(field):return
	var b=field.battle
	if b.tick != _previous_tick:
		if Input.is_physical_key_pressed(KEY_J):observed_key_held_ticks+=1
		if _previous_state == Contract.Battle.State.WINDUP and b.hero.state == Contract.Battle.State.RECOVER:
			releases_observed+=1
		_previous_tick=b.tick;_previous_state=b.hero.state

func _process(_delta: float) -> void:
	if not active:return
	if not is_instance_valid(field) or not is_instance_valid(actor) or not is_instance_valid(recorder):
		finish("dependency_removed");return
	if not recorder.active:
		finish("recorder_stopped");return
	var now:=Time.get_ticks_usec()
	if now-started_us>=DURATION_US:
		finish("review_complete");return
	if field.paused or field.battle.result!="" or field.battle.hero.hp<=0:
		finish("battle_interrupted");return
	var wanted:=intent(now-started_us)
	if wanted.stage != _previous_stage:
		_previous_stage=wanted.stage
		recorder.write({"kind":"author_stage","stage":wanted.stage,"monotonic_us":now,"tick":field.battle.tick})
	# Camera-relative right maps via the exact rotation used by controller.
	# No aiming at fake enemies: target is ground 8 units in that forward direction.
	var direction:=Vector2.RIGHT.rotated(-field.camera_yaw)
	var point: Vector2 = field.battle.hero.pos+direction*8.0
	var screen: Vector2 = field.camera.unproject_position(Contract.Battle.Ground.unit_point(point,field.battle.bridgehead))
	var pointer:=InputEventMouseMotion.new();pointer.position=screen;pointer.global_position=screen
	Input.parse_input_event(pointer);Input.flush_buffered_events()
	recorder.write({"kind":"author_pointer_input","position":[screen.x,screen.y],"monotonic_us":Time.get_ticks_usec(),"tick":field.battle.tick})
	set_inputs(wanted.move,wanted.attack)
	var sample: Dictionary = binding.update_once(field.battle,actor)
	field.view.review_hidden_actor_id=binding.hidden_unit_id
	var b=field.battle;var u=b.hero
	# The pre-draw field process updates camera after this harness. Observe AFTER draw.
	if not RenderingServer.frame_post_draw.is_connected(observe_camera):RenderingServer.frame_post_draw.connect(observe_camera)
	recorder.write({"kind":"author_render_observation","monotonic_us":Time.get_ticks_usec(),"engine_process_frame":Engine.get_process_frames(),"engine_drawn":Engine.get_frames_drawn(),"tick":b.tick,"stage":wanted.stage,"mapping":sample,"pos":[u.pos.x,u.pos.y],"before":[u.before.x,u.before.y],"facing":[u.facing.x,u.facing.y],"state":u.state,"timer":u.timer,"duration":u.duration,"move_slot":u.move_slot,"hero_hp":u.hp,"hero_impacts":u.impacts,"battle_attacks":b.attacks,"battle_hits":b.hits.duplicate(),"camera_size":field.camera.size,"follow":field.follow,"input_vector":str(Input.get_vector("move_left","move_right","move_up","move_down")),"scope":"pre_draw_controller_observation; join captured JPEGs by monotonic timestamp, not one row per JPEG"})

func set_inputs(move: bool, attack: bool) -> void:
	if move != held_action:
		var event:=InputEventAction.new();event.action="move_right";event.pressed=move;event.strength=0.8 if move else 0.0
		Input.parse_input_event(event);Input.flush_buffered_events();held_action=move
		input_receipt({"type":"InputEventAction","action":"move_right","pressed":move,"strength":event.strength})
	if attack != held_attack:
		var event:=InputEventKey.new();event.keycode=KEY_J;event.physical_keycode=KEY_J;event.pressed=attack
		Input.parse_input_event(event);Input.flush_buffered_events();held_attack=attack
		if attack:actual_attack_keydowns+=1
		input_receipt({"type":"InputEventKey","key":KEY_J,"pressed":attack})

func input_receipt(row: Dictionary) -> void:
	if is_instance_valid(recorder) and recorder.active:
		row["kind"]="author_actual_input";row["monotonic_us"]=Time.get_ticks_usec()
		if is_instance_valid(field):row["tick"]=field.battle.tick
		recorder.write(row)

func observe_camera()->void:
	if not active or not is_instance_valid(field) or not is_instance_valid(actor) or not is_instance_valid(recorder) or not recorder.active:return
	var drawn:=Engine.get_frames_drawn()
	if drawn==_last_body_frame:return
	_last_body_frame=drawn
	var c:Camera3D=field.camera
	var body=actor.projected_current_body(c) if actor.visible and actor.has_method("projected_current_body") else {"valid":false,"reason":"original_visual_fallback"}
	recorder.write({"kind":"author_after_draw_camera","monotonic_us":Time.get_ticks_usec(),"engine_drawn":drawn,"tick":field.battle.tick,"projection":c.projection,"fov":c.fov,"size":c.size,"near":c.near,"far":c.far,"transform":str(c.global_transform),"projection_matrix":str(c.get_camera_projection()),"review_profile":field.review_camera_profile.duplicate(true),"body":body,"measurement":"CPU projected current-pose vertices; readback-instrumented diagnostic, not FPS benchmark"})

func finish(reason: String = "cancelled") -> void:
	if RenderingServer.frame_post_draw.is_connected(observe_camera):RenderingServer.frame_post_draw.disconnect(observe_camera)
	set_inputs(false,false)
	if is_instance_valid(actor):binding.disable(actor)
	if _owns_slot and is_instance_valid(field):
		field.view.review_hidden_actor_id=-1;field.follow=_prior_follow
	_owns_slot=false
	if active and is_instance_valid(recorder) and recorder.active:
		var impact_delta: int = field.battle.hero.impacts-_initial_impacts if is_instance_valid(field) else 0
		recorder.write({"kind":"author_dynamic_result","reason":reason,"monotonic_us":Time.get_ticks_usec(),"wall_seconds":(Time.get_ticks_usec()-started_us)/1000000.0,"hero_impacts_delta":impact_delta,"hit_status":"ACTUAL_HERO_IMPACT_OBSERVED" if impact_delta>0 else "NO_HERO_HIT_OBSERVED","actual_attack_keydown_events":actual_attack_keydowns,"observed_key_held_physics_ticks":observed_key_held_ticks,"pulse_warning":"120ms intended pulse may be skipped at low render cadence; only actual emitted input and observed state counts are evidence","observed_release_transitions":releases_observed,"release_sampling":"observed controller ticks; multiple catch-up ticks may skip transitions","inputs_released":not Input.is_action_pressed("move_right") and not Input.is_physical_key_pressed(KEY_J),"hidden_unit_id":binding.hidden_unit_id,"art_status":"NOT_ACCEPTED_MIXED_VISUAL_DIAGNOSTIC"})
		recorder.stop(reason)
	active=false

func _exit_tree() -> void:
	finish("harness_unloaded")
