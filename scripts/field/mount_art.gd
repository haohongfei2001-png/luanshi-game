extends RefCounted
## Shared baked, single-surface horse and carriage meshes. +Z is the muzzle.
const COLLECTION := preload("res://assets/art/mounts/mounts.gltf")
const SURFACE := preload("res://scripts/field/mount_hide.gdshader")
const ATLAS := preload("res://assets/art/mounts/mount-atlas.png")
const SADDLE := Vector3(0.0,1.44,-0.04)
const BIT := Vector3(0.105,1.56,1.15)
const REIN_HAND := Vector3(0.17,1.594,0.24)
const CART_SEAT := Vector3(0.0,0.91,-1.83)
const AXLE := Vector3(0.0,0.55,-1.83)
static var _meshes: Dictionary={}
static var _hide: ShaderMaterial

static func mesh(draught: bool=false, close: bool=true) -> Mesh:
	if _meshes.is_empty():
		var library:=COLLECTION.instantiate()
		for node: MeshInstance3D in library.find_children("*","MeshInstance3D",true,false):
			_meshes[String(node.name)]=node.mesh
		library.free()
	var key:=("Draught" if draught else "Saddle")+("Close" if close else "Rank")
	return _meshes[key]

static func material() -> ShaderMaterial:
	if _hide==null:
		_hide=ShaderMaterial.new()
		_hide.shader=SURFACE
		_hide.set_shader_parameter("surface_atlas",ATLAS)
	return _hide

## stride is accumulated from *real* distance. Interpolate the last fixed step for matching hooves and wheels.
static func pose(state: int, progress: float, stride: float, travelled: float, alpha: float, flash: float=0.0, lot: int=0) -> Color:
	var phase:=fposmod(stride-(1.0-alpha)*travelled*0.68,1.0)
	var gait:=clampf(travelled/(0.05*4.0),0.0,1.0)
	return Color((state+0.5)/128.0,progress if state==7 else gait,phase,(float(posmod(lot,4))+.03+.92*clampf(flash,0.0,1.0))*.25)
