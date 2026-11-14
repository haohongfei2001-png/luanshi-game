extends RefCounted
## Surveyed spurs of the river bank. Each stone grows out of an impassable
## strip of water. The ordinary tile grid still owns the dry track and the deck.
const Ground:=preload("res://scripts/field/ground.gd")
const Models:=preload("res://scripts/field/model_library.gd")
const STONES:=preload("res://assets/third_party/polyhaven_bank/bank_stones.glb")
const PAINT:=preload("res://assets/third_party/polyhaven_bank/lichen_and_stone.jpg")

static func build(parent: Node3D) -> void:
	var library:=Models.meshes(STONES)
	var surface:=StandardMaterial3D.new()
	surface.albedo_texture=PAINT
	surface.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	surface.roughness=1.0
	surface.metallic_specular=.08
	# X is along the river. The second value sets the length of the cut.
	# Run the large faces into the water, with low shingle broken around their heels.
	var groups:Array[Vector4]=[
		Vector4(1,-9.3,4.6,1.03),Vector4(1,-18.0,5.2,1.28),Vector4(-1,-13.1,5.4,1.16),
		Vector4(-1,-6.05,2.2,.70),Vector4(-1,8.9,4.4,1.06),Vector4(1,8.4,3.6,.92),
		Vector4(1,16.1,5.2,1.19),Vector4(-1,20.4,4.4,1.09)]
	var shapes:Array[Vector4]=[Vector4(-.29,.35,.56,.79),Vector4(.17,.03,.68,1.),
		Vector4(.43,.46,.41,.72),Vector4(-.13,.96,.39,.54),Vector4(.34,1.26,.28,.41),
		Vector4(-.46,.93,.25,.38),Vector4(.58,1.03,.21,.29)]
	var instances:Dictionary={}
	for k in groups.size():
		var bed:=groups[k]
		for j in shapes.size():
			var piece:=shapes[j]
			var width:=bed.z*piece.z
			var along:=bed.y+bed.z*piece.x
			var inset:=3.96-piece.y*.95
			var p:=Vector2(Ground.MOAT_X+bed.x*inset,along)
			if absf(p.y)-width*.48<Ground.MOAT_DECK+.60: continue
			var yaw:=.79*k+1.61*j+.16*sin(k*4.+j*.9)
			var basis:=Basis(Vector3.UP,yaw).scaled_local(Vector3(width, width*bed.w*piece.w,width*(.82+.09*sin(k+j))))
			var offset:=Vector3(p.x,-.56-.12*piece.y,p.y)
			var index:=(k*5+j*7)%library.size()
			var key:="RiverStone%02d"%index
			if not instances.has(key): instances[key]=[]
			instances[key].append(Transform3D(basis,offset))
	for key:String in instances:
		var transforms:Array=instances[key]
		var batch:=MultiMesh.new()
		batch.transform_format=MultiMesh.TRANSFORM_3D
		batch.mesh=library[key]
		batch.instance_count=transforms.size()
		for i in transforms.size(): batch.set_instance_transform(i,transforms[i])
		var drawing:=MultiMeshInstance3D.new()
		drawing.name="Bank"+key
		drawing.multimesh=batch
		drawing.material_override=surface
		parent.add_child(drawing)
