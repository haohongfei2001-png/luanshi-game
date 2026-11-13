extends "res://tests/field_contact_window.gd"
## The same existing foot soldiers travel, check their advance and enter combat.
const TICKS=76
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	directory="res://artifacts/loaded-advance"
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
	var success_here:=true
	var states:=[]
	var film:="--advance-film" in OS.get_cmdline_user_args()
	var ids:=[37,38,94,167,166,165,193,194,544,569]
	var distance:=0.
	for t in range(TICKS):
		_step_neutral()
		var tick:=b.tick
		var troop:=b.roster[37]
		var focus:=b.roster[167] if tick<=38 else troop
		distance+=troop.pos.distance_to(troop.before)
		if not film and tick not in [12,41,64]: continue
		field.carry=.82*Battle.DT
		var centre:=focus.before.lerp(focus.pos,.82)
		for yaw_index in (1 if film else 2):
			var reverse:bool=(tick>38 if film else yaw_index==1)
			var side:String="reverse" if reverse else "front"
			# Turn around the same person and leave scale/height/game speed alone.
			_view(centre,22.,LOOK+(PI if reverse else 0.))
			await RenderingServer.frame_post_draw
			var pixels:=root.get_texture().get_image()
			if film:
				success_here=pixels.save_jpg(directory+"/frame-%03d.jpg"%tick,.974)==OK and success_here
			else:
				success_here=pixels.save_png(directory+"/%s-%03d.png"%[side,tick])==OK and success_here
			var troops:=[]
			for id: int in ids:
				var u:=b.roster[id]
				var ground:=Ground.unit_point(u.before.lerp(u.pos,.82))
				var pt:=field.camera.unproject_position(ground+Vector3.UP*1.2)
				var size:=Vector2(pixels.get_size())/root.get_visible_rect().size
				pt*=size
				troops.append({"id":u.id,"kit":u.kit,"team":u.team,"hp":u.hp,"state":u.state,
					"pos":[u.pos.x,u.pos.y],"target":u.target,"walk_distance":u.pos.distance_to(u.before),
					"facing":[u.facing.x,u.facing.y],"run":u.visual_run,"stride":u.visual_stride,
					"impacts":u.impacts,"projection":[pt.x,pt.y]})
			var moving:=0
			var running:=0
			var stopped:=0
			var engaged:=0
			for u in b.roster:
				if u.hero or u.officer or u.mounted or not b.active(u): continue
				if u.before.distance_squared_to(u.pos)>.000001:
					moving+=1
					if u.visual_run: running+=1
				elif u.state==Battle.State.MARCH: stopped+=1
				if u.state in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD,Battle.State.STAGGER]: engaged+=1
			states.append({"tick":tick,"camera":[field.camera.size,field.camera_yaw,centre.x,centre.y],
				"ordinary":Array(b.ordinary_counts),"ids":ids,"tracked":troops,"focus_id":focus.id,"hits":Array(b.hits),
				"losses":Array(b.losses),"marching":moving,"running":running,"stopped":stopped,
				"engaged":engaged,"commands":Array(b.command_counts),"pixels":[pixels.get_width(),pixels.get_height()],
				"resolution_scale":root.scaling_3d_scale})
	var out:=FileAccess.open(directory+("/film.json" if film else "/stills.json"),FileAccess.WRITE)
	out.store_string(JSON.stringify({"seed":Battle.SEED,"tick_seconds":Battle.DT,"distance":distance,
		"states":states},"  "))
	out.close()
	success_here=success_here and distance>3. and b.hits[0]+b.hits[1]>0
	print("LOADED_ADVANCE ",success_here," actor=37 distance=",distance)
	scene.queue_free()
	await process_frame
	quit(0 if success_here else 1)
