extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var count:=0
	for cycle in 3:
		var packed:=load(args[0]) as PackedScene;var scene:=packed.instantiate();root.add_child(scene)
		assert(scene.get_meta("expected_profile_version")==Ground.AuthoredProfile.VERSION)
		var node:=scene.get_node("NativeLowGrassShoulders") as MultiMeshInstance3D
		var poses:Array[Transform3D]=node.get("authored_transforms")
		count=poses.size();assert(count>100 and count<1500)
		assert(node.multimesh and node.multimesh.instance_count==count)
		for index in count:
			var pose:Transform3D=poses[index];var p:=Vector2(pose.origin.x,pose.origin.z)
			assert(absf(p.y)>4.25 and not Ground.blocked(p,true,true))
			assert(absf(pose.origin.y-Surface.height(p))<.0001)
			assert(pose.basis.y.normalized().dot(Surface.normal_at(p))>.999)
		var material:StandardMaterial3D=(node.get("authored_mesh") as Mesh).surface_get_material(0) as StandardMaterial3D
		for key in ["albedo_texture","normal_texture","roughness_texture"]:
			var texture:=material.get(key) as Texture2D;assert(texture and texture.get_image().has_mipmaps())
		scene.free();packed=null
		await process_frame
	print("LOW_GRASS_SUPPORT_PASS opens=3 tufts=",count," physical_root_match=true protected_lane=true graphics=NOT_RUN")
	quit()
