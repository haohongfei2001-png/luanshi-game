extends SceneTree
const Native:=preload("res://scripts/field/maps/experimental_native_support.gd")
const Reference:=preload("res://scripts/field/maps/authored_support.gd")
func _initialize():
 var rows=[{"id":"ground","walkable":true,"vertices":[[0,0,0],[4,0,0],[4,1,4]],"triangles":[[0,1,2]]}]
 var native:=Native.new();var reference:=Reference.new()
 assert(native.configure(rows)==OK);assert(reference.configure(rows)==OK)
 assert(native.kernel==null,"This fixture requires the experimental library to be absent")
 for p in [Vector2(1,1),Vector2(2,1),Vector2(-1,-1),Vector2(4,4)]:assert(var_to_bytes(native.support(p))==var_to_bytes(reference.support(p)))
 print("NATIVE_UNAVAILABLE_FALLBACK_PASS no optional library, exact GDScript results");quit()
