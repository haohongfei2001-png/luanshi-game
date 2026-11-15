extends SceneTree
## Optional reference loader is materialized from the unchanged base commit.
## It runs on the same Battle engine to isolate this change's loading semantics.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
var failures:=[]
var checks:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1:push_error("reference Save script path required");quit(2);return
 var reference=load(args[0])
 if reference==null:quit(2);return
 for version in [1,2,3,4]:
  for bridgehead in [false,true]:
   var b:=Battle.new();b.setup(20,61112,Battle.Arms.Kit.SPEAR,true,version==4,20,bridgehead)
   if version<4:b.traffic_enabled=false;b.soft_crowd=false;b.keep_gate_file=false;b.objectives.enabled=false
   if version==1:b.legacy_missiles=true
   b.start()
   for step in 12:b.step()
   var data:=Save.snapshot(b);data.version=version
   if version<4:
    for key in ["officer_corps","traffic_enabled","soft_crowd","keep_gate_file","world_patrol","ram_crew","reliefs","objectives"]:data.erase(key)
   if version<3:
    for key in ["dry_muster","seat_origin","parked_heading","camp_actions","muster","aftermath_hours","at_camp","breath","winded","buffer_ticks","buffered_slot","buffer_aim","buffer_wall"]:data.erase(key)
   if version==1:
    data.erase("legacy_missiles");data.battle.pop_back()
    for row in data.units:row.resize(Save.UNIT.size()-4)
   var original:=var_to_bytes(data)
   var old:Battle=reference.restore(data);var now:=Save.restore(data)
   var label:="v%d bridgehead=%s" % [version,bridgehead]
   check((old==null)==(now==null),label+" same acceptance")
   check(var_to_bytes(data)==original,label+" no input mutation")
   if bridgehead and version<4:
    check(now==null,label+" historical unsupported second map remains refused")
    continue
   check(now!=null,label+" supported original format loads")
   if old==null or now==null:continue
   check(var_to_bytes(reference.snapshot(old))==var_to_bytes(Save.snapshot(now)),label+" exact restored state")
   for step in 20:
    old.step();now.step()
    check(var_to_bytes(reference.snapshot(old))==var_to_bytes(Save.snapshot(now)),label+" exact continuing state "+str(step))
 # Older terrain bank repair occurs on private objects, exactly as before.
 for revision in [1,2,3]:
  var b:=Battle.new();b.setup(20);b.start()
  var data:=Save.snapshot(b);data.terrain_revision=revision
  var original:=var_to_bytes(data)
  var old:Battle=reference.restore(data);var now:=Save.restore(data)
  check(old!=null and now!=null,"terrain migration available "+str(revision))
  if old!=null and now!=null:check(reference.snapshot(old)==Save.snapshot(now),"terrain migration unchanged "+str(revision))
  check(var_to_bytes(data)==original,"terrain input unchanged")
 print("LEGACY_VERSION_PARITY ",JSON.stringify({"checks":checks,"failures":failures,"reference_sha256":FileAccess.get_sha256(args[0]),"scope":"ORIGINAL_V1_TO_V4_LOADER_SAME_ENGINE_BOTH_MAP_BOUNDARIES_AND_TERRAIN_MIGRATIONS"}))
 quit(0 if failures.is_empty() else 1)
