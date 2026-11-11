extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
var paths: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func reject(source: Dictionary, label: String) -> void:
	var target := W.new(556)
	var before := target.export_campaign_state()
	var result := target.restore_campaign_state(source)
	check(not result.ok, label + " rejected")
	check(before == target.export_campaign_state(), label + " detached atomicity")
func walk(value: Variant, path: Array) -> void:
	paths.append(path)
	if value is Dictionary:
		for key in value: walk(value[key], path + [key])
	elif value is Array:
		for index in range(mini(value.size(), 2)): walk(value[index], path + [index])
func at(state: Dictionary, path: Array) -> Variant:
	var node: Variant = state
	for part in path: node = node[part]
	return node
func put(state: Dictionary, path: Array, value: Variant) -> void:
	var node: Variant = state
	for i in range(path.size() - 1): node = node[path[i]]
	node[path[-1]] = value
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w := W.new()
	check(w.start_youth("volunteer", "homeland").ok, "fixture starts by legal enlistment")
	w.youth_action("first_march")
	var id: String = w.create_battle_ticket().ticket.battle_id
	var b := w.start_battle(id)
	var active := w.export_campaign_state()
	var corrupt := active.duplicate(true)
	corrupt.battle_sessions[id].order = "follow"
	reject(corrupt, "unauthorized recruit command in save")
	corrupt = active.duplicate(true)
	corrupt.world.battle_tickets[id].reserved_roster_snapshot[0][1].id = "phantom_friend"
	reject(corrupt, "unbound comrade identity")
	corrupt = active.duplicate(true)
	corrupt.world.battle_tickets[id].command_authority = "squad"
	reject(corrupt, "forged recruit authority")
	check(w.commit_battle_outcome(Driver.play(b)).ok, "validation fixture real battle")
	w.youth_action("return_to_camp"); w.youth_action("keep_evidence"); w.youth_action("accept_appointment")
	var valid := w.export_campaign_state()
	check(W.new().restore_campaign_state(valid).ok, "unmodified youth graph accepted")
	walk(valid.world.youth, ["world", "youth"])
	for index in range(valid.world.events.size()):
		if valid.world.events[index].kind.begins_with("youth_"):
			walk(valid.world.events[index].details, ["world", "events", index, "details"])
	for path in paths:
		for bad in [null, true, 1.25, "bad", [], {}]:
			if typeof(at(valid, path)) == typeof(bad): continue
			corrupt = valid.duplicate(true)
			put(corrupt, path, bad)
			reject(corrupt, "typed youth boundary " + str(path))
	for field in ["earned_merit", "recorded_merit", "appropriated_merit", "reward_food", "standing"]:
		corrupt = valid.duplicate(true)
		corrupt.world.youth[field] += 1
		reject(corrupt, "unearned career delta " + field)
	corrupt = valid.duplicate(true)
	corrupt.world.youth.characters.recruit_lin.trust += 1
	reject(corrupt, "fabricated relationship")
	corrupt = valid.duplicate(true)
	corrupt.world.youth.evidence[0].disclosed_to = ["officer_qiao"]
	reject(corrupt, "private evidence leaked into NPC knowledge")
	corrupt = valid.duplicate(true)
	corrupt.world.events.append(corrupt.world.events[-1].duplicate(true))
	reject(corrupt, "duplicate appointment journal")
	corrupt = valid.duplicate(true)
	corrupt.world.armies.relief.food += 1
	corrupt.world.cities.pingling.food -= 1
	reject(corrupt, "balanced but unrecorded ration transfer")
	corrupt = valid.duplicate(true)
	corrupt.world.armies.relief.soldiers += 1
	corrupt.world.cities.pingling.soldiers -= 1
	reject(corrupt, "balanced but unappointed soldier")
	corrupt = valid.duplicate(true)
	corrupt.world.youth.appointment.issuer = "clerk_yu"
	reject(corrupt, "clerk cannot grant army authority")
	corrupt = valid.duplicate(true)
	for e in corrupt.world.events:
		if e.kind == "youth_transition" and e.details.action == "choice": e.time_seconds += 1.0
	reject(corrupt, "invented action duration")
	corrupt = valid.duplicate(true)
	corrupt.world.mode = "technical"
	reject(corrupt, "youth cannot erase life constraints")
	print("YOUTH_VALIDATION_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
