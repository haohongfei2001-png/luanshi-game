extends RefCounted
## Imported original meshes share a costume atlas, the metre-scale hand bind and a baked
## motion bank. Merge shared body/weapon geometry once, retaining one draw per crowd batch.
const LIBRARY := preload("res://assets/river_gate/figures/river_company.glb")
const SKIN := preload("res://scripts/field/company_skin.gdshader")
const FABRIC := preload("res://assets/river_gate/figures/cloth_and_iron.png")
const RESPONSE := preload("res://assets/river_gate/figures/surface_response.png")
const MOTION := preload("res://assets/river_gate/figures/company_motion.png")
static var pieces: Dictionary = {}
static var assembled: Dictionary = {}

static func _load_pieces() -> void:
	if not pieces.is_empty(): return
	var library: Node = LIBRARY.instantiate()
	for part in library.find_children("*", "MeshInstance3D", true, false):
		pieces[String(part.name)]=part.mesh
	library.free()

static func costume(kit: int) -> String:
	if kit in [5,6]: return "Archer"
	if kit in [4,7]: return "Guard"
	return "Levy"

static func fighter(kit: int, look: String, detailed: bool, ranks: bool=false) -> ArrayMesh:
	var lod := "Rank" if ranks else ("Close" if detailed else "Line")
	var key := "%s-%d-%s" % [look,kit,lod]
	if assembled.has(key): return assembled[key]
	_load_pieces()
	var body: ArrayMesh=pieces[look+lod]
	var arm_lod := "Close" if detailed else "Line"
	var arms: ArrayMesh=pieces["Arms"+str(kit)+arm_lod]
	# Copy packed indexed arrays only. SurfaceTool would expand every triangle,
	# and importer-generated tangents/lightmap data have no role in these materials.
	var arrays:=body.surface_get_arrays(0)
	var gear:=arms.surface_get_arrays(0)
	var vertex_offset: int=arrays[Mesh.ARRAY_VERTEX].size()
	for attr: int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
		var combined = arrays[attr]
		combined.append_array(gear[attr])
		arrays[attr]=combined
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var second: PackedInt32Array=gear[Mesh.ARRAY_INDEX]
	for i in second.size(): second[i]+=vertex_offset
	indices.append_array(second)
	arrays[Mesh.ARRAY_INDEX]=indices
	for attr: int in [Mesh.ARRAY_TANGENT,Mesh.ARRAY_COLOR,Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
		arrays[attr]=null
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	assembled[key]=result
	return result

static func material(colour: Color, kit: int) -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=SKIN
	result.set_shader_parameter("cloth_atlas", FABRIC)
	result.set_shader_parameter("response_atlas", RESPONSE)
	result.set_shader_parameter("motion_bank", MOTION)
	result.set_shader_parameter("livery", colour)
	result.set_shader_parameter("kit", kit)
	return result
