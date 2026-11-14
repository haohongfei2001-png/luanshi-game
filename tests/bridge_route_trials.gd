extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
func _initialize() -> void:
	for destination:float in [32.5,33.4,34.,34.8,35.6,36.5,37.3]:
		for lane:float in [-2.8,-.7,2.1]:
			var b:=Battle.new()
			b.setup(512,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,512,true)
			b.start()
			var first:=-1
			var first_hp:=100.
			var near:=INF
			while b.tick<650 and b.result.is_empty():
				var target:Battle.Unit=null
				var d2:=42.
				for id in b._near(b.hero.pos,6.5,1):
					var other:=b.roster[id]
					if other.state==Battle.State.ROUT: continue
					var dd:=b.hero.pos.distance_squared_to(other.pos)
					if dd<d2:
						target=other
						d2=dd
				near=minf(near,sqrt(d2))
				var goal:=Vector2(destination,lane)
				if b.hero.impacts>0:
					if first<0:
						first=b.tick
						first_hp=b.hero.hp
					goal=Vector2(28.65,lane)
				if b.hero.hp<62.: goal=Vector2(26.8,-1.)
				var walk:=Vector2.ZERO
				if b.tick>28 and b.hero.pos.distance_to(goal)>.28:
					var local:=b.hero.pos.direction_to(goal).rotated(deg_to_rad(-33.))
					var angle:=roundf(local.angle()/(PI/4.))*PI/4.
					walk=Vector2.from_angle(angle).rotated(deg_to_rad(33.))
				var aim:=b.hero.pos.direction_to(target.pos) if target!=null else Vector2.RIGHT
				b.input_state(walk,aim)
				if target!=null and b.hero.state==Battle.State.MARCH:
					if b.hero.hp<69. and b.hero_cds[3]<=0: b.press_action(3)
					elif d2<9.75: b.press_action(1 if b.hero_cds[1]<=0 else 0)
					elif d2<22. and b.hero_cds[2]<=0. and b.hero.impacts==0: b.press_action(2)
				if b.tick==90: b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG)
				b.step()
			print("ROUTE ",destination," ",lane," tick=",b.tick," hits=",b.hero.impacts," first=",first," hp_first=",first_hp," hp=",b.hero.hp," near=",near)
	quit()
