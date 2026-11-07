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
	if ticket.is_empty() or not world.is_current_battle(ticket.battle_id, simulation):
		return false
	return world.sync_battle_time(ticket.battle_id)

func settle() -> Dictionary:
	if simulation == null:
		return {"ok": false, "reason": "no_battle"}
	if world.battle_ticket(ticket.battle_id).get("status") != "committed" and not world.is_current_battle(ticket.battle_id, simulation):
		return {"ok": false, "reason": "stale_battle_session"}
	return world.commit_battle_outcome(simulation.outcome())

func resume(battle_id: String) -> Dictionary:
	## Explicitly rebind presentation after load; start_battle resumes running state.
	var next_ticket := world.battle_ticket(battle_id)
	if next_ticket.is_empty() or next_ticket.status not in ["reserved", "running"]:
		return {"ok": false, "reason": "battle_not_resumable"}
	var next_simulation := world.start_battle(battle_id)
	if next_simulation == null:
		return {"ok": false, "reason": "battle_start_failed"}
	simulation = next_simulation
	ticket = world.battle_ticket(battle_id)
	return {"ok": true, "ticket": ticket.duplicate(true)}
