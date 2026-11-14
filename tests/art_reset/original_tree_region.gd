extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Builder:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(Ground.authored_landform_enabled);var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	for cycle in 3:
		var scene:=packed.instantiate() as Node3D;root.add_child(scene)
		assert(scene.get_meta("expected_profile_version")==Ground.AuthoredProfile.VERSION)
		var canopy:=scene.get_node("CanopyEdge");assert(canopy.get_child_count()==2)
		var resources:={};var sum_triangles:=0
		for tree:Node3D in canopy.get_children():
			var p:=Vector2(tree.position.x,tree.position.z)
			assert(absf(p.y)>10. and absf(tree.position.y-Surface.height(p))<.0001)
			assert(tree.scale==Vector3.ONE,"No hidden source scale/leaf inflation")
			sum_triangles+=Builder.template_cost(tree).triangles
			for mesh:MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
				resources[mesh.mesh.get_instance_id()]=true
				assert(mesh.mesh.get_surface_count()==3)
				for i in 3:
					var m:=mesh.mesh.surface_get_material(i) as StandardMaterial3D
					for texture:Texture2D in [m.albedo_texture,m.normal_texture,m.roughness_texture]:assert(texture and texture.get_image().has_mipmaps())
		assert(resources.size()==1 and sum_triangles==3198806)
		scene.free();await process_frame
	print("ORIGINAL_TREE_REGION_PASS opens=3 trees=2 unique_tree_mesh=1 full_tree_triangles=3198806 PBR_sets=3 graphics=NOT_RUN navigation_trunks=NOT_INTEGRATED")
	quit()
