extends "res://tests/field_controls.gd"

func _portrait() -> void:
	await super._portrait()
	var u:=field.battle.roster[0]
	var ground:=Ground.unit_point(u.pos)
	var face:=Vector2i(field.camera.unproject_position(ground+Vector3(.143,1.485,0.)))
	var boxes:Array[Vector2i]=[]
	for z:float in [-1.,1.]:
		boxes.append(Vector2i(field.camera.unproject_position(ground+Vector3(.36,1.018,z*.34))))
	var eye:=root.get_texture().get_image()
	var origin:=face-Vector2i(78,52)
	eye.get_region(Rect2i(origin,Vector2i(156,206))).save_png("res://artifacts/natural.png")
	print("HAND_CENTERS ",boxes[0]-origin," ",boxes[1]-origin)
	field.set_process(false)
	field.set_physics_process(false)
	var materials:Array[ShaderMaterial]=[]
	for batch in field.view.groups.values():
		var mat: ShaderMaterial=batch.node.material_override
		if mat.shader.resource_path=="res://scripts/field/company_skin.gdshader" and not materials.has(mat): materials.append(mat)
	for tile in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]:
		for mat in materials: mat.set_shader_parameter("anatomy_tile",tile)
		await RenderingServer.frame_post_draw
		var layer:=root.get_texture().get_image()
		var stat:=PackedInt32Array()
		for center in boxes:
			var count:=0
			for x in range(center.x-6,center.x+7):
				for y in range(center.y-6,center.y+7):
					var c:=layer.get_pixel(x,y)
					if c.r>.8 and c.g<.14 and c.b>.8: count+=1
			stat.append(count)
		if stat[0]+stat[1]>0:
			print("HAND_FEATURE ",tile," ",stat[0]," ",stat[1])
		if tile==8:
			layer.get_region(Rect2i(origin,Vector2i(156,206))).save_png("res://artifacts/skin.png")
	quit(0)
