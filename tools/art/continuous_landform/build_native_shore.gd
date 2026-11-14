extends SceneTree
## Two complete professional scan ledges, uniformly scaled, never a stone scatter.
## Explicit isolated study; build terrain with the same updated shared profile.
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const SOURCE:="res://assets/river_gate/world/masters/coastal_cliff_02/coastal_cliff_02.gltf"
func _initialize() -> void: run.call_deferred()
func own(node:Node,scene:Node) -> void:
	for child in node.get_children():child.owner=scene;own(child,scene)
func run() -> void:
	assert(Ground.authored_landform_enabled,"Requires new shared terrain support")
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/continuous_landform/shore_source.json"))
	for entry:Dictionary in manifest.files:
		assert(FileAccess.get_sha256("res://"+str(entry.path))==str(entry.sha256),"Native source differs from frozen derivative")
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	assert(doc.append_from_file(SOURCE,state)==OK)
	var template:=doc.generate_scene(state) as Node3D
	var scene:=Node3D.new();scene.name="NativeShoreShelf_EXPERIMENT";root.add_child(scene)
	scene.set_script(load("res://scripts/field/experimental_landform_guard.gd"))
	scene.set_meta("composition","two-full-professional-scan-shelves-NOT_ART_ACCEPTED")
	scene.set_meta("expected_profile_version",Ground.AuthoredProfile.VERSION)
	scene.set_meta("source","Poly Haven coastal_cliff_02 / Rob Tuytel / CC0 / explicitly reused existing derivative")
	scene.set_meta("source_gltf_sha256",FileAccess.get_sha256(SOURCE))
	var vertices:=0;var exposed:=0;var walkable_exposed:=0;var face_samples:=0;var reachable_faces:=0
	for side in [-1.,1.]:
		var instance:=template.duplicate() as Node3D;scene.add_child(instance)
		instance.name="CompleteShoreShelf_North" if side<0 else "CompleteShoreShelf_South"
		instance.position=Vector3(27.4,-1.65,side*13.7)
		instance.rotation.y=-PI/2.;instance.scale=Vector3.ONE*.25
		for mesh:MeshInstance3D in instance.find_children("*","MeshInstance3D",true,false):
			for index in mesh.mesh.get_surface_count():
				var material:=mesh.mesh.surface_get_material(index).duplicate() as StandardMaterial3D
				var texture:=material.albedo_texture
				if texture:
					var pixels:=texture.get_image()
					if pixels.is_compressed():assert(pixels.decompress()==OK)
					assert(pixels.generate_mipmaps()==OK);material.albedo_texture=ImageTexture.create_from_image(pixels)
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				# Original geometry/UV/albedo are retained; no extra AO multiplication.
				mesh.set_surface_override_material(index,material)
				var arrays:=mesh.mesh.surface_get_arrays(index)
				var world_vertices:=PackedVector3Array()
				for v:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					var world:Vector3=mesh.global_transform*v;var p:=Vector2(world.x,world.z)
					world_vertices.append(world)
					assert(absf(p.y)>7.5,"Scan encroaches on military bridge lane")
					vertices+=1
					if world.y>Surface.height(p)+.03:
						exposed+=1
						if not Ground.blocked(p,true,true):walkable_exposed+=1
				var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				for i in range(0,indices.size(),3):
					var centre:Vector3=(world_vertices[indices[i]]+world_vertices[indices[i+1]]+world_vertices[indices[i+2]])/3.
					var p:=Vector2(centre.x,centre.z);face_samples+=1
					if not Ground.blocked(p,true,true) and centre.y>Surface.height(p)+.03:reachable_faces+=1
			mesh.create_trimesh_collision()
	print("NATIVE_SHORE_SUPPORT_AUDIT ",JSON.stringify({"vertices":vertices,"exposed":exposed,"walkable_exposed":walkable_exposed,"face_samples":face_samples,"reachable_faces":reachable_faces,"graphics":"NOT_RUN"}))
	if not (exposed>0 and exposed<vertices*.95) or walkable_exposed!=0 or reachable_faces!=0:
		push_error("SHORE_SUPPORT_MISMATCH: require buried backing and zero reachable visual-only ledges")
		template.free();scene.free();quit(1);return
	own(scene,scene);var packed:=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,args[0])==OK)
	template.free();scene.free();quit()
