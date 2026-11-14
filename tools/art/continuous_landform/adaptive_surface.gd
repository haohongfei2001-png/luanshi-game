extends RefCounted
## Locally refined .5m cells with shared edge subdivisions, including tile seams.
## No support-function, navigation or saved-state changes.
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const STEP:=.5
const TOLERANCE:=.008
var levels:Dictionary={}
var distribution:Dictionary={}
func triangle_error(a:Vector3,b:Vector3,c:Vector3) -> float:
	var worst:=0.
	for weights:Vector3 in [Vector3(1,1,1)/3.,Vector3(.5,.5,0),Vector3(0,.5,.5),Vector3(.5,0,.5)]:
		var p:=a*weights.x+b*weights.y+c*weights.z
		worst=maxf(worst,absf(p.y-Surface.height(Vector2(p.x,p.z))))
	return worst
func point(p:Vector2) -> Vector3:return Vector3(p.x,Surface.height(p),p.y)
func resolution(cell:Vector2i) -> int:
	if levels.has(cell):return levels[cell]
	var origin:=Vector2(cell)*STEP
	var n:=1
	# Background-only terrain retains the existing grid. Playable border cells
	# are included so adjacent visible/collision edges remain conforming.
	if absf(origin.x)<=Ground.LIMIT.x+STEP and absf(origin.y)<=Ground.LIMIT.y+STEP:
		while n<8:
			var error:=0.;var s:=STEP/float(n)
			for j in n:
				for i in n:
					var q:=origin+Vector2(i,j)*s
					var a:=point(q);var b:=point(q+Vector2(s,0));var c:=point(q+Vector2(0,s));var d:=point(q+Vector2(s,s))
					error=maxf(error,maxf(triangle_error(a,b,c),triangle_error(b,d,c)))
			if error<=TOLERANCE:break
			n*=2
	levels[cell]=n;distribution[str(n)]=int(distribution.get(str(n),0))+1
	return n
func tile(origin:Vector2,size:float=16.) -> ArrayMesh:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uvs:=PackedVector2Array();var colors:=PackedColorArray();var indices:=PackedInt32Array();var lookup:Dictionary={}
	var base:=Vector2i((origin/STEP).round());var count:=int(roundf(size/STEP))
	for z in count:
		for x in count:
			var cell:=base+Vector2i(x,z);var n:=resolution(cell);var s:=STEP/float(n)
			var q:=Vector2(cell)*STEP
			var north:=maxi(n,resolution(cell+Vector2i(0,-1)))
			var east:=maxi(n,resolution(cell+Vector2i(1,0)))
			var south:=maxi(n,resolution(cell+Vector2i(0,1)))
			var west:=maxi(n,resolution(cell+Vector2i(-1,0)))
			for j in n:
				for i in n:
					var p:=q+Vector2(i,j)*s
					var segments:=[north/n if j==0 else 1,east/n if i==n-1 else 1,south/n if j==n-1 else 1,west/n if i==0 else 1]
					var ring:Array[Vector2]=[]
					var corners:=[p,p+Vector2(s,0),p+Vector2(s,s),p+Vector2(0,s)]
					for side in 4:
						for k in int(segments[side]):ring.append(corners[side].lerp(corners[(side+1)%4],float(k)/float(segments[side])))
					var local:Array[int]=[]
					for v:Vector2 in ring:
						if not lookup.has(v):
							lookup[v]=vertices.size();vertices.append(point(v));normals.append(Surface.normal_at(v));uvs.append(v);colors.append(Surface.masks(v))
						local.append(int(lookup[v]))
					if local.size()==4:indices.append_array([local[0],local[1],local[3],local[1],local[2],local[3]])
					else:
						var center:=p+Vector2.ONE*s*.5;var ci:=vertices.size()
						vertices.append(point(center));normals.append(Surface.normal_at(center));uvs.append(center);colors.append(Surface.masks(center))
						for k in local.size():indices.append_array([ci,local[k],local[(k+1)%local.size()]])
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
