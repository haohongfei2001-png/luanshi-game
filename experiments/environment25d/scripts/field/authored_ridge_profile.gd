extends RefCounted
## Connected terrain watershed study, not source scan or accepted art.
## Crest stations are x/z metres with top heights and cross-slope widths.
## Original bridge/city/river support is excluded by a separate mask.
const NORTH:=[Vector4(-8.,-52.,5.,24.),Vector4(22.,-61.,10.,28.),Vector4(55.,-56.,15.,23.),Vector4(91.,-69.,22.,30.),Vector4(126.,-61.,16.,26.),Vector4(169.,-76.,26.,36.)]
const SOUTH:=[Vector4(-12.,61.,3.,25.),Vector4(25.,67.,7.,31.),Vector4(67.,58.,10.,25.),Vector4(107.,76.,17.,33.),Vector4(164.,68.,13.,34.)]
static func profile(p:Vector2,stations:Array) -> float:
	# Connected sections rather than independent radial mounds. Interpolate a
	# surveyed crest and width along the regional axis, then asymmetric slopes.
	var a:Vector4=stations[0];var b:Vector4=stations[-1]
	for index in stations.size()-1:
		if p.x<=stations[index+1].x:
			a=stations[index];b=stations[index+1];break
	var t:=smoothstep(a.x,b.x,p.x)
	var crest:=lerpf(a.y,b.y,t);var height:=lerpf(a.z,b.z,t);var width:=lerpf(a.w,b.w,t)
	var toward_valley:=signf(crest)*(p.y-crest)<0.
	var distance:=absf(p.y-crest)/(width*(1.18 if toward_valley else .72))
	# Rounded crest, long talus shoulder and steeper outer dip slope.
	var upper:=1.-smoothstep(.0,.62,distance)
	var apron:=1.-smoothstep(.2,1.5,distance)
	return height*(upper*.68+apron*.32)
static func weight(p:Vector2) -> float:
	# Keep all existing city foundations/courtyard, water crossings and the
	# near military road04 exact. Only the connected regional shoulders change.
	return smoothstep(6.,18.,p.x)*smoothstep(28.,42.,absf(p.y))
static func height(p:Vector2) -> float:
	# Saddles are authored by the station heights, not random high-frequency
	# noise or surface speckles. Northern/southern valleys meet a common floor.
	return maxf(profile(p,NORTH),profile(p,SOUTH))
