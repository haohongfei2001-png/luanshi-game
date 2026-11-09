extends SceneTree
const W := preload("res://scripts/world_sim.gd")
func _initialize() -> void:
	var w := W.new(184)
	print("START ", w.start_youth("volunteer", "homeland"))
	print("MARCH ", w.youth_action("first_march"))
	var r := w.create_battle_ticket()
	print("RESERVE ", r)
	if not r.ok: quit(1); return
	var b := w.start_battle(r.ticket.battle_id)
	print("COMMANDS ", b.issue_order("attack"), " / ", b.order)
	for i in range(18000):
		var target := Vector2.ZERO
		var distance := INF
		for u in b.units:
			if u.team == 1 and u.hp > 0.0:
				var d: float = b.player().pos.distance_to(u.pos)
				if d < distance: distance = d; target = u.pos
		var direction: Vector2 = target - b.player().pos
		b.set_player_input(direction if distance > 1.5 else Vector2.ZERO, direction)
		for a in ["guard", "attack", "sweep"]: b.use_action(a)
		b.step(1.0 / 60.0)
		if b.ended: break
	print("OUTCOME ", b.outcome())
	print("SETTLE ", w.commit_battle_outcome(b.outcome()))
	print("RESTORE ", W.new().restore_campaign_state(w.export_campaign_state()))
	print("RETURN ", w.youth_action("return_to_camp"))
	print("CHOICE ", w.youth_action("appeal"))
	print("APPOINT ", w.youth_action("accept_appointment"))
	var valid: bool = w.youth_view().stage == "dangerous_orders" and W.new().restore_campaign_state(w.export_campaign_state()).ok
	print("YOUTH_CORE_SMOKE ", "PASS" if valid else "FAIL")
	quit(0 if valid else 1)
