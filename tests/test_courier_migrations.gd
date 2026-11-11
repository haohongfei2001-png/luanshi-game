extends SceneTree
## These bytes were written by the actual public World7 implementation.
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func original(state: Dictionary) -> Dictionary:
	var old := state.duplicate(true)
	old.world.version = 7
	old.world.erase("couriers")
	for t in old.world.battle_tickets.values(): t.erase("signal_model")
	for s in old.battle_sessions.values():
		for f in ["signal_model", "signal_sequence", "pending_signals", "last_signal"]: s.erase(f)
		for u in s.units:
			u.erase("received_order"); u.erase("received_order_sequence")
	return old
func _initialize() -> void:
	for name in ["youth_at_camp", "youth_running"]:
		var path := "res://tests/fixtures/v08/world7_%s.save.json" % name
		var bytes := FileAccess.get_file_as_bytes(path)
		var decoded := Store.new().decode_campaign(bytes)
		check(decoded.ok, "genuine World7 decodes " + name)
		if not decoded.ok: continue
		var w := W.new()
		check(w.restore_campaign_state(decoded.state).ok, "genuine World7 adopts " + name)
		var old_raw: Dictionary = preload("res://scripts/campaign_value_codec.gd").new().decode(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v08/world7_%s.codec.json" % name))).value
		check(original(w.export_campaign_state()) == old_raw, "every original World7 field exactly preserved")
		# decode_campaign already migrates; compare its stable projection against second load.
		var again := W.new()
		again.restore_campaign_state(decoded.state)
		check(w.export_campaign_state() == again.export_campaign_state(), "same genuine bytes same complete World8")
		check(w.snapshot().version == 8 and w.snapshot().origin == "new_world7" and w.youth_view().enabled, "preserves existing youth identity")
		check(w.snapshot().couriers.is_empty(), "old reports do not become fictional couriers")
		if name == "youth_at_camp":
			check(w.youth_action("arrange_courier").ok, "existing youth may opt into new physical exchange")
			check(w.youth_action("first_march").ok and w.youth_action("wait_courier").ok, "old youth continues into courier mechanic")
		else:
			var b := w.start_battle("1:1")
			var b2 := again.start_battle("1:1")
			check(b.signal_model == "legacy_global_v0" and b.elapsed == 0.03125, "ongoing historical battle keeps exact clock and historical signal model")
			for item in [b, b2]: item.issue_order("retreat")
			for frame in range(2400):
				for item in [b, b2]:
					item.set_player_input(Vector2.LEFT, Vector2.RIGHT)
					item.step(1.0 / 60.0)
				if b.ended: break
			check(b.ended and b.export_campaign_state() == b2.export_campaign_state(), "historical continuation deterministic")
			check(w.commit_battle_outcome(b.outcome()).ok and again.commit_battle_outcome(b2.outcome()).ok, "old running youth settles once")
			check(w.export_campaign_state() == again.export_campaign_state(), "old running youth entire world remains exact")
		check(bytes == FileAccess.get_file_as_bytes(path), "source save bytes untouched")
	print("COURIER_MIGRATIONS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
