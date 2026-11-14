extends "res://scripts/field/river_master_map.gd"
## Preserve the battle-facing door/ram/sightline contract, not the old art build.
## Legacy open-field saves still load their original presentation.
const MASTER_SCENE:="res://assets/river_pass/master/river_pass.scn"
var master:Node3D
func _ready() -> void:
	if not bridgehead:
		super._ready()
		return
	name="RiverPassArt"
	master=(load(MASTER_SCENE) as PackedScene).instantiate()
	add_child(master)
	sun.free()
	sun=master.get_node("Sun")
	gate=master.get_node("GateAndGarrison/Gate")
	ram=master.get_node("Ram")
	ram_beam=ram.find_child("SuspendedBeam",true,false)
	for wheel:Node3D in ram.find_children("RamWheel*","Node3D",true,false):ram_wheels.append(wheel)
	var hall:MeshInstance3D=master.get_node("GateAndGarrison/GateHall")
	var bounds:=hall.mesh.get_aabb()
	roofs.append({"node":hall,"center":hall.position+bounds.get_center(),"w":bounds.size.x*.5,"d":bounds.size.z*.5})
	# Keep source topology, UVs, material boundaries and masked silhouettes.
	# Only remove photographic specularity, not the asset's authored structure.
	var material_cache:Dictionary={}
	for node:MeshInstance3D in master.find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var source:=node.get_active_material(surface) as StandardMaterial3D
			if not source:continue
			if material_cache.has(source):
				node.set_surface_override_material(surface,material_cache[source])
				continue
			var material:=source.duplicate() as StandardMaterial3D
			material.roughness=maxf(material.roughness,.84)
			material.metallic=0.;material.metallic_specular=.10
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
				material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold=.40
				material.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			material_cache[source]=material
			node.set_surface_override_material(surface,material)
func _land_height(p:Vector2) -> float:
	var ledge:=Ground.parapet(p)
	return ledge if ledge>0. else Ground.height(p,bridgehead)-(Ground.MOAT_BED_DEPTH*Ground.moat_depth(p) if bridgehead else 0.)
func composition_audit() -> Dictionary:
	if not master:return {"legacy":true}
	return {"layout":master.get_meta("source_layout"),"groups":master.get_child_count(),"native_instances":master.get_meta("native_instances"),"terrain_tiles":master.get_meta("terrain_tiles"),"runtime_scattering":false}
