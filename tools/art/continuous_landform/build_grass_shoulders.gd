extends SceneTree
## Authored road-edge density fields from one complete native five-blade tuft.
## This distribution is new project work, not a recovered original film layout.
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const Native:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
const PATCHES:=[
	Vector4(31.3,-5.7,2.8,1.5),Vector4(37.,-6.5,4.2,1.4),Vector4(43.,-5.9,2.8,1.6),
	Vector4(31.3,5.7,2.8,1.5),Vector4(37.,6.5,4.2,1.4),Vector4(43.,5.9,2.8,1.6),
	Vector4(30.3,-12.7,1.7,4.3),Vector4(30.3,12.7,1.7,4.3)]
func _initialize() -> void: run.call_deferred()
static func density(p:Vector2) -> float:
	var result:=0.
	for patch:Vector4 in PATCHES:
		var q:=(p-Vector2(patch.x,patch.y))/Vector2(patch.z,patch.w)
		result=maxf(result,pow(maxf(0.,1.-q.length_squared()),1.5))
	return result*.85
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==2,"grass.glb output.scn")
	var template:=Native.load_native(args[0]);var meshes:=template.find_children("*","MeshInstance3D",true,false)
	assert(meshes.size()==1)
	var mesh:Mesh=meshes[0].mesh;var cost:=Native.template_cost(template)
	var rng:=RandomNumberGenerator.new();rng.seed=61112
	var poses:Array[Transform3D]=[];var max_height:=0.
	for iz in range(-65,66):
		for ix in range(104,174):
			var p:=Vector2(ix,iz)*.27+Vector2(rng.randf_range(-.09,.09),rng.randf_range(-.09,.09))
			if absf(p.y)<4.25 or rng.randf()>density(p) or Ground.blocked(p,true,true):continue
			var y:=Surface.height(p);var up:=Surface.normal_at(p)
			if y<Ground.BATTLE_WATER_LEVEL+.25 or up.y<.75:continue
			var yaw:=rng.randf_range(-PI,PI);var forward:=Vector3(sin(yaw),0.,cos(yaw))
			var right:=up.cross(forward).normalized();forward=right.cross(up).normalized()
			# Explicit metric retarget: native .108 BU high tuft becomes .11-.17m.
			var scale:=rng.randf_range(1.,1.6)
			poses.append(Transform3D(Basis(right,up,forward).scaled(Vector3.ONE*scale),Vector3(p.x,y,p.y)))
			max_height=maxf(max_height,mesh.get_aabb().size.y*scale)
	assert(poses.size()>100 and poses.size()<1500)
	var scene:=Node3D.new();scene.name="RoadShoulderLowGrass_EXPERIMENT";root.add_child(scene)
	scene.set_script(load("res://scripts/field/experimental_landform_guard.gd"))
	scene.set_meta("expected_profile_version",Ground.AuthoredProfile.VERSION)
	scene.set_meta("composition","authored-eight-road-shoulder-fields-native-five-blade-grass")
	scene.set_meta("source_glb_sha256",FileAccess.get_sha256(args[0]))
	scene.set_meta("source_units","explicit retarget, not assertion that author BU equals metre")
	scene.set_meta("art_status","NOT_ACCEPTED; whole-game pixels NOT_RUN")
	var node:=MultiMeshInstance3D.new();node.name="NativeLowGrassShoulders"
	node.set_script(load("res://scripts/field/authored_grass_instances.gd"))
	node.set("authored_mesh",mesh);node.set("authored_transforms",poses)
	scene.add_child(node);node.owner=scene
	# Do not serialize dummy-server GPU state; _ready reconstructs from the
	# independently persistent authored mesh/transform data in real rendering.
	node.multimesh=null
	var packed:=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,args[1])==OK)
	print("NATIVE_GRASS_SHOULDERS_BUILT ",JSON.stringify({"tufts":poses.size(),"source_triangles":cost.triangles,"nominal_triangles":poses.size()*int(cost.triangles),"actual_draw_calls":"NOT_MEASURED","max_height_m":max_height,"central_lane":"CLEAR","graphics":"NOT_RUN"}))
	template.free();scene.free();quit()
