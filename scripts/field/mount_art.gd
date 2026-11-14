extends RefCounted
## Shared baked, single-surface horse and carriage meshes. +Z is the muzzle.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
const TACK := preload("res://assets/third_party/wildfire_remounts/native_tack.glb")
const REMOUNT := preload("res://assets/third_party/wildfire_remounts/complete_remount.glb")
const PIGMENTS := preload("res://assets/third_party/wildfire_remounts/horse_coats.png")
const MANE := preload("res://assets/third_party/wildfire_remounts/horse_hair.png")
const POSE_HI := preload("res://assets/third_party/wildfire_remounts/native_pose_hi.png")
const POSE_LO := preload("res://assets/third_party/wildfire_remounts/native_pose_lo.png")
const POSE_NORMAL := preload("res://assets/third_party/wildfire_remounts/native_pose_normal.png")
const SOCKETS := preload("res://assets/third_party/wildfire_remounts/native_sockets.json")
const SURFACE := preload("res://scripts/field/mount_hide.gdshader")
const ATLAS := preload("res://assets/art/mounts/mount-atlas.png")
const SADDLE := Vector3(0.0,1.44,-0.04)
const BIT := Vector3(0.105,1.56,1.15)
const REIN_HAND := Vector3(0.17,1.594,0.24)
const CART_SEAT := Vector3(0.0,0.91,-1.83)
const AXLE := Vector3(0.0,0.55,-1.83)
static var _meshes: Dictionary={}
static var _hide: ShaderMaterial
static var _saddle_frames: Array[Transform3D]=[]
static var _socket_texture: ImageTexture

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
	_prepare_sockets()
	if _hide==null:
		_hide=ShaderMaterial.new()
		_hide.shader=SURFACE
		_hide.set_shader_parameter("surface_atlas",ATLAS)
		_hide.set_shader_parameter("coat_pigments",PIGMENTS)
		_hide.set_shader_parameter("mane_ink",MANE)
		_hide.set_shader_parameter("native_pose_hi",POSE_HI)
		_hide.set_shader_parameter("native_pose_lo",POSE_LO)
		_hide.set_shader_parameter("native_pose_normal",POSE_NORMAL)
		_hide.set_shader_parameter("native_socket_pose",_socket_texture)
	return _hide

## stride is accumulated from *real* distance. Interpolate the last fixed step for matching hooves and wheels.
static func pose(state: int, progress: float, stride: float, travelled: float, alpha: float, flash: float=0.0, lot: int=0) -> Color:
	var phase:=fposmod(stride-(1.0-alpha)*travelled*0.68,1.0)
	var gait:=clampf(travelled/(0.05*4.0),0.0,1.0)
	return Color((state+0.5)/128.0,progress if state==7 else gait,phase,(float(posmod(lot,4))+.03+.92*clampf(flash,0.0,1.0))*.25)

## CPU riders and GPU tack sample exactly the same authored affine frames.
static func _prepare_sockets() -> void:
	if not _saddle_frames.is_empty():
		return
	var values:=PackedFloat32Array()
	var clips: Array=SOCKETS.data["frames"]
	for clip: Array in clips:
		for frame: Dictionary in clip:
			for title: String in ["saddle","head"]:
				var rows: Array=frame[title]
				for row: Array in rows:
					values.append_array(PackedFloat32Array(row))
				if title=="saddle":
					var basis:=Basis(Vector3(rows[0][0],rows[1][0],rows[2][0]),
						Vector3(rows[0][1],rows[1][1],rows[2][1]),
						Vector3(rows[0][2],rows[1][2],rows[2][2]))
					_saddle_frames.append(Transform3D(basis,Vector3(rows[0][3],rows[1][3],rows[2][3])))
	var pixels:=Image.create_from_data(6,66,false,Image.FORMAT_RGBAF,values.to_byte_array())
	_socket_texture=ImageTexture.create_from_image(pixels)

static func _affine_mix(a: Transform3D,b: Transform3D,weight: float) -> Transform3D:
	return Transform3D(Basis(a.basis.x.lerp(b.basis.x,weight),
		a.basis.y.lerp(b.basis.y,weight),a.basis.z.lerp(b.basis.z,weight)),
		a.origin.lerp(b.origin,weight))

static func saddle_pose(phase: float,gait: float) -> Transform3D:
	_prepare_sockets()
	var sample:=clampf(phase,0.,1.)*32.
	var first:=mini(floori(sample),31)
	var blend:=sample-float(first)
	var walk:=_affine_mix(_saddle_frames[first],_saddle_frames[first+1],blend)
	var trot:=_affine_mix(_saddle_frames[33+first],_saddle_frames[34+first],blend)
	var moving:=_affine_mix(walk,trot,smoothstep(.25,.90,gait))
	return _affine_mix(Transform3D.IDENTITY,moving,smoothstep(0.,.16,gait))
