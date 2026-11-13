extends "res://tests/field_contact_window.gd"
## Record the same in-game actors, openings, camera and full-speed movement.
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	directory="res://artifacts/field-headwear"
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
	if "--march-film" in OS.get_cmdline_user_args():
		var b0:=b.ordinary_counts.duplicate()
		var steps:=[]
		var marcher:=b.roster[37]
		var archer:=b.roster[94]
		var start:=marcher.pos
		var previous:=marcher.pos
		var distance:=0.
		for frame in range(102):
			_step_neutral()
			distance+=marcher.pos.distance_to(previous)
			previous=marcher.pos
			var moving:=archer if frame<27 else marcher
			var point:=Ground.unit_point(moving.before.lerp(moving.pos,.82))
			field.carry=.82*Battle.DT
			_view(Vector2(point.x,point.z),22.,-.576)
			await RenderingServer.frame_post_draw
			if frame in [3,12,22,32,44,58,72,90,101]:
				steps.append({"frame":frame,"id":marcher.id,"pos":[marcher.pos.x,marcher.pos.y],
					"facing":[marcher.facing.x,marcher.facing.y],"stride":marcher.visual_stride,
					"state":marcher.state,"hp":marcher.hp,"view_id":moving.id,"bow_state":archer.state,"bow_ammo":archer.ammo,"hits":[b.hits[0],b.hits[1]],"losses":[b.losses[0],b.losses[1]]})
		var file:=FileAccess.open(directory+"/film.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"soldiers":Array(b0),"seed":Battle.SEED,
			"actor":marcher.id,"world_distance":distance,"meters":marcher.pos.distance_to(start),
			"rate":20,"frames":102,"lens":field.camera.size,"steps":steps},"  "))
		file.close()
		success=success and distance>1.0 and b.hits[0]+b.hits[1]>0
		print("FITTED_MARCH ",success," actor=",marcher.id," distance=",distance)
		scene.queue_free()
		await process_frame
		quit(0 if success else 1)
		return
	for frame in range(41): _step_neutral()
	if b.tick!=41: quit(3);return
	var center:=Vector2(0.,-13.)
	var captain = null
	var shield = null
	for u in b.roster:
		if not u.hero and not u.officer and not u.mounted and u.kit==7 and b.active(u) and (shield==null or u.pos.distance_to(Vector2(0.,-13.))<shield.pos.distance_to(Vector2(0.,-13.))): shield=u
		if u.officer and not u.mounted and b.active(u) and (captain==null or u.pos.distance_to(Vector2(5.,-18.))<captain.pos.distance_to(Vector2(5.,-18.))): captain=u
	var labels:=["line","reverse","spearman","archer","guard","officer"]
	for n in labels.size():
		field.carry=.82*Battle.DT
		if n>=2:
			var focus = [b.roster[37],b.roster[94],shield,captain][n-2]
			var aim_angle:float=atan2(focus.facing.y,focus.facing.x)
			var yaw:float=1.19 if n==2 else (1.1 if n==3 else 1.16-aim_angle)
			_view(focus.pos,41.0,yaw)
		else:
			_view(center,32.0,-.576+PI*n)
		await RenderingServer.frame_post_draw
		var out:=root.get_texture().get_image()
		var label:String=labels[n]
		success=out.save_png(directory+"/"+label+".png")==OK and success
		var toward:Array=[[],[]]
		var on_screen:=PackedInt32Array()
		var sides:=[0,0]
		var locators:=[]
		var factor:=Vector2(out.get_size())/root.get_visible_rect().size
		for u in b.roster:
			if u.hero: continue
			var at:=Ground.unit_point(u.before.lerp(u.pos,.82))+Vector3.UP*(1.246+(.73 if u.mounted else 0.))
			var xy:=field.camera.unproject_position(at)
			if not root.get_visible_rect().has_point(xy): continue
			on_screen.append(u.id)
			sides[u.team]+=1
			var native:=xy*factor
			if b.active(u) and not u.mounted:
				if u.kit not in toward[u.team]: toward[u.team].append(u.kit)
				locators.append([u.id,u.team,u.kit,roundi(native.x),roundi(native.y),u.officer])
		if n<2: success=success and sides[0]>=15 and sides[1]>=15
		shots.append({"name":label,"camera":[field.camera.size,field.camera_yaw,field.camera_center.x,field.camera_center.y],
			"seed":Battle.SEED,"tick":b.tick,"unit_ids":Marshalls.raw_to_base64(on_screen.to_byte_array()).sha256_text(),
			"sides_in_window":sides,"kits":toward,"locators":locators,"ordinary":Array(b.ordinary_counts),
			"commands":Array(b.command_counts),"hits":Array(b.hits),"losses":Array(b.losses),
			"hero_hp":b.hero.hp,"pixels":[out.get_width(),out.get_height()],"scale":root.scaling_3d_scale})
	var out:=FileAccess.open(directory+"/line.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(shots,"  "))
	out.close()
	print("FITTED_FORM ",success)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
