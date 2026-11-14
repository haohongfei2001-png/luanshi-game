extends SceneTree
const Reference=preload("res://scripts/field/experimental/full_weight_reference.gd")
var checks:=0;var failures:=0
func check(value:bool,detail:String) -> void:
	checks+=1
	if not value:failures+=1;push_error(detail)
func _initialize() -> void:
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3.ZERO,Vector3.RIGHT,Vector3.FORWARD])
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP])
	arrays[Mesh.ARRAY_TANGENT]=PackedFloat32Array([1,0,0,-1,1,0,0,-1,1,0,0,-1])
	arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,1])
	var source:=ArrayMesh.new();source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{.5:PackedInt32Array([0,1,2])})
	var material:=StandardMaterial3D.new();source.surface_set_material(0,material)
	var joints:=PackedInt32Array();var weights:=PackedFloat32Array()
	for vertex in 3:
		for slot in 9:joints.append(slot if slot<8 else 299);weights.append(.1 if slot<8 else .2)
	var transforms:Array[Transform3D]=[];transforms.resize(300)
	for joint in 300:transforms[joint]=Transform3D.IDENTITY
	transforms[299]=Transform3D(Basis(Vector3.BACK,PI/2),Vector3(.5,1,2))
	var result:=Reference.deform(source,[{"joints":joints,"weights":weights}],transforms)
	check(not result.has("error"),str(result.get("error")))
	if result.has("error"):quit(1);return
	check(result.more_than_eight==3,"ninth influence was lost")
	check(result.source_lods==1,"author LOD was lost")
	var actual:Array=result.mesh.surface_get_arrays(0)
	var normal:=(Vector3.UP*.8+(transforms[299].basis*Vector3.UP)*.2).normalized()
	var tangent:=(Vector3.RIGHT*.8+(transforms[299].basis*Vector3.RIGHT)*.2).normalized()
	for vertex in 3:
		var p:Vector3=arrays[Mesh.ARRAY_VERTEX][vertex]
		check(actual[Mesh.ARRAY_VERTEX][vertex].distance_to(p*.8+(transforms[299]*p)*.2)<.00002,"known complete affine result wrong")
		check(actual[Mesh.ARRAY_NORMAL][vertex].distance_to(normal)<.0002,"complete normal result wrong")
		var t:PackedFloat32Array=actual[Mesh.ARRAY_TANGENT]
		check(Vector3(t[vertex*4],t[vertex*4+1],t[vertex*4+2]).distance_to(tangent)<.0002 and t[vertex*4+3]==-1.,"complete tangent or author handedness wrong")
	check(result.mesh.surface_get_material(0)==material,"author material changed")
	check(actual[Mesh.ARRAY_TEX_UV]==arrays[Mesh.ARRAY_TEX_UV],"source UV changed")
	check(source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==arrays[Mesh.ARRAY_VERTEX],"source mesh mutated")
	var bad:=weights.duplicate();bad[0]=.4
	check(Reference.deform(source,[{"joints":joints,"weights":bad}],transforms).has("error"),"invalid unit sum silently repaired")
	bad=weights.duplicate();bad[0]=-.1
	check(Reference.deform(source,[{"joints":joints,"weights":bad}],transforms).has("error"),"negative influence accepted")
	var large_weights:=PackedFloat32Array();large_weights.resize(3*17);large_weights.fill(1./17.)
	var large_joints:=PackedInt32Array();large_joints.resize(3*17)
	check(Reference.deform(source,[{"joints":large_joints,"weights":large_weights}],transforms).has("error"),"unsupported seventeenth influence silently truncated")
	print("FULL_WEIGHT_REFERENCE_UNIT ",checks," checks ",failures," failures")
	quit(0 if failures==0 else 1)
