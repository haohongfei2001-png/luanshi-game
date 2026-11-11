extends RefCounted
## Honest controls only: no HP/position/outcome mutation or _hurt calls.
static func play(b: BattleSimulation, policy: String = "fight", limit: int = 18000) -> Dictionary:
	if b._ticket.command_authority == "squad": b.issue_order("attack")
	for frame in range(limit):
		if b.ended: break
		var hero := b.player()
		var target: Vector2 = hero.pos + Vector2.RIGHT
		var distance := INF
		for unit in b.units:
			if unit.team == 1 and unit.hp > 0.0:
				var d: float = hero.pos.distance_to(unit.pos)
				if d < distance:
					distance = d
					target = unit.pos
		var direction: Vector2 = target - hero.pos
		if policy == "retreat" or (policy == "delayed_retreat" and b.elapsed > 13.0):
			b.issue_order("retreat")
			b.set_player_input(Vector2.LEFT, Vector2.RIGHT)
		elif policy == "reckless":
			b.set_player_input(direction, direction)
		elif policy == "delayed_retreat":
			b.set_player_input(Vector2.ZERO, direction)
		elif policy == "tactical":
			b.set_player_input(direction if distance > 1.85 else -direction.normalized() if distance < 1.65 else Vector2.ZERO, direction)
			if distance < 2.0: b.use_action("guard")
			if distance < 1.9: b.use_action("attack")
			if distance < 2.4: b.use_action("sweep")
			if distance < 3.8: b.use_action("lunge")
		elif policy == "kite":
			var movement := Vector2.ZERO
			if distance < 1.8: movement = -direction.normalized()
			elif distance > 1.88: movement = direction.normalized()
			if hero.pos.x < -25.0 and movement.x < 0: movement = Vector2(0.4, 1.0 if hero.pos.y < 0 else -1.0)
			if hero.pos.x > 25.0 and movement.x > 0: movement = Vector2(-0.4, 1.0 if hero.pos.y < 0 else -1.0)
			if abs(hero.pos.y) > 14.0: movement.y = -sign(hero.pos.y)
			b.set_player_input(movement, direction)
			if distance < 3.0:
				for action in ["guard", "attack", "sweep"]: b.use_action(action)
		else:
			b.set_player_input(direction if distance > 1.5 else Vector2.ZERO, direction)
			for action in ["guard", "attack", "sweep"]: b.use_action(action)
		b.step(BattleSimulation.FIXED_DELTA)
	return b.outcome()
