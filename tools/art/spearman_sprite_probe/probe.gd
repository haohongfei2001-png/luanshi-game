extends Node3D
# Bounded static-only asset diagnostic, never loaded by shipping game.
var elapsed := 0.0
var capture_path := ""
func _ready() -> void:
	var source := OS.get_environment("SPEARMAN_ATLAS")
	if source.is_empty():
		push_error("SPEARMAN_ATLAS must identify exact unchanged PNG")
		get_tree().quit(2)
		return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	if FileAccess.get_sha256(source) != expected.source_sha256:
		push_error("Atlas SHA mismatch")
		get_tree().quit(2)
		return
	var im := Image.load_from_file(source)
	if im == null or im.get_size() != Vector2i(1536,1024):
		push_error("Invalid atlas dimensions")
		get_tree().quit(2)
		return
	var tex := ImageTexture.create_from_image(im)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 12.0 # diagnostic candidate, not an approved Wild Rift camera
	cam.position = Vector3(0,12,10)
	add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20,14)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("69634e")
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	for i in range(8):
		var frame: Dictionary = manifest.frames[i]
		var anchor := Vector2(frame.anchor_px[0],frame.anchor_px[1])
		var rect: Array = frame.rect
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		var verts := PackedVector3Array()
		var uvs := PackedVector2Array()
		# Common pixels/metre intentionally exposes scale drift rather than hiding it.
		for p in [Vector2(0,0),Vector2(0,512),Vector2(384,512),Vector2(384,0)]:
			verts.append(Vector3((p.x-anchor.x)*0.004,(anchor.y-p.y)*0.004,0))
			uvs.append(Vector2((rect[0]+p.x)/1536.0,(rect[1]+p.y)/1024.0))
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var actor := MeshInstance3D.new()
		actor.mesh = mesh
		actor.position = Vector3((i%4-1.5)*2.5,0.02,(i/4-0.5)*3.3)
		actor.basis = cam.basis
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 128.0/255.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		actor.material_override = mat
		add_child(actor)
	capture_path = OS.get_environment("SPEARMAN_CAPTURE")
	print("STATIC_ATLAS_LOADED: 8 static views; provisional anchors; no animation/gameplay; 12m orthographic candidate")
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 2.0 and not capture_path.is_empty():
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png(capture_path)
		print("CAPTURE_RESULT:",error)
		capture_path = ""
		get_tree().quit(error)
