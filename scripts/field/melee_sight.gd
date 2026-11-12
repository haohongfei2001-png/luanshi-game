extends RefCounted
## Only changes a follow camera's pitch. Steel, bodies, the ram and architecture keep
## their normal depth test. The four sample points come from the same right-hand clip as the GPU.
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Art:=preload("res://scripts/field/company_art.gd")
const GRIP:=Vector3(0.273,0.943,0.075)
const TIP_Z:=[1.055,1.055,1.69,2.034,2.304,0.0,0.0,1.055,0.855]
const TIP_Y:=[0.012,0.142,0.0,0.0,0.143,0.0,0.0,0.012,0.012]
const CELLS:=[Vector2i.ZERO,Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]
const PITCH_STEP:=PI/30.0 # six degrees
static var _bank: Image
static var _quat12:=false
var sampled:=-100
var target:=0.0
var offset:=0.0
var hold_until:=-1
var enabled:=true
var probes:=PackedVector3Array()
var centers:=PackedVector3Array()
var body_height:=PackedFloat32Array()
var body_radius:=PackedFloat32Array()
var last_input_score:=0.0
var last_output_score:=0.0

func prepare() -> void:
	if _bank==null and DisplayServer.get_name()!="headless":
		_bank=Art.MOTION.get_image()
		if _bank!=null:
			# Earlier compatible palettes left translation alpha opaque; fitted V2 stores
			# the four low quaternion nibbles in those two spare alpha channels.
			for at in [Vector2i(1,0),Vector2i(2,0),Vector2i(25,42),Vector2i(26,42)]:
				if _bank.get_pixelv(at).a8!=255:_quat12=true;break

func reset() -> void:
	sampled=-100
	offset=0.0
	target=0.0
	hold_until=-1

func _weapon(b: Battle,alpha: float) -> bool:
	var u:=b.hero
	var kit:=u.kit
	if kit==Battle.Arms.Kit.BOW or kit==Battle.Arms.Kit.CROSSBOW: return false
	if _bank==null or _bank.get_width()!=384 or _bank.get_height()!=576: return false
	var clip:=10 if u.state==Battle.State.GUARD else ((2 if u.state==Battle.State.WINDUP else 6)+u.move_slot)
	var frame:=clampi(int((1.0-u.timer/maxf(u.duration,0.001))*31.0+0.5),0,31)
	var x:=(frame%8)*48+8*3 # RH is the bound hand and the weapon's rigid socket.
	var y:=(kit*16+clip)*4+frame/8
	var rgba:=_bank.get_pixel(x,y)
	var q:=Quaternion(rgba.r*2.0-1.0,rgba.g*2.0-1.0,rgba.b*2.0-1.0,rgba.a*2.0-1.0).normalized()
	var high:=_bank.get_pixel(x+1,y)
	var low:=_bank.get_pixel(x+2,y)
	if _quat12:
		var h:=high.a8
		var l:=low.a8
		q=Quaternion(((rgba.r8<<4)+(h>>4))/2047.5-1.0,((rgba.g8<<4)+(h&15))/2047.5-1.0,((rgba.b8<<4)+(l>>4))/2047.5-1.0,((rgba.a8<<4)+(l&15))/2047.5-1.0).normalized()
	var tr:=(Vector3(high.r,high.g,high.b)*256.0+Vector3(low.r,low.g,low.b))/257.0*6.0-Vector3.ONE*3.0
	var feet:=Ground.unit_point(u.before.lerp(u.pos,alpha))
	var yaw:=Basis(Vector3.UP,atan2(u.facing.x,u.facing.y))
	var tip:=Vector3(0,TIP_Y[kit],TIP_Z[kit])
	probes.clear()
	for fraction: float in [0.0,0.30,0.68,0.94]:
		probes.append(feet+yaw*((q*(GRIP+tip*fraction)+tr)*1.07))
	return true

func _gather(b: Battle,alpha: float) -> bool:
	centers.clear();body_height.clear();body_radius.clear()
	var hero:=b.hero
	var cell:=b._cell(hero.pos)
	var touched:=0
	var opponent:=false
	for d: Vector2i in CELLS:
		var x:=cell.x+d.x
		var y:=cell.y+d.y
		if x<0 or x>=Battle.COLS or y<0 or y>=Battle.ROWS: continue
		var id:=b.grid[y*Battle.COLS+x]
		while id>=0:
			touched+=1
			var u:=b.roster[id]
			id=b.links[id]
			if u!=hero and b.active(u):
				var pos:=u.before.lerp(u.pos,alpha)
				var dist:=pos.distance_squared_to(hero.pos)
				if dist<=24.0:
					if u.team!=hero.team and dist<12.25: opponent=true
					var h:=1.70 if not u.officer else 1.81
					if b.corps.is_wounded(u.id):h=0.91
					centers.append(Ground.unit_point(pos)+Vector3.UP*(0.77 if u.mounted else 0.0))
					body_height.append(h)
					body_radius.append(0.31 if u.officer else 0.28)
			if centers.size()>=32 or touched>=112: return opponent
	return opponent

func _score(yaw: float,pitch: float) -> float:
	var right:=Vector3(cos(yaw),0,-sin(yaw))
	var eye:=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
	var up:=eye.cross(right)
	var obstruction:=0.0
	for k in probes.size():
		var worst:=0.0
		for i in centers.size():
			var d:=probes[k]-centers[i]
			var x:=d.dot(right)
			var radius:=body_radius[i]
			if absf(x)>=radius: continue
			# The depth test is evaluated at the proxy's projected height. A rear
			# soldier crossing the same screen coordinate must not steer the camera.
			var height:=clampf(d.dot(up)/up.y,0.40,body_height[i])
			var relative:=d-Vector3.UP*height
			if relative.dot(eye)>=-0.13: continue
			var y:=relative.dot(up)
			var sq:=(x*x+y*y)/(radius*radius)
			if sq<1.0:worst=maxf(worst,1.0-sq)
		obstruction+=worst*(1.16 if k<2 else 1.0)
	return obstruction

func update(b: Battle,base_pitch: float,yaw: float,zoom: float,alpha: float,dt: float,following: bool) -> float:
	if not enabled or not following or not b.started or b.result!="" or b.vehicle!=0 or zoom>31.0:
		reset()
		return 0.0
	var u:=b.hero
	if sampled>b.tick: reset()
	if sampled+2<=b.tick:
		sampled=b.tick
		if u.state in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD] and _weapon(b,alpha) and _gather(b,alpha) and centers.size()>=2:
			var normal:=_score(yaw,base_pitch)
			last_input_score=normal
			last_output_score=normal
			var best:=0.0
			var best_score:=normal
			if normal>=0.62:
				for candidate: float in [PITCH_STEP,PITCH_STEP*2.0]:
					var score:=_score(yaw,base_pitch+candidate)
					# Choose the smallest useful adjustment and discount tiny model-edge changes.
					if score+(0.12 if best>0.0 else 0.0)<best_score:
						best_score=score
						best=candidate
			if best>0.0 and normal-best_score>=0.45:
				target=best
				hold_until=b.tick+6
				last_output_score=best_score
			elif b.tick>hold_until:target=0.0
		elif b.tick>hold_until:target=0.0
	# No roll or yaw: WASD and mouse bearings stay the same. Limit angular travel
	# even when an entire front rank simultaneously steps into the eye line.
	offset=move_toward(offset,target,maxf(dt,0.0)*deg_to_rad(27.0 if target>offset else 20.0))
	return offset
