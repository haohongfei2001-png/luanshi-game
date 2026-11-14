extends RefCounted
## Four pollards grow on the outer crossing. Use the source tree's complete
## solid branch curtains, with one shared colour material for the four instances.
const SOURCE:=preload("res://assets/third_party/river_willow/pollard.glb")
const Models:=preload("res://scripts/field/model_library.gd")
const Ground:=preload("res://scripts/field/ground.gd")

static func plant(parent: Node3D) -> void:
	var mats:Dictionary={}
	var renders:=Models.meshes(SOURCE)
	var trees:Array[Vector4]=[Vector4(18.0,-10.5,6.25,-.48),Vector4(30.0,-14.6,6.50,2.91),
		Vector4(17.8,11.2,5.43,.38),Vector4(30.0,16.1,4.81,2.22)]
	var batch_scene:=Node3D.new()
	batch_scene.name="RiverWillows"
	parent.add_child(batch_scene)
	for key:String in renders:
		var body:ArrayMesh=renders[key]
		for i in body.get_surface_count():
			var old:=body.surface_get_material(i) as StandardMaterial3D
			if old==null or mats.has(old): continue
			var bark:=ShaderMaterial.new()
			bark.shader=preload("res://scripts/field/pendant_willow.gdshader")
			bark.set_shader_parameter("colour",old.albedo_texture)
			if not old.albedo_texture: bark.set_shader_parameter("fallback",old.albedo_color)
			else: bark.set_shader_parameter("fallback",Color(0,0,0,0))
			mats[old]=bark
		var copy:=body.duplicate() as ArrayMesh
		for id in copy.get_surface_count():
			var original:=body.surface_get_material(id)
			if mats.has(original): copy.surface_set_material(id,mats[original])
		var pack:=MultiMesh.new()
		pack.transform_format=MultiMesh.TRANSFORM_3D
		pack.mesh=copy
		pack.instance_count=trees.size()
		for i in trees.size():
			var t:=trees[i]
			var loc:=Ground.unit_point(Vector2(t.x,t.y),true)
			var scale_factor:=t.z/6.8
			var axis:=Basis(Vector3.UP,t.w).scaled_local(Vector3(scale_factor*.91,scale_factor,scale_factor*1.06))
			pack.set_instance_transform(i,Transform3D(axis,loc+Vector3.DOWN*.08))
		var row:=MultiMeshInstance3D.new()
		row.name=key
		row.multimesh=pack
		batch_scene.add_child(row)
