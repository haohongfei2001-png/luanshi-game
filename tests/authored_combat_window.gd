extends "res://tests/bridgehead_window.gd"
## Native game simulation, one image for each consecutive 20 Hz tick.
## Only the shared baked pose image changes between the two recordings.
const PROOF:="res://artifacts/authored-combat"

func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	var hw:=size*.5*root.size.x/root.size.y
	var hd:=size*.5/maxf(sin(field.camera_pitch),.28)
	var co:=absf(cos(yaw))
	var si:=absf(sin(yaw))
	field.view.sync_view(center,Vector2(co*hw+si*hd+4.,si*hw+co*hd+6.),.82,size)
	field.hud.update_model(field.battle,field.paused)

func _open_match() -> Node:
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): return null
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	return scene

func _seek_sequence() -> Dictionary:
	var b:=field.battle
	var history:={}
	var pending:={}
	while b.tick<650 and b.result=="":
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
		for u:Battle.Unit in b.roster:
			if u.hero or u.officer or u.mounted or u.kit not in [0,1,7]: continue
			var past:Dictionary=history.get(u.id,{"state":-1,"recent":[]})
			var recent:Array=past.recent
			var approached:=0.
			for distance:float in recent: approached+=distance
			if u.state==Battle.State.WINDUP and int(past.state)==Battle.State.MARCH and approached>.10:
				if not u.stock_strike and u.move_slot==0 and u.target>=0 and u.pos.x>29. and u.pos.x<43. and absf(u.pos.y)<5.:
					pending[u.id]={"start":maxi(1,b.tick-6),"windup":b.tick,"actor":u.id,
						"impacts":u.impacts,"recovered":false,"walked":0.,"facing":u.facing}
			if pending.has(u.id):
				var row:Dictionary=pending[u.id]
				if u.state==Battle.State.RECOVER: row.recovered=true
				if row.recovered and u.state==Battle.State.MARCH:
					row.walked+=u.pos.distance_to(u.before)
				if u.impacts>int(row.impacts) and row.walked>.12 and b.tick-int(row.start)<42:
					return row
				if not b.active(u) or b.tick-int(row.start)>42: pending.erase(u.id)
			recent.append(u.pos.distance_to(u.before))
			if recent.size()>6: recent.pop_front()
			history[u.id]={"state":u.state,"recent":recent}
	return {}

func _run() -> void:
	for folder:String in [OUT,PROOF,PROOF+"/normal",PROOF+"/close",PROOF+"/reverse"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scout=await _open_match()
	if scout==null: quit(1);return
	var selected:=_seek_sequence()
	if selected.is_empty():
		push_error("No complete ordinary approach/cut/recovery/walk sequence in the unchanged bridge battle")
		quit(2);return
	scout.queue_free()
	await process_frame
	var scene=await _open_match()
	if scene==null: quit(3);return
	var b:=field.battle
	while b.tick<int(selected.start):
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var subject:Battle.Unit=b.roster[int(selected.actor)]
	var direction:Vector2=selected.facing
	var yaw:=atan2(direction.x,direction.y)+.80
	var index:Array=[]
	for frame in 48:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var shots:Array=[["normal",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)],["close",subject.pos,6.3,yaw]]
		if frame in [0,12,24,47]: shots.append(["reverse",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)+PI])
		for shot:Array in shots:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var captured:=root.get_texture().get_image()
			if captured.get_width()!=2560 or captured.get_height()!=1600: quit(4);return
			if captured.save_png(PROOF+"/%s/frame-%03d.png"%[shot[0],frame])!=OK: quit(5);return
		index.append({"tick":b.tick,"actor":subject.id,"kit":subject.kit,"team":subject.team,"xz":[subject.pos.x,subject.pos.y],
			"facing":[subject.facing.x,subject.facing.y],"state":subject.state,"timer":subject.timer,"duration":subject.duration,
			"move_slot":subject.move_slot,"target":subject.target,"impacts":subject.impacts,"received":subject.received,
			"travel":subject.pos.distance_to(subject.before),"hp":subject.hp,"contact_tick":subject.contact_tick,"contact_blocked":subject.contact_blocked,
			"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),"ordinary":Array(b.ordinary_counts),
			"camera_close":[subject.pos.x,subject.pos.y,6.3,yaw]})
	var f:=FileAccess.open(PROOF+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames":48,"fps":20,"duration":2.4,"size":[2560,1600],"scale":root.scaling_3d_scale,
		"normal_camera":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y,22.,deg_to_rad(-33.)],"seed":Battle.SEED,
		"kind":"consecutive original-speed actual game steps, no realtime performance claim","index":index},"  "))
	f.close()
	print("AUTHORED_COMBAT_MOTION ",JSON.stringify(index[0])," terminal=",JSON.stringify(index[-1]))
	scene.queue_free()
	await process_frame
	quit()
