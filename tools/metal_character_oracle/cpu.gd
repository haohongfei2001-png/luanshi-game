extends SceneTree
## Exact authored-source geometry/LOD audit. Not a visual or battle pass.
const Palette = preload("res://scripts/field/experimental/native_rig_palette.gd")
var failures := 0
var checks := 0
func check(value: bool, detail: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(detail)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var source := load("res://assets/ubc_lab/ubc_animated.glb") as PackedScene
	var actor := source.instantiate()
	root.add_child(actor)
	await process_frame
	await process_frame
	var skeleton: Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	var player: AnimationPlayer=actor.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var meshes: Array=actor.find_children("*","MeshInstance3D",true,false)
	var native_signatures := []
	var entries := []
	var total_lods := 0
	for mesh: MeshInstance3D in meshes:
		var packed := Palette.pack_textured_mesh(mesh.mesh,mesh.skin.get_bind_count())
		check(not packed.has("error"),"source mesh rejected: "+str(packed.get("error")))
		if packed.has("error"):quit(1);return
		total_lods+=packed.source_lods
		var signature := []
		for surface in mesh.mesh.get_surface_count():
			var native_arrays := mesh.mesh.surface_get_arrays(surface)
			var packed_arrays: Array= packed.mesh.surface_get_arrays(surface)
			signature.append(native_arrays)
			for channel in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2,Mesh.ARRAY_COLOR,Mesh.ARRAY_INDEX,Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3]:
				check(native_arrays[channel]==packed_arrays[channel],"changed authored geometry or UV: "+str(mesh.name)+" / "+str(channel))
			check(packed.mesh.surface_get_material(surface)==mesh.mesh.surface_get_material(surface),"source material reference lost")
			var before := RenderingServer.mesh_get_surface(mesh.mesh.get_rid(),surface)
			var after := RenderingServer.mesh_get_surface(packed.mesh.get_rid(),surface)
			check(before.get("lods",[])==after.get("lods",[]),"source LOD bytes or distances changed")
			var bones: PackedInt32Array=native_arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=native_arrays[Mesh.ARRAY_WEIGHTS]
			var influence_count: int=bones.size()/native_arrays[Mesh.ARRAY_VERTEX].size()
			for i in bones.size():
				var vertex: int=i/influence_count
				var k: int=i%influence_count
				var pair := Palette.unpack_weight(packed.tables[surface],vertex,k)
				check(is_equal_approx(pair.x,float(bones[i])),"joint index changed")
				check(is_equal_approx(pair.y,weights[i]),"authored weight changed")
		native_signatures.append(var_to_bytes(signature))
		entries.append({"mesh":str(mesh.name),"vertices":packed.tables[0].vertices,"binds":mesh.skin.get_bind_count(),"lods":packed.source_lods,"influences":packed.tables[0].influences})
	var samples := []
	var worst := 0.0
	var worst_raw_bake := 0.0
	for clip: StringName in player.get_animation_list():
		if clip=="RESET":continue
		for phase: float in [0.0,0.25,0.5,0.75]:
			player.play(clip)
			player.seek(player.get_animation(clip).length*phase,true)
			player.advance(0.0)
			var error := 0.0
			var raw_bake_error := 0.0
			for mesh: MeshInstance3D in meshes:
				var captured := Palette.capture(skeleton,mesh.skin)
				check(not captured.has("error"),"unresolvable intact skin")
				if captured.has("error"):quit(1);return
				var texture := Palette.encode([captured.transforms])
				var baked: ArrayMesh
				if DisplayServer.get_name()!="headless":
					await process_frame
					baked=mesh.bake_mesh_from_current_skeleton_pose()
					if baked==null:push_error("native bake unavailable");quit(1);return
				for surface in mesh.mesh.get_surface_count():
					var arrays := mesh.mesh.surface_get_arrays(surface)
					var native: PackedVector3Array=baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] if baked else PackedVector3Array()
					var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
					var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
					var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
					var influences: int=bones.size()/vertices.size()
					for vertex in vertices.size():
						var p := Vector3.ZERO
						var reference := Vector3.ZERO
						var sum_weights := 0.0
						for k in influences:
							var index := vertex*influences+k
							sum_weights+=weights[index]
							p+=(Palette.unpack(texture.image,bones[index],0)*vertices[vertex])*weights[index]
							var name: StringName=mesh.skin.get_bind_name(bones[index])
							var bone: int=skeleton.find_bone(name) if not name.is_empty() else mesh.skin.get_bind_bone(bones[index])
							reference+=(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bones[index])*vertices[vertex])*weights[index]
						# Godot 4.6.3 CPU bake sums source + w*(Tsource-source).
						# GLES3 instead sums w*T directly. Preserve source UNORM16
						# weights, and account for the documented CPU-only residual.
						if baked:
							raw_bake_error=maxf(raw_bake_error,p.distance_to(native[vertex]))
							var predicted_cpu_bake:=p+vertices[vertex]*(1.0-sum_weights)
							error=maxf(error,predicted_cpu_bake.distance_to(native[vertex]))
						else:error=maxf(error,p.distance_to(reference))
			worst=maxf(worst,error)
			worst_raw_bake=maxf(worst_raw_bake,raw_bake_error)
			check(error<0.00002,"native Skeleton CPU deformation parity failed: "+String(clip)+" phase "+str(phase)+" error "+str(error))
			samples.append({"clip":clip,"phase":phase,"max_position_error_m":error,"raw_bake_error_m":raw_bake_error})
	for i in meshes.size():
		var signature := []
		for surface in meshes[i].mesh.get_surface_count():signature.append(meshes[i].mesh.surface_get_arrays(surface))
		check(var_to_bytes(signature)==native_signatures[i],"source mutated")
	var report := {"checks":checks,"failures":failures,"native_bones":skeleton.get_bone_count(),"meshes":entries,"source_lods_preserved":total_lods,
		"samples":samples,"worst_position_error_m":worst,"worst_raw_bake_error_m":worst_raw_bake,"cpu_bake_formula":"palette_p + source_vertex*(1-sumWeights); source weights unchanged","graphics":"NOT_RUN" if DisplayServer.get_name()=="headless" else RenderingServer.get_video_adapter_name(),"deformation_reference":"CPU linear blend roundtrip only; native RenderingServer skeleton unavailable in headless" if DisplayServer.get_name()=="headless" else "MeshInstance3D.bake_mesh_from_current_skeleton_pose","material_pixel_parity":"NOT_RUN","full_battle_performance":"NOT_RUN","shipping_enabled":false}
	var folder:=OS.get_environment("INTACT_OUTPUT")
	if folder.is_empty():folder="user://metal-character-oracle/cpu"
	DirAccess.make_dir_recursive_absolute(folder)
	var f:=FileAccess.open(folder.path_join("cpu.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "));f.close()
	print("INTACT_NATIVE_PALETTE ",JSON.stringify(report))
	actor.queue_free();await process_frame
	quit(0 if failures==0 else 1)
