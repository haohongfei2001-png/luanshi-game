extends SceneTree
## MapQuery diagnostics must not assume authored navigation or imply resumability.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Store:=preload("res://scripts/field/experimental_map_save.gd")
const MapQuery:=preload("res://scripts/field/maps/map_query.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const MappedState:=preload("res://scripts/field/maps/mapped_save_state.gd")
class DiagnosticMap:
 extends MapQuery
 func identity()->Dictionary:
  return {"map_id":"diagnostic-stub-not-a-game-map","topology_revision":1,"topology_sha256":"a".repeat(64)}
var checks:=0
var failures:=[]
var store:=Store.new(true)
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func diagnostic(b:Battle,expected:Dictionary,label:String):
 var bytes:=var_to_bytes(expected)
 var data:=Save.snapshot(b)
 check(data.version==5 and data.map_identity==b.map_runtime.identity(),label+" remains v5 identity diagnostic")
 check(not data.has("mapped_state"),label+" no invented resumable state")
 check(var_to_bytes(data)==bytes,label+" matches identity-only diagnostic exactly")
 check(MappedState.snapshot(b)=={},label+" direct mapped-state helper fails closed")
 check(Save.restore(data)==null,label+" not misclassified as legacy")
 check(store.restore(data,Runtime.new())==null,label+" experimental restore refused")
 check(store.save(b,"must_not_write")!=OK,label+" experimental write refused")
 check(not FileAccess.file_exists(store.slot_path("must_not_write")),label+" refused write creates no slot")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=3:push_error("SOURCE_JSON ORIGINAL_512_SAVED_VARIANT OUTPUT_JSON; use original isolated XDG data");quit(2);return
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var base:=Battle.new();base.setup(20)
 var prior:=Save.snapshot(base)
 var stub:=DiagnosticMap.new();base.map_runtime=stub
 var expected:=prior.duplicate(true);expected.version=5;expected.map_identity=stub.identity()
 diagnostic(base,expected,"non-authored MapQuery stub without nav")
 base.map_runtime=MapQuery.new();expected.map_identity={}
 diagnostic(base,expected,"base MapQuery without nav")
 base.map_runtime=Runtime.new()
 check(base.map_runtime.identity()=={},"unbound authored identity safe")
 diagnostic(base,expected,"unbound authored runtime")
 var partial:=Runtime.new();partial.nav=Navigation.new();partial.source=source.duplicate(true);base.map_runtime=partial
 check(partial.identity()=={},"unconfigured navigation not a bound identity")
 diagnostic(base,expected,"unconfigured authored navigation")
 # Configure the actual source once; no synthetic geometry or fresh battle.
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in source.surfaces:
  if not surface.get("walkable",false):continue
  for p in surface.vertices:low=low.min(Vector2(p[0],p[2]));high=high.max(Vector2(p[0],p[2]))
 var nav:=Navigation.new()
 if nav.configure(source,Rect2(low,high-low),{"gate_main":true},.7,3.4)!=OK:quit(2);return
 var runtime:=Runtime.new()
 if runtime.bind(nav,source)!=OK:quit(2);return
 var paths:=[store.slot_path("test_512"),Save.FILE,"user://campaign_sentinel.bin"]
 var hashes:=[]
 for path in paths:hashes.append(FileAccess.get_sha256(path))
 var battle:=store.load_slot(runtime,"test_512")
 if battle==null:push_error("Expected actual512 disk slot did not restore");quit(2);return
 var original:=FileAccess.get_file_as_bytes(args[1])
 var normal:=Save.snapshot(battle)
 check(var_to_bytes(normal)==original,"supported HF08 typed snapshot remains byte-identical to86ab3ae oracle")
 check(normal.has("mapped_state") and normal.mapped_state.mode==MappedState.MODE,"supported HF08 continuation schema preserved")
 expected=normal.duplicate(true);expected.erase("mapped_state")
 runtime.source.battle_mode="unsupported_campaign_mode"
 diagnostic(battle,expected,"configured runtime with unsupported mode")
 check(store.restore(normal,runtime)==null,"unsupported mode rejects otherwise valid checkpoint")
 runtime.source.battle_mode=MappedState.MODE
 runtime.nav._gates.gate_main=false
 diagnostic(battle,expected,"configured runtime with closed gate")
 check(store.restore(normal,runtime)==null,"unsupported closed gate rejects valid checkpoint")
 runtime.nav._gates.gate_main=true
 var topology=runtime.source.topology_sha256;runtime.source.erase("topology_sha256");expected.map_identity={}
 diagnostic(battle,expected,"configured runtime with incomplete identity")
 runtime.source.topology_sha256=topology
 check(var_to_bytes(Save.snapshot(battle))==original,"all diagnostics leave live battle typed state unchanged")
 for i in paths.size():check(FileAccess.get_sha256(paths[i])==hashes[i],"existing slot/legacy/campaign file unchanged "+paths[i])
 var report:={"checks":checks,"failures":failures,"original_typed_sha256":Store._digest(original).hex_encode(),"tick":battle.tick,"roster":battle.roster.size(),"scope":"SAFE_MAPQUERY_DIAGNOSTICS_AND_UNCHANGED_HF08_TYPED_FORMAT"}
 FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("MAPPED_SNAPSHOT_BOUNDARY ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
