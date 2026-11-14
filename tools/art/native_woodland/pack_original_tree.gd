extends SceneTree
## Exact complete source diagnostic, never default game or a shipping army forest.
const Native:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
func _initialize() -> void: run.call_deferred()
func own(node:Node,scene:Node) -> void:
	for child in node.get_children():child.owner=scene;own(child,scene)
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==2,"verified original directory, output.scn")
	var source:=args[0];var receipt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source.path_join("restoration.json")))
	assert(receipt.files.size()==11 and receipt.license=="CC0-1.0")
	for f:Dictionary in receipt.files:
		assert(FileAccess.get_sha256(source.path_join(str(f.path)))==str(f.sha256),"Original source not verified")
	var tree:=Native.load_native(source.path_join("island_tree_01_2k.gltf"));tree.name="OriginalMatureTree_FULL_SOURCE_DIAGNOSTIC"
	root.add_child(tree);var cost:=Native.template_cost(tree)
	assert(cost.triangles==1599403,"Not complete original tree source")
	tree.set_meta("source","Poly Haven island_tree_01 / Rico Cilliers and Rob Tuytel / CC0")
	tree.set_meta("status","NOT_ART_ACCEPTED; full source quality baseline, NOT final real-time LOD")
	tree.set_meta("source_receipt_sha256",FileAccess.get_sha256(source.path_join("restoration.json")))
	tree.set_meta("cost",cost);tree.set_meta("source_scale","original GLTF metre-scale, no leaf inflation or mesh normalization")
	own(tree,tree);var packed:=PackedScene.new();assert(packed.pack(tree)==OK);assert(ResourceSaver.save(packed,args[1])==OK)
	var instances:=0;var triangles:=0
	var reloaded:=load(args[1]) as PackedScene;assert(reloaded)
	var copy:=reloaded.instantiate() as Node3D
	for part:MeshInstance3D in copy.find_children("*","MeshInstance3D",true,false):
		instances+=1
		for index in part.mesh.get_surface_count():
			var m:=part.mesh.surface_get_material(index) as StandardMaterial3D
			assert(m and m.albedo_texture and m.normal_texture and m.roughness_texture)
			assert(m.albedo_texture.get_image().has_mipmaps() and m.normal_texture.get_image().has_mipmaps())
	triangles=Native.template_cost(copy).triangles;assert(triangles==1599403)
	print("ORIGINAL_TREE_PACKED ",JSON.stringify({"meshes":instances,"triangles":triangles,"packed_bytes":FileAccess.get_file_as_bytes(args[1]).size(),"packed_sha256":FileAccess.get_sha256(args[1]),"materials":"all three original PBR sets; explicit mipmaps","graphics":"NOT_RUN","quality":"NOT_ACCEPTED","runtime_budget":"NOT_MEASURED"}))
	copy.free();tree.free();quit()
