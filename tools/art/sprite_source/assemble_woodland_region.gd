extends SceneTree
## Source-family composition experiment. No legacy art and no gameplay writes.
const Ground:=preload("res://scripts/field/ground.gd")
const TREE_LAYOUT:=[
	# Northern edge is one linked canopy group, with an open gap toward the gate.
	[32.1,-14.8,1.22,-18.0],[37.7,-16.3,1.36,23.0],[41.2,-12.8,1.12,107.0],
	# Sparse near frame: crowns do not span the protected central travel lane.
	[34.0,15.7,1.28,-42.0],[41.0,19.0,1.42,68.0]]
const COMPLETE_TREE_LAYOUT:=[[32.1,-14.8,1.0,-18.0],[34.0,15.7,1.0,-42.0]]
const BUSH_LAYOUT:=[
	[31.5,-11.2,.70,12.0],[35.9,-12.9,.85,37.0],[40.8,-10.2,.62,-22.0],
	[33.8,12.3,.72,-20.0],[38.8,16.4,.8,55.0]]
func _initialize() -> void: run.call_deferred()
static func load_native(path:String) -> Node3D:
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	assert(doc.append_from_file(path,state)==OK,"Native source missing")
	var node:=doc.generate_scene(state) as Node3D;assert(node)
	# GLTFDocument's runtime images arrive without mip levels even when the
	# imported sampler requests them. Generate once per shared family, not per leaf.
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		for index in mesh.mesh.get_surface_count():
			var material:=mesh.mesh.surface_get_material(index).duplicate() as StandardMaterial3D
			for key:String in ["albedo_texture","normal_texture","roughness_texture"]:
				var texture:=material.get(key) as Texture2D
				if texture==null:continue
				var pixels:=texture.get_image()
				if pixels.is_compressed():assert(pixels.decompress()==OK)
				assert(pixels.generate_mipmaps(key=="normal_texture")==OK)
				assert(pixels.has_mipmaps())
				material.set(key,ImageTexture.create_from_image(pixels))
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mesh.mesh.surface_set_material(index,material)
	return node
static func template_cost(node:Node3D) -> Dictionary:
	var triangles:=0;var surfaces:=0;var nodes:=0
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		nodes+=1
		for surface in mesh.mesh.get_surface_count():
			assert(mesh.mesh.surface_get_primitive_type(surface)==Mesh.PRIMITIVE_TRIANGLES)
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			triangles+=(indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3
			surfaces+=1
	return {"triangles":triangles,"surfaces":surfaces,"mesh_nodes":nodes,"actual_draw_calls":"NOT_MEASURED"}
func own(node:Node,scene:Node) -> void:
	for child in node.get_children():child.owner=scene;own(child,scene)
func add_group(scene:Node3D,template:Node3D,layout:Array,label:String) -> void:
	var group:=Node3D.new();group.name=label;scene.add_child(group)
	for index in layout.size():
		var row:Array=layout[index];var p:=Vector2(row[0],row[1])
		assert(absf(p.y)>10.0,"Tree or understory encroaches on action route")
		var instance:=template.duplicate() as Node3D
		instance.name="%s_%02d"%[label,index];group.add_child(instance)
		instance.position=Vector3(p.x,Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p),p.y)
		instance.scale=Vector3.ONE*float(row[2]);instance.rotation.y=deg_to_rad(row[3])
		instance.set_meta("author_origin_preserved",true)
		instance.set_meta("placement_reason","north linked crown / south sparse frame; central route clear")
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size() in [3,4],"tree.glb bush.glb output.scn [--complete-tree-intake]")
	var whole_tree:=args.size()==4
	if whole_tree:assert(args[3]=="--complete-tree-intake")
	var tree:=load_native(args[0]);var bush:=load_native(args[1])
	var tree_cost:=template_cost(tree);var bush_cost:=template_cost(bush)
	var trees:=COMPLETE_TREE_LAYOUT if whole_tree else TREE_LAYOUT
	if whole_tree:
		assert(tree_cost.triangles==1599403,"Full-source tree count mismatch")
		var receipt_path:=args[0].get_base_dir().path_join("restoration.json")
		var receipt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
		assert(receipt.files.size()==11 and receipt.license=="CC0-1.0")
		for f:Dictionary in receipt.files:
			assert(FileAccess.get_sha256(args[0].get_base_dir().path_join(str(f.path)))==str(f.sha256),"Original tree source changed")
	var region:=Node3D.new();region.name="SpriteFamilyWoodland_PRODUCTION_EXPERIMENT";root.add_child(region)
	if Ground.authored_landform_enabled:
		region.set_script(load("res://scripts/field/experimental_landform_guard.gd"))
		region.set_meta("expected_profile_version",Ground.AuthoredProfile.VERSION)
	region.set_meta("composition","native-tree-and-shrub-source-identified; tree-sha256="+FileAccess.get_sha256(args[0]))
	region.set_meta("art_status","NOT_ACCEPTED; GODOT_GRAPHICS_NOT_RUN")
	region.set_meta("tree_resource_cost",tree_cost);region.set_meta("bush_resource_cost",bush_cost)
	region.set_meta("source_tree_sha256",FileAccess.get_sha256(args[0]))
	region.set_meta("source_bush_sha256",FileAccess.get_sha256(args[1]))
	region.set_meta("scope","Woodland family only; not complete battlefield or terrain")
	if whole_tree:
		region.set_meta("composition","two-complete-original-mature-trees-no-leaf-inflation; diagnostic NOT completed woodland")
		region.set_meta("known_limit","Tree trunk navigation footprints not integrated; no complete collision or forest performance acceptance")
	add_group(region,tree,trees,"CanopyEdge");add_group(region,bush,BUSH_LAYOUT,"UnderstoryEdge")
	own(region,region)
	var packed:=PackedScene.new();assert(packed.pack(region)==OK)
	assert(ResourceSaver.save(packed,args[2])==OK)
	print("WOODLAND_REGION_EXPORTED ",JSON.stringify({"trees":trees.size(),"bushes":BUSH_LAYOUT.size(),"nominal_triangles":trees.size()*int(tree_cost.triangles)+BUSH_LAYOUT.size()*int(bush_cost.triangles),"actual_draw_calls":"NOT_MEASURED","graphics":"NOT_RUN","output":args[2]}))
	tree.free();bush.free();region.free();quit()
