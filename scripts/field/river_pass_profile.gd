extends RefCounted
## Shared editable landform plan for the whole river-pass master.
## x,z metres; the military crossings and fort foundations are surveyed anchors.
const LANDFORMS: Array[Dictionary] = [
 {"center":Vector2(35.,-12.),"radii":Vector2(11.,10.),"rise":2.8},
 {"center":Vector2(36.,15.),"radii":Vector2(11.,11.),"rise":2.2},
 {"center":Vector2(-4.,-30.),"radii":Vector2(29.,23.),"rise":6.4},
 {"center":Vector2(-5.,33.),"radii":Vector2(25.,22.),"rise":4.8},
 {"center":Vector2(-81.,-43.),"radii":Vector2(36.,22.),"rise":7.5},
 {"center":Vector2(43.,-49.),"radii":Vector2(34.,24.),"rise":11.0},
 {"center":Vector2(78.,48.),"radii":Vector2(28.,20.),"rise":8.0},
 {"center":Vector2(123.,-35.),"radii":Vector2(30.,27.),"rise":17.0},
 {"center":Vector2(119.,54.),"radii":Vector2(33.,21.),"rise":15.0},
 {"center":Vector2(-39.,-91.),"radii":Vector2(73.,37.),"rise":28.0},
 {"center":Vector2(71.,-103.),"radii":Vector2(69.,45.),"rise":39.0},
 {"center":Vector2(-133.,24.),"radii":Vector2(32.,82.),"rise":20.0}]
static func crossing(z:float) -> float:
	var choices:=[-35.,0.,35.]
	var closest:=0.
	for v:float in choices:
		if absf(z-v)<absf(z-closest):closest=v
	return closest
static func river_center(z:float) -> float:
	return -32.+smoothstep(4.4,13.,absf(z-crossing(z)))*(2.5*sin(z*.078)+.85*sin(z*.17+.6))
static func river_width(z:float) -> float:
	return smoothstep(4.4,12.,absf(z-crossing(z)))*(1.25+.75*sin(z*.21)+.24*sin(z*.61))
static func moat_center(z:float) -> float:
	return 24.+smoothstep(5.2,13.,absf(z))*(.5*sin(z*.18)+.22*sin(z*.37))
static func moat_depth(p:Vector2) -> float:
	var radius:=Vector2(p.x-moat_center(p.y),maxf(absf(p.y)-18.5,0.)).length()
	var outer:=5.85+smoothstep(5.2,12.,absf(p.y))*(.32*sin(p.y*.28)+.16*sin(p.y*.69))
	return 1.-smoothstep(2.7,outer,radius)
static func height(p:Vector2) -> float:
	var land:=0.
	for form:Dictionary in LANDFORMS:
		var q:Vector2=(p-form.center)/form.radii
		land+=float(form.rise)*pow(maxf(0.,1.-q.length_squared()),2)
	# Open military approach, fixed sill and original garrison courtyard.
	var approach:=smoothstep(26.,29.8,p.x)*(1.-smoothstep(46.,50.,p.x))
	var road_base:=smoothstep(29.8,35.,p.x)*(1.-smoothstep(41.,46.,p.x))
	land*=lerpf(1.,road_base,approach)
	land+=.65*smoothstep(29.8,34.,p.x)*(1.-smoothstep(41.,46.,p.x))*(1.-smoothstep(2.8,6.5,absf(p.y)))
	var foundation:=smoothstep(42.,46.,p.x)*(1.-smoothstep(91.,97.,p.x))
	land*=lerpf(1.,smoothstep(24.5,34.,absf(p.y)),foundation)
	# Preserve all three bridge landing levels while the river widens naturally
	# between them. Riverbed and actor support surface use this same profile.
	var center:=river_center(p.y)
	var width:=river_width(p.y)
	land*=smoothstep(6.8+width,12.+width,absf(p.x-center))
	var bank:=smoothstep(3.9,7.2,absf(p.x-center)-width)
	return land-(1.-bank)*3.8
