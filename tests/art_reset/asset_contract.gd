extends SceneTree
const Contract:=preload("res://tools/art/authored_reset/asset_contract.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var denied:=Contract.load_verified({})
	assert(not denied.ok and denied.reason=="MISSING_source")
	var original:=Node3D.new();var part:=MeshInstance3D.new();part.mesh=BoxMesh.new();original.add_child(part);part.owner=original
	var scene:=PackedScene.new();assert(scene.pack(original)==OK);original.free()
	var path:="user://admission-test.tscn";assert(ResourceSaver.save(scene,path)==OK)
	var license:=FileAccess.open("user://synthetic-license.txt",FileAccess.WRITE);license.store_string("TEST GENERATED BOX ONLY, NOT A PRODUCTION ASSET");license.close()
	var entry:={"source":path,"sha256":FileAccess.get_sha256(path),"license_evidence":"user://synthetic-license.txt","metres_per_unit":.01,"triangle_budget":12,"surface_budget":1}
	var accepted:=Contract.load_verified(entry);assert(accepted.ok)
	var wrapper:Node3D=accepted.node;root.add_child(wrapper)
	var imported:=wrapper.get_child(0).get_child(0) as MeshInstance3D
	assert(imported.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].size()==24)
	assert(accepted.audit.base_triangles==12 and accepted.audit.uv_surfaces==1)
	assert(is_equal_approx(wrapper.get_child(0).scale.x,.01))
	wrapper.free()
	entry.triangle_budget=11;assert(Contract.load_verified(entry).reason=="BUDGET_EXCEEDED")
	entry.sha256="wrong";assert(Contract.load_verified(entry).reason=="SOURCE_HASH_MISMATCH")
	print("ASSET_ADMISSION_PASS synthetic fixture only; visual NOT_RUN")
	quit()
