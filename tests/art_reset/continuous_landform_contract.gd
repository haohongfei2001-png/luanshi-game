extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Existing:=preload("res://scripts/field/river_pass_profile.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(not Ground.authored_landform_enabled,"Test requires normal default OFF")
	var samples:=[];var old_height:=[];var old_open:=[];var old_blocked:=[]
	for z in range(-64,65,2):
		for x in range(-118,119,2):
			var p:=Vector2(x,z);samples.append(p);old_height.append(Ground.height(p,true));old_open.append(Ground.height(p,false));old_blocked.append(Ground.blocked(p,true,true))
			assert(Ground.height(p,true)==Existing.height(p),"Default changed existing saves")
	Ground.authored_landform_enabled=true;var changed:=0;var max_delta:=0.;var blocked_changes:=0;var tree_changes:=0
	for i in samples.size():
		var p:Vector2=samples[i]
		assert(Ground.height(p,false)==old_open[i],"Open-field save support changed")
		if Ground.blocked(p,true,true)!=old_blocked[i]:
			blocked_changes+=1
			var in_new_woodland:=Ground.native_woodland_enabled and Ground.NativeWoodland.blocked(p)
			if in_new_woodland:tree_changes+=1
			assert(in_new_woodland or (p.x>15. and p.x<33. and absf(p.y)>3.7 and absf(p.y)<26.),"Navigation change escaped exact authored moat/tree footprints")
		var delta:float=absf(Ground.height(p,true)-old_height[i]);max_delta=maxf(max_delta,delta)
		if delta>.00001:changed+=1
		var in_approach:=p.x>0. and p.x<46.6 and absf(p.y)<38.
		var in_shore_shelves:=false # Old isolated scan-support shelves removed
		if not in_approach and not in_shore_shelves:assert(delta==0.,"Landform escaped explicit approach/shore domains")
	for bridge_x:float in [-32.,24.]:
		for z:float in ([-35.,0.,35.] if bridge_x<0 else [0.]):
			assert(is_equal_approx(Ground.deck_height(Vector2(bridge_x,z),true),.13))
	for z in range(-23,24):
		assert(Ground.height(Vector2(48,z),true)==Existing.height(Vector2(48,z)))
	assert(changed>100 and max_delta>.3,"No actual terrain reconstruction")
	print("LANDFORM_CONTRACT_PASS ",JSON.stringify({"sample_count":samples.size(),"changed_support_samples":changed,"max_delta_m":max_delta,"old_open_field":"EXACT","default":"OFF","blocked_route_samples_changed_total":blocked_changes,"changed_inside_exact_tree_footprints":tree_changes,"allowed_navigation_domains":"authored moat and opt-in source wood footprints","graphics":"NOT_RUN"}))
	Ground.authored_landform_enabled=false;quit()
