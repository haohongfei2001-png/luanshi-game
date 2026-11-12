extends SceneTree
const Field := preload("res://scripts/field/controller.gd")
const Ground := preload("res://scripts/field/ground.gd")
func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var field:=preload("res://scenes/river_gate.tscn").instantiate() as Field
	root.add_child(field)
	await process_frame
	var tick_log:={}
	field.hud.go.pressed.emit()
	var shots: Array=[["river",Ground.RIVER_X,0,18],["camp",-72.0,-7.0,38],["gate",48.0,-1.5,56],["battle",7.0,-1.0,78]]
	for shot in shots:
		while field.battle.tick<int(shot[3]):
			await physics_frame
		field.pan_to(Vector2(float(shot[1]),float(shot[2])))
		await process_frame
		await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image()
		if img.save_jpg(OS.get_environment("ENV_PROOF")+"/"+str(shot[0])+".jpg",0.88)!=OK:
			quit(1)
			return
		tick_log[shot[0]]={"tick":field.battle.tick,"center":[field.camera_center.x,field.camera_center.y],
			"size":field.camera.size,"hits":field.battle.hits.duplicate(),"visible":field.view.visible_soldiers}
	print("RIVER_CRAFT "+JSON.stringify(tick_log))
	quit(0)
