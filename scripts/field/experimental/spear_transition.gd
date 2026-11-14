extends RefCounted
## Opt-in single-actor research only. Additive world-space pose inertialization.
## Does not freeze feet or change simulation. Affine strain is measured, not hidden.
const BONES:=16
const DURATION:=.15
var previous:Array[Transform3D]=[]
var residual:Array[Transform3D]=[]
var previous_clip:=-1
var previous_time:=-1.
var started:=-1.

static func zero_matrix() -> Transform3D:
	return Transform3D(Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO),Vector3.ZERO)

static func difference(a:Transform3D,b:Transform3D) -> Transform3D:
	return Transform3D(Basis(a.basis.x-b.basis.x,a.basis.y-b.basis.y,a.basis.z-b.basis.z),a.origin-b.origin)

static func scaled(a:Transform3D,weight:float) -> Transform3D:
	return Transform3D(Basis(a.basis.x*weight,a.basis.y*weight,a.basis.z*weight),a.origin*weight)

static func plus(a:Transform3D,b:Transform3D) -> Transform3D:
	return Transform3D(Basis(a.basis.x+b.basis.x,a.basis.y+b.basis.y,a.basis.z+b.basis.z),a.origin+b.origin)

static func decay(age:float) -> float:
	var t:=clampf(age/DURATION,0.,1.)
	return 1.-t*t*t*(10.+t*(-15.+6.*t))

func sample(poses:Array[Transform3D],model:Transform3D,clip:int,time:float) -> Array[Transform3D]:
	assert(poses.size()==BONES)
	# A culled/reappearing actor or time rewind must not inherit stale contact.
	if previous_time<0. or time<previous_time or time-previous_time>.2:
		previous.clear()
		residual.clear()
		previous_clip=-1
	var world:Array[Transform3D]=[]
	for pose:Transform3D in poses: world.append(model*pose)
	if clip!=previous_clip and not previous.is_empty():
		residual.clear()
		for i:int in BONES: residual.append(difference(previous[i],world[i]))
		started=time
	var weight:=decay(time-started) if started>=0. else 0.
	var inverse_basis:=model.basis.inverse()
	var local:Array[Transform3D]=[]
	previous.clear()
	for i:int in BONES:
		var offset:=scaled(residual[i],weight) if residual.size()==BONES else zero_matrix()
		previous.append(plus(world[i],offset))
		# A delta is a vector, so omit the inverse model's translation.
		local.append(Transform3D(inverse_basis*offset.basis,inverse_basis*offset.origin))
	previous_time=time
	previous_clip=clip
	return local

static func upload(material:ShaderMaterial,offsets:Array[Transform3D]) -> void:
	var x:=PackedVector4Array()
	var y:=PackedVector4Array()
	var z:=PackedVector4Array()
	for m:Transform3D in offsets:
		x.append(Vector4(m.basis.x.x,m.basis.y.x,m.basis.z.x,m.origin.x))
		y.append(Vector4(m.basis.x.y,m.basis.y.y,m.basis.z.y,m.origin.y))
		z.append(Vector4(m.basis.x.z,m.basis.y.z,m.basis.z.z,m.origin.z))
	material.set_shader_parameter("spear_delta_x",x)
	material.set_shader_parameter("spear_delta_y",y)
	material.set_shader_parameter("spear_delta_z",z)
