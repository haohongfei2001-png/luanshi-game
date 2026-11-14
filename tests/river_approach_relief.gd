extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Store:=preload("res://scripts/field/save.gd")
const Battle:=preload("res://scripts/field/battle.gd")
func _initialize() -> void:
	var legacy_samples:=0
	var max_grade:=0.
	for x in range(-118,119,2):
		for z in range(-64,65,2):
			var p:=Vector2(x,z)
			var slope:=(p-Ground.RIDGE)/Ground.RIDGE_RADII
			var east:=(p-Ground.EAST_HILL)/Ground.EAST_RADII
			var bank:=clampf((absf(p.x-Ground.RIVER_X)-3.9)/2.4,0.,1.)
			var original:=3.9*pow(maxf(0.,1.-slope.length_squared()),2)+1.8*pow(maxf(0.,1.-east.length_squared()),2)-(1.-bank)*.92
			assert(is_equal_approx(Ground.height(p,false),original),"Legacy open-field height changed")
			legacy_samples+=1
	for x in range(30,47):
		for z in range(-18,19):
			var p:=Vector2(x,z)
			if Ground.blocked(p,true,true):continue
			var h:=Ground.deck_height(p,true)
			assert(is_equal_approx(Ground.unit_point(p,true).y,h))
			var grade:=Vector2(Ground.bridgehead_relief(p+Vector2(.1,0))-Ground.bridgehead_relief(p-Vector2(.1,0)),Ground.bridgehead_relief(p+Vector2(0,.1))-Ground.bridgehead_relief(p-Vector2(0,.1))).length()/.2
			max_grade=maxf(max_grade,grade)
	print("APPROACH_GRADE ",max_grade)
	assert(max_grade<.72,"Approach develops an unwalkable abrupt step")
	assert(Ground.bridgehead_relief(Vector2(36.,0.))>.5,"Road crown missing")
	assert(Ground.bridgehead_relief(Vector2(35.,-11.8))>2.,"North shoulder missing")
	assert(Ground.bridgehead_relief(Vector2(36.8,14.2))>1.6,"South terrace missing")
	for z in range(-24,25):
		assert(is_zero_approx(Ground.bridgehead_relief(Vector2(Ground.WALL_X,z))),"Wall foundation lifted")
	for x in range(18,30):
		assert(is_zero_approx(Ground.bridgehead_relief(Vector2(x,0.))),"Bridge abutment lifted")
	var battle:=Battle.new()
	battle.setup(20,Battle.SEED,3,true,true,20,true)
	battle.hero.pos=Vector2(36.,0.)
	battle.hero.before=battle.hero.pos
	var before:=Store.snapshot(battle)
	var restored:=Store.restore(before)
	assert(restored!=null and restored.hero.pos==battle.hero.pos)
	assert(restored.hero.hp==battle.hero.hp and restored.ordinary_counts==battle.ordinary_counts)
	assert(restored.losses==battle.losses and restored.rng.state==battle.rng.state)
	print("RIVER_APPROACH_RELIEF_PASS ",JSON.stringify({"legacy_samples":legacy_samples,"max_approach_grade":max_grade,"road_height":Ground.deck_height(Vector2(36.,0.),true),"north_shoulder":Ground.deck_height(Vector2(35.,-11.8),true),"south_shoulder":Ground.deck_height(Vector2(36.8,14.2),true),"save_restoration":true}))
	quit(0)
