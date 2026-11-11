class_name BattleAdapter
extends RefCounted
## Small UI boundary. The WorldSim owns the ticket and bound BattleSim.

var world: WorldSimulation
var simulation: BattleSimulation
var ticket: Dictionary = {}

func _init(authority: WorldSimulation) -> void:
	world = authority

func begin_local_depot() -> Dictionary:
	var reservation := world.create_battle_ticket("hequ")
	if not reservation.ok:
		return reservation
	ticket = reservation.ticket
	simulation = world.start_battle(ticket.battle_id)
	if simulation == null:
		world.cancel_battle_ticket(ticket.battle_id)
		return {"ok": false, "reason": "battle_start_failed"}
	ticket = world.battle_ticket(ticket.battle_id)
	return {"ok": true, "ticket": ticket.duplicate(true)}

func sync_world() -> bool:
	if ticket.is_empty():
		return false
	return world.sync_battle_time(ticket.battle_id)

func settle() -> Dictionary:
	if simulation == null:
		return {"ok": false, "reason": "no_battle"}
	return world.commit_battle_outcome(simulation.outcome())
