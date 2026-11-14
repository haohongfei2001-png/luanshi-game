extends RefCounted
const VERSION:="continuous-causeway-native-shore-support-02"
## OFF-by-default production experiment. Metres; never changes the save schema.
## Continuous raised military causeway, drainage swales and woodland terraces.
## Shared by gameplay support and the new surveyed visible surface.
const Existing:=preload("res://scripts/field/river_pass_profile.gd")
static func height(p:Vector2) -> float:
	var original:=Existing.height(p)
	# Exactly preserve bridge abutments, military gate foundations and outskirts.
	var along:=smoothstep(29.95,32.3,p.x)*(1.-smoothstep(42.8,46.6,p.x))
	var across:=1.-smoothstep(23.,32.,absf(p.y))
	# Two continuous shore shelves back the full scanned ledges, outside all
	# protected bridge lanes. Shared support changes, never a floating visual cap.
	var shelf_along:=smoothstep(7.4,9.2,absf(p.y))*(1.-smoothstep(17.,19.4,absf(p.y)))
	var shelf_across:=smoothstep(26.0,28.0,p.x)*(1.-smoothstep(29.2,33.0,p.x))
	var shore_shelf:=1.55*shelf_along*shelf_across
	if along*across<=0.:return original+shore_shelf
	var side:=absf(p.y)
	var crown:=.46*(1.-smoothstep(0.,4.5,side))
	# Broad depressed drainage, not decorative stones or an overlaid dark stripe.
	var drain_center:=6.65+.28*sin((p.x-30.)*.24)
	var drain:=-.34*(1.-smoothstep(.55,1.65,absf(side-drain_center)))
	var terrace_height:=1.45 if p.y<0. else 1.15
	var terrace:=terrace_height*smoothstep(8.2,15.3,side)
	# Continuous shallow wheel wear in the ACTUAL support height; not painted ruts.
	var ruts:=-.035*(1.-smoothstep(.17,.43,absf(side-1.35)))
	var target:=crown+drain+terrace+ruts
	return lerpf(original,target,along*across)+shore_shelf
