extends SceneTree
## Use the normal battle options and read the actual renderer backbuffer after each change.
const Field:=preload("res://scripts/field/controller.gd")

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var scene:=preload("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	var f:Field=scene.field
	var original:=root.size
	var ok:=true
	var cases:Array[Vector3i]=[Vector3i(2,2560,1440),Vector3i(3,3840,2160),Vector3i(0,original.x,original.y)]
	f.hud.graphic_toggle.pressed.emit()
	if not f.hud.graphic_row.visible: ok=false
	for probe in cases:
		f.hud.display_mode.item_selected.emit(probe.x)
		for i in 4: await process_frame
		await RenderingServer.frame_post_draw
		var size:=root.get_texture().get_image().get_size()
		var written:=ConfigFile.new()
		var saved:bool=written.load(f.QUALITY_FILE)==OK and int(written.get_value("display","mode",-1))==probe.x
		print("RIVER_DISPLAY ",probe.x," ",size," ",root.scaling_3d_scale," mode=",root.mode," saved=",saved)
		ok=ok and saved and size==Vector2i(probe.y,probe.z) and root.scaling_3d_scale==1.
	f.set_quality(f.Quality.BALANCED,true)
	f.hud.display_mode.item_selected.emit(f.DisplayChoice.QHD)
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var storage:=ConfigFile.new()
	ok=ok and storage.load(f.QUALITY_FILE)==OK and int(storage.get_value("display","mode",-1))==f.DisplayChoice.QHD
	ok=ok and root.scaling_3d_scale==1. and f.detail_preset==f.Quality.NATIVE_MSAA
	f.hud.display_mode.item_selected.emit(f.DisplayChoice.WINDOW)
	print("RIVER_DISPLAY_PASS ",ok)
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
