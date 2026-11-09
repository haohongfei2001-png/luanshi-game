extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func world6(state: Dictionary) -> Dictionary:
	var old := state.duplicate(true)
	old.world.version = 6
	old.world.erase("couriers")
	old.world.erase("origin"); old.world.erase("mode"); old.world.erase("youth")
	for t in old.world.battle_tickets.values(): t.erase("purpose"); t.erase("command_authority"); t.erase("signal_model")
	for session in old.battle_sessions.values():
		for f in ["signal_model", "signal_sequence", "pending_signals", "last_signal"]: session.erase(f)
		for unit in session.units:
			unit.erase("received_order"); unit.erase("received_order_sequence")
	return old
func expected(profile: String, phase: String) -> Dictionary:
	return Codec.new().decode(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v07/%s_%s.codec.json" % [profile, phase]))).value
func _initialize() -> void:
	for profile in ["early_v1", "late_v1", "legacy_test_v0"]:
		for phase in ["running", "committed"]:
			var path := "res://tests/fixtures/v07/%s_%s.save.json" % [profile, phase]
			var bytes := FileAccess.get_file_as_bytes(path)
			var decoded := Store.new().decode_campaign(bytes)
			check(decoded.ok, "genuine World6 decodes " + profile + phase)
			if not decoded.ok: continue
			var w := W.new()
			check(w.restore_campaign_state(decoded.state).ok, "genuine migration adopts")
			check(world6(w.export_campaign_state()) == expected(profile, phase), "every original World6 field preserved")
			check(not w.youth_view().enabled and not w.start_youth("forced", "survival").ok, "old commander never turned into fifteen-year-old")
			if phase == "running":
				var b := w.start_battle("1:1")
				b.issue_order("retreat")
				for frame in range(2400):
					b.set_player_input(Vector2.LEFT, Vector2.RIGHT); b.step(1.0 / 60.0)
					if b.ended: break
				check(b.ended and w.commit_battle_outcome(b.outcome()).ok, "migrated original physical withdrawal")
				check(world6(w.export_campaign_state()) == expected(profile, "committed"), "whole World6 continuation and receipt exact")
			else:
				var before := w.snapshot()
				var r := w.commit_battle_outcome(w.battle_ticket("1:1").outcome)
				check(r.ok and r.already_committed and w.snapshot() == before, "old receipt never duplicates")
			check(bytes == FileAccess.get_file_as_bytes(path), "source save untouched")
	# Even an untouched early-profile World6 save remains an old technical life.
	var pristine6 := world6(W.new().export_campaign_state())
	var old_life := W.new()
	check(old_life.restore_campaign_state(pristine6).ok and not old_life.youth_view().startable and not old_life.start_youth("volunteer", "survival").ok, "pristine older save cannot be retroactively aged fifteen")
	print("YOUTH_WORLD6_MIGRATION_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
