extends Node
## Inert main-scene CPU probe. No CLI --script, assets, renderer or Controller.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Store:=preload("res://scripts/field/experimental_map_save.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const SOURCE:="res://test_data/hf08-source.json"
const EXPECTED:="res://test_data/expected.bin"
const CONFIG:="res://test_data/config.json"
var checks:=0
var failures:Array[String]=[]
var receipt:Dictionary={}
func _ready():run.call_deferred()
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures.append(label)
 return ok
func digest(value:Variant)->String:return Store._digest(var_to_bytes(value)).hex_encode()
func observation(b:Battle)->Dictionary:
 var health:=[]
 for u in b.roster:health.append([u.id,u.hp,u.mount_hp,u.state,u.impacts,u.received,u.ammo,u.target])
 return {"tick":b.tick,"health":health,"attacks":b.attacks,"blocked":b.blocked_hits,
 "hits":b.hits.duplicate(),"losses":b.losses.duplicate(),"orders":Save._rows(b.orders,Save.ORDER),
 "shots":Save._rows(b.shots,Save.SHOT),"corps":b.corps.snapshot(),"arrived":b.messages_arrived,
 "lost":b.messages_lost,"refused":b.messages_refused,"rng":b.rng.state,"result":b.result}
func inputs(b:Battle):
 # Same real input contract as the source writer that produced expected.bin.
 if b.tick==5:b.command(0,Battle.Mission.HOLD,Battle.Channel.COURIER)
 if b.tick==80:b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG)
 if b.tick==402:b.command(0,Battle.Mission.PRESS,Battle.Channel.COURIER)
 b.sprinting=b.tick%37<5
 b.input_state(Vector2.ZERO,Vector2.RIGHT)
 if b.tick%53==7:b.press_action(0)
func run():
 var features:={}
 for name in ["editor","template","template_debug","template_release","debug","release","standalone","linux","x86_64","double","single"]:features[name]=OS.has_feature(name)
 receipt={"engine":Engine.get_version_info(),"debug_build":OS.is_debug_build(),"features":features,
 "display_server":DisplayServer.get_name(),"main_scene":ProjectSettings.get_setting("application/run/main_scene"),
 "executable":OS.get_executable_path(),"scope":"TEMPLATE_CPU_SAVE_RESUME_NOT_RELEASE_GPU_M5_UI_OR_ART_ACCEPTANCE"}
 for path in [CONFIG,SOURCE,EXPECTED]:
  if not check(FileAccess.file_exists(path),"REQUIRED_RESOURCE_MISSING "+path):finish();return
 var config=JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
 if not check(config is Dictionary and config.get("schema")==1,"valid packed test config"):finish();return
 if not check(FileAccess.get_sha256(SOURCE)==config.source_sha256,"packed source exact bytes"):finish();return
 if not check(FileAccess.get_sha256(EXPECTED)==config.expected_sha256,"packed typed oracle exact bytes"):finish();return
 var source=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
 var expected=bytes_to_var(FileAccess.get_file_as_bytes(EXPECTED))
 if not check(source is Dictionary and expected is Dictionary,"decoded source and typed oracle"):finish();return
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in source.surfaces:
  if not surface.get("walkable",false):continue
  for p in surface.vertices:low=low.min(Vector2(p[0],p[2]));high=high.max(Vector2(p[0],p[2]))
 var nav:=Navigation.new()
 if not check(nav.configure(source,Rect2(low,high-low),{"gate_main":true},.7,3.4)==OK,"actual source navigation configured"):finish();return
 var runtime:=Runtime.new()
 if not check(runtime.bind(nav,source)==OK,"actual source runtime configured"):finish();return
 var store:=Store.new(true);var path:=store.slot_path(config.slot)
 receipt["map_identity"]=runtime.identity();receipt["slot_path"]=ProjectSettings.globalize_path(path)
 if not check(FileAccess.get_sha256(path)==config.slot_sha256,"reads pre-existing source-writer disk slot exact bytes"):finish();return
 var protected:={}
 for key in [path,Save.FILE,"user://campaign_sentinel.bin"]:
  if not check(FileAccess.file_exists(key),"existing protected file "+key):finish();return
  protected[key]=FileAccess.get_sha256(key)
 var battle:=store.load_slot(runtime,config.slot)
 if not check(battle!=null,"real experimental slot load"):finish();return
 if not check(battle.tick==config.saved_tick and battle.ordinary_counts==PackedInt32Array([config.ordinary_per_side,config.ordinary_per_side]),"preserved saved tick and ordinary roster"):finish();return
 check(var_to_bytes(Save.snapshot(battle))==var_to_bytes(expected.initial),"template restored initial typed Save exact")
 receipt["initial_snapshot_sha256"]=digest(Save.snapshot(battle))
 for step in expected.frames.size():
  inputs(battle);battle.step()
  check(digest(Save.snapshot(battle))==expected.frames[step][0],"template full typed Save frame "+str(step))
  check(digest(observation(battle))==expected.frames[step][1],"template combat/order/projectile/RNG frame "+str(step))
 check(var_to_bytes(Save.snapshot(battle))==var_to_bytes(expected.final),"template final typed bytes identical to uninterrupted source oracle")
 for key in protected:check(FileAccess.get_sha256(key)==protected[key],"protected disk file unchanged "+key)
 receipt["final"]={"tick":battle.tick,"roster":battle.roster.size(),"ordinary_per_side":Array(battle.ordinary_counts),
 "attacks":battle.attacks,"hits":battle.hits,"losses":battle.losses,"snapshot_sha256":digest(Save.snapshot(battle))}
 receipt["continued_ticks"]=expected.frames.size();receipt["source_sha256"]=FileAccess.get_sha256(SOURCE)
 finish()
func finish():
 receipt["checks"]=checks;receipt["failures"]=failures;receipt["status"]="PASS" if failures.is_empty() else "REFUSED"
 var output:=OS.get_environment("LUANSHI_SAVE5_PACK_REPORT")
 if not output.is_empty():
  var file:=FileAccess.open(output,FileAccess.WRITE)
  if file==null:get_tree().quit(3);return
  file.store_string(JSON.stringify(receipt,"  "));file.close()
 print("PACKED_SAVE5_RESULT ",JSON.stringify(receipt));get_tree().quit(0 if failures.is_empty() else 2)
