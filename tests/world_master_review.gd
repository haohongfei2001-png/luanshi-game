extends SceneTree
## Deterministic real-game stills. The complete battle advances between views.
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const OUT:="res://docs/evidence/river-whole-rebuild/review"
var field
var records:Array=[]
var source_sha:=OS.get_environment("WORLD_SOURCE_SHA")
func _initialize() -> void:
	_run.call_deferred()
func _snap(label:String,point:Vector2,zoom:float) -> void:
	field.camera_yaw=deg_to_rad(-33.)
	field.camera.size=zoom
	field.pan_to(point)
	field._process(Battle.DT)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	assert(pic.get_size()==root.size)
	assert(is_equal_approx(root.scaling_3d_scale,1.0))
	var native_size:=pic.get_size()
	pic.save_png(OUT+"/"+label+".png")
	pic.save_jpg(OUT+"/"+label+".jpg",.94)
	pic.resize(1440,810,Image.INTERPOLATE_LANCZOS)
	pic.save_jpg(OUT+"/"+label+"-preview.jpg",.93)
	var b=field.battle
	var row:={"source_sha":source_sha,"pixels":[native_size.x,native_size.y],"preview_px":[pic.get_width(),pic.get_height()],"native_window":[root.size.x,root.size.y],"msaa":root.msaa_3d,"shadow_mode":field.map.sun.directional_shadow_mode,"shadow_pancake":field.map.sun.directional_shadow_pancake_size,"shadow_enabled":field.map.sun.shadow_enabled,"sun_degrees":str(field.map.sun.rotation_degrees),"shadow_distance":field.map.sun.directional_shadow_max_distance,"frame":label,"seed":Battle.SEED,"tick":b.tick,"ordinary":Array(b.ordinary_counts),"hits":b.hits.duplicate(),"center":[point.x,point.y],"zoom":zoom,"internal":root.scaling_3d_scale,"world_audit":field.theater.audit(),"renderer":RenderingServer.get_video_adapter_name()}
	records.append(row)
	print("WORLD_MASTER_FRAME ",JSON.stringify(row))
func _inventory() -> void:
	for path:String in [field.map.WOODLAND]:
		var packed:Node3D=(load(path) as PackedScene).instantiate()
		var members:Array=[packed]
		members.append_array(packed.find_children("*","MeshInstance3D",true,false))
		var parts:Array=[]
		for node:Node in members:
			if not node is MeshInstance3D:continue
			var mesh:Mesh=node.mesh
			var materials:Array=[]
			for i in mesh.get_surface_count():
				var m:=mesh.surface_get_material(i)
				if m is StandardMaterial3D:
					materials.append({"name":m.resource_name,"transparency":m.transparency,"color":str(m.albedo_color),"scissor":m.alpha_scissor_threshold,"texture":m.albedo_texture.resource_path if m.albedo_texture else ""})
				elif m is ShaderMaterial:
					materials.append({"shader":m.shader.resource_path,"botanical_part":m.get_shader_parameter("botanical_part")})
			parts.append({"name":node.name,"aabb":str(mesh.get_aabb()),"surfaces":mesh.get_surface_count(),"materials":materials})
		print("WORLD_PLANT_SOURCE ",JSON.stringify({"path":path,"root_type":packed.get_class(),"parts":parts}))
		packed.free()
	var instances:Array=[]
	for node:Node in field.map.get_children():
		if String(node.name).begins_with("WholeBroadleaf"):
			instances.append({"name":node.name,"position":str(node.position),"children":node.get_child_count()})
	print("WORLD_PLANT_INSTANCES ",JSON.stringify(instances))
func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.hud.plan_requested.emit(5)
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.go.pressed.emit()
	assert(field.battle.started and field.battle.bridgehead)
	_inventory()
	assert(field.map._land_height(Vector2(Ground.MOAT_X,12.))<Ground.BATTLE_WATER_LEVEL,"The actual moat bed must remain below its visible water")
	assert(field.map._land_height(Vector2(Ground.RIVER_X,12.))<Ground.BATTLE_WATER_LEVEL,"The river bed must remain below its visible water")
	for tick in 50:field._physics_process(Battle.DT)
	await _snap("bridgehead-0050",Ground.BRIDGE_VIEW,22.)
	for tick in 85:field._physics_process(Battle.DT)
	await _snap("bridgehead-0135",Ground.BRIDGE_VIEW,22.)
	await _snap("whole-war-0135",Vector2(9.,0.),115.)
	await _snap("grove-0135",Vector2(38.,-10.),18.)
	await _snap("gate-architecture",Vector2(48.,0.),18.)
	await _snap("settled-fort",Vector2(89.,2.),48.)
	await _snap("western-woodland",Vector2(-83.,-33.),42.)
	var previous_lod:=root.mesh_lod_threshold
	root.mesh_lod_threshold=0.
	await _snap("native-crowns-full-geometry",Vector2(38.,-10.),18.)
	root.mesh_lod_threshold=previous_lod
	field.map.sun.rotation_degrees=Vector3(-48.,-31.,0.)
	await _snap("previous-daylight",Ground.BRIDGE_VIEW,22.)
	field.map.sun.rotation_degrees=Vector3(-48.,58.,0.)
	root.size=Vector2i(3840,2160)
	await process_frame
	await _snap("bridgehead-0135-uhd",Ground.BRIDGE_VIEW,22.)
	var file:=FileAccess.open(OUT+"/frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	print("WORLD_MASTER_STILLS ",field.theater.audit().is_empty())
	scene.queue_free()
	await process_frame
	quit(0)
