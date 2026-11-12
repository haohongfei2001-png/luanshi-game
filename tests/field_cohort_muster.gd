extends SceneTree
## Godot 4 headless. These are real campaign reservations/settlements and
## 24 fixed simulation ticks per scale. They do not measure game-frame FPS.
const Field := preload("res://scripts/field/battle.gd")
const World := preload("res://scripts/field/campaign.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Save := preload("res://scripts/field/save.gd")
var errors: Array[String]=[]
var measurements: Array[Dictionary]=[]

func _initialize() -> void:
	for total: int in [1024,3000,5000,10000]:
		_measure(total)
	_changed_weapons()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var file:=FileAccess.open("res://artifacts/field-cohort-muster.json",FileAccess.WRITE)
	check(file!=null,"Write the batch accounting measurements")
	if file:
		file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"os":OS.get_name(),"rendered":false,"rows":measurements,"errors":errors},"  "))
		file.close()
	print("FIELD_COHORT_MUSTER_", "PASS" if errors.is_empty() else "FAIL", " ", JSON.stringify(errors))
	quit(0 if errors.is_empty() else 1)

func check(ok: bool, reason: String) -> bool:
	if not ok:
		errors.append(reason)
		push_error(reason)
	return ok

func _measure(total: int) -> void:
	var initial_memory:=OS.get_static_memory_usage()
	var begin:=Time.get_ticks_usec()
	var field:=Field.new()
	@warning_ignore("integer_division")
	var per_side:=total/2
	field.setup(per_side,Field.SEED,Arms.Kit.DUAL)
	var setup_us:=Time.get_ticks_usec()-begin
	var actor_bytes:=OS.get_static_memory_usage()-initial_memory
	var world:=World.new()
	if not check(world.bind(field),"Bind real world forces at scale %d" % total): return
	begin=Time.get_ticks_usec()
	if not check(world.reserve(),"Reserve both actual rosters at scale %d" % total): return
	var reserve_us:=Time.get_ticks_usec()-begin
	var ticket: Dictionary=world.snapshot().battle_tickets[World.ENCOUNTER]
	if not check(ticket.has("muster") and not ticket.has("reserved_roster_snapshot"),"Stored field ticket contains batch counts"): return
	var muster: Dictionary=ticket.muster
	var all_counts: PackedInt32Array=muster.kit_counts
	var batches:=0
	var ordinary:=0
	for company in field.companies.size():
		var people:=0
		for kit in Arms.NAMES.size():
			var count:=all_counts[company*Arms.NAMES.size()+kit]
			batches+=int(count>0)
			people+=count
		check(people==field.companies[company].initial,"Every company retained its actual ordinary headcount")
		ordinary+=people
	check(ordinary==total and muster.principals.size()==field.companies.size()+1,"Counts exclude player and independently recorded officers")
	var legacy: Array=world.battle_ticket(World.ENCOUNTER).reserved_roster_snapshot
	for team in 2:
		var pieces:=0
		var arrows:=0
		var bolts:=0
		for entry: Dictionary in legacy[team]:
			pieces+=2 if entry.weapon==Arms.NAMES[Arms.Kit.DUAL] else 1
			if entry.weapon==Arms.NAMES[Arms.Kit.BOW]: arrows+=Arms.ARROWS_PER_QUIVER
			if entry.weapon==Arms.NAMES[Arms.Kit.CROSSBOW]: bolts+=Arms.BOLTS_PER_CASE
		check(muster.people[team]==legacy[team].size() and muster.weapons[team]==pieces,"Expanded and batched troop and weapon counts agree")
		check(muster.ammunition[team]==PackedInt32Array([arrows,bolts]),"Both forms reserve the same arrows and bolts")
	var compact_bytes:=var_to_bytes(muster).size()
	var legacy_bytes:=var_to_bytes(legacy).size()
	check(compact_bytes<legacy_bytes,"Compact ticket retains fewer serialized bytes at scale %d" % total)
	legacy.clear()
	field.start()
	var ticks: Array[int]=[]
	for frame in 24:
		begin=Time.get_ticks_usec()
		field.step()
		ticks.append(Time.get_ticks_usec()-begin)
	ticks.sort()
	check(field.tick==ticks.size() and field.hits[0]+field.hits[1]>0,"Sample contains real simulation ticks and contact at %d" % total)
	var observed_hits: int=field.hits[0]+field.hits[1]
	# This independent timing sample ends here. Settlement is controlled by
	# removing the commander through the actual damage/decision path.
	if field.hero.hp>0:
		field._hurt(field.roster[per_side],field.hero,10000.0,field.roster[per_side].pos)
	field.step()
	begin=Time.get_ticks_usec()
	var receipt:=world.settle()
	var settle_us:=Time.get_ticks_usec()-begin
	if not check(not receipt.is_empty() and world.audit().is_empty() and world.audit_quivers(),"Actual settlement conserves people, weapons and ammunition"): return
	for team in 2:
		check(receipt.dead_ids[team].size()+receipt.living_ids[team].size()==muster.people[team],"Battle deaths and survivors close the issued ledger")
	var m: Dictionary={"ordinary":total,"per_side":per_side,"live_actor_objects":field.roster.size(),"companies":field.companies.size(),"ordinary_weapon_cohorts":batches,"individual_principals":muster.principals.size(),"legacy_roster_variant_bytes":legacy_bytes,"muster_variant_bytes":compact_bytes,"engine_static_bytes_delta_setup":actor_bytes,"setup_us":setup_us,"reserve_us":reserve_us,"settle_us":settle_us,"timed_simulation_ticks":ticks.size(),"tick_p50_us":ticks[11],"tick_p95_us":ticks[22],"tick_p99_us":ticks[23],"sample_hits":observed_hits}
	measurements.append(m)
	print("FIELD_COHORT_SAMPLE ",JSON.stringify(m))

func _changed_weapons() -> void:
	var b:=Field.new()
	b.setup(20)
	var world:=World.new()
	if not check(world.bind(b) and world.reserve(),"Real muster prepared for inventory mismatch"): return
	b.start()
	var opponent:=b.roster[b.side_size]
	b._hurt(opponent,b.hero,10000.0,opponent.pos)
	b.step()
	var original:=b.roster[0].kit
	b.roster[0].kit=Arms.Kit.DUAL
	check(world.settle().is_empty(),"A company cannot return an extra forged second sword")
	b.roster[0].kit=original
	var receipt:=world.settle()
	check(not receipt.is_empty() and world.settle()==receipt and world.audit().is_empty(),"Corrected actual gear and repeated settlement remain balanced")
	var restored:=Save.restore(Save.snapshot(b))
	var copy:=World.new()
	check(restored!=null and copy.bind(restored) and copy.snapshot()==world.snapshot(),"Field quicksave can rebuild the compact ticket and earlier settlement unchanged")
