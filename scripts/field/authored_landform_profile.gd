extends RefCounted
const VERSION:="continuous-military-road-and-eroded-moat-03"
## Default-OFF: one road/shoulder/wet-bank cross-section, shared support+collision.
const Existing:=preload("res://scripts/field/river_pass_profile.gd")
static func rebuild_weight(p:Vector2) -> float:
	return smoothstep(0.,8.,p.x)*(1.-smoothstep(44.,46.6,p.x))*(1.-smoothstep(27.,38.,absf(p.y)))
static func road_half_width(x:float) -> float:
	return 3.7+.4*smoothstep(34.,44.,x)
static func height(p:Vector2) -> float:
	var original:=Existing.height(p);var weight:=rebuild_weight(p)
	if weight<=0.:return original
	# Preserve the existing bridge's ground footprint exactly. Its deck remains
	# the same Ground.deck_height override; no visual bridge relocation.
	var bridge_keep:=(1.-smoothstep(3.95,5.3,absf(p.y)))*smoothstep(16.,18.,p.x)*(1.-smoothstep(29.95,31.,p.x))
	weight*=1.-bridge_keep
	var side:=absf(p.y);var road_width:=road_half_width(p.x)
	var road:=.16*(1.-smoothstep(0.,road_width,side))
	var road_blend:=smoothstep(29.95,32.,p.x)*(1.-smoothstep(43.,46.6,p.x))
	var ruts:=-.045*(1.-smoothstep(.18,.45,absf(side-1.35)))*road_blend
	var drain_center:=road_width+1.5+.15*sin(p.x*.22)
	var drainage:=-.22*(1.-smoothstep(.45,1.2,absf(side-drain_center)))
	var shoulder:=.22*smoothstep(road_width+1.,road_width+4.,side)
	# Low elongated banks instead of the old collection of 2–3m round hummocks.
	var outer_rise:=.62*smoothstep(12.,25.,side)
	var land:=road+ruts+drainage+shoulder+outer_rise
	var depth:=Existing.moat_depth(p)
	if depth>0.:
		# Broad upper bench, erosion face and submerged toe are continuous along
		# the entire moat, not two scan slices glued to a vertical dirt mound.
		var bench:=-.55-.10*sin(p.y*.31)
		var surface:=lerpf(land,bench,smoothstep(0.,.28,depth))
		surface=lerpf(surface,-2.45,smoothstep(.28,.72,depth))
		surface=lerpf(surface,-3.4,smoothstep(.72,1.,depth))
		land=surface+3.4*depth # Ground subtracts the SAME moat depth once.
	return lerpf(original,land,weight)
