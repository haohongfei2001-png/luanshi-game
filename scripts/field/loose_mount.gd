extends RefCounted
## A surviving ordinary horse follows a short bank/verge path after its rider falls.
## Positions come from the saved instant of loss, even when the camera was elsewhere.
const Ground:=preload("res://scripts/field/ground.gd")
const STEP:=.58
const GATHER:=.72
const SETTLE:=1.18

var points:=PackedVector2Array()
var lengths:=PackedFloat32Array()
var start_pose:=Transform2D.IDENTITY
var rest_pose:=Transform2D.IDENTITY
var length:=0.
var wait:=0.
var speed:=0.
var duration:=0.

func _init(start:Vector2,facing:Vector2,lot:int) -> void:
	var heading:=facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT
	start_pose=Transform2D(atan2(heading.x,heading.y),start)
	points.append(start)
	lengths.append(0.)
	var side:=signf(start.y)
	if absf(start.y)<1.5: side=signf(heading.y) if absf(heading.y)>.30 else (1. if lot%2==0 else -1.)
	var bank:=signf(start.x-Ground.MOAT_X)
	if absf(start.x-Ground.MOAT_X)<.6: bank=1. if heading.x>=0. else -1.
	var clear_gate:=absf(start.x-Ground.WALL_X)<1.55 and absf(start.y)<Ground.GATE_HALF-.3
	var inside:=start.x>=Ground.WALL_X
	var goal:=start+Vector2(heading.x*(3.+lot%5),side*(12.+lot%8))
	if start.x>Ground.RIVER_X+7. and start.x<Ground.BACK_X-2.:
		if inside and absf(start.y)<Ground.WALL_Z:
			goal.x=clampf(start.x+4.+lot%7,Ground.WALL_X+7.,Ground.BACK_X-3.)
			goal.y=clampf(goal.y,-Ground.WALL_Z+3.,Ground.WALL_Z-3.)
		elif not inside:
			var splay:=float((lot*13)%19-9)*.42
			goal.x=clampf(start.x+splay,Ground.MOAT_X+Ground.MOAT_BANK+2.,Ground.WALL_X-4.) if bank>0. else clampf(start.x+splay,Ground.RIVER_X+8.,Ground.MOAT_X-Ground.MOAT_BANK-2.)
	goal=goal.clamp(-Ground.LIMIT+Vector2.ONE,Ground.LIMIT-Vector2.ONE)
	var waypoints:=PackedVector2Array()
	# A mount on the deck first reaches its own bank on the bridge boards.
	if absf(start.x-Ground.MOAT_X)<Ground.MOAT_BANK+1. and absf(start.y)<Ground.MOAT_DECK+.4:
		waypoints.append(Vector2(Ground.MOAT_X+bank*(Ground.MOAT_BANK+1.45),clampf(start.y,-Ground.MOAT_DECK+.75,Ground.MOAT_DECK-.75)))
	if clear_gate:
		waypoints.append(Vector2(Ground.WALL_X+(3.3 if inside else -3.3),clampf(start.y,-2.5,2.5)))
	elif Ground.parapet(start)>.1:
		waypoints.append(Vector2(Ground.WALL_X+3.,side*5.1))
		waypoints.append(Vector2(Ground.WALL_X+6.4,side*4.6))
	waypoints.append(goal)
	var p:=start
	for waypoint in waypoints:
		for i in 95:
			if p.distance_squared_to(waypoint)<STEP*STEP: break
			var aim:=p.direction_to(waypoint)
			# A rider that fell near a bridge lip leaves at its current bank. Once
			# the horse has left the boards it can turn out along the dry verge.
			var on_deck:=absf(p.x-Ground.MOAT_X)<Ground.MOAT_BANK+.3 and absf(p.y)<=Ground.MOAT_DECK+.05
			if on_deck and absf(waypoint.x-Ground.MOAT_X)>Ground.MOAT_BANK: aim.y=clampf(aim.y,-.34,.34)
			# A real horse turns through its neck and shoulders over several strides.
			var radians:=wrapf(aim.angle()-heading.angle(),-PI,PI)
			heading=heading.rotated(clampf(radians,-.29,.29)).normalized()
			var next:=Ground.travel(p,heading*STEP,clear_gate,true)
			if on_deck and absf(next.y)>Ground.MOAT_DECK-.12 and absf(next.x-Ground.MOAT_X)<Ground.MOAT_WATER+.3:
				next=Ground.travel(p,aim.normalized()*STEP,clear_gate,true)
			if p.distance_squared_to(next)<.015:
				next=Ground.travel(p,aim*STEP,clear_gate,true)
			if p.distance_squared_to(next)<.015: break
			heading=p.direction_to(next)
			length+=p.distance_to(next)
			p=next
			points.append(p)
			lengths.append(length)
	wait=.58+.032*float(lot%8)
	speed=minf(3.55+.12*float(lot%5),length/(.5*(GATHER+SETTLE)+.15))
	if speed>.01: duration=length/speed+.5*(GATHER+SETTLE)
	rest_pose=start_pose if points.size()==1 else Transform2D(atan2(heading.x,heading.y),p)

func distance_at(age:float) -> float:
	var t:=age-wait
	if t<=0. or length==0.: return 0.
	if t>=duration: return length
	if t<GATHER: return speed*.5*t*t/GATHER
	if t>duration-SETTLE: return length-speed*.5*pow(duration-t,2)/SETTLE
	return speed*(t-.5*GATHER)

## The planar angle uses the art's +Z muzzle; Godot Y rotation has the same angle.
func sample(distance:float) -> Transform2D:
	if distance<=0.: return start_pose
	if distance>=length: return rest_pose
	var i:=clampi(lengths.bsearch(distance),1,points.size()-1)
	var delta:=points[i]-points[i-1]
	var weight:=(distance-lengths[i-1])/(lengths[i]-lengths[i-1])
	var dir:=delta.normalized()
	var previous:=points[i-1]-points[i-2] if i>=2 else Vector2(sin(start_pose.get_rotation()),cos(start_pose.get_rotation()))
	var following:=points[i+1]-points[i] if i+1<points.size() else delta
	var incoming:=(previous.normalized()+dir).normalized()
	var outgoing:=(dir+following.normalized()).normalized()
	var angle:=lerp_angle(atan2(incoming.x,incoming.y),atan2(outgoing.x,outgoing.y),weight)
	return Transform2D(angle,points[i-1].lerp(points[i],weight))
