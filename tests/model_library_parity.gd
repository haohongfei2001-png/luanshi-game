extends SceneTree
## Run headless. Every directly read mesh must be the same resource used by the imported scene.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
func _initialize() -> void:
	var total:=0
	for library: PackedScene in [preload("res://assets/river_gate/figures/river_company.glb"),
			preload("res://assets/river_gate/figures/field_garments.gltf"),
			preload("res://assets/third_party/wildfire_garments/field_issues.glb"),
			preload("res://assets/river_gate/figures/garrison_bodies.glb"),
			preload("res://assets/environment/bank-willows.gltf"),
			preload("res://assets/environment/quaternius/grove.glb"),
			preload("res://assets/art/mounts/field_tack.glb"),
			preload("res://assets/third_party/wildfire_remounts/hide.glb")]:
		var actual:=FieldMeshes.meshes(library)
		var root_node:=library.instantiate()
		var expected:=root_node.find_children("*","MeshInstance3D",true,false)
		if actual.is_empty() or actual.size()!=expected.size():
			push_error("Mesh count mismatch in "+library.resource_path)
			root_node.free()
			quit(1)
			return
		for node: MeshInstance3D in expected:
			if actual.get(String(node.name))!=node.mesh:
				push_error("Different mesh at "+library.resource_path+" "+String(node.name))
				root_node.free()
				quit(1)
				return
		total+=actual.size()
		root_node.free()
	print("MESH_LIBRARY_PARITY ",total)
	quit()
