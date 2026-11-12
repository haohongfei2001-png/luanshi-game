extends SceneTree
## godot --headless --path . --script res://tests/field_patrol.gd -- --field-size=20
## --patrol-accounts-only runs the original three-city itinerary and allocation arithmetic alone.
const World := preload("res://scripts/world_sim.gd")
const Patrol := preload("res://scripts/field/patrol_muster.gd")
const Battle := preload("res://scripts/field/battle.gd")
const FieldWorld := preload("res://scripts/field/campaign.gd")
const Store := preload("res://scripts/field/save.gd")
const SEED := Battle.SEED

var errors: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> bool:
	if not condition:
		errors.append(message)
		push_error(message)
	return condition

func _run() -> void:
	var reference := _journey()
	_capacity()
	if "--patrol-accounts-only" in OS.get_cmdline_user_args():
		print("FIELD_PATROL_ACCOUNTS_", "PASS" if errors.is_empty() else "FAIL", " ", JSON.stringify(errors))
	else:
		await _menu_to_camp(reference)
		print("FIELD_PATROL_", "PASS" if errors.is_empty() else "FAIL", " ", JSON.stringify(errors))
	quit(0 if errors.is_empty() else 1)

func _journey() -> Dictionary:
	var control := World.new(SEED)
	var start := control.snapshot()
	check(start.armies.relief.location == "pingling" and start.armies.relief.soldiers == 60 and start.armies.relief.weapons == 30 and start.cities.hequ.soldiers == 15, "Depart with the original three-city muster")
	check(control.march("river"), "Normal world command accepts the patrol route")
	var marching := control.player_view()
	check(marching.army.location == "" and marching.army.march.destination == "hequ", "The army is in transit before arrival")
	check(control.advance(World.ROUTES.river.hours), "Existing clock advances all three hours of the march")
	var expected := control.snapshot()
	var patrol := World.new()
	check(Patrol.arrive(patrol, SEED), "Patrol uses the authoritative journey")
	var reached := patrol.snapshot()
	for key in ["hour", "time_seconds", "armies", "cities", "ledger", "events", "convoys", "reports", "initial_totals", "initial_force_roster"]:
		check(reached[key] == expected[key], "Patrol and independent normal march agree on " + key)
	check(reached.time_seconds == 10800.0 and reached.armies.relief.location == "hequ", "Passage takes the recorded three hours")
	check(reached.armies.relief.food < start.armies.relief.food and reached.ledger.food_consumed > 0 and not reached.convoys.is_empty(), "Supply consumption and hostile convoys happened en route")
	check(patrol.audit().is_empty(), "Untouched three-city ledger balances on arrival")
	print("FIELD_PATROL_ROUTE ", JSON.stringify({"hours": reached.hour, "relief": [reached.armies.relief.soldiers, reached.armies.relief.weapons, reached.armies.relief.food], "garrison": [reached.cities.hequ.soldiers, reached.cities.hequ.weapons, reached.cities.hequ.food], "convoys": reached.convoys.size()}))
	return reached

func _capacity() -> void:
	for people: int in [0, 1, 2, 3, 15, 31, 32, 33, 34, 60, 67, 528, 1057, 2200]:
		for arms: int in [0, 1, 2, 3, 15, 30, 33, 35, 66, 528, 2200]:
			for has_hero: bool in [false, true]:
				var n := Patrol.ordinary_for(people, arms, has_hero)
				var commanders := ceili(float(n) / Patrol.COMPANY_SIZE)
				var people_used := n + commanders + (1 if has_hero else 0)
				var weapons_used := n + commanders + (2 if has_hero else 0)
				check(n >= 0 and (n == 0 or (people_used <= people and weapons_used <= arms)), "Every fielded billet is funded")
				var next := n + 1 + ceili(float(n + 1) / Patrol.COMPANY_SIZE)
				check(next + int(has_hero) > people or next + 2 * int(has_hero) > arms, "One additional soldier would exceed arms or people")
	check(Patrol.ordinary_for(60, 30, true) == 27 and Patrol.ordinary_for(15, 15) == 14, "Actual asymmetric patrol complement")
	check(Patrol.ordinary_for(2200, 2200, true) > 2048, "Muster accounting does not truncate armies to the pressure sample")

func _save_copy(b):
	# Exercise the same binary field payload as the game's quick slot without touching a career or quicksave.
	var file := FileAccess.create_temp(FileAccess.READ_WRITE, "luanshi-patrol", "bin")
	if not check(file != null, "Create isolated checkpoint"):
		return null
	file.store_buffer(var_to_bytes(Store.snapshot(b)))
	file.flush()
	file.seek(0)
	return Store.restore(bytes_to_var(file.get_buffer(file.get_length())))

func _resources_match(actual: Dictionary, marched: Dictionary) -> void:
	for pool in ["armies", "cities"]:
		for id in marched[pool]:
			for stock in ["soldiers", "weapons", "food"]:
				check(actual[pool][id][stock] == marched[pool][id][stock], "%s retains the march's recorded %s" % [id, stock])
	for key in ["ledger", "convoys", "initial_totals", "initial_force_roster"]:
		check(actual[key] == marched[key], "Opening did not replace the original " + key)

func _menu_to_camp(marched: Dictionary) -> void:
	var shell = load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	var field = shell.field
	var hud = field.hud
	if not check(hud.plan.item_count > 4 and hud.plan.is_visible_in_tree(), "The normal muster offers the patrol in the army menu"):
		shell.free()
		return
	hud.plan.get_popup().index_pressed.emit(4)
	var b = field.battle
	if not check(b.get("world_patrol") == true, "The shipping army menu launches the real patrol"):
		shell.free()
		return
	var w = field.theater
	var header: Dictionary = w.snapshot()
	var people := [0, 0]
	var officers := [0, 0]
	for u in b.roster:
		if u.hero:
			continue
		if u.officer:
			officers[u.team] += 1
		else:
			people[u.team] += 1
	check(people == [27, 14] and officers == [1, 1] and b.roster.size() == 44, "Field carries the actual asymmetric roster, officers and player")
	check(header.time_seconds == marched.time_seconds and not b.started, "Muster opens after the same journey, before combat")
	_resources_match(header, marched)

	# Select the deployed company's task in the same controls used by a player.
	hud.mission.get_popup().index_pressed.emit(Battle.Mission.WITHDRAW)
	hud.issue.pressed.emit()
	check(b.companies[0].mission == Battle.Mission.WITHDRAW, "Prebattle order reaches the patrol")
	hud.go.pressed.emit()
	if not check(b.started, "The normal deploy button reserves and starts the patrol"):
		shell.free()
		return
	var ticket: Dictionary = w.battle_ticket(FieldWorld.ENCOUNTER)
	if not check(ticket.get("status") == "running", "Field is locked against the actual registered armies"):
		shell.free()
		return
	var rosters: Array = ticket.reserved_roster_snapshot
	var uncommitted: int = marched.armies.relief.soldiers - rosters[0].size()
	var spare: int = marched.armies.relief.weapons - w.reserved_weapons[0]
	check(rosters[0].size() == 29 and rosters[1].size() == 15 and uncommitted == 31 and spare == 1, "Only the equipped patrol reserved people and weapons")
	check(w.audit().is_empty() and w.audit_quivers(), "Partial deployment balances all registered inventories")
	b.input_state(Vector2.LEFT, Vector2.LEFT)
	for i in 24:
		b.step()
	check(w.sync(), "Live patrol synchronizes its strategic clock")
	var copy = _save_copy(b)
	if not check(copy != null and copy.get("world_patrol") == true, "Binary live patrol checkpoint restores its origin"):
		shell.free()
		return
	var other := FieldWorld.new()
	if not check(other.bind(copy), "Reload reconstructs the actual march, field ticket and clock"):
		shell.free()
		return
	check(other.battle_ticket(FieldWorld.ENCOUNTER) == ticket and other.snapshot().time_seconds == w.snapshot().time_seconds, "Restored ticket and clock match at contact")
	for i in 12:
		b.step()
		copy.step()
	check(Store.snapshot(copy) == Store.snapshot(b), "Restored unequal rosters and field actions replay exactly")
	for i in 1600:
		if b.result != "":
			break
		b.step()
	if not check(b.result == "成功撤离", "Withdraw on foot with actual surviving soldiers reaching their exits"):
		shell.free()
		return
	var receipt: Dictionary = w.settle()
	if not check(not receipt.is_empty(), "Campaign settles the actual withdrawal"):
		shell.free()
		return
	var state: Dictionary = w.snapshot()
	var observation: Dictionary = w.player_view().known.get("hequ", {}).get("contents", {})
	check(observation.get("outcome") == b.result and observation.get("owner") == "bei", "Survivors remember the withdrawal after leaving the gate")
	check(not observation.has("soldiers") and not observation.has("food") and not observation.has("fort"), "Withdrawal does not reveal the hostile garrison inventory")
	var returned: Dictionary = state.armies.relief
	var rear: Dictionary = state.armies.get("hequ_rearguard", {})
	var alive: int = marched.armies.relief.soldiers - receipt.dead_ids[0].size() - receipt.captured_officers[0].size()
	var weapons_lost := 0
	for count: int in receipt.dropped_by_kit[0].values():
		weapons_lost += count
	var carried: int = returned.weapons + int(rear.get("weapons", 0))
	var expected_arms: int = marched.armies.relief.weapons - weapons_lost + receipt.captured_officers[1].size() - receipt.captured_officers[0].size()
	check(returned.soldiers + int(rear.get("soldiers", 0)) == alive and alive >= uncommitted, "All nondeployed people remain in their world's forces")
	check(carried == expected_arms and carried >= spare and w.audit().is_empty() and w.audit_quivers(), "Dropped gear and unused equipment balance on return")
	check(w.settle() == receipt, "Reloading results cannot settle the battle twice")
	var finished = _save_copy(b)
	var replay := FieldWorld.new()
	check(finished != null and replay.bind(finished) and replay.settle() == receipt, "Binary postbattle checkpoint recreates the receipt and march")
	if not replay.receipt.is_empty():
		check(replay.snapshot().armies == state.armies and replay.snapshot().ledger == state.ledger, "Saved and live postbattle armies and resources match")
	print("FIELD_PATROL_ENCOUNTER ", JSON.stringify({"ordinary": people, "officers": officers, "uncommitted": uncommitted, "unused_weapons": spare, "end": b.result, "seconds": state.time_seconds, "army": returned.soldiers, "rearguard": rear.get("soldiers", 0), "weapons": carried}))
	_wrong_origin(field)
	shell.free()

func _wrong_origin(field) -> void:
	var ordinary := Battle.new()
	ordinary.setup(20)
	var data := Store.snapshot(ordinary)
	data["world_patrol"] = true
	var candidate = Store.restore(data)
	if candidate != null:
		var verifier := FieldWorld.new()
		check(not verifier.bind(candidate), "A normal exercise cannot claim soldiers from the world patrol")
	var current = field.battle
	var world = field.theater
	var figures_id: int = field.view.get_instance_id()
	var ledger: Dictionary = world.snapshot().ledger
	var click_load := OS.get_environment("LUANSHI_PATROL_ISOLATED_SLOT") == "1"
	if click_load:
		# The cloud replay gives this process a fresh, private XDG_DATA_HOME.
		# Refuse any pre-existing slot, including when the harness is run manually.
		if not check(not FileAccess.file_exists(Store.FILE), "Use an empty disposable quickslot for the normal Load button"):
			return
		var fixture := FileAccess.open(Store.FILE, FileAccess.WRITE)
		if not check(fixture != null, "Write the mismatched checkpoint in the isolated slot"):
			return
		fixture.store_buffer(var_to_bytes(data))
		fixture.close()
		field.hud.load_button.pressed.emit()
		check(DirAccess.remove_absolute(ProjectSettings.globalize_path(Store.FILE)) == OK, "Remove isolated test checkpoint")
		check(current.notice != "已恢复战场", "Failed loading cannot announce that the battle was restored")
	elif candidate != null:
		field.call("_adopt", candidate)
	check(is_same(field.battle, current) and is_same(field.theater, world), "Rejected provenance leaves the existing battle and world active")
	check(is_instance_id_valid(figures_id) and field.view.get_instance_id() == figures_id, "The previous rendered battle survives rejection")
	check(world.snapshot().ledger == ledger and not world.receipt.is_empty(), "Rejection preserves the settled campaign receipt")
	print("FIELD_PATROL_REJECT ", JSON.stringify({"quickload_button": click_load, "retained_world": is_same(field.theater, world)}))
