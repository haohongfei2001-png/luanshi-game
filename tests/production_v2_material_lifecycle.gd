extends SceneTree
const Adapter=preload("res://scripts/field/experimental/production_v2/uv_spatial/adapter.gd")
const Actor=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const MaterialControl=preload("res://scripts/review/production_v2_material_control.gd")
func reject(reason:String):push_error(reason);quit(2)
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1:reject("one exact source18 GLB required");return
 if FileAccess.get_sha256(args[0])!=Adapter.SOURCE_SHA:reject("wrong source18");return
 var adapter:=Adapter.new()
 if adapter.configure_contract("res://scripts/field/experimental/production_v2/uv_spatial/source18_contract.json")!=OK:reject("contract configure failed");return
 var document:=GLTFDocument.new();var state:=GLTFState.new()
 if document.append_from_file(args[0],state)!=OK:reject("source18 import failed");return
 var model=document.generate_scene(state);var packed:=PackedScene.new()
 if model==null or packed.pack(model)!=OK:reject("source18 packing failed");return
 model.free()
 var control:=MaterialControl.new();var instances=[]
 for index in 7:
  var actor:=Actor.new();root.add_child(actor)
  if actor.setup(packed)!=OK:reject("actual actor setup failed");return
  instances.append(actor)
 var original:=control.material_state(instances)
 for actor in instances:
  if adapter.apply(actor).get("applied",true):reject("default is not OFF");return
 if original!=control.material_state(instances):reject("default modified materials");return
 for actor in instances:
  var receipt:=adapter.apply(actor,true)
  if not receipt.get("applied",false) or receipt.get("surfaces")!=18:reject("override rejected "+JSON.stringify(receipt));return
 if adapter.materials.size()!=2:reject("shared material count changed");return
 var restored:=0
 for actor in instances:restored+=adapter.restore(actor)
 if restored!=126 or original!=control.material_state(instances):reject("restore differs");return
 for actor in instances:actor.free()
 print("MATERIAL_LIFECYCLE_PASS seven_actual_source18_actors 126_surfaces two_shared_materials default_OFF restored_exact GPU_NOT_RUN")
 quit()
