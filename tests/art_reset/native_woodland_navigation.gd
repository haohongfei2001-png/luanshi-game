extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Trees:=preload("res://scripts/field/native_woodland_navigation.gd")
func _initialize() -> void:
 assert(Ground.authored_landform_enabled and Ground.native_woodland_enabled)
 var visited:=0;var routes:=0;var max_steps:=0
 for row:Array in Trees.LAYOUT:
  var center:=Vector2(row[0],row[1]);assert(Ground.blocked(center,true,true))
  Ground.native_woodland_enabled=false;assert(not Ground.blocked(center,true,true));Ground.native_woodland_enabled=true
  for angle in [0.,PI*.5,PI,PI*1.5]:
   var axis:=Vector2(cos(angle),sin(angle));var start:=center-axis*5.;var goal:=center+axis*5.
   # Some western source roots neighbor the actual moat. Only clear-ground
   # routes are tests of tree avoidance rather than moat pathfinding.
   if Ground.moat_blocks(start) or Ground.moat_blocks(goal):continue
   var p:=start;var steps:=0
   while p.distance_to(goal)>.12 and steps<600:
    var target:=Ground.waypoint(p,goal,true)
    var next:=Ground.travel(p,p.direction_to(target)*minf(.07,p.distance_to(target)),true,true)
    assert(not Trees.blocked(next),"Ground.travel entered original low wood")
    p=next;steps+=1;visited+=1
   assert(p.distance_to(goal)<.12,"Tree avoidance got stuck")
   max_steps=maxi(max_steps,steps);routes+=1
 var spawned:=0
 for count in [20,100,250,512]:
  var b:=Battle.new();b.setup(count,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,count,true)
  for u in b.roster:
   assert(not Trees.blocked(u.pos),"Actual unit spawned in tree footprint")
   spawned+=1
 for x in range(0,47):
  for z in range(-4,5):assert(not Trees.blocked(Vector2(x,z)),"Protected military lane obstructed")
 print("NATIVE_WOODLAND_NAV_PASS routes=",routes," real_travel_steps=",visited," max_route_steps=",max_steps," actual_muster_units=",spawned," protected_road=true default_off_exact=true graphics=NOT_RUN")
 quit()
