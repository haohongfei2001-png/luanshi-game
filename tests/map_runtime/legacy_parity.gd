extends SceneTree
const Legacy:=preload("res://scripts/field/maps/legacy_map_runtime.gd")
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize():
 var maps=[Legacy.new(false),Legacy.new(true)];var checks:=0
 for pass_id in 2:
  for bridgehead in [false,true]:
   var runtime=maps[int(bridgehead)]
   for x in [-100.,-35.,0.,20.,24.,29.,48.,50.,66.,89.,100.]:
    for z in [-40.,-24.,-6.,0.,6.,24.,40.]:
     var p:=Vector2(x,z);var q:=p+Vector2(1.2,.3)
     assert(runtime.height(p)==Ground.height(p,bridgehead));assert(runtime.deck_height(p)==Ground.deck_height(p,bridgehead));assert(runtime.unit_point(p)==Ground.unit_point(p,bridgehead))
     assert(runtime.restore_bank_position(p)==Ground.restore_bank_position(p,bridgehead));assert(runtime.waypoint(p,q)==Ground.waypoint(p,q,bridgehead));checks+=5
     for open in [false,true]:
      assert(runtime.blocked(p,open)==Ground.blocked(p,open,bridgehead));assert(runtime.can_step(p,q,open)==Ground.can_step(p,q,open,bridgehead));assert(runtime.travel(p,q-p,open)==Ground.travel(p,q-p,open,bridgehead));assert(runtime.retreat_waypoint(p,q,open)==Ground.retreat_waypoint(p,q,open,bridgehead));assert(runtime.clear_shot(p,q,open)==Ground.clear_shot(p,q,open));checks+=5
     for mounted in [false,true]:assert(runtime.pace(p,mounted)==Ground.pace(p,mounted,bridgehead));checks+=1
 var exposed=maps[0].landmarks();exposed.gate=Vector2.ZERO;assert(maps[0].landmarks().gate==Ground.GATE)
 print("LEGACY_MAP_INSTANCE_PARITY_PASS checks=",checks," alternating_openfield_bridgehead no_global_map_change; NEW_SCENE_BINDING_NOT_RUN")
 quit()
