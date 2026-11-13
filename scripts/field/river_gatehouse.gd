extends RefCounted
## The permanent gate piers and each upper pitch come from the same authored model.
## Keep the original door, walkway, routes and sightline behaviour.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
const GATE := preload("res://assets/third_party/wildfire_gate/river_gate.glb")
const TOWER := preload("res://assets/third_party/wildfire_gate/corner_tower.glb")
const ATLAS := preload("res://assets/third_party/wildfire_gate/gate_clay_and_timber.png")

static var atlas_material: StandardMaterial3D

static var corner_material: StandardMaterial3D

static func _postern_masonry() -> StandardMaterial3D:
	if corner_material: return corner_material
	corner_material=_stone_and_tiles().duplicate() as StandardMaterial3D
	corner_material.albedo_color=Color("d4cbbd")
	corner_material.vertex_color_use_as_albedo=false
	return corner_material

static func _stone_and_tiles() -> StandardMaterial3D:
	if atlas_material: return atlas_material
	var surface := StandardMaterial3D.new()
	surface.albedo_texture=ATLAS
	surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	surface.roughness=1.0
	surface.metallic_specular=.12
	surface.cull_mode=BaseMaterial3D.CULL_DISABLED
	atlas_material=surface
	return surface

static func mount(parent: Node3D, wall_x: float, roofs: Array[Dictionary]) -> void:
	var meshes:=FieldMeshes.meshes(GATE)
	var surface:=_stone_and_tiles()
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

static func mount_corner(parent: Node3D, footing: Vector3, roofs: Array[Dictionary]) -> void:
	var parts:=FieldMeshes.meshes(TOWER)
	var stone:=_place(parent,parts["CornerBatter"],_postern_masonry(),footing.x)
	stone.position=footing
	var gallery:=_place(parent,parts["CornerGallery"],_postern_masonry(),footing.x)
	gallery.position=footing
	roofs.append({"node":gallery,"center":footing+Vector3.UP*5.65,"w":2.58,"d":2.64})

static func mount_curtain(parent: Node3D, start: Vector3, finish: Vector3) -> void:
	var part: ArrayMesh=FieldMeshes.meshes(TOWER)["CurtainWalk"]
	var delta:=finish-start
	var distance:=delta.length()
	var count:=maxi(1,roundi(distance/20.0))
	var step:=delta/float(count)
	for section in count:
		var stone:=_place(parent,part,_postern_masonry(),0.)
		stone.rotation.y=atan2(delta.x,delta.z)
		stone.scale.z=distance/(20.0*count)
		stone.position=start+step*(section+.5)
