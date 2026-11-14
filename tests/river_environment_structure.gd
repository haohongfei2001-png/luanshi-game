extends SceneTree
const Map:=preload("res://scripts/field/river_master_map.gd")
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var map:=Map.new()
	map.bridgehead=true
	root.add_child(map)
	await process_frame
	var unchanged:=0
	for x in range(-118,119,2):
		for z in range(-64,65,2):
			var p:=Vector2(x,z)
			if Ground.blocked(p,true,true):continue
			if Ground.parapet(p)>0.:continue
			assert(is_equal_approx(map._land_height(p),Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p)),"Walkable terrain/actor contact mismatch")
			unchanged+=1
	for grove:Vector4 in Map.APPROACH_GROVES:
		assert(absf(grove.y)>15.,"Tall canopy trunk inside bridge-to-gate action corridor")
	var crowns:=0
	var willows:=0
	var toes:=0
	var grass:=0
	for child:Node in map.get_children():
		if String(child.name).begins_with("WholeBroadleaf"):crowns+=1
		if String(child.name).begins_with("WholeNativeWillow"):willows+=1
		if String(child.name).begins_with("SubmergedTalusFan"):toes+=1
		if String(child.name).begins_with("RiparianGrassCove"):grass+=1
		assert(not String(child.name).begins_with("WholeBankFooting"),"Regular bead shoreline restored")
	assert(crowns>=100 and willows==8 and toes>30 and grass>20)
	var parts:Dictionary=map._library(Map.WOODLAND)
	for name:String in ["RiverWillowGreen","FieldOakBroadA","FieldOakBroadB","FieldElmA","FieldMapleGreen","FieldBrushA","FieldBrushB","VergeGrassA","VergeGrassB"]:
		assert(parts.has(name),"Missing native woodland mesh "+name)
	print("RIVER_ENVIRONMENT_STRUCTURE_PASS ",JSON.stringify({"walkable_samples":unchanged,"native_crowns":crowns,"native_willows":willows,"talus_fan_parts":toes,"riparian_clumps":grass,"visual_verdict":"NOT_RUN"}))
	map.queue_free()
	await process_frame
	quit(0)
