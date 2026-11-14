extends RefCounted
## Bake a connected production support mesh from the GAMEPLAY survey only.
## No old visual shader, texture, tree, rock or fort model is imported here.
const Ground:=preload("res://scripts/field/ground.gd")
static func height(p:Vector2) -> float:
	return Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p)
static func normal_at(p:Vector2) -> Vector3:
	var e:=.05
	return Vector3(height(p-Vector2(e,0))-height(p+Vector2(e,0)),2.*e,height(p-Vector2(0,e))-height(p+Vector2(0,e))).normalized()
static func masks(p:Vector2) -> Color:
	# Continuous metric masks, not photographic textures. R=road, G=bank,
	# B=wet ground, A=1. Artists can edit material layers without moving actors.
	var road:=1.-smoothstep(3.7,6.4,absf(p.y))
	var river_distance:=absf(p.x-Ground.river_center(p.y))
	var bank:=1.-smoothstep(5.,10.,river_distance)
	bank=maxf(bank,Ground.moat_depth(p))
	var wet:=1.-smoothstep(-1.7,-.3,height(p))
	return Color(road,bank,wet,1.)
static func tile(origin:Vector2,size:float=16.,step:float=.5) -> ArrayMesh:
	assert(size>0 and step>0 and is_equal_approx(size/step,roundf(size/step)))
	var n:=int(roundf(size/step))+1
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uvs:=PackedVector2Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
	for z:int in n:
		for x:int in n:
			var p:=origin+Vector2(x,z)*step
			vertices.append(Vector3(p.x,height(p),p.y));normals.append(normal_at(p))
			uvs.append(p);colors.append(masks(p))
	for z:int in n-1:
		for x:int in n-1:
			var i:=z*n+x;indices.append_array([i,i+n,i+1,i+1,i+n,i+n+1])
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
