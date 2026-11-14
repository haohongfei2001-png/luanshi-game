extends SceneTree
const Support:=preload("res://scripts/field/maps/authored_support.gd")
func surface(id:String,y:float,walkable:bool=true)->Dictionary:
 return {"id":id,"walkable":walkable,"vertices":[[0,y,0],[4,y,0],[4,y+1,4],[0,y+1,4]],"triangles":[[0,1,2],[0,2,3]]}
func _initialize():
 var support:=Support.new();assert(support.configure([surface("gate_floor",1.),surface("roof",12.,false)])==OK)
 assert(support.support(Vector2(2,2)).position==Vector3(2,1.5,2),"Tagged floor under roof, not highest visual surface")
 assert(support.support(Vector2(-1,2)).error==ERR_DOES_NOT_EXIST)
 assert(support.support(Vector2(2,2),"roof").error==ERR_DOES_NOT_EXIST)
 assert(support.support(Vector2(NAN,0)).error==ERR_INVALID_PARAMETER)
 var json_source:=Support.new();assert(json_source.configure(JSON.parse_string(JSON.stringify([surface("ground",0.)])))==OK);assert(json_source.support(Vector2(2,2)).position.y==.5)
 var layered:=Support.new();assert(layered.configure([surface("ground",0.),surface("bridge",5.)])==OK)
 assert(layered.support(Vector2(2,2)).reason=="EXPLICIT_SURFACE_REQUIRED")
 assert(layered.support(Vector2(2,2),"ground").position.y==.5)
 assert(layered.support(Vector2(2,2),"bridge").position.y==5.5)
 assert(support.support(Vector2(2,2)).position.y==1.5,"Second map cannot contaminate first")
 var bad=surface("bad",0.);bad.triangles=[[0,0,0]];assert(Support.new().configure([bad])==ERR_INVALID_DATA)
 bad=surface("bad",0.);bad.triangles=[[0,1,99]];assert(Support.new().configure([bad])==ERR_INVALID_DATA)
 bad=surface("bad",0.);bad.vertices[0][1]=INF;assert(Support.new().configure([bad])==ERR_INVALID_DATA)
 var source=surface("immutable",2.);var isolated:=Support.new();assert(isolated.configure([source])==OK);source.vertices[0][1]=99;assert(isolated.support(Vector2.ZERO).position.y==2.)
 print("AUTHORED_SUPPORT_PASS tagged_floor_not_roof explicit_layers invalid_data rejection instance_isolation; TEST_GEOMETRY_ONLY_NOT_ART_OR_BATTLE_NAV")
 quit()
