extends SceneTree
const Path:=preload("res://scripts/field/loose_mount.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
var errors:=0

func expect(ok:bool,what:String) -> void:
	if not ok:
		push_error(what)
		errors+=1

func _initialize() -> void:
	var samples:=0
	var minimum:=INF
	var short_paths:=0
	var origins:=[Vector2(24,2.9),Vector2(24,-3.3),Vector2(19.65,3.48),Vector2(20,0),Vector2(29,-3.45),Vector2(28.5,-7),Vector2(30.4,1),Vector2(41,3),Vector2(47.8,0),Vector2(48.5,0),Vector2(49.9,9),Vector2(63,-8),Vector2(17,-4),Vector2(-32,2)]
	for j in origins.size():
		for a in 8:
			var origin:Vector2=origins[j]
			var dir:=Vector2.from_angle(a*PI/4.)
			var route:=Path.new(origin,dir,17*j+a)
			var again:=Path.new(origin,dir,17*j+a)
			expect(route.sample(0.).origin==origin,"First foot at the rider")
			expect(route.sample(0.).origin.is_equal_approx(route.sample(route.distance_at(.4)).origin),"Horse waits for fall")
			expect(is_equal_approx(route.distance_at(500),route.distance_at(450)),"Settled horse")
			var last:=origin
			for k in 361:
				var t:=k/24.
				var d:=route.distance_at(t)
				var at:=route.sample(d)
				expect(not Ground.moat_blocks(at.origin),"Hoof entered the moat at %s" % at.origin)
				var through_open_gate:=absf(origin.x-Ground.WALL_X)<1.55 and absf(origin.y)<Ground.GATE_HALF-.3
				expect(not Ground.blocked(at.origin,through_open_gate,true),"Blocked geometry at %s from %s" % [at.origin,origin])
				expect(at.origin.distance_to(last)<.185,"Exceeded trot speed")
				expect(at.is_equal_approx(again.sample(again.distance_at(t))),"Path depends on previous draws")
				last=at.origin
				samples+=1
			minimum=minf(minimum,route.length)
			if route.length<3.: short_paths+=1
	var b:=Battle.new()
	b.setup(512,Battle.SEED,3,true,true,512,true)
	b.start()
	for ticks in 175: b.step()
	var restored:=Save.restore(Save.snapshot(b))
	expect(restored!=null,"Real bridgehead save could not reload")
	var living_empty:=0
	if restored!=null:
		for u in b.roster:
			if u.mounted and u.state==Battle.State.DEAD and u.mount_hp>0. and u.lost_tick>=0:
				living_empty+=1
				var saved:=restored.roster[u.id]
				var age:=(b.tick-u.lost_tick-.5)*Battle.DT
				var age2:=(restored.tick-saved.lost_tick-.5)*Battle.DT
				var p:=Path.new(u.pos,u.facing,u.id)
				var q:=Path.new(saved.pos,saved.facing,saved.id)
				expect(p.sample(p.distance_at(age)).is_equal_approx(q.sample(q.distance_at(age2))),"Restored mount drift")
	expect(living_empty>0,"No unseated horse sampled from the active battle")
	print("LOOSE_HORSE_", "PASS" if errors==0 else "FAIL"," samples=",samples," distinct_routes=",origins.size()*8," min_length=",minimum," paths_shorter_than_3m=",short_paths," real_saved_loose=",living_empty)
	quit(0 if errors==0 else 1)
