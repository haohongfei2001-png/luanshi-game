extends SceneTree
const Builder:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
func _initialize() -> void:
	var root_node:=Node3D.new()
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3.ZERO,Vector3.RIGHT,Vector3.BACK])
	var triangle:=ArrayMesh.new();triangle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	for i in 3:
		var instance:=MeshInstance3D.new();instance.mesh=triangle;root_node.add_child(instance)
	var cost:=Builder.template_cost(root_node)
	assert(cost.triangles==3 and cost.surfaces==3 and cost.mesh_nodes==3)
	assert(cost.actual_draw_calls=="NOT_MEASURED")
	root_node.free();print("WOODLAND_ACTUAL_RESOURCE_COST_PASS nonindexed_shared_mesh");quit()
