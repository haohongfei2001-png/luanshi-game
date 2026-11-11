class_name ComradePetition
extends RefCounted
## A supplemental claim, distinct from the historical first appeal. No rerolls.
const PEOPLE := ["recruit_lin", "recruit_zhou", "recruit_wu", "recruit_tian"]
const REVISION := 1

static func record(y: Dictionary) -> Dictionary:
	for entry in y.get("timeline", []):
		if entry.action == "comrade_petition": return entry.details.duplicate(true)
	return {}

static func available(y: Dictionary) -> bool:
	if y.is_empty() or y.stage != "dangerous_orders" or y.appropriated_merit <= 0 or not record(y).is_empty(): return false
	# Close the claim before any voluntary credit bargain is quoted. The petition cannot
	# reclaim merit the player later freely trades, or rewrite an already fixed quote.
	for e in y.timeline:
		if e.action == "camp_appraisal": return false
	return true

static func evaluate(y: Dictionary) -> Dictionary:
	var decisions: Array = []
	var signatures := 0
	var battle: String = y.battle_ids[0]
	var prior_witnesses: Array = []
	var private_witnesses: Array = []
	for evidence in y.evidence:
		if evidence.kind == "witness_deposition" and evidence.battle_id == battle:
			prior_witnesses.append(evidence.witness)
		if evidence.kind == "private_roster_copy" and evidence.battle_id == battle:
			private_witnesses.append(evidence.witness)
	var present := 0
	for id in PEOPLE:
		var c: Dictionary = y.characters[id]
		if c.alive and (id in y.roster or c.location == "pingling") and battle in c.known_battles: present += 1
	for id in PEOPLE:
		var c: Dictionary = y.characters[id]
		# A soldier in this actual roster is locally present only because the caller and
		# strict replay both establish the squad at camp. The protected survivor stays there.
		if not c.alive or (id not in y.roster and c.location != "pingling"): continue
		if battle not in c.known_battles: continue
		var reason := "fear_of_blame"
		var sign := false
		if id in prior_witnesses:
			reason = "already_testified"
		elif c.grievance > c.trust + c.respect:
			reason = "losses_before_credit"
		elif id == y.protected_id and c.trust >= 3:
			sign = true
			reason = "protected_me"
		elif id == "recruit_wu" and c.respect >= 1 and c.trust >= 3:
			sign = true
			reason = "earned_respect"
		elif id in ["recruit_lin", "recruit_zhou"] and c.trust >= 3 and id in private_witnesses:
			sign = true
			reason = "kept_our_record"
		elif id == "recruit_tian" and present >= 3 and c.trust >= 3 and c.respect >= 1:
			sign = true
			reason = "shared_survival"
		if sign: signatures += 1
		decisions.append({"id": id, "sign": sign, "reason": reason, "trust": c.trust,
			"respect": c.respect, "grievance": c.grievance})
	return {"revision": REVISION, "battle_id": battle, "decisions": decisions,
		"restored": mini(y.appropriated_merit, signatures)}

static func description(d: Dictionary, people: Dictionary) -> String:
	if d.is_empty(): return ""
	var lines := ["同袍补证：书吏核对亲历证词，追回名册军功%d；不发粮、不增兵。" % d.restored]
	var reasons := {"already_testified": "先前申诉时我已经作证，书吏不会把同一份证词再记一次功", "protected_me": "你替我承担责难，让我留营，我愿说出亲历之事", "losses_before_credit": "死去的人太多，我先顾幸存者，不愿再争功担责", "earned_respect": "我看重实战本领，亲眼见过你的战果，也信得过你，我愿联署", "kept_our_record": "你保留了我们的真实名册，我愿站出来核对", "shared_survival": "至少三名亲历同袍仍在营中，彼此可以照应，我信得过你，愿作证", "fear_of_blame": "我虽亲历战斗，眼下仍怕上官追责，暂不联署"}
	for c in d.decisions:
		lines.append("%s：%s。%s" % [people[c.id].name, reasons[c.reason], "已联署，信任与尊重各+1。" if c.sign else "未联署，不受额外惩罚。"])
	if d.decisions.is_empty(): lines.append("已无活着且在营的亲历同袍，无人能代死者或远方人作证。")
	return "\n".join(lines)
