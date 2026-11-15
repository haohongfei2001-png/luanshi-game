extends SceneTree
const Obstacles:=preload("res://scripts/field/maps/authored_obstacles.gd")
func _initialize():
 var path:=OS.get_cmdline_user_args()[0];var contract:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var a:=Obstacles.new();var b:=Obstacles.new();assert(a.configure(contract.solid_obstacles,[contract.gate_dynamic])==OK);assert(b.configure(contract.solid_obstacles,[contract.gate_dynamic])==OK)
 assert(a.obstruction(Vector3(30,1.2,3),.45,1.9).blocked)
 assert(not a.obstruction(Vector3(30,1.2,3),.45,1.9,{"gate_main":true}).blocked)
 assert(b.obstruction(Vector3(30,1.2,3),.45,1.9).blocked,"Opening a gate in one query must not mutate another map")
 assert(a.obstruction(Vector3(30,1.2,-1),.45,1.9,{"gate_main":true}).blocked,"Opening the gate must not remove its pier")
 assert(a.obstruction(Vector3(0,1,3.5),.45,1.9).blocked,"Real bridge rail body clearance")
 for x in [-6.,0.,6.]:assert(not a.obstruction(Vector3(x,1,0),.7,3.4).blocked,"Mounted centre passage")
 assert(not a.obstruction(Vector3(76,1.2,3),.7,3.4).blocked,"Rear retreat opening")
 assert(a.obstruction(Vector3(NAN,0,0),.45,1.9).error==ERR_INVALID_PARAMETER)
 print("PRODUCTION_V2_REAL_ARCHITECTURE_OBSTACLE_PASS ",JSON.stringify({"contract_sha256":FileAccess.get_sha256(path),"statistics":a.statistics(),"scope":"sampled real gate/bridge/retreat body clearance; not complete navigation, GPU or Battle"}));quit()
