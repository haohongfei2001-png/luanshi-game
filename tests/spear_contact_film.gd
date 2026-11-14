extends "res://tests/bridgehead_window.gd"
## Camera-only continuous capture; never changes actor pose, simulation or scenery.
## SPEAR_ACTOR/START/FRAMES/YAW/SIZE select a repeatable unobstructed view.
## Movie FPS is simulation time, NOT measured realtime rendering performance.
const Probe=preload("res://scripts/field/experimental/spear_probe.gd")
var probe:RefCounted

const FILM_OUT:="res://artifacts/spear-contact-film"

func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	field.carry=Battle.DT*.82
	field._draw_field()
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

func _instance(subject:Battle.Unit) -> Dictionary:
	var tier:int=field.view.lod_by_id[subject.id]
	var batch=field.view.groups[field.view._key(subject)+30*tier]
	var wanted:=subject.before.lerp(subject.pos,.82)
	var nearest:=-1
	var distance:=INF
	for i:int in batch.used:
		var origin:Vector3=batch.mesh.get_instance_transform(i).origin
		var d2:=Vector2(origin.x,origin.z).distance_squared_to(wanted)
		if d2<distance:
			distance=d2
			nearest=i
	if nearest<0 or distance>.0001: return {}
	var transform:Transform3D=batch.mesh.get_instance_transform(nearest)
	var data:Color=batch.mesh.get_instance_custom_data(nearest)
	var columns:Array=[]
	for column:Vector3 in [transform.basis.x,transform.basis.y,transform.basis.z,transform.origin]:
		columns.append([column.x,column.y,column.z])
	return {"tier":tier,"custom":[data.r,data.g,data.b,data.a],"transform":columns,"matching_origin_error_squared":distance,"index":nearest}


func _run() -> void:
	var actor:=int(OS.get_environment("SPEAR_ACTOR")) if OS.has_environment("SPEAR_ACTOR") else 548
	var start:=int(OS.get_environment("SPEAR_START")) if OS.has_environment("SPEAR_START") else 10
	var count:=int(OS.get_environment("SPEAR_FRAMES")) if OS.has_environment("SPEAR_FRAMES") else 41
	var yaw:=float(OS.get_environment("SPEAR_YAW")) if OS.has_environment("SPEAR_YAW") else PI*.75
	var size:=float(OS.get_environment("SPEAR_SIZE")) if OS.has_environment("SPEAR_SIZE") else 22.
	if start<0 or count<23 or count>200 or size<4.: quit(8);return
	for folder:String in [OUT,FILM_OUT,FILM_OUT+"/frames"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=await _open_match()
	if scene==null: quit(3);return
	var b:=field.battle
	if actor<0 or actor>=b.roster.size() or b.roster[actor].kit!=3 or b.roster[actor].mounted: quit(8);return
	while b.tick<start:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var rows:Array=[]
	var center:Vector2=b.roster[actor].pos
	var dimensions:=root.size
	if dimensions not in [Vector2i(2560,1440),Vector2i(3840,2160)]: quit(4);return
	for frame:int in count:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[actor]
		_set_view(center,size,yaw)
		var instance:=_instance(subject)
		if instance.is_empty(): quit(7);return
		var experiment:Dictionary={}
		if OS.get_environment("SPEAR_PROBE")=="1":
			if probe==null: probe=Probe.new()
			var tier:int=field.view.lod_by_id[subject.id]
			var batch=field.view.groups[field.view._key(subject)+30*tier]
			var index:int=instance["index"]
			var model:Transform3D=batch.mesh.get_instance_transform(index)
			var data:Color=batch.mesh.get_instance_custom_data(index)
			experiment=probe.draw(field.view,batch,index,model,data,(float(b.tick)+.82)*Battle.DT)
			# The probe supplies its own matching shadow; suppress only the old actor's caster.
			var caster_key:int=200+field.view._key(subject)+30*tier
			if field.view.groups.has(caster_key):
				var caster=field.view.groups[caster_key]
				for slot:int in caster.used:
					if caster.mesh.get_instance_transform(slot).origin.distance_squared_to(model.origin)<.000001:
						caster.mesh.set_instance_transform(slot,Transform3D(Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO),Vector3.ZERO))
		await RenderingServer.frame_post_draw
		var captured:=root.get_texture().get_image()
		if captured.get_size()!=dimensions: quit(4);return
		captured.save_png(FILM_OUT+"/frames/frame-%03d.png"%frame)
		rows.append({"tick":b.tick,"actor":actor,"kit":subject.kit,"team":subject.team,"state":subject.state,
			"timer":subject.timer,"duration":subject.duration,"move_slot":subject.move_slot,
			"position":[subject.pos.x,subject.pos.y],"hp":subject.hp,"impacts":subject.impacts,
			"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),
			"ordinary":Array(b.ordinary_counts).duplicate(),"facing":[subject.facing.x,subject.facing.y],
			"camera":[center.x,center.y,size,yaw],"instance":instance,"experiment":experiment})
	FileAccess.open(FILM_OUT+"/sequence.json",FileAccess.WRITE).store_string(JSON.stringify({
		"seed":Battle.SEED,"frames":count,"fps":20,"seconds":float(count)*Battle.DT,"size":[dimensions.x,dimensions.y],"scale":root.scaling_3d_scale,
		"realtime_performance_measurement":false,
		"internal_pixels":[roundi(dimensions.x*root.scaling_3d_scale),roundi(dimensions.y*root.scaling_3d_scale)],
		"selection":{"actor":actor,"start":start,"yaw":yaw,"camera_size":size},"index":rows},"  "))
	print("SPEAR_CONTACT_FILM ",JSON.stringify(rows[0])," last=",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
