extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
func _initialize() -> void:
	# Execute this harness against archived public World7 source, never current World8.
	assert(W.VERSION == 7, "World7 fixture capture requires original World7 source")
	var w := W.new()
	assert(w.start_youth("volunteer", "homeland").ok)
	write(w, "youth_at_camp")
	assert(w.youth_action("first_march").ok)
	var made: Dictionary = w.create_battle_ticket()
	var battle: BattleSimulation = w.start_battle(made.ticket.battle_id)
	battle.step(0.03125)
	write(w, "youth_running")
	quit()
func write(w, label: String) -> void:
	var encoded := Store.new().encode_campaign(w)
	assert(encoded.ok)
	var raw: Dictionary = preload("res://scripts/campaign_value_codec.gd").new().encode(w.export_campaign_state())
	FileAccess.open("/tmp/world7_" + label + ".codec.json", FileAccess.WRITE).store_string(JSON.stringify(raw.value))
	FileAccess.open("/tmp/world7_" + label + ".save.json", FileAccess.WRITE).store_buffer(encoded.bytes)
