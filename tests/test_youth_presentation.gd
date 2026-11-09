extends SceneTree
## Isolated text fixtures only; real loss/save proofs live in test_youth_attrition.
func _initialize() -> void:
	var ui := preload("res://scripts/youth_ui.gd").new()
	ui.view = {"relationships": {"comrade": {"name": "测试同袍", "role": "comrade", "alive": false}},
		"timeline": [{"at": 3600.0, "action": "attrition", "details": {"cause": "starvation", "dead_ids": ["comrade", "commander"]}}, {"at": 7200.0, "action": "interrupted", "details": {"action": "protect_comrade"}}],
		"endpoint": {"reason": "commander_dead", "cause": "starvation", "army_ids": []}}
	var record: String = ui._records_text()
	var checks := [record.contains("主角因断粮死亡"), not record.contains("主角战死"), record.contains("确认死亡：测试同袍、主角"), record.contains("保护未及完成"), ui._relations_text().contains("测试同袍 · 因断粮死亡")]
	ui.view.endpoint.erase("cause")
	checks.append(ui._records_text().contains("主角战死"))
	ui.view.endpoint = {"reason": "first_patrol_withdrawn", "army_ids": []}
	checks.append(ui._records_text().contains("已撤离初阵") and not ui._records_text().contains("撤回营地"))
	ui.free()
	var failures := checks.count(false)
	print("YOUTH_PRESENTATION_SUMMARY " + JSON.stringify({"checks": checks.size(), "failures": failures}))
	quit(0 if failures == 0 else 1)
