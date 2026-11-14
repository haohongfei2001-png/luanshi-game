extends SceneTree
## Actual source StandardMaterial/Skin versus full-weight batched shader. Isolated
## technical A/B, never Chinese art, locomotion/contact or battlefield acceptance.
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const MaterialAdapter=preload("res://scripts/field/experimental/native_rig_material.gd")
var failures:=0
var reports:=[]
var diagnostic:=OS.get_environment("INTACT_DIAGNOSTIC")
func _initialize() -> void:run.call_deferred()
func view() -> SubViewport:
	var viewport:=SubViewport.new();viewport.size=Vector2i(512,512);viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X
	if OS.has_environment("INTACT_PARITY_FULL_MESH") or not diagnostic.is_empty():viewport.mesh_lod_threshold=0.0
	root.add_child(viewport)
	var world:=WorldEnvironment.new();world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.035,.045,.055)
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=.45;viewport.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-25,0);viewport.add_child(sun)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.4
	viewport.add_child(camera);camera.position=Vector3(3,2.1,4);camera.look_at(Vector3(0,.9,0));camera.current=true
	return viewport
func abort(detail:String) -> void:
	push_error(detail);quit(1)
func run() -> void:
	if DisplayServer.get_name()=="headless":abort("GPU parity requires an actual graphics renderer");return
	var folder:="res://artifacts/native-character-parity/gpu_full" if OS.has_environment("INTACT_PARITY_FULL_MESH") else "res://artifacts/native-character-parity/gpu"
	if not diagnostic.is_empty():folder="res://artifacts/native-character-parity/diagnostic_"+diagnostic
	DirAccess.make_dir_recursive_absolute(folder)
	var native_view:=view();var batch_view:=view()
	var actor:Node3D=load("res://assets/ubc_lab/ubc_animated.glb").instantiate();native_view.add_child(actor)
	var skeleton:Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	var player:AnimationPlayer=actor.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var entries:=[]
	for native:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var packed:=Palette.pack_textured_mesh(native.mesh,native.skin.get_bind_count())
		if packed.has("error"):abort(str(packed));return
		var shaders:=[]
		for surface in native.mesh.get_surface_count():
			var original:StandardMaterial3D=native.get_active_material(surface)
			var colors:PackedColorArray=native.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
			var low:=Color(1,1,1,1);var high:=Color(0,0,0,0)
			for color:Color in colors:
				for channel in 4:low[channel]=minf(low[channel],color[channel]);high[channel]=maxf(high[channel],color[channel])
			print("INTACT_ACTIVE_MATERIAL ",JSON.stringify({"mesh":native.name,"surface":surface,"active_equals_surface":original==native.mesh.surface_get_material(surface),"material_override":str(native.material_override),"surface_override":str(native.get_surface_override_material(surface)),"color_min":low,"color_max":high,"normal_enabled":original.normal_enabled,"normal_scale":original.normal_scale,"albedo":original.albedo_color,"roughness":original.roughness,"metallic":original.metallic}))
			var chosen:StandardMaterial3D=original
			if diagnostic=="no_normal":
				chosen=original.duplicate();chosen.normal_enabled=false
				native.set_surface_override_material(surface,chosen)
			if diagnostic.begins_with("normal_"):
				chosen=original.duplicate()
				var normal_image:=Image.create(4,4,false,Image.FORMAT_RGB8)
				var value:=Color(.5,.5,1)
				if diagnostic=="normal_x":value=Color(.85,.5,1)
				if diagnostic=="normal_y":value=Color(.5,.85,1)
				normal_image.fill(value);chosen.normal_texture=ImageTexture.create_from_image(normal_image)
				native.set_surface_override_material(surface,chosen)
			var material:=MaterialAdapter.adapt(chosen)
			if material.has("error"):abort(str(material));return
			var shader:ShaderMaterial=material.material
			if diagnostic=="unshaded":
				var plain:StandardMaterial3D=original.duplicate();plain.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
				native.set_surface_override_material(surface,plain)
				var plain_shader:=Shader.new();plain_shader.code=shader.shader.code.replace("render_mode blend_mix,", "render_mode unshaded, blend_mix,")
				shader.shader=plain_shader
			if diagnostic.begins_with("tbn_"):
				var axis:="NORMAL"
				if diagnostic=="tbn_t":axis="TANGENT"
				if diagnostic=="tbn_b":axis="BINORMAL"
				var fragment:="void fragment(){ALBEDO=normalize("+axis+")*.5+vec3(.5); }"
				var native_debug:=ShaderMaterial.new();native_debug.shader=Shader.new()
				native_debug.shader.code="shader_type spatial; render_mode unshaded,cull_disabled; "+fragment
				native.set_surface_override_material(surface,native_debug)
				var batch_debug:=Shader.new()
				batch_debug.code=shader.shader.code.split("void fragment()")[0].replace("render_mode blend_mix,", "render_mode unshaded, blend_mix,")+fragment
				shader.shader=batch_debug
			shader.set_shader_parameter("influence_table",ImageTexture.create_from_image(packed.tables[surface].image))
			shader.set_shader_parameter("influence_groups",packed.tables[surface].groups)
			packed.mesh.surface_set_material(surface,shader);shaders.append(shader)
		var batch:=MultiMeshInstance3D.new();batch.multimesh=MultiMesh.new()
		batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D;batch.multimesh.use_custom_data=true
		batch.multimesh.use_colors=true
		batch.multimesh.mesh=packed.mesh;batch.multimesh.instance_count=1
		batch.multimesh.set_instance_transform(0,native.global_transform)
		batch.multimesh.set_instance_custom_data(0,Color(0,0,0,0))
		batch.multimesh.set_instance_color(0,Color.WHITE)
		print("INTACT_INSTANCE_COLOR ",JSON.stringify({"mesh":native.name,"instance_color":batch.multimesh.get_instance_color(0),"source_vertex_color_first":native.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR][0]}))
		batch.multimesh.custom_aabb=AABB(Vector3(-4,-4,-4),Vector3(8,8,8))
		batch_view.add_child(batch)
		entries.append({"native":native,"shaders":shaders})
	for sample:Array in [["Idle",0.0],["Walk",.45],["Sword_Attack",.5],["Death01",.75]]:
		player.play(sample[0]);player.seek(player.get_animation(sample[0]).length*sample[1],true);player.advance(0.)
		for entry:Dictionary in entries:
			var capture:=Palette.capture(skeleton,entry.native.skin)
			if capture.has("error"):abort(str(capture));return
			var bank:=Palette.encode([capture.transforms])
			for shader:ShaderMaterial in entry.shaders:shader.set_shader_parameter("palette",ImageTexture.create_from_image(bank.image))
		for frame in 4:await process_frame
		await RenderingServer.frame_post_draw
		var a:=native_view.get_texture().get_image();var b:=batch_view.get_texture().get_image()
		a.save_png(folder+"/"+sample[0]+"-native.png");b.save_png(folder+"/"+sample[0]+"-batch.png")
		var error_sum:=0.;var error_max:=0.;var different:=0;var visible:=0
		var background:=a.get_pixel(0,0)
		for y in a.get_height():
			for x in a.get_width():
				var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
				var error:=maxf(absf(p.r-q.r),maxf(absf(p.g-q.g),absf(p.b-q.b)))
				error_sum+=error;error_max=maxf(error,error_max)
				if p!=background or q!=background:visible+=1
				if error>2./255.:different+=1
		var pass_value:=visible>1000 and error_sum/(512*512)<.001 and different<visible*.02
		if not pass_value:failures+=1
		var row:={"clip":sample[0],"phase":sample[1],"mae":error_sum/(512*512),"max":error_max,"visible":visible,"pixels_over_2_levels":different,"pass":pass_value}
		reports.append(row);print("INTACT_NATIVE_GPU ",JSON.stringify(row))
	var f:=FileAccess.open(folder+"/parity.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"source":OS.get_environment("GITHUB_SHA"),"renderer":RenderingServer.get_video_adapter_name(),"diagnostic_only":not diagnostic.is_empty(),"diagnostic":diagnostic,"lod_threshold":native_view.mesh_lod_threshold,"native_size":[512,512],"internal":1.,"reports":reports,"art_pass":false,"shipping_enabled":false,"full_battle_performance":"NOT_RUN","source_weights":"UBC four-slot import; explicit >8 source tested separately on CPU only"},"  "));f.close()
	quit(0 if failures==0 else 1)
