extends SceneTree
const Host=preload("res://scripts/field/maps/authored_scene_host.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var handoff:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]+"/native-handoff.json"))
 var document:=GLTFDocument.new();var state:=GLTFState.new()
 var error:=document.append_from_file(args[0]+"/river-valley-hf01.glb",state)
 assert(error==OK,"Raw author GLB must really parse")
 var visual:=document.generate_scene(state);assert(visual!=null)
 var packed:=PackedScene.new();assert(packed.pack(visual)==OK);visual.free()
 # Runtime resource-cache mapping only, no file/author-wrapper rewriting.
 # This is raw-source structural validation, NOT imported/exported PCK proof.
 packed.take_over_path(handoff.scene.path.get_base_dir()+"/river-valley-hf01.glb")
 var mother=load(args[0]+"/mother.tscn") as PackedScene
 assert(mother!=null)
 var host:=Host.new();var code:=host.configure(mother,handoff.identity)
 var report={"scope":"RAW_GLTF_AND_EXACT_AUTHOR_WRAPPER_STRUCTURE_NO_GPU_NO_EXPORTED_IMPORT_PROOF","error":code,"glb_sha256":FileAccess.get_sha256(args[0]+"/river-valley-hf01.glb"),"identity":handoff.identity}
 if code==OK:
  root.add_child(host);report.sun_energy=host.sun.light_energy;report.sun_count=host.master.find_children("*","DirectionalLight3D",true,false).size();report.world_count=host.master.find_children("*","WorldEnvironment",true,false).size();report.gate_path=str(host.master.get_path_to(host.authored_gate));report.gate_origin=str(host.authored_gate.global_position)
  assert(is_equal_approx(host.sun.light_energy,2.7));assert(host.master.transform==Transform3D.IDENTITY)
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));host.free();print("RAW_AUTHOR_HOST_STRUCTURE ",JSON.stringify(report));quit()
