extends RefCounted
## A company's signal is one curved textile attached to the bearer's staff.
## Both standards use one MultiMesh each; cloth deformation follows the battle clock.
const Builder := preload("res://scripts/field/mesh_builder.gd")
const CLOTH_SHADER := preload("res://scripts/field/field_standard.gdshader")

static func material(garrison: bool) -> ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=CLOTH_SHADER
	mat.set_shader_parameter("garrison",garrison)
	mat.set_shader_parameter("cloth",Color("a24c40") if garrison else Color("335776"))
	mat.set_shader_parameter("reverse",Color("723a35") if garrison else Color("253e53"))
	return mat

static func _stitch_point(u: float,v: float,garrison: bool) -> Vector3:
	var fly:=1.12
	if garrison:
		# The centre is cut away between two long tapered fly corners.
		fly-=.32*(1.-absf(2.*v-1.))
	else:
		fly+=.105*(1.-v)-.055*v
	var x:=.043+u*fly
	var top:=3.46-.075*u-.055*sin(PI*u)
	var bottom:=2.68+.030*u-.085*sin(PI*u)
	var billow:=.098*sin(1.71*PI*u-.39*v)*u+.115*u*u
	return Vector3(x,lerpf(bottom,top,v),billow)

static func mesh(garrison: bool) -> ArrayMesh:
	var builder:=Builder.new()
	builder.joint=1
	builder.rod(Vector3.ZERO,Vector3.UP*3.55,.038,.027,Color.WHITE,8)
	builder.joint=3
	builder.rod(Vector3.UP*3.52,Vector3.UP*3.64,.052,.026,Color.WHITE,8)
	builder.joint=2
	for y:float in [2.69,2.75,3.40,3.46]:
		builder.rod(Vector3.UP*y,Vector3.UP*(y+.030),.043,.043,Color.WHITE,8)
	for row in 4:
		for col in 6:
			var u:=float(col)/6.
			var v:=float(row)/4.
			var du:=1./6.
			var dv:=1./4.
			for offset:Vector2 in [Vector2(0,0),Vector2(du,dv),Vector2(du,0),
					Vector2(0,0),Vector2(0,dv),Vector2(du,dv)]:
				var s:=u+offset.x
				var t:=v+offset.y
				var pos:=_stitch_point(s,t,garrison)
				var tangent:=_stitch_point(s+.001,t,garrison)-pos
				var rise:=_stitch_point(s,t+.001,garrison)-pos
				builder.surface.set_normal(tangent.cross(rise).normalized())
				builder.surface.set_color(Color.WHITE)
				builder.surface.set_uv(Vector2(s,t))
				builder.surface.set_uv2(Vector2.ZERO)
				builder.surface.add_vertex(pos)
	return builder.finish()
