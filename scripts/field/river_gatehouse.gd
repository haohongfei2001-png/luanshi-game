extends RefCounted
## The permanent gate piers and each upper pitch come from the same authored model.
## Keep the original door, walkway, routes and sightline behaviour.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
const GATE := preload("res://assets/third_party/wildfire_gate/river_gate.glb")
const ATLAS := preload("res://assets/third_party/wildfire_gate/gate_clay_and_timber.png")

static func mount(parent: Node3D, wall_x: float, roofs: Array[Dictionary]) -> void:
	var meshes := FieldMeshes.meshes(GATE)
	var surface := StandardMaterial3D.new()
	surface.albedo_texture=ATLAS
	surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	surface.roughness=1.0
	surface.metallic_specular=.12
	surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	_place(parent,meshes["Piers"],surface,wall_x)
	var full:=_place(parent,meshes["WatchHall"],surface,wall_x)
	var halves: Array[Dictionary]=[]
	for side: int in [-1,1]:
		var half:=_place(parent,meshes["WestPitch" if side<0 else "EastPitch"],surface,wall_x)
		half.visible=false
		halves.append({"node":half,"normal":Vector3.RIGHT*side,"center":Vector3(wall_x+side*1.67,5.7,0),"w":1.62,"d":9.85})
	roofs.append({"node":full,"center":Vector3(wall_x,5.65,0),"w":3.30,"d":10.55,"pieces":halves})

static func _place(parent: Node3D,body: Mesh,surface: Material,wall_x: float) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.mesh=body
	node.material_override=surface
	node.position.x=wall_x
	parent.add_child(node)
	return node
