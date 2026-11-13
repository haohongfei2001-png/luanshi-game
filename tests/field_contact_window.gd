extends "res://tests/river_art_capture.gd"
## A replay of two contacts between existing soldiers. Only the camera is moved.
const PLAN_FILE := "res://artifacts/contact-plan.json"
const OUTPUT := "res://artifacts/contact-window"
const LOOK := -.576
var moments: Array=[]

func _step_neutral() -> void:
	# The hero stands at muster in both passes. Restoring the input camera before
	# every simulation step makes the cursor ray identical in both game versions.
	field.carry=0.0
	field.camera_yaw=LOOK
	field.camera.size=22.
	field.pan_to(field.battle.hero.pos)
	field._physics_process(Battle.DT)

func _choose() -> bool:
	var b:=field.battle
	var found: Dictionary={}
	for repeat in 560:
		_step_neutral()
		if b.result!="" or field.paused: break
		for u in b.roster:
			# get() lets this recorder replay the chosen IDs on the previous game.
			if u.get("contact_tick")!=b.tick or u.officer or u.hero or u.mounted or u.wall_post: continue
			if u.hp<=0. or u.get("contact_source")==null: continue
			var source_id:int=int(u.get("contact_source"))
			if source_id<0: continue
			var v:=b.roster[source_id]
			if v.kit in [5,6] or v.mounted or v.pos.distance_to(u.pos)>3.8: continue
			var kind:=""
			if u.kit==7 and u.get("contact_blocked") and u.state==Battle.State.GUARD:
				kind="shield"
			elif not u.get("contact_blocked") and u.state==Battle.State.STAGGER:
				kind="stagger"
			if kind=="" or found.has(kind): continue
			var center:=u.pos.lerp(v.pos,.29)
			found[kind]={"kind":kind,"tick":b.tick,"defender":u.id,"attacker":v.id,
				"side":int(u.get("contact_side")),"center":[center.x,center.y]}
		if found.size()==2: break
	if found.size()!=2:
		push_error("Missing a genuine contact: "+str(found));return false
	var result:Array=found.values()
	var handle:=FileAccess.open(PLAN_FILE,FileAccess.WRITE)
	handle.store_string(JSON.stringify(result))
	print("FIELD_CONTACT_PLAN "+JSON.stringify(result))
	return true

func _record(events: Array) -> bool:
	if events.size()!=2: return false
	var b:=field.battle
	var last:=0
	for e in events: last=maxi(last,int(e.tick)+11)
	for tick in range(1,last+1):
		_step_neutral()
		if b.tick!=tick: return false
		for e in events:
			var offset:=tick-int(e.tick)
			if offset < -6 or offset > 11: continue
			var u:=b.roster[int(e.defender)]
			var v:=b.roster[int(e.attacker)]
			var center:=Vector2(float(e.center[0]),float(e.center[1]))
			field.carry=.65*Battle.DT
			_view(center,22.,LOOK)
			await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image()
			if frame.save_jpg("%s/%s-%02d.jpg"%[OUTPUT,e.kind,offset+6],.94)!=OK: return false
			# Native matching close-ups complement the entire 22 m film.
			if offset in [-2,0,1,3,5]:
				_view(center,9.5,LOOK)
				await RenderingServer.frame_post_draw
				if root.get_texture().get_image().save_png("%s/%s-native-%02d.png"%[OUTPUT,e.kind,offset+6])!=OK: return false
			moments.append({"tick":tick,"kind":e.kind,"defender":u.id,"attacker":v.id,
				"hp":u.hp,"source_hp":v.hp,"received":u.received,"impacts":v.impacts,"state":u.state,
				"pos":[u.pos.x,u.pos.y,v.pos.x,v.pos.y],"hits":Array(b.hits),"blocked":b.blocked_hits,
				"losses":Array(b.losses),"ordinary":Array(b.ordinary_counts)})
	var out:=FileAccess.open(OUTPUT+"/states.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(moments))
	return moments.size()==36

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	var ok:=field.battle.started and field.battle.ordinary_counts==PackedInt32Array([512,512])
	if "--find-contact-plan" in OS.get_cmdline_user_args():
		ok=ok and _choose()
	else:
		var plan=JSON.parse_string(FileAccess.get_file_as_string(PLAN_FILE))
		ok=ok and plan is Array and await _record(plan)
	print("FIELD_CONTACT_WINDOW "+str(ok))
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
