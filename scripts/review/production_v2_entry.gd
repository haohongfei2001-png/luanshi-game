class_name DotProductionV2Entry
extends SceneTree
## Explicit internal runner. No shipping menu/save/default path reaches this.
## Run only with LUANSHI_PRODUCTION_V2=1 and a verified complete mother manifest.
const ResourceClosure:=preload("res://scripts/review/resource_closure.gd")
const PackedIdentity:=preload("res://scripts/review/resource_identity.gd")
const Identity:=preload("res://scripts/field/maps/map_identity.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
const Host:=preload("res://scripts/field/maps/authored_scene_host.gd")
const Controller:=preload("res://scripts/field/maps/authored_field_controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Actor:=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const Binding:=preload("res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd")
var field:Controller
var entry_receipt:Dictionary={}
var packed_observations:Dictionary={}
func _initialize():start.call_deferred()
func fail(reason:String):
 push_error("PRODUCTION_V2_ENTRY_REJECTED "+reason);quit(2)
func checked_path(path:Variant)->bool:
 return path is String and path.begins_with("res://") and not ".." in path and FileAccess.file_exists(path)
func checked_resource(path:Variant,original_sha:Variant,identities:Dictionary)->bool:
 if not path is String or not path.begins_with("res://") or ".." in path or not Identity.valid_sha(original_sha):return false
 var row=identities.get(path)
 if not row is Dictionary or row.get("original_source_sha256")!=original_sha:return false
 var expected:Dictionary=row.duplicate(true);expected.erase("original_source_sha256")
 var observed:=PackedIdentity.describe(path)
 if observed!=expected:return false
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=original_sha:return false
 packed_observations[path]=observed
 return true
func start()->void:
 if OS.get_environment("LUANSHI_PRODUCTION_V2")!="1":fail("explicit opt-in required");return
 var args:=OS.get_cmdline_user_args()
 var validate_only:=args.has("--validate-setup")
 if validate_only:args.remove_at(args.find("--validate-setup"))
 if args.size()!=1 or not checked_path(args[0]):fail("one existing res:// manifest required");return
 var raw=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 if not raw is Dictionary:fail("invalid manifest JSON");return
 var manifest:Dictionary=raw
 if manifest.get("internal_mode")!="open_gate_field_no_campaign":fail("unsupported map mode; siege/campaign not wired");return
 var hashes:Dictionary={}
 var identities=manifest.get("resource_identities")
 if not identities is Dictionary:fail("export-verified original/packed resource identities required");return
 for key in ["scene","navigation"]:
  if not manifest.get(key) is Dictionary or not checked_resource(manifest[key].get("path"),manifest[key].get("sha256"),identities):fail("missing "+key);return
  # Original hashes were verified at export; exact imported payload hashes
  # above are independently observed in this PCK. Do not conflate the two.
  hashes[manifest[key].path]=manifest[key].sha256
 var identity:=Identity.new()
 if identity.configure(manifest,hashes)!=OK:fail("map payload/source identity mismatch");return
 var data=JSON.parse_string(FileAccess.get_file_as_string(manifest.navigation.path))
 if not data is Dictionary:fail("invalid navigation JSON");return
 for key in ["map_id","topology_revision","topology_sha256","authored_source_sha256"]:
  if data.get(key)!=manifest.get(key):fail("navigation disagrees with mother: "+key);return
 var actor_spec=manifest.get("actor")
 if not actor_spec is Dictionary:fail("missing actual actor identity");return
 for pair in [["path","sha256"],["timing_path","timing_sha256"]]:
  if not checked_resource(actor_spec.get(pair[0]),actor_spec.get(pair[1]),identities):fail("actor/timing byte identity mismatch");return
 var closure:=ResourceClosure.collect([manifest.scene.path,manifest.navigation.path,actor_spec.path,actor_spec.timing_path])
 if not closure.error.is_empty():fail("actual dependency closure failed "+JSON.stringify(closure));return
 var declared:Array=identities.keys();declared.sort()
 if declared!=closure.paths:fail("declared resource identity set differs from actual transitive closure "+JSON.stringify({"declared":declared,"actual":closure.paths}));return
 for resource_path in identities:
  var row=identities[resource_path]
  if not row is Dictionary or not checked_resource(resource_path,row.get("original_source_sha256"),identities):fail("declared dependency bytes differ: "+str(resource_path));return
 if not Identity.positive_integer(manifest.get("ordinary_per_side")):fail("ordinary_per_side must be an exact positive integer");return
 var count:=int(manifest.get("ordinary_per_side",0))
 if not count in [20,100,250,512]:fail("unsupported explicit troop count");return
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in data.get("surfaces",[]):
  if not surface.get("walkable",false):continue
  for point in surface.vertices:
   low=low.min(Vector2(point[0],point[2]));high=high.max(Vector2(point[0],point[2]))
 if not low.is_finite() or not high.is_finite():fail("no tagged source support");return
 var bounds:=Rect2(low,high-low)
 var nav:=Navigation.new()
 if nav.configure(data,bounds,{"gate_main":true},.7,3.4)!=OK:fail("source navigation rejected");return
 var runtime:=Runtime.new()
 if runtime.bind(nav,data)!=OK:fail("source semantic mode rejected");return
 var battle:=Battle.new();battle.setup(count,int(manifest.get("seed",61112)),Battle.Arms.Kit.SPEAR,true,true,count,false)
 var muster:=Muster.apply(battle,runtime)
 if muster.error!=OK:fail("source capacity/strict muster rejected "+JSON.stringify(muster));return
 var host:=Host.new()
 if host.configure(load(manifest.scene.path) as PackedScene,manifest)!=OK:host.free();fail("mother root identity/lights/gate rejected");return
 var packed_actor:=load(actor_spec.path) as PackedScene
 var actor:=Actor.new()
 if actor.setup(packed_actor)!=OK:host.free();actor.free();fail("complete Skeleton asset rejected");return
 var binding:=Binding.new();var timing=JSON.parse_string(FileAccess.get_file_as_string(actor_spec.timing_path))
 if not timing is Dictionary or binding.configure_timing(timing,actor_spec.sha256)!=OK:host.free();actor.free();fail("actual animation timing mismatch");return
 binding.ground_point=Callable(runtime,"unit_point");binding.enabled=true
 field=Controller.new()
 if field.configure(battle,host,actor,binding,bounds,"INTERNAL_COMPLETE_MOTHER_WIP_NOT_ART_ACCEPTED")!=OK:host.free();actor.free();field.free();fail("Controller binding rejected");return
 var ordinary_budget=manifest.get("ordinary_spearmen_per_team",0)
 if not (ordinary_budget is int or ordinary_budget is float) or not is_finite(float(ordinary_budget)) or ordinary_budget!=floor(float(ordinary_budget)) or ordinary_budget<0 or ordinary_budget>3:fail("ordinary spear probe budget must be0..3 each side");return
 var ordinary_ids:=Binding.select_ordinary_ids(battle,int(ordinary_budget));var ordinary_instances:=[]
 if ordinary_ids.size()!=2*int(ordinary_budget):fail("not enough actual eligible ordinary foot spearmen; never substitute troop types");return
 for id in ordinary_ids:
  var extra_actor:=Actor.new();var extra_binding:=Binding.new()
  if extra_actor.setup(packed_actor)!=OK or extra_binding.configure_timing(timing,actor_spec.sha256)!=OK:extra_actor.free();fail("ordinary actor setup rejected");return
  extra_binding.ground_point=Callable(runtime,"unit_point");extra_binding.enabled=true
  ordinary_instances.append({"unit_id":id,"actor":extra_actor,"binding":extra_binding})
 if field.configure_ordinary_spearmen(ordinary_instances)!=OK:fail("actual ordinary unit binding rejected");return
 root.add_child(field)
 if field.view.review_hidden_actor_ids.size()!=ordinary_ids.size():fail("ordinary source bindings were not all supported initially");return
 if not validate_only:field.deploy()
 entry_receipt={"kind":"PRODUCTION_V2_ENTRY_READY_NOT_ART_ACCEPTANCE","manifest_sha256":FileAccess.get_sha256(args[0]),"map_identity":identity.identity(),"visual_revision":manifest.visual_revision,"scene_sha256":hashes[manifest.scene.path],"navigation_sha256":hashes[manifest.navigation.path],"actor_sha256":actor_spec.sha256,"muster":muster,"camera":{"pitch_degrees":45.,"fov":50.,"nominal_body_fraction":.125},"ordinary_new_spear_ids":ordinary_ids,"scope":"WIP_NEW_HERO_AND_EXPLICIT_LIMITED_ACTUAL_SPEARMEN; REMAINDER_OLD_CROWD_DIAGNOSTIC; NO_SIEGE_CAMPAIGN_OR_NEW_SAVE_SUPPORT"}
 entry_receipt["validate_only"]=validate_only
 entry_receipt["runtime_packed_observations"]=packed_observations
 entry_receipt["actual_resource_closure"]=closure
 entry_receipt["source_hash_scope"]="original bytes verified during export; runtime independently hashes imported packed resources"
 print("PRODUCTION_V2_ENTRY_READY ",JSON.stringify(entry_receipt))
 if validate_only:quit()
