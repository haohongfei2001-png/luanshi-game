extends "res://tests/authored_combat_window.gd"
const CLOSE_OUT:="res://artifacts/authored-combat-close"

func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	field.carry=Battle.DT*.82
	field._draw_field()
	field.hud.update_model(field.battle,field.paused)

func _horses_near(u:Battle.Unit) -> bool:
	var b:=field.battle
	for team:int in [0,1]:
		for id:int in b._near(u.pos,2.8,team):
			var other:Battle.Unit=b.roster[id]
			if other.mounted and other.mount_hp>0.: return true
	return false

func _seek_clear_sequence() -> Dictionary:
	var b:=field.battle
	var history:={}
	var pending:={}
	while b.tick<550 and b.result=="":
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
		for u:Battle.Unit in b.roster:
			if u.hero or u.officer or u.mounted or u.kit not in [0,1,7]: continue
			var past:Dictionary=history.get(u.id,{"state":-1,"recent":[]})
			var recent:Array=past.recent
			var approached:=0.
			for distance:float in recent: approached+=distance
			if u.state==Battle.State.WINDUP and int(past.state)==Battle.State.MARCH and approached>.10:
				if not u.stock_strike and u.move_slot==0 and u.target>=0 and u.pos.x>29. and u.pos.x<44. and absf(u.pos.y)<12. and not _horses_near(u):
					pending[u.id]={"start":maxi(1,b.tick-6),"windup":b.tick,"hit":-1,"resume":-1,
						"actor":u.id,"impacts":u.impacts,"recovered":false,"walked":0.}
			if pending.has(u.id):
				var row:Dictionary=pending[u.id]
				if u.impacts>int(row.impacts) and int(row.hit)<0: row.hit=b.tick
				if u.state==Battle.State.RECOVER: row.recovered=true
				if row.recovered and u.state==Battle.State.MARCH:
					if int(row.resume)<0: row.resume=b.tick
					row.walked+=u.pos.distance_to(u.before)
				var blocked:=_horses_near(u)
				if int(row.hit)>0 and row.walked>.12 and b.tick-int(row.start)<42 and not blocked:
					return row
				if blocked or not b.active(u) or b.tick-int(row.start)>42: pending.erase(u.id)
			recent.append(u.pos.distance_to(u.before))
			if recent.size()>6: recent.pop_front()
			history[u.id]={"state":u.state,"recent":recent}
	return {}

func _run() -> void:
	for folder:String in [OUT,CLOSE_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scout=await _open_match()
	if scout==null: quit(1);return
	var selected:=_seek_clear_sequence()
	if selected.is_empty():
		push_error("No unobstructed real approach/cut/resumed walk episode")
		quit(4);return
	scout.queue_free()
	await process_frame
	var scene=await _open_match()
	if scene==null: quit(5);return
	var b:=field.battle
	var rows:Array=[]
	var marks:Array=[]
	for mark:int in [selected.start,selected.windup,int(selected.windup)+2,selected.hit,int(selected.hit)+3,selected.resume,int(selected.resume)+2]:
		if not marks.has(mark): marks.append(mark)
	marks.sort()
	for tick:int in marks:
		while b.tick<tick:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[int(selected.actor)]
		var shots:Array=[["side",subject.pos,6.3,0.]]
		if tick in [int(selected.windup)+2,int(selected.hit)]: shots.append(["line",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)])
		if tick==int(selected.hit): shots.append(["reverse",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)+PI])
		for shot:Array in shots:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var captured:=root.get_texture().get_image()
			if captured.get_width()!=2560 or captured.get_height()!=1600: quit(2);return
			if captured.save_jpg(CLOSE_OUT+"/%s-%03d.jpg"%[shot[0],tick],.78)!=OK: quit(3);return
			rows.append({"actor":subject.id,"tick":tick,"view":shot[0],"camera":[shot[1].x,shot[1].y,shot[2],shot[3]],
				"position":[subject.pos.x,subject.pos.y],"state":subject.state,"timer":subject.timer,"duration":subject.duration,
				"impacts":subject.impacts,"hp":subject.hp,"hits":Array(b.hits),"losses":Array(b.losses),
				"ordinary":Array(b.ordinary_counts),"scale":root.scaling_3d_scale,"size":[2560,1600]})
	var f:=FileAccess.open(CLOSE_OUT+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"selected":selected,"rows":rows},"  "))
	f.close()
	print("AUTHORED_CLOSE ",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
