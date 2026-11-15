extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
func _initialize():
 var results:=[]
 for count in [20,100,250,512]:
  for bridgehead in [false,true]:
   var battle:=Battle.new();battle.setup(count,61112,Battle.Arms.Kit.SPEAR,true,true,count,bridgehead);battle.started=true
   for step in 400:battle.step()
   var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(var_to_bytes(Save.snapshot(battle)))
   results.append({"per_team":count,"bridgehead":bridgehead,"tick":battle.tick,"sha256":digest.finish().hex_encode(),"attacks":battle.attacks,"hero_hp":battle.hero.hp})
 var path=OS.get_cmdline_user_args()[0];FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
 print("REAL_BATTLE_DETERMINISM_CAPTURE ",JSON.stringify(results));quit()
