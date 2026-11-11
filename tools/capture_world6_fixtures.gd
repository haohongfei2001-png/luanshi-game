extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
var destination: String
func write(name: String, w: WorldSimulation) -> void:
	var encoded := Store.new().encode_campaign(w)
	assert(encoded.ok)
	var file := FileAccess.open(destination.path_join(name + ".save.json"), FileAccess.WRITE)
	file.store_buffer(encoded.bytes)
	file.close()
	file = FileAccess.open(destination.path_join(name + ".codec.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(Codec.new().encode(w.export_campaign_state()).value))
	file.close()
func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0]
	assert(W.VERSION == 6)
	for profile in ["early_v1", "late_v1", "legacy_test_v0"]:
		var w := W.new(184, profile)
		w.march("river"); w.advance(3)
		var id: String = w.create_battle_ticket().ticket.battle_id
		var b := w.start_battle(id)
		b.use_action("guard"); b.set_player_input(Vector2(0.2, -0.1), Vector2.RIGHT); b.step(0.03125)
		write(profile + "_running", w)
		b.issue_order("retreat")
		for frame in range(2400):
			b.set_player_input(Vector2.LEFT, Vector2.RIGHT); b.step(1.0 / 60.0)
			if b.ended: break
		assert(b.ended)
		assert(w.commit_battle_outcome(b.outcome()).ok)
		write(profile + "_committed", w)
	print("WORLD6_FIXTURES_CAPTURED_FROM_84cc5f8")
	quit()
