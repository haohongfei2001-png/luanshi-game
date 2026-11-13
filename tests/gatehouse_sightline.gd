extends SceneTree
## Exercise the built map. Every check reads the actual gatehouse MeshInstance3D.
const Landscape:=preload("res://scripts/field/landscape.gd")
const Ground:=preload("res://scripts/field/ground.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var map:=Landscape.new()
	root.add_child(map)
	await process_frame
	var roof:MeshInstance3D
	for part in map.roofs:
		var center:Vector3=part.center
		if part.has("pieces") and absf(center.x-Ground.WALL_X)<.01 and absf(center.z)<.01:
			roof=part.node
			break
	if not is_instance_valid(roof):
		push_error("Gatehouse roof missing from the battle map")
		quit(1)
		return
	var center:=Ground.GATE
	var survey:=Ground.unit_point(center)+Vector3(-18,31,20)
	map.reveal_sightline(center,Vector2(-10,-3),survey,32.0,true,true)
	var visible_during_survey:=roof.visible
	var player:=Vector2(Ground.WALL_X,0.0)
	var overhead:=Ground.unit_point(player)+Vector3.UP*36.0
	map.reveal_sightline(player,player,overhead,22.0,true,true)
	var portal_revealed:=not roof.visible
	map.reveal_sightline(center,Vector2(-10,-3),survey,32.0,true,true)
	var restored:=roof.visible
	print("GATEHOUSE_SIGHTLINE ",JSON.stringify({"survey_full_roof":visible_during_survey,
		"hero_under_roof_revealed":portal_revealed,"restored_after_pan":restored}))
	map.queue_free()
	await process_frame
	quit(0 if visible_during_survey and portal_revealed and restored else 1)
