extends SceneTree
const Native:=preload("res://scripts/field/maps/experimental_native_support.gd")
const Reference:=preload("res://scripts/field/maps/authored_support.gd")
func _initialize():
 var rows=[{"id":"ground","walkable":true,"vertices":[[0,0,0],[4,0,0],[4,1,4]],"triangles":[[0,1,2]]}]
 var native:=Native.new();var reference:=Reference.new()
 assert(native.configure(rows)==OK);assert(reference.configure(rows)==OK)
 assert(native.kernel==null,"This fixture requires the experimental library to be absent")
 for p in [Vector2(1,1),Vector2(2,1),Vector2(-1,-1),Vector2(4,4)]:assert(var_to_bytes(native.support(p))==var_to_bytes(reference.support(p)))
 var data={"surfaces":rows,"solids":[],"portals":[]}
 var nav=load("res://scripts/field/maps/experimental_native_navigation.gd").new()
 var original=load("res://scripts/field/maps/authored_navigation.gd").new()
 assert(nav.configure(data,Rect2(0,0,4,4))==OK);assert(original.configure(data,Rect2(0,0,4,4))==OK)
 assert(nav.support.kernel==null)
 for a in [Vector2(1,1),Vector2(2,1),Vector2(-1,-1)]:
  for b in [Vector2(3,1),Vector2(2,2),Vector2(4,4)]:assert(nav.can_travel(a,b,"ground","ground")==original.can_travel(a,b,"ground","ground"))
 print("NATIVE_UNAVAILABLE_FALLBACK_PASS no optional library, exact GDScript results");quit()
