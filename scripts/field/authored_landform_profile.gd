extends RefCounted
## OFF-by-default production experiment. Metres; never changes the save schema.
## Continuous raised military causeway, drainage swales and woodland terraces.
## Shared by gameplay support and the new surveyed visible surface.
const Existing:=preload("res://scripts/field/river_pass_profile.gd")
static func height(p:Vector2) -> float:
	var original:=Existing.height(p)
	# Exactly preserve bridge abutments, military gate foundations and outskirts.
	var along:=smoothstep(29.95,32.3,p.x)*(1.-smoothstep(42.8,46.6,p.x))
	var across:=1.-smoothstep(23.,32.,absf(p.y))
	if along*across<=0.:return original
	var side:=absf(p.y)
	var crown:=.46*(1.-smoothstep(0.,4.5,side))
	# Broad depressed drainage, not decorative stones or an overlaid dark stripe.
	var drain_center:=6.65+.28*sin((p.x-30.)*.24)
	var drain:=-.34*(1.-smoothstep(.55,1.65,absf(side-drain_center)))
	var terrace_height:=3.05 if p.y<0. else 2.45
	var terrace:=terrace_height*smoothstep(8.2,15.3,side)
	# Continuous shallow wheel wear in the ACTUAL support height; not painted ruts.
	var ruts:=-.035*(1.-smoothstep(.17,.43,absf(side-1.35)))
	var target:=crown+drain+terrace+ruts
	return lerpf(original,target,along*across)
