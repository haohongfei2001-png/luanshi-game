extends "res://tests/bridgehead_clothing_window.gd"
## Diagnostic material views of the same live actor and exact current animation.
## The altered materials are evidence only and never enter a product resource.
func _run() -> void:
	var out:="res://artifacts/person-diagnostic"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): quit(1);return
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	b.input_state(Vector2.ZERO,b.hero.facing)
	while b.tick<135: b.step()
	var focus:=b.roster[62]
	var original:Shader=load("res://scripts/field/company_skin.gdshader")
	var code:=original.code
	for mode in ["actual","clay","normal","unlit"]:
		var altered:=code
		if mode=="clay":
			altered=altered.replace("ALBEDO = mix(colour, vec3(.65,.35,.19), flash * .24);","ALBEDO = vec3(.6);")
		elif mode=="normal":
			altered=altered.replace("render_mode cull_disabled, diffuse_lambert, specular_disabled;","render_mode cull_disabled, unshaded;")
			altered=altered.replace("ALBEDO = mix(colour, vec3(.65,.35,.19), flash * .24);","ALBEDO = .5+.5*normalize(NORMAL);")
		elif mode=="unlit":
			altered=altered.replace("render_mode cull_disabled, diffuse_lambert, specular_disabled;","render_mode cull_disabled, unshaded;")
		var shader:=Shader.new()
		shader.code=altered
		for key in field.view.groups:
			var material:ShaderMaterial=field.view.groups[key].material_override
			if material!=null: material.shader=shader
		_set_view(focus.pos,2.4,2.697)
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		if image.save_jpg(out+"/"+mode+".jpg",.945)!=OK: quit(2);return
	var company=load("res://scripts/field/company_art.gd")
	var rows:=[]
	for look in ["Archer","Regular","Guard","Player","Officer"]:
		for detail in [false,true]:
			var mesh:ArrayMesh=company.fighter(3,look,detail)
			var a:=mesh.surface_get_arrays(0)
			var normals:PackedVector3Array=a[Mesh.ARRAY_NORMAL]
			var low:=10.
			var high:=0.
			for normal in normals:
				low=minf(low,normal.length())
				high=maxf(high,normal.length())
			rows.append({"role":look,"close":detail,"vertices":normals.size(),"triangles":a[Mesh.ARRAY_INDEX].size()/3,"normal_length":[low,high]})
	var f:=FileAccess.open(out+"/geometry.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"actor":focus.id,"tick":b.tick,"xz":[focus.pos.x,focus.pos.y],"stance":focus.state,"hits":Array(b.hits),"losses":Array(b.losses),"meshes":rows},"  "))
	f.close()
	print("PERSON_DIAGNOSTIC ",focus.id," ",b.tick," ",JSON.stringify(rows))
	scene.queue_free()
	await process_frame
	quit()
