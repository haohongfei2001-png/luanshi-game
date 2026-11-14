extends SceneTree
## Read-only search of the actual fixed-seed battle for unoccluded complete cuts.
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const OUT:="res://docs/evidence/river-gate-v1-rc23/native-chain/clear-sequences.json"

func _initialize() -> void:
	call_deferred("_run")

func _crowd(b:Battle,u:Battle.Unit) -> Dictionary:
	var live:=0
	var dead:=0
	var horses:=0
	for other:Battle.Unit in b.roster:
		if other.id==u.id or other.state==Battle.State.ESCAPED: continue
		var d2:=other.pos.distance_squared_to(u.pos)
		if d2>16.: continue
		if other.mounted and other.mount_hp>0.: horses+=1
		if d2<6.25:
			if other.state==Battle.State.DEAD: dead+=1
			else: live+=1
	return {"live":live,"dead":dead,"horses":horses}

func _run() -> void:
	var b:=Battle.new()
	b.setup(512,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true)
	b.start()
	var states:=PackedInt32Array()
	states.resize(b.roster.size())
	states.fill(-1)
	var movement:=PackedFloat32Array()
	movement.resize(b.roster.size())
	var pending:={}
	var completed:Array=[]
	var fingerprint:={}
	while b.tick<500 and b.result=="":
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
		if b.tick==100:
			var marker:Battle.Unit=b.roster[617]
			fingerprint={"actor":617,"tick":b.tick,"position":[marker.pos.x,marker.pos.y],"hp":marker.hp,"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate()}
		for u:Battle.Unit in b.roster:
			if u.hero or u.officer or u.mounted or u.kit not in [0,1]: continue
			if u.state==Battle.State.WINDUP and states[u.id]==Battle.State.MARCH and movement[u.id]>.10:
				if not u.stock_strike and u.move_slot==0 and u.target>=0:
					pending[u.id]={"actor":u.id,"kit":u.kit,"start":maxi(1,b.tick-6),"windup":b.tick,"hit":-1,"resume":-1,
						"impacts":u.impacts,"recovered":false,"walked":0.,"peak_live":0,"peak_dead":0,"peak_horses":0}
			if pending.has(u.id):
				var row:Dictionary=pending[u.id]
				var crowd:=_crowd(b,u)
				row.peak_live=maxi(row.peak_live,crowd.live)
				row.peak_dead=maxi(row.peak_dead,crowd.dead)
				row.peak_horses=maxi(row.peak_horses,crowd.horses)
				if u.impacts>int(row.impacts) and int(row.hit)<0:
					row.hit=b.tick
					row.position=[u.pos.x,u.pos.y]
					row.facing=[u.facing.x,u.facing.y]
				if u.state==Battle.State.RECOVER: row.recovered=true
				if row.recovered and u.state==Battle.State.MARCH:
					if int(row.resume)<0: row.resume=b.tick
					row.walked+=u.pos.distance_to(u.before)
				if int(row.hit)>0 and row.walked>.12 and b.tick-int(row.start)<24:
					row.end=b.tick
					row.score=int(row.peak_horses)*100+int(row.peak_live)*5+int(row.peak_dead)*7
					completed.append(row.duplicate(true))
					pending.erase(u.id)
				elif not b.active(u) or b.tick-int(row.start)>=24:
					pending.erase(u.id)
			states[u.id]=u.state
			movement[u.id]=movement[u.id]*.67+u.pos.distance_to(u.before)
	completed.sort_custom(func(a:Dictionary,c:Dictionary)->bool: return a.score<c.score)
	if completed.size()>16: completed.resize(16)
	var proof={"seed":Battle.SEED,"ordinary":[512,512],"fingerprint":fingerprint,"top":completed,"simulated_steps":b.tick}
	FileAccess.open(OUT,FileAccess.WRITE).store_string(JSON.stringify(proof,"  "))
	print("NATIVE_CLEAR_SCOUT ",JSON.stringify(proof))
	quit(0)
