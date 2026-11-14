extends "res://tests/bridgehead_clothing_window.gd"
## Record every fixed simulation tick from 114 through 173. The player remains
## on the bridge; mounted/foot companies on both sides advance and strike.
func _run() -> void:
	var out:="res://artifacts/bridge-window"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): quit(1);return
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	b.input_state(Vector2.ZERO,b.hero.facing)
	while b.tick<113: b.step()
	var records:=[]
	var close_shot:="--close-dress" in OS.get_cmdline_user_args()
	var reverse_shot:="--reverse-dress" in OS.get_cmdline_user_args()
	for frame in 60:
		b.step()
		var focus:=b.roster[62]
		var center:=Ground.BRIDGE_VIEW if not close_shot else focus.before.lerp(focus.pos,.82)
		_set_view(center,5.3 if close_shot else 22.,2.697 if close_shot else deg_to_rad(-33.)+(PI if reverse_shot else 0.))
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		if image.get_width()!=2560 or image.get_height()!=1600: quit(2);return
		if image.save_jpg(out+"/frame-%03d.jpg"%frame,.942)!=OK: quit(3);return
		records.append({"tick":b.tick,"actor":focus.id,"stance":focus.state,"xz":[focus.pos.x,focus.pos.y],"stride":focus.stride,"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),"view":field.camera.size,"ordinary":Array(b.ordinary_counts)})
	var f:=FileAccess.open(out+"/recording.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"index":records,"fps":20,"scale":root.scaling_3d_scale,"frames":60,"size":[2560,1600],"close":close_shot,"reverse":reverse_shot},"  "))
	f.close()
	if records[0].tick!=114 or records[-1].tick!=173 or records[0].hits==records[-1].hits: quit(4);return
	print("FIELD_COAT_MOTION_PASS ",records[0].tick," ",records[-1].tick," ",records[-1].hits)
	scene.queue_free()
	await process_frame
	quit()
