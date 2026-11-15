extends SceneTree
const Obstacles:=preload("res://scripts/field/maps/authored_obstacles.gd")
func _initialize():
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));var map:=Obstacles.new();assert(map.configure(source.solids)==OK)
 var checks:=0
 for x in range(-10,82):
  for z in range(-36,36):
   for radius in [.45,.7,2.5]:
    var p:=Vector3(x+.13,1.2,z+.27)
    assert(map.obstruction(p,radius,3.4,{"gate_main":true})==map.obstruction(p,radius,3.4,{"gate_main":true},true));checks+=1
 assert(map.segment_obstruction(Vector3(26,2.4,3),Vector3(34,2.4,3)))
 assert(not map.segment_obstruction(Vector3(26,2.4,3),Vector3(34,2.4,3),{"gate_main":true}))
 assert(map.segment_obstruction(Vector3(26,2.4,-1),Vector3(34,2.4,-1),{"gate_main":true}))
 assert(not map.segment_obstruction(Vector3(26,20,3),Vector3(34,20,3)))
 print("SOURCE_OBSTACLE_INDEX_EXACT_PARITY ",checks," point/capsule checks; exact vertical-clipped segment gate/pier/above tests PASS");quit()
