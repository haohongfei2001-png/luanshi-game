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
	Ground.authored_landform_enabled=true;var changed:=0;var max_delta:=0.
	for i in samples.size():
		var p:Vector2=samples[i]
		assert(Ground.height(p,false)==old_open[i],"Open-field save support changed")
		assert(Ground.blocked(p,true,true)==old_blocked[i],"Military routes changed")
		var delta:float=absf(Ground.height(p,true)-old_height[i]);max_delta=maxf(max_delta,delta)
		if delta>.00001:changed+=1
		if p.x<=29.95 or p.x>=46.6 or absf(p.y)>=32.:assert(delta==0.,"Landform escaped intended approach")
	for bridge_x:float in [-32.,24.]:
		for z:float in ([-35.,0.,35.] if bridge_x<0 else [0.]):
			assert(is_equal_approx(Ground.deck_height(Vector2(bridge_x,z),true),.13))
	for z in range(-23,24):
		assert(Ground.height(Vector2(48,z),true)==Existing.height(Vector2(48,z)))
	assert(changed>100 and max_delta>.3,"No actual terrain reconstruction")
	print("LANDFORM_CONTRACT_PASS ",JSON.stringify({"sample_count":samples.size(),"changed_support_samples":changed,"max_delta_m":max_delta,"old_open_field":"EXACT","default":"OFF","blocked_routes":"EXACT","graphics":"NOT_RUN"}))
	Ground.authored_landform_enabled=false;quit()
