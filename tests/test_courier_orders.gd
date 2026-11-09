extends SceneTree
## Physical courier tests. Mutation fixtures below test local guards only, never
## claim to be a valid saved history. Persistence uses only causal player actions.
const W := preload("res://scripts/world_sim.gd")
const C := preload("res://scripts/courier_orders.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _initialize() -> void: call_deferred("run")
func life() -> WorldSimulation:
	var w := W.new()
	check(w.start_youth("volunteer", "homeland").ok, "start genuine youth")
	return w
func act(w: WorldSimulation, action: String) -> bool:
	var result := w.youth_action(action)
	check(result.ok, action + " " + str(result))
	return result.ok
func reject(w: WorldSimulation, action: String, label: String) -> void:
	var before := w.export_campaign_state()
	check(not w.youth_action(action).ok and before == w.export_campaign_state(), label)
func roundtrip(w: WorldSimulation, label: String) -> void:
	var encoded := Store.new().encode_campaign(w)
	check(encoded.ok, label + " encodes " + str(encoded.get("reason", "")))
	if not encoded.ok: return
	var decoded := Store.new().decode_campaign(encoded.bytes)
	var restored := W.new()
	check(decoded.ok and restored.restore_campaign_state(decoded.state).ok, label + " restores")
	check(w.export_campaign_state() == restored.export_campaign_state(), label + " exact graph")
func forged(saved: Dictionary, label: String) -> void:
	var target := life()
	var before := target.export_campaign_state()
	check(not target.restore_campaign_state(saved).ok, label + " rejected")
	check(before == target.export_campaign_state(), label + " atomic rejection")
func run() -> void:
	var technical := W.new()
	reject(technical, "arrange_courier", "technical life cannot issue youth orders")
	var w := life()
	reject(w, "wait_courier", "no courier no wait")
	reject(w, "courier_comply", "cannot reply before delivery")
	var initial := w.snapshot()
	var total := w.totals()
	if not act(w, "arrange_courier"): finish(); return
	var arranged := w.snapshot()
	check(arranged.time_seconds == initial.time_seconds, "arrangement zero time")
	check(arranged.cities.pingling.soldiers == initial.cities.pingling.soldiers - 1 and arranged.cities.pingling.food == initial.cities.pingling.food - 10, "one actual camp soldier and ten rations debited")
	check(w.totals() == total and w.audit().is_empty(), "dispatch conserves all resources")
	check(arranged.armies == initial.armies and arranged.youth == initial.youth, "dispatch creates neither army nor quest completion nor rank")
	check(arranged.couriers[0].authority == "camp_superior" and arranged.couriers[0].issuer == "officer_qiao", "recruit arranges superior order, not personal command")
	reject(w, "arrange_courier", "zero-time duplicate cannot spawn courier")
	roundtrip(w, "queued")
	act(w, "first_march")
	check(w.snapshot().time_seconds == 10800.0 and w.snapshot().couriers[0].status == "outbound", "army arrives before courier")
	check(w.player_view().courier_orders[0].known == "arranged", "outbound truth not leaked")
	reject(w, "courier_refuse", "cannot answer before physical delivery")
	roundtrip(w, "outbound")
	act(w, "wait_courier")
	check(w.snapshot().time_seconds == 14400.0 and w.snapshot().couriers[0].status == "awaiting_reply", "delivery takes departure plus real river travel")
	check(w.snapshot().youth.stage == "first_battle" and w.snapshot().battle_tickets.is_empty(), "receiving order does not magically finish mission or battle")
	check(w.player_view().courier_orders[0].known == "delivered", "actual recipient learns delivery")
	var delivered := w.export_campaign_state()
	act(w, "courier_refuse")
	check(w.snapshot().time_seconds == delivered.world.time_seconds and w.snapshot().couriers[0].status == "returning", "reply instant locally but return still travels")
	check(w.snapshot().armies == delivered.world.armies and w.snapshot().youth == delivered.world.youth, "refusal does not teleport troops or invent narrative outcome")
	reject(w, "courier_comply", "reply cannot be replaced or duplicated")
	roundtrip(w, "returning")
	for i in range(3): act(w, "wait_courier")
	check(w.snapshot().couriers[0].status == "returned" and w.snapshot().couriers[0].camp_received_at == 25200.0, "reply reaches camp after three hours")
	check(w.player_view().courier_orders[0].known == "reply_sent", "distant recipient cannot know camp received")
	check(w.audit().is_empty(), "returned soldier and food conserve")
	roundtrip(w, "returned unobserved")
	skipped_terminal_meal(w, "returned")
	var lost := life()
	act(lost, "arrange_courier")
	for i in range(4): act(lost, "wait_courier")
	check(lost.snapshot().couriers[0].status == "lost", "actual hostile endpoint intercepts absent recipient")
	check(lost.snapshot().couriers[0].food == 6, "lost rations persist as inaccessible road cache")
	check(lost.audit().is_empty(), "lost courier soldier and food ledger conserve")
	check(lost.player_view().courier_orders[0].known == "arranged", "secret interception not revealed")
	for i in range(3): act(lost, "wait_courier")
	var view: Dictionary = lost.player_view().courier_orders[0]
	check(view.overdue and not view.has("status") and not view.has("food") and not view.has("due_at"), "overdue exposes uncertainty only")
	roundtrip(lost, "lost")
	skipped_terminal_meal(lost, "lost")
	guard_fixtures()
	fractional_clock()
	malformed(delivered)
	migration()
	battle_clock()
	terminal_wait()
	finish()
func guard_fixtures() -> void:
	# Deliberate state mutation, not save/replay acceptance evidence.
	for field in ["soldiers", "food", "owner"]:
		var w := life()
		w._state.cities.pingling[field] = {"soldiers": 0, "food": 9, "owner": "bei"}[field]
		reject(w, "arrange_courier", "dispatch rejects insufficient/hostile source " + field)
	var state := life().snapshot()
	state.couriers = [C.initial(1, "first_orders", 0.0)]
	state.time_seconds = 3600.0
	C.tick(state)
	check(state.couriers[0].status == "outbound" and state.ledger.dead == 0, "enemy endpoint does not kill courier at departure")
	state.time_seconds = 14400.0
	state.armies.relief.location = "hequ"
	C.tick(state)
	check(state.couriers[0].status == "awaiting_reply", "living co-located patrol screens rendezvous")
	check(C.reply(state, "comply"), "screened patrol can reply")
	state.cities.pingling.owner = "bei"
	state.time_seconds = 25200.0
	var dead: int = state.ledger.dead
	C.tick(state)
	check(state.couriers[0].status == "lost" and state.ledger.dead == dead + 1, "captured camp intercepts returning courier")
	C.tick(state)
	check(state.ledger.dead == dead + 1, "loss cannot debit soldier twice")
func fractional_clock() -> void:
	var a := life()
	act(a, "arrange_courier"); act(a, "first_march")
	var b := W.new()
	check(b.restore_campaign_state(a.export_campaign_state()).ok, "fractional clone")
	# Clock-driver tests deliberately bypass action authority but do not mutate
	# events/resources; both run the same actual unified world-clock mechanism.
	a._advance_clock_to(14400.125)
	for t in [10800.03125, 11000.5, 14399.875, 14400.0, 14400.125]: b._advance_clock_to(t)
	check(a.export_campaign_state() == b.export_campaign_state(), "fractional versus coarse transport identical")
	check(a.snapshot().couriers[0].delivered_at == 14400.0, "fractional call cannot move arrival boundary")
	roundtrip(a, "fractional delivery")
func skipped_terminal_meal(w: WorldSimulation, terminal: String) -> void:
	# Forge all resource totals consistently: conservation alone cannot detect
	# deleting the final hourly ration debit before interception or return.
	var bad := w.export_campaign_state()
	var c: Dictionary = bad.world.couriers[0]
	var at: float = c.camp_received_at if terminal == "returned" else c.due_at
	var count: int = bad.world.events.size()
	bad.world.events = bad.world.events.filter(func(e): return not (e.kind == "courier" and e.details.action == "meal" and e.time_seconds == at))
	check(bad.world.events.size() == count - 1, terminal + " fixture removes exactly one terminal meal")
	c.meal_at -= 3600.0
	if terminal == "returned":
		bad.world.cities.pingling.food += 1
	else:
		c.food += 1
	bad.world.ledger.food_consumed -= 1
	bad.world.ledger.food_consumed_military -= 1
	forged(bad, terminal + " skipped terminal meal with balanced inventories")
func malformed(valid: Dictionary) -> void:
	for pair in [["authority", "player"], ["issuer", "commander"], ["route", "mountain"], ["food", 99], ["id", 2], ["delivered_at", 0.0], ["status", "returned"], ["known", "camp_confirmed"], ["due_at", NAN]]:
		var bad := valid.duplicate(true)
		bad.world.couriers[0][pair[0]] = pair[1]
		forged(bad, "forged " + pair[0])
	for action in ["dispatch", "meal", "depart", "deliver"]:
		var duplicate := valid.duplicate(true)
		for index in range(duplicate.world.events.size()):
			var e: Dictionary = duplicate.world.events[index]
			if e.kind == "courier" and e.details.action == action:
				duplicate.world.events.insert(index + 1, e.duplicate(true))
				break
		forged(duplicate, "replayed " + action + " event")
	var early := valid.duplicate(true)
	for e in early.world.events:
		if e.kind == "courier" and e.details.action == "deliver": e.time_seconds -= 0.125
	early.world.couriers[0].delivered_at -= 0.125
	early.world.couriers[0].known_at -= 0.125
	forged(early, "coordinated premature delivery event and state")
	var receipt := valid.duplicate(true)
	receipt.world.events.append({"hour": receipt.world.hour, "time_seconds": receipt.world.time_seconds, "kind": "courier", "details": {"action": "observe", "id": 1, "value": ""}})
	receipt.world.couriers[0].known = "camp_confirmed"
	forged(receipt, "forged distant camp observation and state")
	var no_events := valid.duplicate(true)
	no_events.world.events = no_events.world.events.filter(func(e): return e.kind != "courier")
	forged(no_events, "courier without causal events")
	var extra := valid.duplicate(true)
	extra.world.couriers[0].secret = true
	forged(extra, "unknown courier field")
func migration() -> void:
	var w := life()
	act(w, "first_march")
	var old := w.export_campaign_state()
	old.world.version = 7
	old.world.erase("couriers")
	var previous := old.duplicate(true)
	var loaded := W.new()
	check(loaded.restore_campaign_state(old).ok, "World7 youth migrates")
	check(old == previous, "migration does not alter caller input")
	check(loaded.snapshot().couriers.is_empty(), "migration invents no courier")
	var back := loaded.export_campaign_state()
	back.world.version = 7
	back.world.erase("couriers")
	check(back == previous, "World7 historical graph preserved")
func battle_clock() -> void:
	var w := life()
	act(w, "arrange_courier"); act(w, "first_march"); act(w, "wait_courier")
	var reservation := w.create_battle_ticket()
	check(reservation.ok, "courier does not prevent genuine battle")
	if not reservation.ok: return
	reject(w, "courier_comply", "battle lock prevents menu reply")
	reject(w, "wait_courier", "battle owns world clock")
	var b := w.start_battle(reservation.ticket.battle_id)
	var outcome := Driver.play(b)
	check(w.commit_battle_outcome(outcome).ok, "physical battle settles with courier present")
	check(w.snapshot().time_seconds > 14400.0 and w.audit().is_empty(), "battle advances shared clock and preserves resources")
	roundtrip(w, "post combat courier")
	act(w, "return_to_camp")
	for i in range(3):
		if w.snapshot().couriers[0].status != "returned": act(w, "wait_courier")
	check(w.snapshot().couriers[0].reply == "no_response", "unanswered order times out without fabricated player reply")
	check(w.snapshot().couriers[0].status == "returned" and w.player_view().courier_orders[0].known == "camp_confirmed", "only real reunion confirms camp receipt")
	roundtrip(w, "camp receipt confirmed")
func terminal_wait() -> void:
	var w := W.new()
	check(w.start_youth("forced", "survival").ok, "forced low-supply terminal fixture")
	act(w, "arrange_courier")
	# Real combat leaves a fractional world timestamp before later waits.
	act(w, "first_march")
	var ticket := w.create_battle_ticket()
	check(ticket.ok, "terminal fixture real battle")
	if not ticket.ok: return
	check(w.commit_battle_outcome(Driver.play(w.start_battle(ticket.ticket.battle_id))).ok, "terminal fixture settles real combat")
	var iterations := 0
	while not w.snapshot().campaign_ended and iterations < 60:
		if not act(w, "wait_courier"):
			print("TERMINAL_WAIT_FAILURE_AT ", w.snapshot().time_seconds, " iterations ", iterations)
			break
		iterations += 1
	check(w.snapshot().campaign_ended and not w.snapshot().commander.alive, "waiting cannot freeze protagonist starvation")
	check(w.snapshot().youth.endpoint.get("reason") == "commander_dead" and w.snapshot().youth.endpoint.get("cause") == "starvation", "terminal wait records actual cause")
	var last: Dictionary = w.snapshot().events[-1]
	check(last.kind == "courier_wait" and last.time_seconds - last.details.started_at < 3600.0, "death interrupts fractional wait at actual boundary")
	check(w.audit().is_empty(), "terminal wait resources conserved")
	reject(w, "wait_courier", "dead protagonist cannot wait again")
	reject(w, "courier_comply", "dead protagonist cannot reply")
	roundtrip(w, "terminal wait")
func finish() -> void:
	print("COURIER_ORDERS_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
