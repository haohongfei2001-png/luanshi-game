extends SceneTree
func _initialize():
 var p=PCKPacker.new()
 if p.pck_start('/workspace/shared/actor-probe.pck')!=OK:quit(1);return
 var files=['project.godot','scripts/field/experimental/controlled_author_actor.gd','scripts/field/experimental/controlled_author_cache.gdshader','tools/art/soldier_controlled_probe/actor_adapter_check.gd']
 for f in files:
  if p.add_file('res://'+f,'res://'+f)!=OK:quit(1);return
 if p.flush()!=OK:quit(1);return
 quit()
