extends "res://scripts/field/experimental/spear_rigid_transition.gd"
## Closed two-arm chain for the isolated spear probe. No game activation.
var span_residual:=0.
var last_reach_error:=0.
const PALMS:=[Vector3(-.273,.943,.075),Vector3(.273,.943,.075)]

static func grip(m:Transform3D,side:int) -> Vector3:
	return m*PALMS[0 if side<0 else 1]

static func limit_ball(p:Vector3,center:Vector3,radius:float) -> Vector3:
	var delta:=p-center
	return center+delta.limit_length(radius)

static func place(rest:Vector3,at:Vector3,basis:Basis) -> Transform3D:
	return Transform3D(basis,at-basis*rest)

static func limb(basis:Basis,axis:Vector3,desired:Vector3) -> Basis:
	return Basis(Quaternion((basis*axis).normalized(),desired.normalized()))*basis

func sample(poses:Array[Transform3D],model:Transform3D,clip:int,time:float) -> Array[Transform3D]:
	var raw:Array[Transform3D]=[]
	for p:Transform3D in poses: raw.append(model*p)
	var axis:=raw[8].basis.z.normalized()
	var span:=(grip(raw[5],-1)-grip(raw[8],1)).dot(axis)
	var eligible:=clip in [0,1,2,6] or clip>=16
	var reset:=previous_time<0. or time<previous_time or time-previous_time>.2
	if reset: span_residual=0.
	if not reset and clip!=previous_clip and not previous.is_empty():
		var old_axis:=previous[8].basis.z.normalized()
		span_residual=(grip(previous[5],-1)-grip(previous[8],1)).dot(old_axis)-span
	var ignored:=super.sample(poses,model,clip,time)
	if not eligible or started<0. or decay(time-started)<=0.: return ignored
	span+=span_residual*decay(time-started)
	var weapon:=previous[8].basis
	axis=weapon.z.normalized()
	var support:=axis*span
	var shoulders:Array[Vector3]=[]
	var centers:Array[Vector3]=[]
	var radii:Array[float]=[]
	for side:int in [-1,1]:
		var upper:=3 if side<0 else 6
		var fore:=upper+1
		var hand:=upper+2
		var a:Vector3=PIVOTS[upper]
		var b:Vector3=PIVOTS[fore]
		var c:Vector3=PIVOTS[hand]
		var shoulder:Vector3=previous[1]*a
		shoulders.append(shoulder)
		centers.append(shoulder+weapon*(PALMS[0 if side<0 else 1]-c))
		radii.append(((b-a).length()+(c-b).length())*weapon.x.length()-.0001)
	var anchor:Vector3=(grip(previous[8],1)+grip(previous[5],-1)-support)*.5
	for iteration:int in 24:
		anchor=limit_ball(limit_ball(anchor,centers[0]-support,radii[0]),centers[1],radii[1])
	last_reach_error=maxf(0.,maxf(anchor.distance_to(centers[1])-radii[1],(anchor+support).distance_to(centers[0])-radii[0]))
	for side:int in [-1,1]:
		var index:=0 if side<0 else 1
		var upper:=3 if side<0 else 6
		var fore:=upper+1
		var hand:=upper+2
		var a:Vector3=PIVOTS[upper]
		var b:Vector3=PIVOTS[fore]
		var c:Vector3=PIVOTS[hand]
		var shoulder:=shoulders[index]
		var palm:=anchor+support if side<0 else anchor
		var hand_pose:=place(PALMS[index],palm,weapon)
		var wrist:Vector3=hand_pose*c
		var line:=wrist-shoulder
		var reach:=maxf(line.length(),.0001)
		var forward:=line/reach
		var pole:Vector3=previous[fore]*b-shoulder
		pole-=forward*pole.dot(forward)
		if pole.length_squared()<.00000001:
			pole=forward.cross(Vector3.UP if absf(forward.y)<.9 else Vector3.RIGHT)
		pole=pole.normalized()
		var length_a:=(b-a).length()*weapon.x.length()
		var length_b:=(c-b).length()*weapon.x.length()
		var along:=(length_a*length_a-length_b*length_b+reach*reach)/(2.*reach)
		var elbow:=shoulder+forward*along+pole*sqrt(maxf(0.,length_a*length_a-along*along))
		previous[upper]=place(a,shoulder,limb(previous[upper].basis,b-a,elbow-shoulder))
		previous[fore]=place(b,elbow,limb(previous[fore].basis,c-b,wrist-elbow))
		previous[hand]=hand_pose
	previous[15]=previous[5]
	var offsets:Array[Transform3D]=[]
	var inverse_basis:=model.basis.inverse()
	for i:int in BONES:
		var delta:=difference(previous[i],raw[i])
		offsets.append(Transform3D(inverse_basis*delta.basis,inverse_basis*delta.origin))
	return offsets
