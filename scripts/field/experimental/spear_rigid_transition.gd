extends "res://scripts/field/experimental/spear_transition.gd"
## Research iteration: separated quaternion/pivot residuals, connected rigid limbs.
## Not contact IK. Source-supported soles may raise the whole body, never freeze XZ.
const PARENTS:=[-1,0,1,1,3,4,1,6,7,0,9,10,0,12,13,5]
const PIVOTS:=[Vector3(0,.86,0),Vector3(0,1.008,0),Vector3(0,1.427,.015),
	Vector3(-.225,1.405,-.012),Vector3(-.258,1.145,.014),Vector3(-.273,.915,.055),
	Vector3(.225,1.405,-.012),Vector3(.258,1.145,.014),Vector3(.273,.915,.055),
	Vector3(-.12,.858,-.012),Vector3(-.134,.477,.021),Vector3(-.141,.123,-.016),
	Vector3(.12,.858,-.012),Vector3(.134,.477,.021),Vector3(.141,.123,-.016),Vector3(-.273,.915,.055)]
var rotation_residual:Array[Quaternion]=[]
var pivot_residual:=Vector3.ZERO
var last_support_mask:=0
var last_support_lift:=0.

static func sole_min(m:Transform3D,bone:int) -> float:
	var bottom:=INF
	for dx:float in [-.05,.05]:
		for dz:float in [-.072,.187]: bottom=minf(bottom,(m*(PIVOTS[bone]+Vector3(dx,-.117,dz))).y)
	return bottom

func sample(poses:Array[Transform3D],model:Transform3D,clip:int,time:float) -> Array[Transform3D]:
	assert(poses.size()==BONES)
	if previous_time<0. or time<previous_time or time-previous_time>.2:
		previous.clear()
		rotation_residual.clear()
		previous_clip=-1
		started=-1.
	var world:Array[Transform3D]=[]
	for pose:Transform3D in poses: world.append(model*pose)
	if clip!=previous_clip and not previous.is_empty():
		rotation_residual.clear()
		for i:int in BONES:
			var old:=previous[i].basis.orthonormalized().get_rotation_quaternion()
			var next:=world[i].basis.orthonormalized().get_rotation_quaternion()
			rotation_residual.append((old*next.inverse()).normalized())
		pivot_residual=previous[0]*PIVOTS[0]-world[0]*PIVOTS[0]
		started=time
	var weight:=decay(time-started) if started>=0. else 0.
	var shown:Array[Transform3D]=[]
	last_support_mask=0
	last_support_lift=0.
	if weight>0. and rotation_residual.size()==BONES:
		for i:int in BONES:
			var correction:=Quaternion.IDENTITY.slerp(rotation_residual[i],weight)
			var basis:=Basis(correction)*world[i].basis
			var pivot:Vector3=world[i]*PIVOTS[i]+pivot_residual*weight if i==0 else shown[PARENTS[i]]*PIVOTS[i]
			shown.append(Transform3D(basis,pivot-basis*PIVOTS[i]))
		# The unmodified author pose identifies support. Swing feet are not pinned.
		# Keep original clearance; lifting all bones preserves rigid limbs/grip seams.
		for bone:int in [11,14]:
			var source_height:=sole_min(world[bone],bone)-model.origin.y
			if source_height<=.018*model.basis.x.length():
				last_support_mask|=1 if bone==11 else 2
				last_support_lift=maxf(last_support_lift,model.origin.y+source_height-sole_min(shown[bone],bone))
		if last_support_lift>0.:
			for i:int in BONES: shown[i].origin.y+=last_support_lift
	else:
		shown=world.duplicate()
	var inverse_basis:=model.basis.inverse()
	var local:Array[Transform3D]=[]
	for i:int in BONES:
		var offset:=difference(shown[i],world[i])
		local.append(Transform3D(inverse_basis*offset.basis,inverse_basis*offset.origin))
	previous=shown
	previous_time=time
	previous_clip=clip
	return local
