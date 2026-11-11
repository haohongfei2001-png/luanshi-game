extends RefCounted
const Builder := preload("res://scripts/field/mesh_builder.gd")
const Arms := preload("res://scripts/field/arms.gd")
const SKIN := Color("d1a07e")
const IRON := Color("70776f")
const EDGE := Color("c1c5b9")
const HIDE := Color("4c352b")
const WOOD := Color("805a3a")
const HAIR := Color("312a26")
const CLOTH := Color("d5c8a5")
const BRASS := Color("b28c52")

static func fighter(kit: int, detailed: bool) -> ArrayMesh:
	var b := Builder.new()
	var n := 8 if detailed else 5
	var lamellar:=kit in [Arms.Kit.SHIELD,Arms.Kit.GLAIVE,Arms.Kit.CROSSBOW]
	var vest:=IRON if lamellar else Color("93775b")
	for side: float in [-1.0,1.0]:
		b.joint = 1 if side < 0 else 2
		var x := side * 0.14
		b.rod(Vector3(x,0.72,0),Vector3(x*1.12,0.16,0),0.118,0.080,HIDE,n)
		b.block(Vector3(x*1.12,0.09,0.046),Vector3(0.16,0.15,0.27),HAIR)
	b.joint = 0
	b.dye = 1
	b.loft([Vector3(0,0.53,0),Vector3(0,0.94,0),Vector3(0,1.28,0),Vector3(0,1.38,0)],
		[Vector2(0.34,0.23),Vector2(0.225,0.16),Vector2(0.31,0.20),Vector2(0.18,0.14)],n,CLOTH)
	b.dye = 0
	b.loft([Vector3(0,0.96,0),Vector3(0,1.25,0)], [Vector2(0.257,0.184),Vector2(0.296,0.209)],n,vest)
	b.loft([Vector3(0,0.88,0),Vector3(0,0.955,0)], [Vector2(0.254,0.181),Vector2(0.25,0.184)],n,HIDE)
	if detailed:
		for row in 3:
			for i in 5:
				b.block(Vector3((i-2)*0.079,1.019+row*0.078,0.181-absf(i-2)*0.020),Vector3(0.070,0.066,0.035),vest.lightened(0.09*(row%2)))
		if lamellar:
			for side: float in [-1,1]:
				b.loft([Vector3(side*0.215,0.63,0),Vector3(side*0.193,0.88,0)],[Vector2(0.14,0.177),Vector2(0.145,0.168)],6,vest)
		b.block(Vector3(0,0.918,0.185),Vector3(0.09,0.055,0.038),BRASS)
		b.rod(Vector3(-0.17,1.36,0.10),Vector3(0.08,1.13,0.20),0.036,0.029,HIDE)
	# Shaped jaw, cheek, brow and helmet. The positive Z axis is the direction of contact.
	b.loft([Vector3(0,1.34,0.015),Vector3(0,1.42,0.043),Vector3(0,1.53,0.018),Vector3(0,1.62,0)],
		[Vector2(0.088,0.092),Vector2(0.123,0.13),Vector2(0.155,0.153),Vector2(0.142,0.14)],n,SKIN)
	if detailed:
		b.rod(Vector3(0,1.526,0.143),Vector3(0,1.475,0.174),0.028,0.026,SKIN)
		for sign_x: float in [-1.0,1.0]:
			b.block(Vector3(sign_x*0.064,1.526,0.15),Vector3(0.061,0.015,0.015),HAIR)
			b.rod(Vector3(sign_x*0.148,1.51,0.006),Vector3(sign_x*0.148,1.456,0.012),0.031,0.024,SKIN)
	b.loft([Vector3(0,1.55,-0.023),Vector3(0,1.64,-0.023),Vector3(0,1.72,-0.035)],
		[Vector2(0.184,0.185),Vector2(0.16,0.16),Vector2(0.053,0.053)],n,IRON if kit not in [Arms.Kit.BOW,Arms.Kit.STAFF] else HAIR)
	if detailed:
		b.rod(Vector3(0,1.57,-0.016),Vector3(0,1.593,-0.018),0.177,0.169,HIDE,8)
		for side: float in [-1,1]:
			b.block(Vector3(side*0.13,1.466,-0.055),Vector3(0.046,0.14,0.151),vest)
		b.block(Vector3(0,1.431,0.161),Vector3(0.056,0.010,0.012),Color("8e5d49"))
	b.dye = 1
	b.rod(Vector3(0,1.70,-0.035),Vector3(0,1.79,-0.078),0.048,0.025,CLOTH)
	b.dye = 0
	for side: float in [-1.0,1.0]:
		b.joint = 3 if side > 0 else 4
		var shoulder := Vector3(side*0.255,1.28,0)
		var elbow := Vector3(side*0.35,1.00,0.05)
		var hand := Vector3(side*0.34,1.01,0.30)
		b.dye = 1
		b.rod(shoulder,elbow,0.115,0.080,CLOTH,n)
		b.dye = 0
		b.rod(elbow,hand,0.078,0.053,HIDE,n)
		b.rod(hand - Vector3(0,0,0.025),hand+Vector3(0,0.006,0.093),0.067,0.052,SKIN,n)
		if detailed:
			b.rod(hand+Vector3(-side*0.044,0.034,0.015),hand+Vector3(-side*0.061,0.032,0.075),0.028,0.014,SKIN)
	b.joint = 3
	match kit:
		Arms.Kit.BOW:
			var grip := Vector3(0.34,1.03,0.36)
			for side: float in [-1.0,1.0]:
				var bend := grip+Vector3(0,side*0.42,0.12)
				var tip := grip+Vector3(0,side*0.69,-0.13)
				b.rod(grip,bend,0.030,0.023,WOOD)
				b.rod(bend,tip,0.023,0.014,WOOD)
				b.rod(tip,grip+Vector3(0,0,-0.29),0.009,0.009,CLOTH,3)
		Arms.Kit.CROSSBOW:
			b.block(Vector3(0.34,1.035,0.42),Vector3(0.115,0.11,0.90),WOOD)
			for side: float in [-1.0,1.0]:
				var tip := Vector3(0.34+side*0.45,1.1,0.48)
				b.rod(Vector3(0.34,1.09,0.73),tip,0.039,0.021,IRON)
				b.rod(tip,Vector3(0.34,1.11,0.22),0.010,0.010,CLOTH,3)
		Arms.Kit.STAFF, Arms.Kit.SPEAR, Arms.Kit.GLAIVE:
			var tip_z := 1.88 if kit != Arms.Kit.STAFF else 1.42
			b.rod(Vector3(0.34,0.91,-0.65),Vector3(0.34,1.13,tip_z),0.040,0.030,WOOD)
			if kit == Arms.Kit.SPEAR:
				b.rod(Vector3(0.34,1.13,tip_z-0.04),Vector3(0.34,1.175,tip_z+0.37),0.075,0.002,EDGE,4)
				b.dye = 1
				b.rod(Vector3(0.34,1.13,tip_z-0.12),Vector3(0.34,1.0,tip_z-0.29),0.064,0.043,CLOTH)
				b.dye = 0
			elif kit == Arms.Kit.GLAIVE:
				_blade(b,Vector3(0.34,1.12,tip_z-0.1),0.65,0.14,true)
		_:
			_blade(b,Vector3(0.34,1.02,0.32),0.91 if kit!=Arms.Kit.DUAL else 0.65,0.079 if kit==Arms.Kit.DAO else 0.056,kit==Arms.Kit.DAO)
			if kit == Arms.Kit.DUAL:
				b.joint = 4
				_blade(b,Vector3(-0.34,1.02,0.32),0.62,0.055,false)
			if kit == Arms.Kit.SHIELD:
				b.joint = 4
				b.block(Vector3(-0.34,1.00,0.42),Vector3(0.47,0.80,0.088),HIDE)
				b.block(Vector3(-0.34,1.00,0.48),Vector3(0.072,0.73,0.06),BRASS)
	return b.finish()

static func _blade(b: Builder, p: Vector3,length: float,width: float,curved: bool) -> void:
	b.rod(p-Vector3(0,0,0.12),p+Vector3(0,0,0.14),0.039,0.037,HIDE)
	b.block(p+Vector3(0,0,0.13),Vector3(0.14,0.07,0.055),BRASS)
	var a := p + Vector3(0,0,0.15)
	var m := a + Vector3(0,0.05 if curved else 0,length*0.68)
	var tip := a + Vector3(0,0.19 if curved else 0,length)
	b.quad(a-Vector3(0,width,0),a+Vector3(0,width,0),m+Vector3(0,width*1.15,0),m-Vector3(0,width,0),EDGE)
	b.tri(m-Vector3(0,width,0),m+Vector3(0,width*1.15,0),tip,EDGE)

static func horse(cart: bool = false) -> ArrayMesh:
	var b := Builder.new()
	b.loft([Vector3(0,0.77,0),Vector3(0,1.06,0),Vector3(0,1.30,-0.03)],
		[Vector2(0.20,0.50),Vector2(0.29,0.78),Vector2(0.23,0.63)],8,WOOD)
	b.rod(Vector3(0,1.08,0.43),Vector3(0,1.67,0.77),0.23,0.15,WOOD,7)
	b.rod(Vector3(0,1.65,0.75),Vector3(0,1.50,1.11),0.16,0.10,WOOD,7)
	b.rod(Vector3(0,1.70,0.74),Vector3(0,1.87,0.70),0.088,0.036,HAIR)
	b.rod(Vector3(0,1.23,-0.65),Vector3(0,0.57,-0.87),0.10,0.045,HAIR)
	b.block(Vector3(0,1.32,-0.04),Vector3(0.52,0.12,0.49),HIDE)
	for x: float in [-0.18,0.18]:
		for z: float in [-0.47,0.47]:
			b.joint = 1 if x*z<0 else 2
			b.rod(Vector3(x,0.96,z),Vector3(x,0.50,z+0.09),0.105,0.063,WOOD)
			b.rod(Vector3(x,0.50,z+0.09),Vector3(x,0.10,z),0.068,0.047,HIDE)
			b.block(Vector3(x,0.068,z+0.028),Vector3(0.12,0.12,0.17),HAIR)
	if cart:
		b.joint = 0
		b.block(Vector3(0,0.83,-1.85),Vector3(1.56,0.14,1.28),WOOD)
		for x: float in [-0.78,0.78]:
			b.rod(Vector3(x,0.94,-2.45),Vector3(x*0.6,1.02,0.1),0.055,0.04,WOOD)
			for k in 10:
				var angle := TAU*k/10
				var end := Vector3(x*1.10,0.58+cos(angle)*0.54,-1.84+sin(angle)*0.54)
				var next := Vector3(end.x,0.58+cos(angle+TAU/10)*0.54,-1.84+sin(angle+TAU/10)*0.54)
				b.rod(Vector3(end.x,0.58,-1.84),end,0.034,0.023,WOOD)
				b.rod(end,next,0.062,0.062,HIDE)
	return b.finish()

## At roughly 10–30 px tall, keep the limb joints, livery and weapon silhouette.
## Each limb has an open triangular cross section; details are in the close mesh.
static func silhouette(kit: int) -> ArrayMesh:
	var b:=Builder.new()
	b.dye=1
	b.loft([Vector3(0,0.49,0),Vector3(0,1.24,0),Vector3(0,1.34,0)],[Vector2(0.32,0.20),Vector2(0.29,0.18),Vector2(0.16,0.13)],5,CLOTH)
	b.dye=0
	b.rod(Vector3(0,0.89,0),Vector3(0,0.96,0),0.245,0.24,HIDE,5)
	b.loft([Vector3(0,1.35,0.016),Vector3(0,1.56,0.02)],[Vector2(0.105,0.13),Vector2(0.15,0.15)],5,SKIN)
	b.rod(Vector3(0,1.54,0),Vector3(0,1.73,-0.025),0.177,0.07,IRON,5)
	for sign_x: float in [-1,1]:
		b.joint=1 if sign_x<0 else 2
		b.rod(Vector3(sign_x*0.15,0.60,0),Vector3(sign_x*0.16,0.08,0.025),0.104,0.073,HIDE,3)
		b.joint=4 if sign_x<0 else 3
		b.dye=1
		b.rod(Vector3(sign_x*0.24,1.26,0),Vector3(sign_x*0.34,1.01,0.08),0.11,0.07,CLOTH,3)
		b.dye=0
		b.rod(Vector3(sign_x*0.34,1.01,0.08),Vector3(sign_x*0.34,1.01,0.35),0.066,0.046,SKIN,3)
	b.joint=3
	if kit in [Arms.Kit.SPEAR,Arms.Kit.STAFF,Arms.Kit.GLAIVE]:
		var length:=1.45 if kit==Arms.Kit.STAFF else 1.94
		b.rod(Vector3(0.34,0.93,-0.61),Vector3(0.34,1.14,length),0.044,0.033,WOOD,3)
		if kit!=Arms.Kit.STAFF:
			b.rod(Vector3(0.34,1.14,length-0.19),Vector3(0.34,1.20,length+0.33),0.13 if kit==Arms.Kit.GLAIVE else 0.072,0.005,EDGE,3)
	elif kit==Arms.Kit.BOW:
		for s: float in [-1,1]:
			b.rod(Vector3(0.34,1.03,0.37),Vector3(0.34,1.03+s*0.65,0.22),0.045,0.017,WOOD,3)
			b.rod(Vector3(0.34,1.03+s*0.65,0.22),Vector3(0.34,1.03,0.05),0.012,0.012,CLOTH,3)
	elif kit==Arms.Kit.CROSSBOW:
		b.rod(Vector3(0.34,1.04,0.06),Vector3(0.34,1.08,0.85),0.064,0.045,WOOD,3)
		b.rod(Vector3(-0.09,1.07,0.66),Vector3(0.77,1.07,0.66),0.040,0.030,IRON,3)
	else:
		_blade(b,Vector3(0.34,1.01,0.33),0.82,0.07,kit==Arms.Kit.DAO)
		if kit==Arms.Kit.SHIELD:
			b.joint=4
			b.block(Vector3(-0.34,1.0,0.42),Vector3(0.46,0.8,0.085),HIDE)
		elif kit==Arms.Kit.DUAL:
			b.joint=4
			_blade(b,Vector3(-0.34,1.01,0.33),0.63,0.052,false)
	return b.finish()
