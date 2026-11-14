extends RefCounted
## Shared analytic survey -> clipped water mesh; works with current Ground mode.
## No height opt-in, game state, collider, soldier count or camera modification.
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
static func clip(input:Array[Vector3],level:float=Ground.BATTLE_WATER_LEVEL) -> Array[Vector3]:
	var output:Array[Vector3]=[]
	for i in input.size():
		var a:Vector3=input[i];var b:Vector3=input[(i+1)%input.size()]
		if a.y<=level:output.append(Vector3(a.x,level,a.z))
		if (a.y<=level)!=(b.y<=level):
			var crossing:Vector3=a.lerp(b,(level-a.y)/(b.y-a.y));crossing.y=level;output.append(crossing)
	return output
static func append_triangle(out:Array[Vector3],a:Vector3,b:Vector3,c:Vector3) -> int:
	var polygon:=clip([a,b,c]);var discarded:=0
	for i in range(1,polygon.size()-1):
		if (polygon[i]-polygon[0]).cross(polygon[i+1]-polygon[0]).length_squared()>.000000000001:out.append_array([polygon[0],polygon[i],polygon[i+1]])
		else:discarded+=1
	return discarded
static func mesh(origin:Vector2,extent:Vector2,step:float=.5) -> ArrayMesh:
	assert(step>0. and extent.x>0. and extent.y>0.)
	var nx:=int(ceil(extent.x/step));var nz:=int(ceil(extent.y/step));var vertices:Array[Vector3]=[];var discarded:=0
	for z in nz:
		for x in nx:
			var p:=origin+Vector2(x,z)*step;var q:Vector2=(p+Vector2.ONE*step).min(origin+extent)
			var a:=Vector3(p.x,Surface.height(p),p.y);var b:=Vector3(q.x,Surface.height(Vector2(q.x,p.y)),p.y)
			var c:=Vector3(p.x,Surface.height(Vector2(p.x,q.y)),q.y);var d:=Vector3(q.x,Surface.height(q),q.y)
			discarded+=append_triangle(vertices,a,b,c);discarded+=append_triangle(vertices,b,d,c)
	var normals:=PackedVector3Array();normals.resize(vertices.size());normals.fill(Vector3.UP)
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array(vertices);arrays[Mesh.ARRAY_NORMAL]=normals
	var result:=ArrayMesh.new();if not vertices.is_empty():result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	result.set_meta("discarded_sub_square_millimetre_slivers",discarded)
	return result
