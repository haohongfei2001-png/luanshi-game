extends "res://tests/field_contact_window.gd"
## First genuine left and right shield contacts. Never change an attack, actor or controller.
const PERIOD:=34
const PRIOR:=11
func _pick_sides() -> bool:
	var b:=field.battle
	var slots:={}
	for k in range(500):
		_step_neutral()
		if b.result!="" or field.paused: break
		for u in b.roster:
			if u.hero or u.officer or u.mounted or u.wall_post or u.kit!=7 or u.hp<=0.: continue
			if u.contact_tick!=b.tick or not u.contact_blocked or u.state!=Battle.State.GUARD: continue
			var v:=b.roster[u.contact_source]
			if v.kit in [5,6] or v.mounted or v.pos.distance_to(u.pos)>3.8: continue
			var label: String="right" if u.contact_side==1 else "left"
			if slots.has(label) or b.tick<=PRIOR: continue
			var middle:=u.pos.lerp(v.pos,.25)
			slots[label]={"side":label,"sign":u.contact_side,"tick":b.tick,"defender":u.id,"attacker":v.id,
				"at":[middle.x,middle.y],"facing":[u.facing.x,u.facing.y],"map":"河关"}
		if slots.size()==2: break
	if slots.size()!=2: return false
	var f:=FileAccess.open(directory+"/events.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(slots.values(),"  "));f.close()
	print("SHIELD_BRACE_EVENTS ",JSON.stringify(slots.values()))
	return true

func _take(events:Array) -> bool:
	var result:=true
	var receipt:=[]
	var b:=field.battle
	var last:=0
	for e in events: last=maxi(last,int(e.tick)+PERIOD-PRIOR-1)
	for t in range(1,last+1):
		_step_neutral()
		if t!=b.tick: return false
		for e in events:
			var index:=t-int(e.tick)+PRIOR
			if index<0 or index>=PERIOD: continue
			var u:=b.roster[int(e.defender)]
			var v:=b.roster[int(e.attacker)]
			var cx:float=e.at[0];var cz:float=e.at[1]
			field.carry=.65*Battle.DT
			for dir in 2:
				var yaw:float=LOOK if dir==0 else LOOK+PI
				_view(Vector2(cx,cz),22.,yaw)
				await RenderingServer.frame_post_draw
				var out:=root.get_texture().get_image()
				var prefix: String="%s/%s-%s-%02d"%[directory,e.side,"front" if dir==0 else "reverse",index]
				result=out.save_jpg(prefix+".jpg",.94)==OK and result
				if index in [PRIOR-2,PRIOR,PRIOR+2,PRIOR+4]: result=out.save_png(prefix+".png")==OK and result
				var defat:=Ground.unit_point(u.before.lerp(u.pos,.65))+Vector3.UP*1.20
				var face:=field.camera.unproject_position(defat)*Vector2(out.get_size())/root.get_visible_rect().size
				receipt.append({"tick":t,"index":index,"side":e.side,"dir":dir,"kit":u.kit,"id":u.id,
					"attacker":v.id,"state":u.state,"source_state":v.state,"received":u.received,"source_hits":v.impacts,
					"blocked":u.contact_blocked,"hit_side":u.contact_side,"contact_tick":u.contact_tick,
					"facing":[u.facing.x,u.facing.y],"hp":u.hp,"source_hp":v.hp,"pos":[u.pos.x,u.pos.y,v.pos.x,v.pos.y],
					"losses":Array(b.losses),"hits":Array(b.hits),"blocks":b.blocked_hits,"soldiers":Array(b.ordinary_counts),
					"camera":[field.camera.size,yaw,cx,cz],"px":[face.x,face.y],"pixels":[out.get_width(),out.get_height()]})
	var f:=FileAccess.open(directory+"/states.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(receipt,"  "));f.close()
	return result and receipt.size()==4*PERIOD

func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	directory="res://artifacts/shield-brace"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene);field=scene.field
	field.set_physics_process(false);field.set_process(false)
	field.hud.plan_requested.emit(1);field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416));await process_frame
	var ok:=field.battle.started and field.battle.ordinary_counts==PackedInt32Array([512,512])
	if "--find-shield-events" in OS.get_cmdline_user_args():
		ok=ok and _pick_sides()
	else:
		var rows=JSON.parse_string(FileAccess.get_file_as_string(directory+"/events.json"))
		ok=ok and rows is Array and await _take(rows)
	print("SHIELD_BRACE_WINDOW ",ok)
	scene.queue_free();await process_frame
	quit(0 if ok else 1)
