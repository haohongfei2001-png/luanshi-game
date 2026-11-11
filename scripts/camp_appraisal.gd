class_name CampAppraisal
extends RefCounted
## Optional, once-per-life camp negotiation. No private evidence or hidden courier fate.
## Versioned event payloads extend the existing World8 timeline, not its save shape.
const REVISION := 1
const SUPPORT_FOOD := 8
const BARGAIN_FOOD := 4

static func shape(d: Variant) -> bool:
	if not d is Dictionary or d.size() != 7: return false
	for key in ["revision", "outcome", "reason", "food", "recorded_merit", "battles", "receipts"]:
		if not d.has(key): return false
	for key in ["revision", "food", "recorded_merit"]:
		if not d[key] is int: return false
	if not d.outcome is String or not d.reason is String or not d.battles is Array or not d.receipts is Array: return false
	for id in d.battles:
		if not id is String: return false
	for r in d.receipts:
		if not r is Dictionary or r.size() != 2 or not r.get("id") is int or not r.get("reply") is String: return false
	return true

static func offer(y: Dictionary) -> Dictionary:
	for entry in y.get("timeline", []):
		if entry.action == "camp_appraisal": return entry.details.duplicate(true)
	return {}

static func settled(y: Dictionary) -> bool:
	for entry in y.get("timeline", []):
		if entry.action in ["appraisal_accept", "appraisal_decline"]: return true
	return false

static func pending(y: Dictionary) -> bool:
	var quoted := offer(y)
	return y.get("stage") == "dangerous_orders" and not quoted.is_empty() and quoted.outcome != "denied" and not settled(y)

static func returned(couriers: Array) -> Array:
	var result: Array = []
	for c in couriers:
		if c.status == "returned": result.append({"id": c.id, "reply": c.reply})
	return result

static func evaluate(y: Dictionary, receipts: Array, stock: int) -> Dictionary:
	# The camp already heard these battles in return_to_camp. A private roster is not evidence here.
	var result := {"revision": REVISION, "outcome": "denied", "reason": "no_record", "food": 0,
		"recorded_merit": y.recorded_merit, "battles": y.characters.officer_qiao.known_battles.duplicate(),
		"receipts": receipts.duplicate(true)}
	if result.battles.is_empty(): return result
	var compliant := false
	for receipt in receipts:
		if receipt.reply == "refuse":
			result.reason = "returned_refusal"
			return result
		if receipt.reply == "comply": compliant = true
	if y.recorded_merit >= 2 or compliant:
		result.outcome = "support"
		result.reason = "returned_compliance" if compliant else "credited_record"
		result.food = SUPPORT_FOOD
	elif y.recorded_merit >= 1:
		result.outcome = "bargain"
		result.reason = "credit_for_rations"
		result.food = BARGAIN_FOOD
	if result.food > stock:
		result.outcome = "denied"
		result.reason = "insufficient_stock"
		result.food = 0
	return result

static func decision(y: Dictionary) -> String:
	for entry in y.get("timeline", []):
		if entry.action == "appraisal_accept": return "accepted"
		if entry.action == "appraisal_decline": return "declined"
	return "closed" if y.get("stage") != "dangerous_orders" else "pending"

static func description(quoted: Dictionary, resolution: String = "pending") -> String:
	if quoted.is_empty(): return ""
	var receipts: Array = quoted.receipts
	var account := "尚无带回营中的回执，不以失联推断抗命。" if receipts.is_empty() else "仅使用已带回营中的回报。"
	for r in receipts:
		account += " 回营回报%d：%s。" % [r.id, {"comply": "愿遵令回营", "refuse": "暂不遵令", "no_response": "未获答复", "not_found": "未找到巡队"}.get(r.reply, "未注明")]
	var prefix: String = {"accepted": "已按以下条件领粮一次（历史记录）：\n", "declined": "已拒绝以下配给，未让功也未领粮（历史记录）：\n", "closed": "当时的营中答复（已离开这次商谈）：\n"}.get(resolution, "")
	var basis := str(prefix) + "营中已收亲历战报%d份，名册记功%d。%s\n" % [quoted.battles.size(), quoted.recorded_merit, account]
	match quoted.outcome:
		"support": return basis + "队正认可已登记的战果或送回的遵令答复，准给八份营粮，军中声望+1、队正尊重+1，不改军功归属。"
		"bargain": return basis + "队正只肯给四份营粮，条件是把你名下的一点军功改记为他的调度之功；军中声望+1。接受才转让军功；拒绝则保留军功。"
		_: return basis + {"returned_refusal": "队正以已经带回的拒令答复为由，不批额外营粮；没有另加撤职或强迫出战。", "insufficient_stock": "营中现粮不足以支付这次配给，没有凭空许诺物资。", "no_record": "尚无足够已登记的战功支持这次申请。"}.get(quoted.reason, "本次未批额外营粮。")
