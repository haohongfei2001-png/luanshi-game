extends SceneTree
const Battle=preload("res://scripts/field/battle.gd")
const Save=preload("res://scripts/field/save.gd")
const Focus=preload("res://tools/representation_compare/contact_camera.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
 for count in [100,250,512]:
  var battle=Battle.new();battle.setup(count,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true);battle.start()
  var min_pairs:=100000;var max_pairs:=0;var first:Dictionary
  var start=250 if count==512 else 50
  var end=start+320
  for i in end:
   battle.step()
   if battle.tick>=start:
    var before=var_to_bytes(Save.snapshot(battle))
    var row=Focus.observe(battle)
    assert(var_to_bytes(Save.snapshot(battle))==before)
    assert(row==Focus.observe(battle))
    assert(row.center.size()==2 and row.alive>0)
    if battle.tick==start:first=row
    min_pairs=mini(min_pairs,row.live_contact_pairs);max_pairs=maxi(max_pairs,row.live_contact_pairs)
  if battle.tick!=end or battle.result!="":push_error("Live window unavailable");quit(1);return
  print("CONTACT_FOCUS_READONLY_LIVE count=",count," start=",start," end=",end," first=",JSON.stringify(first)," contact_pairs_min=",min_pairs," max=",max_pairs," hits=",battle.hits," losses=",battle.losses)
 quit()
