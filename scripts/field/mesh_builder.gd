extends RefCounted
## A small original mesh authoring palette. The UV channels carry the authored figure paint, joint and cloth mask through instancing.
var surface := SurfaceTool.new()
var joint := 0
var dye := 0.0
func _init() -> void:
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

func tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var cross_normal := (b-a).cross(c-a)
	if cross_normal.length_squared() < 0.000000001: return
	var n := cross_normal.normalized()
	for p: Vector3 in [a,c,b]:
		surface.set_normal(n)
		surface.set_color(color)
		surface.set_uv(Vector2(color.r,color.g))
		surface.set_uv2(Vector2(joint,2.0*dye+color.b))
		surface.add_vertex(p)

func quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,col: Color) -> void:
	tri(a,b,c,col)
	tri(a,c,d,col)

func ring(center: Vector3, r: Vector2, count: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in count:
		var angle := TAU*i/count
		pts.append(center+Vector3(sin(angle)*r.x,0,cos(angle)*r.y))
	return pts

func loft(centers: Array, radii: Array, n: int, color: Color) -> void:
	var last := ring(centers[0],radii[0],n)
	for i in n:
		tri(centers[0],last[(i+1)%n],last[i],color)
	for level in range(1, centers.size()):
		var next := ring(centers[level],radii[level],n)
		for i in n:
			var k := (i+1)%n
			quad(last[i],last[k],next[k],next[i],color)
		last = next
	for i in n:
		tri(centers.back(),last[i],last[(i+1)%n],color)

func block(center: Vector3,size: Vector3,col: Color) -> void:
	var a := center-size*0.5
	var b := center+size*0.5
	var q := [Vector3(a.x,a.y,b.z),Vector3(b.x,a.y,b.z),Vector3(b.x,b.y,b.z),Vector3(a.x,b.y,b.z),
		Vector3(a.x,a.y,a.z),Vector3(b.x,a.y,a.z),Vector3(b.x,b.y,a.z),Vector3(a.x,b.y,a.z)]
	for face in [[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[3,2,6,7],[4,5,1,0]]:
		quad(q[face[0]],q[face[1]],q[face[2]],q[face[3]],col)

func rod(a: Vector3,b: Vector3,ra: float,rb: float,col: Color,n: int=5) -> void:
	var axis := a.direction_to(b)
	if axis.length_squared() < 0.5: return
	var basis_x := axis.cross(Vector3.FORWARD if absf(axis.y)>0.85 else Vector3.UP).normalized()
	var basis_z := axis.cross(basis_x)
	for i in n:
		var t := TAU*i/n
		var nt := TAU*(i+1)/n
		var edge := cos(t)*basis_x+sin(t)*basis_z
		var next := cos(nt)*basis_x+sin(nt)*basis_z
		quad(a+ra*edge,a+ra*next,b+rb*next,b+rb*edge,col)
		tri(b,b+rb*edge,b+rb*next,col)
		tri(a,a+ra*next,a+ra*edge,col)

func finish() -> ArrayMesh:
	surface.index()
	return surface.commit()
