extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Store:=preload("res://scripts/field/save.gd")

func _initialize() -> void:
	# The playable bridge deck and actor height use the same new river section.
	assert(Ground.height(Vector2(Ground.RIVER_X,15.),true)<Ground.BATTLE_WATER_LEVEL)
	assert(Ground.deck_height(Vector2(Ground.MOAT_X,14.),true)<Ground.BATTLE_WATER_LEVEL)
	assert(is_equal_approx(Ground.deck_height(Vector2(Ground.MOAT_X,0.),true),.13))
	assert(is_equal_approx(Ground.height(Vector2(Ground.RIVER_X,15.),false),-.92))
	for x in range(17,33):
		for z in range(-26,27):
			var p:=Vector2(x,z)
			if not Ground.blocked(p,true,true):
				assert(Ground.deck_height(p,true)>Ground.BATTLE_WATER_LEVEL,"A walkable foot position is underwater")
	var old:=Battle.new()
	old.setup(20,Battle.SEED,3,true,true,20,true)
	old.hero.pos=Vector2(Ground.MOAT_X+4.6,12.4)
	old.hero.before=old.hero.pos
	var data:=Store.snapshot(old)
	data.erase("terrain_revision")
	var restored:=Store.restore(data)
	assert(restored!=null)
	assert(not Ground.moat_blocks(restored.hero.pos))
	assert(restored.hero.pos.x>Ground.MOAT_X)
	assert(restored.hero.hp==old.hero.hp and restored.losses==old.losses)
	assert(restored.rng.state==old.rng.state)
	assert(restored.hero.id in restored._near(restored.hero.pos,.05,0),"Migrated actors must be searchable before the next step")
	assert(restored.ordinary_counts==old.ordinary_counts)
	data["terrain_revision"]=2
	var intermediate:=Store.restore(data)
	assert(intermediate!=null and not Ground.moat_blocks(intermediate.hero.pos))
	var current:=Store.snapshot(restored)
	var round_trip:=Store.restore(current)
	assert(round_trip!=null and round_trip.hero.pos==restored.hero.pos)
	assert(round_trip.hero.before==restored.hero.before)
	var field:=Battle.new()
	field.setup(20)
	field.hero.pos=Vector2(0.,0.)
	var previous:=Store.snapshot(field)
	previous.erase("terrain_revision")
	var untouched:=Store.restore(previous)
	assert(untouched!=null and untouched.hero.pos==field.hero.pos)
	current["terrain_revision"]=4
	assert(Store.restore(current)==null)
	print("WORLD_TERRAIN_COMPAT_PASS ",JSON.stringify({"ordinary":Array(restored.ordinary_counts),"old":Array([old.hero.pos.x,old.hero.pos.y]),"restored":[restored.hero.pos.x,restored.hero.pos.y],"losses":restored.losses}))
	quit(0)
