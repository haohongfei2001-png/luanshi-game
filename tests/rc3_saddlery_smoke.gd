extends SceneTree
const Art:=preload("res://scripts/field/mount_art.gd")
const Field:=preload("res://scripts/field/controller.gd")
var failures: Array[String]=[]
var field: Field
func check(ok: bool,meaning: String) -> void:
	if not ok: failures.append(meaning);push_error(meaning)
func _initialize() -> void:
	run.call_deferred()
func action(name: String) -> void:
	for press in [true,false]:
		var event:=InputEventAction.new()
		event.action=name
		event.pressed=press
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func frames(n: int) -> void:
	for i in n:
		await RenderingServer.frame_post_draw
func sample(label: String) -> void:
	await RenderingServer.frame_post_draw
	var file:=OS.get_environment("TAIL_ART_OUT")+"/"+label+".png"
	var img:=root.get_texture().get_image()
	check(img!=null and img.save_png(file)==OK,label+" render readback")
	var used:=field.view.horse.used+field.view.horse_rank.used
	print("MOUNT_SCREEN ",JSON.stringify({"label":label,"ordinary":[field.battle.ordinary_counts[0],field.battle.ordinary_counts[1]],"tick":field.battle.tick,"vehicle":field.battle.vehicle,"hits":field.battle.hits,"mounted_and_parked":used,"close":field.view.horse.used,"rank":field.view.horse_rank.used,"cart":field.view.cart.used,"px":[img.get_width(),img.get_height()],"scale":root.scaling_3d_scale,"shadows":field.map.sun.shadow_enabled,"zoom":field.camera.size,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_video_adapter_name()}))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_environment("TAIL_ART_OUT"))
	check(DisplayServer.get_name()!="headless","A real graphical display")
	for tow in [false,true]:
		for close in [true,false]:
			var mesh:=Art.mesh(tow,close)
			check(mesh!=null and mesh.get_surface_count()==1,"One drawable imported surface")
			if not mesh: continue
			var arrays:=mesh.surface_get_arrays(0)
			var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV2]
			var joints:={}
			for coord in uv: joints[floori(coord.x*32.0)]=true
			var expected= [0,1,2,3,4,11,12,14] if tow else [0,1,2,3,4,11,12]
			for group in expected: check(joints.has(group),"Imported mount joint %d"%group)
			print("MOUNT_ASSET ",JSON.stringify({"tow":tow,"close":close,"surface":mesh.get_surface_count(),"indices":arrays[Mesh.ARRAY_INDEX].size(),"joints":joints.keys(),"min":str(mesh.get_aabb().position),"max":str(mesh.get_aabb().end)}))
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await frames(3)
	for id in [1,2]:
		if id==2:
			field.new_muster(512)
			await frames(2)
		await action("field_deploy")
		await action("field_mount" if id==1 else "field_chariot")
		check(field.battle.vehicle==id,"The existing input path mounted the selected vehicle")
		var origin:=field.battle.hero.pos
		Input.action_press("move_right")
		await frames(24)
		Input.action_release("move_right")
		await frames(3)
		check(field.battle.hero.pos.distance_to(origin)>.15,"The mounted player advanced")
		await sample("saddle-field" if id==1 else "cart-field")
		field.camera.size=8.4
		field.follow=true
		await frames(5)
		await sample("saddle-near" if id==1 else "cart-near")
		field.camera.size=26.0
	if failures.is_empty():print("MOUNT_ART_PASS")
	else: print("MOUNT_ART_FAIL ",failures)
	quit(0 if failures.is_empty() else 1)
