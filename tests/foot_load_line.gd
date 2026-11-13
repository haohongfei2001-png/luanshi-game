extends "res://tests/river_art_capture.gd"
const OUT := "res://artifacts/foot-load/line"
var trajectory: Array=[]

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810.,416.))
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(1);return
	var centre:=Vector2.ZERO
	var pinned:=false
	# The same fixed piece of ground spans the first advance and subsequent
	# contact of the eight real leading infantry of this company.
	for frame in 68:
		_advance(frame+7)
		if not pinned:
			for i in range(64,72): centre+=b.roster[i].pos
			centre=centre/8.+Vector2(2.8,0.)
			pinned=true
		field.carry=.50*Battle.DT
		_view(centre,22.,-.576)
		await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image()
		success=img.save_jpg("%s/%03d.jpg"%[OUT,frame],.94)==OK and success
		var people: Array=[]
		var viewc:=root.get_visible_rect().size
		# Count the walk/idle variants that the shipping shader actually addresses.
		var use:=PackedInt32Array([0,0,0,0])
		for u in b.roster:
			if u.hero or u.officer or u.mounted or u.kit not in [3,7] or not b.active(u): continue
			var p:=u.before.lerp(u.pos,.5)
			var screen:=field.camera.unproject_position(Ground.unit_point(p)+Vector3.UP*1.15)
			if screen.x<0. or screen.y<0. or screen.x>=viewc.x or screen.y>=viewc.y: continue
			var lot:=(u.id*5+u.squad*3)%8
			var alt:=1 if lot in [1,4] else (2 if lot in [2,5,7] else 0)
			if u.state==Battle.State.MARCH: use[3 if u.visual_run else alt]+=1
			if u.id>=64 and u.id<72:
				people.append([u.id,u.kit,u.state,p.x,p.y,u.hp,u.target,alt,screen.x,screen.y])
		trajectory.append([b.tick,Array(b.hits),Array(b.losses),people,Array(use),field.camera.size])
		if frame in [0,8,17,28,41,53,67]:
			img.save_png("%s/snapshot-%03d.png"%[OUT,frame])
			print("LOAD_LINE ",frame," ",JSON.stringify(trajectory.back()))
	FileAccess.open(OUT+"/trajectory.json",FileAccess.WRITE).store_string(JSON.stringify(trajectory))
	print("LOAD_LINE_PASS ",success," ordinary=",b.ordinary_counts," hits=",b.hits)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
