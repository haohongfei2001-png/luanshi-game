extends "res://tests/bridgehead_window.gd"
## Replay uses the ordinary muster popup and exactly the bridgehead_window key stream.
## Project a conservative horse trunk (no head, legs, or tack) in front of each
## living foot spear/shield breast point, independently of torso pixels' colour.
func _facts() -> Dictionary:
	var row:=super._facts()
	if row.tick%5==0:
		row["mounts"]=_mounts()
	return row

func _mounts() -> Dictionary:
	var b:=field.battle
	var riders:=0
	var loose:=0
	var moved:=0
	var wet:=0
	var hoof_positions:={}
	var hulls:Array=[]
	var viewport:=root.get_visible_rect()
	var view=field.view
	for u in b.roster:
		if not u.mounted or u.mount_hp<=0.0 or u.state==Battle.State.ESCAPED: continue
		var empty:=u.hp<=0. and u.state==Battle.State.DEAD
		var pos:=u.pos
		var heading:=u.facing
		if empty:
			loose+=1
			if "loose_mounts" in view and view.loose_mounts.has(u.id):
				var path=view.loose_mounts[u.id]
				var age:=maxf(0.,(b.tick-u.lost_tick-1)*Battle.DT)
				var tr:Transform2D=path.sample(path.distance_at(age))
				pos=tr.origin
				heading=Vector2(sin(tr.get_rotation()),cos(tr.get_rotation()))
			if pos.distance_to(u.pos)>1.5: moved+=1
			if Ground.moat_blocks(pos): wet+=1
			if pos.distance_squared_to(u.pos)>1.:
				hoof_positions[u.id]=[snappedf(pos.x,.01),snappedf(pos.y,.01)]
		else: riders+=1
		var base:=Ground.unit_point(pos,true)
		var cam:=field.camera
		var torso:=base+Vector3.UP*1.14
		if not viewport.grow(70.).has_point(cam.unproject_position(torso)): continue
		var points:=PackedVector2Array()
		var side:=heading.orthogonal()
		for length:float in [-.69,.46]:
			for width:float in [-.27,.27]:
				for height:float in [.87,1.36]:
					var planar:=heading*length+side*width
					points.append(cam.unproject_position(base+Vector3(planar.x,height,planar.y)))
		hulls.append([Geometry2D.convex_hull(points),cam.to_local(torso).z,empty])
	var footmen:=0
	var behind_empty:=0
	var behind_ridden:=0
	var behind_either:=0
	var center_empty:=0
	for u in b.roster:
		if u.hero or u.officer or u.mounted or not b.active(u) or u.kit not in [3,7]: continue
		var chest:=Ground.unit_point(u.pos,true)+Vector3.UP*1.16
		var point:=field.camera.unproject_position(chest)
		if not viewport.has_point(point): continue
		footmen+=1
		var depth:=field.camera.to_local(chest).z
		var blocked_empty:=false
		var blocked_ridden:=false
		for hull:Array in hulls:
			if hull[1]<depth+.15 or not Geometry2D.is_point_in_polygon(point,hull[0]): continue
			if hull[2]: blocked_empty=true
			else: blocked_ridden=true
		if blocked_empty:
			behind_empty+=1
			if u.pos.distance_squared_to(b.hero.pos)<36.: center_empty+=1
		if blocked_ridden: behind_ridden+=1
		if blocked_empty or blocked_ridden: behind_either+=1
	return {"empty":loose,"ridden":riders,"empty_moved":moved,"in_water":wet,"visible_foot_spear_shield":footmen,"covered_by_empty":behind_empty,"covered_by_ridden":behind_ridden,"covered_any":behind_either,"covered_empty_near_player":center_empty,"displaced_xz":hoof_positions}

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge():
		push_error("The bridgehead plan could not be selected in its regular popup")
		quit(1);return
	var b:=field.battle
	for u in b.roster:
		if not u.hero and not u.officer and u.team==0 and u.pos.x<Ground.MOAT_X-3.: initial_west[u.id]=true
	_click(field.hud.go.get_global_rect().get_center())
	if not b.started:
		push_error("Deploy button failed")
		quit(1);return
	first_game_frame=Engine.get_frames_drawn()
	var preview:="--bridge-stills" in OS.get_cmdline_user_args()
	var frames:=0
	while frames<295 and b.result=="" and not field.paused:
		frames+=1
		if b.tick!=last_tick:
			last_tick=b.tick
			_drive()
			var m:=_facts()
			snapshots.append(m)
			if b.tick%25==0: print("BRIDGE_TICK ",JSON.stringify(m))
			if b.tick in [105,120,135,145,165,185,205,225,240] or (b.hero.impacts>0 and not clicked):
				if b.hero.impacts>0: clicked=true
				await RenderingServer.frame_post_draw
				var frame:=root.get_texture().get_image()
				screenshot_ok=frame.save_jpg(OUT+"/view-%04d.jpg"%b.tick,.94)==OK and screenshot_ok
		await process_frame
		if preview and b.tick>=150: break
	for key:Key in [KEY_W,KEY_S,KEY_A,KEY_D]: _key(key,false)
	var fact:=_facts()
	var clear_count:=0
	var entered_water:=false
	var off_lens:=false
	var first_blow:=-1
	for row:Dictionary in snapshots:
		if row.both_landmarks: clear_count+=1
		if row.feet_in_deep_water>0: entered_water=true
		if not is_equal_approx(row.zoom,22.) or absf(row.yaw-deg_to_rad(-33.))>.0001: off_lens=true
		if first_blow<0 and row.hero_impacts>0: first_blow=row.tick
	var terminal:={"ordinary":Array(b.ordinary_counts),"officers":Array(b.command_counts),"seed":Battle.SEED,
		"frames_of_play":frames,"sampled_ticks":snapshots.size(),"first_player_strike":first_blow,
		"held_both":clear_count,"feet_in_deep_water":entered_water,"different_lens":off_lens,
		"shield_contacts":contacts.values(),"rank_spear_contacts":troop_contacts,"resolution":[root.size.x,root.size.y],"internal":root.scaling_3d_scale,
		"camera_start":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y],"software":RenderingServer.get_video_adapter_name(),
		"last":fact,"frames":snapshots,"inputs":notes,"first_game_frame":first_game_frame,"physics_fps":Engine.physics_ticks_per_second,"world_audit":field.theater.audit().is_empty()}
	var file:=FileAccess.open(OUT+"/input-and-camera.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(terminal,"  "))
	file.close()
	var ok:bool=screenshot_ok and b.ordinary_counts==PackedInt32Array([512,512]) and not entered_water and not off_lens and clear_count>=snapshots.size()*.98 and crossed.size()>0 and fact.hits[0]+fact.hits[1]>0
	if not preview: ok=ok and frames>=200 and first_blow>0 and contacts.size()>0
	print("BRIDGE_WINDOW ",ok," ",JSON.stringify(fact)," first_player_strike=",first_blow," contacts=",contacts.size()," frames=",frames)
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
