extends RefCounted
## One river-valley landscape composition; no random scattering of landmarks.
## Tree origins retain source scale and navigate through the exact wood hull.
const TREE_GROUPS:=[
 [10.,-21.,1.,12.],[13.,-27.,1.,93.],
 [32.1,-14.8,1.,-18.],[35.,-21.,1.,42.],[35.,-27.,1.,-71.],
 [15.,20.,1.,-27.],[15.,29.,1.,131.],
 [34.,15.7,1.,-42.],[35.,23.,1.,87.],[36.,33.,1.,19.],
 [65.,-29.,1.,-17.],[71.,-29.,1.,39.],[79.,-29.,1.,-71.],
 [63.,30.,1.,52.],[72.,40.,1.,-103.],[79.,41.,1.,26.]]
static func cover(p:Vector2) -> float:
 # A continuous meadow margin around the preserved military clearance.
 # Drier packed approach and fort court remain open. No noisy pigment mask.
 var road_clearance:=smoothstep(4.7,8.5,absf(p.y))
 var field_edge:=smoothstep(-4.,3.,p.x)*(1.-smoothstep(43.,47.,p.x))
 var valley:=1.-smoothstep(31.,42.,absf(p.y))
 return road_clearance*field_edge*valley
static func grass_density(p:Vector2) -> float:
 # Reduce density along actual approach shoulder, keep contiguous outer cover.
 return cover(p)*.72
