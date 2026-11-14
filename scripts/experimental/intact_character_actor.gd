extends Node3D
## Opt-in source-character adapter, NEVER loaded by the shipping presentation.
## Battle state is read-only. Missing weapon/ride clips are exposed, not faked.
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const DEFAULT_MODEL := "res://assets/ubc_lab/ubc_animated.glb"
# Exact UAL Standard RM root-translation endpoint distances, scaled using the
# committed rest-aware retarget. These are SOURCE data, not foot-lock approval.
const SOURCE_CYCLE_METERS := {"Walk": 1.345947387, "Jog_Fwd": 5.176720911, "Sprint": 5.694392888}
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var hand_sockets: Dictionary = {}
var source_bounds := AABB()
var source_min_y := 0.0
var last_clip := ""
var last_receipt: Dictionary = {}

func configure(path: String = DEFAULT_MODEL) -> void:
	assert(model == null, "Create a separate adapter for each intact source instance")
	model = (load(path) as PackedScene).instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	player = model.find_children("*", "AnimationPlayer", true, false)[0]
	assert(skeleton.get_bone_count() == 65)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: String in ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sword_Idle"]:
		player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		# Native mesh/Skin/weights/materials are untouched. Bounds here describe
		# the imported rest shape only, not its posed soles or collision.
		var box: AABB = model.global_transform.affine_inverse() * mesh.global_transform * mesh.mesh.get_aabb()
		source_bounds = box if first else source_bounds.merge(box)
		first = false
	source_min_y = source_bounds.position.y
	for label: String in ["hand_l", "hand_r"]:
		var index := skeleton.find_bone(label)
		assert(index >= 0)
		var socket := BoneAttachment3D.new()
		socket.name = "Source_" + label
		socket.bone_name = label
		socket.bone_idx = index
		skeleton.add_child(socket)
		hand_sockets[label] = socket
	_sample("Idle", 0.0)

func _sample(clip: String, seconds: float) -> void:
	if clip != last_clip:
		player.play(clip)
		last_clip = clip
	player.seek(seconds, true)
	player.advance(0.0)
	skeleton.force_update_all_bone_transforms()

func observe(battle: Battle, unit: Battle.Unit, alpha: float, traveled_meters: float) -> Dictionary:
	assert(model != null and alpha >= 0.0 and alpha <= 1.0)
	var point := unit.before.lerp(unit.pos, alpha)
	position = Vector3(point.x, Ground.deck_height(point, battle.bridgehead) - source_min_y, point.y)
	var heading := atan2(unit.facing.x, unit.facing.y)
	if unit.facing_before != Vector2.ZERO:
		heading = lerp_angle(atan2(unit.facing_before.x, unit.facing_before.y), heading, alpha)
	rotation.y = heading # Source glTF forward is +Z, NOT Godot Camera3D -Z.
	var state_age := maxf(0.0, unit.duration - unit.timer - (1.0 - alpha) * Battle.DT)
	var clock := (float(battle.tick) + alpha) * Battle.DT
	var clip := "Idle"
	var clip_time := fposmod(clock, player.get_animation("Idle").length)
	var unsupported := ""
	var moving := unit.pos.distance_squared_to(unit.before) > 0.000001
	if unit.mounted or (unit.hero and battle.vehicle != 0):
		unsupported = "native_riding_and_vehicle_clip_missing"
	elif unit.state == Battle.State.ESCAPED:
		unsupported = "escaped_not_drawn"
	elif unit.state == Battle.State.DEAD:
		clip = "Death01"
		# The old presentation's short fall timer must not truncate a complete
		# imported fall. Read the actual death stamp, without delaying any death.
		var death_age := maxf(0.0, (float(battle.tick - unit.lost_tick) + alpha) * Battle.DT)
		clip_time = minf(death_age if unit.lost_tick >= 0 else state_age, player.get_animation(clip).length)
	elif unit.state == Battle.State.STAGGER:
		clip = "Hit_Chest"
		clip_time = minf(state_age, player.get_animation(clip).length)
	elif unit.state in [Battle.State.WINDUP, Battle.State.RECOVER, Battle.State.GUARD]:
		unsupported = "authored_weapon_contact_curve_missing"
	elif moving:
		clip = "Walk"
		clip_time = fposmod(traveled_meters / SOURCE_CYCLE_METERS[clip], 1.0) * player.get_animation(clip).length
		unsupported = "source_stride_not_ground_contact_approved"
	visible = unit.state != Battle.State.ESCAPED
	_sample(clip, clip_time)
	last_receipt = {"id": unit.id, "tick": battle.tick, "state": unit.state, "clip": clip,
		"clip_seconds": clip_time, "position": [position.x, position.y, position.z],
		"forward": [basis.z.x, basis.z.y, basis.z.z], "bones": skeleton.get_bone_count(),
		"unsupported": unsupported, "weapon_attached": false, "foot_contact_approved": false,
		"native_rig_preserved": true, "shipping_enabled": false}
	return last_receipt
