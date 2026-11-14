extends SceneTree
const Battle = preload("res://scripts/field/battle.gd")
const Arms = preload("res://scripts/field/arms.gd")
const Store = preload("res://scripts/field/save.gd")
const Contract = preload("res://scripts/field/experimental/author_phase_contract.gd")
const Binding = preload("res://scripts/field/experimental/author_unit_binding.gd")
const PEAK := 19.0/36.0 # Measured source frame, NOT independently proven contact.
class ProbeActor extends Node3D:
	var calls := 0
	var fail := false
	func apply_author_phase(_clip: String,_phase: float) -> Error:
		calls += 1
		return ERR_INVALID_DATA if fail else OK
func _initialize() -> void:
	var a = Battle.new();var b = Battle.new()
	a.setup(20);b.setup(20);a.start();b.start()
	var binding = Binding.new();var actor = ProbeActor.new()
	assert(binding.update_once(a,actor).reason == "default_off")
	assert(not actor.visible and binding.hidden_unit_id == -1)
	binding.enabled = true;binding.thrust_peak = PEAK
	var counts := {"walk":0,"thrust":0,"fallback":0,"releases":0}
	for tick in 600:
		var moving := tick%100 < 45
		var movement := Vector2(0.6,0) if moving else Vector2.ZERO
		var facing := Vector2(1,0) if tick%80<40 else Vector2(0,1)
		for battle in [a,b]:
			battle.input_state(movement,facing)
			if tick%35 == 0:battle.press_action(0)
			if tick%173 == 0:battle.press_action(1)
		var prior: int = a.hero.state
		a.step();b.step()
		var before := var_to_bytes(Store.snapshot(a))
		var prior_walk: float = binding.walk_phase
		var sample: Dictionary = binding.update_once(a,actor)
		assert(var_to_bytes(Store.snapshot(a)) == before,"binding changed battle snapshot")
		assert(var_to_bytes(Store.snapshot(b)) == before,"twin simulation diverged")
		var phase: float = binding.walk_phase
		assert(binding.update_once(a,actor) == sample,"same tick must be idempotent")
		assert(binding.walk_phase == phase)
		if sample.supported:
			counts[sample.clip] += 1
			assert(actor.visible and binding.hidden_unit_id == a.hero.id)
			assert(actor.position.is_equal_approx(Contract.Battle.Ground.unit_point(a.hero.pos,a.bridgehead)))
			var direction: Vector3 = actor.basis.z.normalized()
			assert(Vector2(direction.x,direction.z).is_equal_approx(a.hero.facing.normalized()))
			if prior == Battle.State.WINDUP and a.hero.state == Battle.State.RECOVER and sample.clip == "thrust":
				assert(is_equal_approx(sample.phase,PEAK));counts.releases += 1
		else:
			counts.fallback += 1
			assert(binding.walk_phase == prior_walk,"unsupported/stop advanced walk")
			assert(not actor.visible and binding.hidden_unit_id == -1)
	assert(counts.walk>0 and counts.thrust>0 and counts.releases>0 and counts.fallback>0)
	# Isolated contract fixtures do not mutate either live Battle.
	var u = Battle.Unit.new();u.kit=Arms.Kit.SPEAR;u.pos=Vector2.ONE
	assert(Contract.sample(u,1,0.,PEAK).reason == "mounted_without_clip")
	for state in [Battle.State.GUARD,Battle.State.STAGGER,Battle.State.DEAD,Battle.State.ROUT,Battle.State.ESCAPED]:
		u.state=state;assert(not Contract.sample(u,0,0.,PEAK).supported)
	u.state=Battle.State.MARCH;u.before=u.pos
	assert(Contract.sample(u,0,0.,PEAK).reason == "idle_without_clip")
	u.before=Vector2.ZERO;u.facing=Vector2.LEFT
	assert(Contract.sample(u,0,0.,PEAK).reason == "strafe_or_backward_without_clip")
	u.pos=Vector2.RIGHT;u.facing=Vector2.RIGHT;u.facing_before=Vector2.LEFT
	assert(Contract.sample(u,0,0.,PEAK).reason == "turn_without_clip")
	u.facing_before=u.facing;u.visual_run=true
	assert(Contract.sample(u,0,0.,PEAK).reason == "run_without_clip")
	u.visual_run=false;u.kit=Arms.Kit.SWORD
	assert(not Contract.sample(u,0,0.,PEAK).supported)
	u.kit=Arms.Kit.SPEAR;u.state=Battle.State.WINDUP;u.duration=.22;u.timer=0.
	assert(Contract.sample(u,0,0.).reason == "thrust_peak_evidence_missing")
	assert(is_equal_approx(Contract.sample(u,0,0.,PEAK).phase,PEAK))
	u.state=Battle.State.RECOVER;u.duration=.48;u.timer=.48
	assert(is_equal_approx(Contract.sample(u,0,0.,PEAK).phase,PEAK))
	u.timer=0.;assert(is_equal_approx(Contract.sample(u,0,0.,PEAK).phase,1.))
	u.move_slot=1;assert(not Contract.sample(u,0,0.,PEAK).supported)
	# Failed application must expose the original visual, never leave an invisible hero.
	var moving_battle = Battle.new();moving_battle.setup(20);moving_battle.start()
	moving_battle.input_state(Vector2.RIGHT*0.6,Vector2.RIGHT);moving_battle.step();moving_battle.step()
	actor.fail=true
	var failure: Dictionary = binding.update_once(moving_battle,actor)
	assert(failure.reason == "actor_apply_failed",str(failure))
	assert(not actor.visible and binding.hidden_unit_id == -1)
	actor.fail=false
	binding.disable(actor);assert(not actor.visible and binding.hidden_unit_id == -1)
	actor.free()
	print("AUTHOR_BINDING_TECHNICAL_PASS ",JSON.stringify(counts)," ticks=600 GPU_NOT_RUN ART_NOT_ACCEPTED")
	quit()
