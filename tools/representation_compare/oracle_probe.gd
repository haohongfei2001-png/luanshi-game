extends SceneTree
const Battle=preload("res://scripts/field/battle.gd")
const Save=preload("res://scripts/field/save.gd")
func _initialize():go.call_deferred()
func go():
 var rows=[]
 for count in [20,100,250,512]:
  var battle=Battle.new();battle.setup(count,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true);battle.start()
  for tick in 500:
   battle.step()
   if battle.tick in [300,500]:rows.append({"count":count,"tick":battle.tick,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"roster":battle.roster.size(),"snapshot_sha":var_to_bytes(Save.snapshot(battle)).hex_encode().sha256_text()})
 print("SIMULATION_ORACLE_ONLY ",JSON.stringify(rows));quit()
