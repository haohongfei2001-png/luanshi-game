extends RefCounted
## Imported model libraries store their ArrayMesh resources in the PackedScene.
## Reading them directly avoids creating and immediately destroying render instances
## in the middle of first-launch shader and pipeline compilation.
static func meshes(library: PackedScene) -> Dictionary:
	var result := {}
	var state := library.get_state()
	for node_index in state.get_node_count():
		if state.get_node_type(node_index) != &"MeshInstance3D":
			continue
		for property_index in state.get_node_property_count(node_index):
			if state.get_node_property_name(node_index,property_index) == &"mesh":
				var mesh: ArrayMesh = state.get_node_property_value(node_index,property_index)
				result[String(state.get_node_name(node_index))] = mesh
				break
	return result
