extends SceneTree
## Two-process HF08 resume proof, actual caller-supplied source only. No art data.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Store:=preload("res://scripts/field/experimental_map_save.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
var checks:=0
var failures:Array[String]=[]
var checkpoints:=[]
var store:=Store.new(true)
var outdir:String
var source:Dictionary
var runtime:Runtime
var legacy_before:PackedByteArray
var world_before:PackedByteArray

func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok: failures.append(label);push_error(label)
 return ok
func digest(value:Variant)->String: return Store._digest(var_to_bytes(value)).hex_encode()
func write_variant(path:String,value:Variant):
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(var_to_bytes(value));file.close()
func read_variant(path:String)->Variant: return bytes_to_var(FileAccess.get_file_as_bytes(path))
func observation(b:Battle)->Dictionary:
 var health:=[]
 for u in b.roster:health.append([u.id,u.hp,u.mount_hp,u.state,u.impacts,u.received,u.ammo,u.target])
 return {"tick":b.tick,"health":health,"attacks":b.attacks,"blocked":b.blocked_hits,
 "hits":b.hits.duplicate(),"losses":b.losses.duplicate(),"orders":Save._rows(b.orders,Save.ORDER),
 "shots":Save._rows(b.shots,Save.SHOT),"corps":b.corps.snapshot(),"arrived":b.messages_arrived,
 "lost":b.messages_lost,"refused":b.messages_refused,"rng":b.rng.state,"result":b.result}
func inputs(b:Battle):
 # Same real command/control calls on uninterrupted and resumed simulation.
 if b.tick==5:b.command(0,Battle.Mission.HOLD,Battle.Channel.COURIER)
 if b.tick==80:b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG)
 if b.tick==402:b.command(0,Battle.Mission.PRESS,Battle.Channel.COURIER)
 b.sprinting=b.tick%37<5
 b.input_state(Vector2.ZERO,Vector2.RIGHT)
 if b.tick%53==7:b.press_action(0)
func make_runtime(data:Dictionary)->Runtime:
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in data.surfaces:
  if not surface.get("walkable",false):continue
  for p in surface.vertices:low=low.min(Vector2(p[0],p[2]));high=high.max(Vector2(p[0],p[2]))
 var nav:=Navigation.new()
 if not check(nav.configure(data,Rect2(low,high-low),{"gate_main":true},.7,3.4)==OK,"navigation configured"):return null
 var map:=Runtime.new()
 if not check(map.bind(nav,data)==OK,"runtime configured"):return null
 return map
func pair(b:Battle,steps:int,label:String)->void:
 var before:=Save.snapshot(b);var bytes:=var_to_bytes(before)
 var copy:=store.restore(before,runtime)
 if not check(copy!=null,label+" restores"):return
 check(var_to_bytes(before)==bytes,label+" input immutable")
 check(var_to_bytes(Save.snapshot(copy))==bytes,label+" complete typed snapshot identical immediately")
 for step in steps:
  inputs(b);inputs(copy);b.step();copy.step()
  check(Save.snapshot(b)==Save.snapshot(copy),label+" full Save continuation "+str(step))
  check(observation(b)==observation(copy),label+" events continuation "+str(step))
 checkpoints.append({"label":label,"tick":b.tick,"attacks":b.attacks,"losses":b.losses.duplicate(),"shots":b.shots.size(),"orders":b.orders.size(),"sha256":digest(Save.snapshot(b))})
func rejection_tests(b:Battle):
 var good:=Save.snapshot(b);var original:=var_to_bytes(good)
 check(Store.new().restore(good,runtime)==null,"default-off restore")
 check(Store.new().save(b)==ERR_UNAVAILABLE,"default-off write")
 check(Store.new().load_slot(runtime)==null,"default-off disk load")
 check(Save.restore(good)==null,"ordinary loader still rejects v5")
 check(Save.save(b)==ERR_UNAVAILABLE,"ordinary writer cannot overwrite legacy")
 check(store.restore(good,Runtime.new())==null,"unconfigured map refused")
 check(store.restore(good,null)==null,"missing runtime refused")
 for version in [1,2,3,4,6]:
  var wrong:=good.duplicate(true);wrong.version=version
  check(store.restore(wrong,runtime)==null,"experimental entry rejects non-v5 version "+str(version))
 check(store.restore(JSON.parse_string(JSON.stringify(good)),runtime)==null,"diagnostic lossy JSON not a save")
 var bad:=good.duplicate(true);bad.erase("mapped_state")
 check(store.restore(bad,runtime)==null,"old incomplete v5 refused")
 for key in ["map_id","topology_revision","topology_sha256"]:
  bad=good.duplicate(true)
  bad.map_identity[key]="unknown" if key=="map_id" else (99 if key=="topology_revision" else "f".repeat(64))
  var unchanged:=var_to_bytes(bad)
  check(store.restore(bad,runtime)==null,"wrong "+key+" rejected")
  check(var_to_bytes(bad)==unchanged,"wrong identity input not changed")
 for key in ["terrain_revision","world_patrol","traffic_enabled","keep_gate_file","aftermath_hours","at_camp"]:
  bad=good.duplicate(true);bad[key]=1 if key in ["terrain_revision","aftermath_hours"] else true
  check(store.restore(bad,runtime)==null,"unsupported mode "+key+" rejected")
 bad=good.duplicate(true);bad.losses[0]+=1
 check(store.restore(bad,runtime)==null,"casualty corruption rejected")
 bad=good.duplicate(true);bad.units[0][Save.UNIT.find(&"pos")]=Vector2(999,999)
 check(store.restore(bad,runtime)==null,"unsupported saved position rejected without relocation")
 bad=good.duplicate(true);bad.mapped_state.units[0][0]=Vector2(999,999)
 check(store.restore(bad,runtime)==null,"invalid station rejected")
 bad=good.duplicate(true);bad.mapped_state.agent_radius=.45
 check(store.restore(bad,runtime)==null,"changed agent geometry rejected")
 for slot in ["","../river_gate_quick_v1","/tmp/escape","a/b","a\\b","a".repeat(49)]:
  check(store.save(b,slot)==ERR_INVALID_PARAMETER and store.load_slot(runtime,slot)==null,"unsafe slot rejected")
 check(var_to_bytes(good)==original and var_to_bytes(Save.snapshot(b))==original,"rejection leaves live battle/input unchanged")
 # Pure rendering/source revisions are not topology. No nav rebuild or mutation.
 var visual:=runtime.source.duplicate(true)
 runtime.source.visual_revision=999;runtime.source.authored_source_sha256="d".repeat(64)
 check(store.restore(good,runtime)!=null,"visual-only revision preserves resume")
 runtime.source=visual
 var mode=runtime.source.battle_mode;runtime.source.battle_mode="unsupported_world_battle"
 check(store.restore(good,runtime)==null,"unsupported runtime mode rejected")
 runtime.source.battle_mode=mode
func disk_corruption_tests(b:Battle,slot:String):
 var valid:=FileAccess.get_file_as_bytes(store.slot_path(slot))
 var corrupt_path:=store.slot_path("corrupt")
 var variants:=[PackedByteArray(),valid.slice(0,20),valid.slice(0,valid.size()-1)]
 var changed:=valid.duplicate();changed[changed.size()-1]^=1;variants.append(changed)
 changed=valid.duplicate();changed[0]=0;variants.append(changed)
 for bytes in variants:
  var file:=FileAccess.open(corrupt_path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
  check(store.load_slot(runtime,"corrupt")==null,"corrupt/truncated file rejected")
 var file:=FileAccess.open(corrupt_path,FileAccess.WRITE)
 var huge:=PackedByteArray();huge.resize(Store.MAX_BYTES+1);file.store_buffer(huge);file.close()
 check(store.load_slot(runtime,"corrupt")==null,"oversized file rejected")
 # A failed write to an existing experimental slot must retain its old bytes.
 var old_mode:=b.world_patrol;b.world_patrol=true
 check(store.save(b,slot)==ERR_INVALID_DATA,"unsupported save refuses write")
 b.world_patrol=old_mode
 check(FileAccess.get_file_as_bytes(store.slot_path(slot))==valid,"failed save retains previous experimental slot")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=5:push_error("write|read SOURCE_JSON COUNT TARGET_TICK OUTPUT_DIRECTORY");quit(2);return
 var phase:=args[0];var count:=int(args[2]);var target:=int(args[3]);outdir=args[4]
 source=JSON.parse_string(FileAccess.get_file_as_string(args[1]));runtime=make_runtime(source)
 if runtime==null:finish(phase);return
 var slot:="test_"+str(count)
 if phase=="write":
  # Test-specific XDG_DATA_HOME is mandatory. Never touch someone's actual saves.
  if not check(OS.get_environment("XDG_DATA_HOME").contains("save5"),"isolated test user data required"):finish(phase);return
  var legacy:=Battle.new();legacy.setup(20);legacy.start();legacy.step()
  check(Save.save(legacy)==OK,"real legacy quick slot seeded")
  legacy_before=FileAccess.get_file_as_bytes(Save.FILE)
  write_variant("user://campaign_sentinel.bin",{"world":"unchanged","grain":1234,"clock":83})
  world_before=FileAccess.get_file_as_bytes("user://campaign_sentinel.bin")
  var b:=Battle.new();b.setup(count,61112,Battle.Arms.Kit.SPEAR,true,true,count,false)
  if not check(Muster.apply(b,runtime).error==OK,"real authored initial muster"):finish(phase);return
  b.start();var had_contact:=false;var had_casualty:=false
  while b.tick<target and b.result.is_empty():
   if b.tick==10:pair(b,3,"march_pending_order")
   if b.hits[0]+b.hits[1]>0 and not had_contact:had_contact=true;pair(b,3,"first_real_attack")
   if b.losses[0]+b.losses[1]>0 and not had_casualty:had_casualty=true;pair(b,3,"first_real_casualty")
   if b.tick>=target:break
   inputs(b);b.step()
   if b.tick%100==0:print("SAVE5_PROGRESS ",b.tick," attacks=",b.attacks," losses=",b.losses)
  check(b.tick==target,"requested actual tick reached")
  check(had_contact and had_casualty,"real attack and casualty checkpoints reached")
  rejection_tests(b)
  if not check(store.save(b,slot)==OK,"real experimental atomic save"):finish(phase);return
  check(store.save(b,"river_gate_quick_v1")==OK,"same leaf name remains in experimental namespace")
  disk_corruption_tests(b,slot)
  var saved:=Save.snapshot(b);write_variant(outdir.path_join("saved.bin"),saved)
  var expected:=[]
  for step in 20:
   inputs(b);b.step();expected.append([digest(Save.snapshot(b)),digest(observation(b))])
  write_variant(outdir.path_join("expected.bin"),{"initial":saved,"frames":expected,"final":Save.snapshot(b),"legacy":legacy_before,"world":world_before,"writer_pid":OS.get_process_id()})
  check(FileAccess.get_file_as_bytes(Save.FILE)==legacy_before,"legacy quick bytes untouched")
  check(FileAccess.get_file_as_bytes("user://campaign_sentinel.bin")==world_before,"campaign sentinel untouched")
  check(Save.load_quick()!=null,"legacy quick remains readable")
 elif phase=="read":
  var expected:Dictionary=read_variant(outdir.path_join("expected.bin"))
  check(expected.writer_pid is int,"persisted writer process receipt present; external runner verifies restart")
  var b:=store.load_slot(runtime,slot)
  if not check(b!=null,"disk load with explicitly configured runtime"):finish(phase);return
  check(Save.snapshot(b)==expected.initial,"restarted whole initial Save equals writer")
  for step in expected.frames.size():
   inputs(b);b.step()
   check(digest(Save.snapshot(b))==expected.frames[step][0],"restart complete Save frame "+str(step))
   check(digest(observation(b))==expected.frames[step][1],"restart events frame "+str(step))
  check(var_to_bytes(Save.snapshot(b))==var_to_bytes(expected.final),"restarted final bytes exact")
  check(FileAccess.get_file_as_bytes(Save.FILE)==expected.legacy,"restart old quick bytes untouched")
  check(FileAccess.get_file_as_bytes("user://campaign_sentinel.bin")==expected.world,"restart campaign untouched")
  check(b.ordinary_counts==PackedInt32Array([count,count]),"ordinary roster not reduced")
  checkpoints.append({"tick":b.tick,"attacks":b.attacks,"hits":b.hits,"losses":b.losses,"roster":b.roster.size(),"sha256":digest(Save.snapshot(b))})
 else:check(false,"unknown phase")
 finish(phase)
func finish(phase:String):
 var report:={"phase":phase,"checks":checks,"failures":failures,"checkpoints":checkpoints,"pid":OS.get_process_id(),"scope":"REAL_CPU_SAVE_RESUME_NO_CAMPAIGN_NO_ART_GPU_OR_M5_CLAIM"}
 FileAccess.open(outdir.path_join(phase+".json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("EXPERIMENTAL_SAVE5_RESULT ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
