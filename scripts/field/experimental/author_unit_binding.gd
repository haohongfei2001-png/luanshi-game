extends RefCounted
## Opt-in adapter for ONE already-configured actor. Caller owns its lifecycle.
## update_once after Battle.step, before render; do not invoke on interpolated Units.
## Caller must restore old visual whenever hidden_unit_id == -1, including teardown.
const Contract = preload("res://scripts/field/experimental/author_phase_contract.gd")
const Ground = preload("res://scripts/field/ground.gd")
var enabled := false
var hidden_unit_id := -1
var walk_phase := 0.0
var thrust_peak := -1.0 # Keep disabled until source-measured evidence is supplied.
var _last_tick := -1
var _unit_id := -1
var _last_sample: Dictionary = {}

func update_once(battle, actor: Node3D) -> Dictionary:
	var unit = battle.hero
	if _unit_id != unit.id or battle.tick < _last_tick:
		walk_phase = 0.0
		_last_tick = -1
		_unit_id = unit.id
	var sample := Contract.sample(unit,battle.vehicle,walk_phase,thrust_peak)
	if enabled and battle.tick != _last_tick and sample.supported and sample.clip == "walk":
		# At most one fixed tick, never catch up missing observations with fake walking.
		walk_phase = fposmod(walk_phase+Contract.Battle.DT/Contract.WALK_SECONDS,1.0)
		sample.phase = walk_phase
	_last_tick = battle.tick
	hidden_unit_id = -1
	actor.visible = false
	if not enabled:
		sample = {"supported":false,"reason":"default_off","clip":"","phase":0.0}
	elif sample.supported:
		var error: int = actor.apply_author_phase(sample.clip,sample.phase)
		if error != OK:
			sample = {"supported":false,"reason":"actor_apply_failed","error":error,"clip":"","phase":0.0}
		else:
			# No additive root motion, interpolation, ground lift or simulation mutation.
			actor.transform = Transform3D(Basis(Vector3.UP,atan2(unit.facing.x,unit.facing.y)).scaled(Vector3.ONE*1.07),Ground.unit_point(unit.pos,battle.bridgehead))
			actor.visible = true
			hidden_unit_id = unit.id
	sample["hidden_unit_id"] = hidden_unit_id
	_last_sample = sample.duplicate()
	return sample

func disable(actor: Node3D) -> void:
	enabled = false
	hidden_unit_id = -1
	actor.visible = false
