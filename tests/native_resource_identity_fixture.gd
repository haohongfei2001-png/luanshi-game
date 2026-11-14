extends SceneTree
## Tiny PCK reproduces export remapping without raw GLB/source-checkout fallback.
func _initialize()->void:
 var out:=OS.get_environment('IDENTITY_FIXTURE_OUT')
 if out.is_empty():push_error('IDENTITY_FIXTURE_OUT required');quit(1);return
 DirAccess.make_dir_recursive_absolute(out)
 var mesh_root:=Node3D.new();mesh_root.name='ActualImportedScene'
 var packed:=PackedScene.new()
 if packed.pack(mesh_root)!=OK:quit(1);return
 if ResourceSaver.save(packed,out+'/packed.scn')!=OK:quit(1);return
 mesh_root.free()
 var files={
 'project.godot':'config_version=5\n[application]\nrun/main_scene="res://probe.tscn"\n',
 'probe.tscn':'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://probe.gd" id="1"]\n[node name="Probe" type="Node"]\nscript=ExtResource("1")\n',
 'probe.gd':'extends Node\nconst Identity=preload("res://identity.gd")\nfunc _ready():\n var path="res://assets/gate.glb"\n var row=Identity.describe(path)\n var scene=load(path)\n if row.has("error") or FileAccess.file_exists(path) or not scene is PackedScene:\n  push_error("EXPORTED_IDENTITY_FIXTURE_FAILED");get_tree().quit(1);return\n print("EXPORTED_IDENTITY_FIXTURE_PASS ",JSON.stringify(row));get_tree().quit()\n',
 'gate.glb.import':'[remap]\nimporter="scene"\ntype="PackedScene"\npath="res://.godot/imported/gate.scn"\n'}
 for name in files:
  var file=FileAccess.open(out+'/'+name,FileAccess.WRITE);file.store_string(files[name]);file.close()
 var packer:=PCKPacker.new()
 if packer.pck_start(out+'/identity.pck')!=OK:quit(1);return
 var members={'project.godot':out+'/project.godot','probe.tscn':out+'/probe.tscn','probe.gd':out+'/probe.gd','identity.gd':'res://scripts/review/resource_identity.gd','assets/gate.glb.import':out+'/gate.glb.import','.godot/imported/gate.scn':out+'/packed.scn'}
 for name in members:
  if packer.add_file(name,members[name])!=OK:quit(1);return
 if packer.flush()!=OK:quit(1);return
 print('IDENTITY_FIXTURE_CREATED');quit()
