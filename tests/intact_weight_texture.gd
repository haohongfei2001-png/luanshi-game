extends SceneTree
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const MaterialAdapter=preload("res://scripts/field/experimental/native_rig_material.gd")
var checks:=0
var failures:=0
func check(value:bool,detail:String) -> void:
	checks+=1
	if not value:failures+=1;push_error(detail)
func _initialize() -> void:run.call_deferred()
func mesh_with_count(count:int) -> ArrayMesh:
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	var vertices:=PackedVector3Array();vertices.resize(count)
	var joints:=PackedInt32Array();joints.resize(count*4)
	var weights:=PackedFloat32Array();weights.resize(count*4)
	var custom:=PackedFloat32Array();custom.resize(count*4)
	for i in count:
		vertices[i]=Vector3(float(i%3),float(i%2),float(i%5))
		for j in 4:joints[i*4+j]=j;weights[i*4+j]=.25;custom[i*4+j]=float(i+j)*.01
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_BONES]=joints;arrays[Mesh.ARRAY_WEIGHTS]=weights
	arrays[Mesh.ARRAY_CUSTOM0]=custom
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,count-1,1,0,count-1])
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{1.2:PackedInt32Array([1,0,count-1])},Mesh.ARRAY_CUSTOM_RGBA_FLOAT<<Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return mesh
func run() -> void:
	var source:=mesh_with_count(3)
	for slots:int in [9,12,16]:
		var joints:=PackedInt32Array();var weights:=PackedFloat32Array()
		for vertex in 3:
			for slot in slots:joints.append(299-slot);weights.append(1./slots)
		var result:=Palette.pack_textured_mesh(source,300,[{"joints":joints,"weights":weights}])
		check(not result.has("error"),"complete source weights rejected")
		if result.has("error"):quit(1);return
		var table:Dictionary=result.tables[0]
		check(table.influences==slots,"tail slots lost")
		check(result.mesh.surface_get_arrays(0)[Mesh.ARRAY_CUSTOM0]==source.surface_get_arrays(0)[Mesh.ARRAY_CUSTOM0],"authored custom UV lost")
		for vertex in 3:
			for slot in slots:
				var actual:=Palette.unpack_weight(table,vertex,slot)
				check(actual==Vector2(joints[vertex*slots+slot],weights[vertex*slots+slot]),"joint/weight not byte-equivalent float32")
	var oversized:=Palette.pack_textured_mesh(source,300,[{"joints":PackedInt32Array(range(51)),"weights":PackedFloat32Array(range(51))}])
	check(oversized.has("error"),"17 slots silently truncated")
	var large:=mesh_with_count(65537)
	var packed:=Palette.pack_textured_mesh(large,4)
	check(not packed.has("error"),"32-bit source indices rejected")
	if not packed.has("error"):
		check(RenderingServer.mesh_get_surface(large.get_rid(),0).lods==RenderingServer.mesh_get_surface(packed.mesh.get_rid(),0).lods,"32-bit LOD indices lost")
	var mat:=StandardMaterial3D.new();mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	check(not MaterialAdapter.adapt(mat).has("error"),"explicit supported material rejected")
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	check(MaterialAdapter.adapt(mat).has("error"),"unsupported author alpha silently removed")
	print("INTACT_WEIGHT_TEXTURE ",JSON.stringify({"checks":checks,"failures":failures,"synthetic_slots":[9,12,16],"synthetic_32bit_lods":true,"source_custom_uv_preserved":true,"graphics":"NOT_RUN","shipping_enabled":false}))
	quit(0 if failures==0 else 1)
