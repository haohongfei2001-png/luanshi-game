extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Existing:=preload("res://scripts/field/river_pass_profile.gd")
func _initialize() -> void:
	assert(Ground.authored_landform_enabled)
	var samples:=0;var water:=0;var accessible:=0;var asymmetry:=0.
	for iz in range(-104,105):
		for ix in range(60,133):
			var p:=Vector2(ix,iz)*.25;var depth:=Ground.moat_depth(p)
			assert(depth>=0. and depth<=1.)
			if absf(p.y)<=5.3:assert(is_equal_approx(depth,Existing.moat_depth(p)),"Bridge depth changed")
			if absf(p.y)>Ground.MOAT_DECK:
				var h:=Ground.deck_height(p,true)
				if h<Ground.BATTLE_WATER_LEVEL+.12 and depth>0.:
					water+=1;assert(Ground.moat_blocks(p),"Visually submerged navigable cell")
				if not Ground.moat_blocks(p):accessible+=1
			asymmetry=maxf(asymmetry,absf(depth-Ground.moat_depth(Vector2(48.-p.x,p.y))))
			samples+=1
	var max_join_gap:=0.
	for i in range(-254,255):
		var z:=float(i)*.1;var x:=Ground.AuthoredProfile.water_station(z).x
		var gap:=absf(Ground.deck_height(Vector2(x-.0001,z),true)-Ground.deck_height(Vector2(x+.0001,z),true))
		max_join_gap=maxf(max_join_gap,gap)
	assert(max_join_gap<.002,"Asymmetric bank sections have a discontinuous central join")
	assert(water>1000 and accessible>1000 and asymmetry>.15)
	print("ASYMMETRIC_WATERCOURSE_PASS ",JSON.stringify({"max_central_join_gap_over_0_2mm_m":max_join_gap,"samples":samples,"submerged_or_wet_blocked":water,"accessible_bank_samples":accessible,"max_cross_channel_depth_asymmetry":asymmetry,"bridge_depth":"EXACT","graphics":"NOT_RUN"}))
	quit()
