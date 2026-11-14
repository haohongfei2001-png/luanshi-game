extends RefCounted
## Imported field meshes share a costume atlas, the metre-scale hand bind and a baked
## motion bank. Merge shared body/weapon geometry once, retaining one draw per crowd batch.
const FieldMeshes := preload("res://scripts/field/model_library.gd")
const LIBRARY := preload("res://assets/river_gate/figures/river_company.glb")
const GARMENTS := preload("res://assets/river_gate/figures/field_garments.gltf")
const GARRISON := preload("res://assets/third_party/wildfire_garments/field_issues.glb")
const SHIELD := preload("res://assets/third_party/wildfire_shields/garrison_shield.glb")
const HEADWEAR := preload("res://assets/third_party/wildfire_headwear/headwear.glb")
const ISSUE_COLOURS := preload("res://assets/third_party/wildfire_garments/field_colours.png")
const MASTER := preload("res://assets/river_gate/figures/field_company_master.glb")
const FIELD_BODY := preload("res://assets/river_gate/figures/garrison_bodies.glb")
const SKIN := preload("res://scripts/field/company_skin.gdshader")
const FABRIC := preload("res://assets/river_gate/figures/campaign_colours.svg")
const MOTION := preload("res://assets/river_gate/figures/company_motion.png")
static var pieces: Dictionary = {}
static var assembled: Dictionary = {}

static func _load_pieces() -> void:
	if not pieces.is_empty(): return
	for asset: PackedScene in [LIBRARY, MASTER, SHIELD]:
		pieces.merge(FieldMeshes.meshes(asset),true)

static func costume(kit: int) -> String:
	if kit in [5,6]: return "Archer"
	if kit in [4,7]: return "Guard"
	if kit in [1,3]: return "Regular"
	return "Levy"

static func fighter(kit: int, look: String, detailed: bool, ranks: bool=false) -> ArrayMesh:
	var lod := "Rank" if ranks else ("Close" if detailed else "Line")
	var key := "%s-%d-%s" % [look,kit,lod]
	if assembled.has(key): return assembled[key]
	_load_pieces()
	var body: ArrayMesh=pieces[look+lod+"Master"]
	var arms: ArrayMesh=pieces["Arms"+str(kit)+lod]
	# Copy packed indexed arrays only. SurfaceTool would expand every triangle,
	# and importer-generated tangents/lightmap data have no role in these materials.
	var arrays:=body.surface_get_arrays(0)
	var attachments: Array[ArrayMesh]=[arms]
	if kit==7: attachments.append(pieces["GarrisonShield"])
	for attachment: ArrayMesh in attachments:
		var gear:=attachment.surface_get_arrays(0)
		var vertex_offset: int=arrays[Mesh.ARRAY_VERTEX].size()
		for attr: int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2]:
			var combined = arrays[attr]
			combined.append_array(gear[attr])
			arrays[attr]=combined
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var extra: PackedInt32Array=gear[Mesh.ARRAY_INDEX]
		for i in extra.size(): extra[i]+=vertex_offset
		indices.append_array(extra)
		arrays[Mesh.ARRAY_INDEX]=indices
	for attr: int in [Mesh.ARRAY_TANGENT,Mesh.ARRAY_COLOR,Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:
		arrays[attr]=null
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	assembled[key]=result
	return result

static func material(colour: Color, kit: int, player: bool=false, shoulder: Color=Color.TRANSPARENT) -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=SKIN
	result.set_shader_parameter("cloth_atlas", FABRIC)
	result.set_shader_parameter("issue_atlas", ISSUE_COLOURS)
	result.set_shader_parameter("motion_bank", MOTION)
	result.set_shader_parameter("livery", colour)
	result.set_shader_parameter("shoulder_dye", shoulder)
	result.set_shader_parameter("kit", kit)
	result.set_shader_parameter("player_costume",player)
	return result
