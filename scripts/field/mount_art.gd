extends RefCounted
## Shared baked, single-surface horse and carriage meshes. +Z is the muzzle.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
const TACK := preload("res://assets/art/mounts/field_tack.glb")
const REMOUNT := preload("res://assets/third_party/wildfire_remounts/complete_remount.glb")
const PIGMENTS := preload("res://assets/third_party/wildfire_remounts/horse_coats.png")
const MANE := preload("res://assets/third_party/wildfire_remounts/horse_hair.png")
const POSE_HI := preload("res://assets/third_party/wildfire_remounts/native_pose_hi.png")
const POSE_LO := preload("res://assets/third_party/wildfire_remounts/native_pose_lo.png")
const POSE_NORMAL := preload("res://assets/third_party/wildfire_remounts/native_pose_normal.png")
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
		var animals:=FieldMeshes.meshes(REMOUNT)
		var tack:=FieldMeshes.meshes(TACK)
		for title: String in tack:
			var part: ArrayMesh=tack[title]
			var animal: ArrayMesh=animals["RemountClose" if title.ends_with("Close") else "RemountRank"]
			var body:=animal.surface_get_arrays(0)
			var gear:=part.surface_get_arrays(0)
			var offset: int=body[Mesh.ARRAY_VERTEX].size()
			for attr: int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
				var data=body[attr]
				data.append_array(gear[attr])
				body[attr]=data
			var index: PackedInt32Array=gear[Mesh.ARRAY_INDEX]
			for i in index.size(): index[i]+=offset
			var combined: PackedInt32Array=body[Mesh.ARRAY_INDEX]
			combined.append_array(index)
			body[Mesh.ARRAY_INDEX]=combined
			for attr: int in [Mesh.ARRAY_TANGENT,Mesh.ARRAY_COLOR,Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
				body[attr]=null
			var result:=ArrayMesh.new()
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,body)
			_meshes[title]=result
	var key:=("Draught" if draught else "Saddle")+("Close" if close else "Rank")
	return _meshes[key]

static func material() -> ShaderMaterial:
	if _hide==null:
		_hide=ShaderMaterial.new()
		_hide.shader=SURFACE
		_hide.set_shader_parameter("surface_atlas",ATLAS)
		_hide.set_shader_parameter("coat_pigments",PIGMENTS)
		_hide.set_shader_parameter("mane_ink",MANE)
		_hide.set_shader_parameter("native_pose_hi",POSE_HI)
		_hide.set_shader_parameter("native_pose_lo",POSE_LO)
		_hide.set_shader_parameter("native_pose_normal",POSE_NORMAL)
	return _hide

## stride is accumulated from *real* distance. Interpolate the last fixed step for matching hooves and wheels.
static func pose(state: int, progress: float, stride: float, travelled: float, alpha: float, flash: float=0.0, lot: int=0) -> Color:
	var phase:=fposmod(stride-(1.0-alpha)*travelled*0.68,1.0)
	var gait:=clampf(travelled/(0.05*4.0),0.0,1.0)
	return Color((state+0.5)/128.0,progress if state==7 else gait,phase,(float(posmod(lot,4))+.03+.92*clampf(flash,0.0,1.0))*.25)
