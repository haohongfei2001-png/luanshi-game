extends "res://tests/field_contact_window.gd"
## Watch a naturally contested sector along both directions at the normal game zoom.
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	directory="res://artifacts/field-dye"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	var b:=field.battle
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(2);return
	for frame in range(41): _step_neutral()
	if b.tick!=41: quit(3);return
	var center:=Vector2(0.,-13.)
	for n in range(2):
		field.carry=.82*Battle.DT
		_view(center,22.,-.576+PI*n)
		await RenderingServer.frame_post_draw
		var out:=root.get_texture().get_image()
		var label:="line" if n==0 else "reverse"
		success=out.save_png(directory+"/"+label+".png")==OK and success
		var toward:Array=[[],[]]
		var on_screen:=PackedInt32Array()
		var sides:=[0,0]
		var locators:=[]
		var factor:=Vector2(out.get_size())/root.get_visible_rect().size
		for u in b.roster:
			if u.hero or u.officer: continue
			var at:=Ground.unit_point(u.before.lerp(u.pos,.82))+Vector3.UP*(1.246+(.73 if u.mounted else 0.))
			var xy:=field.camera.unproject_position(at)
			if not root.get_visible_rect().has_point(xy): continue
			on_screen.append(u.id)
			sides[u.team]+=1
			var native:=xy*factor
			if b.active(u) and not u.mounted:
				if u.kit not in toward[u.team]: toward[u.team].append(u.kit)
				locators.append([u.id,u.team,u.kit,roundi(native.x),roundi(native.y)])
		success=success and sides[0]>=15 and sides[1]>=15
		shots.append({"name":label,"camera":[field.camera.size,field.camera_yaw,center.x,center.y],
			"seed":Battle.SEED,"tick":b.tick,"unit_ids":Marshalls.raw_to_base64(on_screen.to_byte_array()).sha256_text(),
			"sides_in_window":sides,"kits":toward,"locators":locators,"ordinary":Array(b.ordinary_counts),
			"commands":Array(b.command_counts),"hits":Array(b.hits),"losses":Array(b.losses),
			"hero_hp":b.hero.hp,"pixels":[out.get_width(),out.get_height()],"scale":root.scaling_3d_scale})
	var out:=FileAccess.open(directory+"/line.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(shots,"  "))
	out.close()
	print("LIVERY_LINE ",success)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
