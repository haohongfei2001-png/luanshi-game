extends SceneTree
const Collector=preload("res://tools/production_v2/collect_resource_identities.gd")
func _initialize()->void:
 var path:="res://scripts/field/maps/map_identity.gd"
 # Use tracked scripts as direct resources; actual imported image closure is
 # independently verified by packed_resource_closure.gd and the nine-resource PCK fixture.
 var source={"scene":{"path":path,"sha256":FileAccess.get_sha256(path)},"navigation":{"path":path,"sha256":FileAccess.get_sha256(path)},"actor":{"path":path,"sha256":FileAccess.get_sha256(path),"timing_path":path,"timing_sha256":FileAccess.get_sha256(path)}}
 var result:=Collector.build(source)
 assert(result.error.is_empty(),JSON.stringify(result))
 assert(result.manifest.resource_identities.has(path));assert(not source.has("resource_identities"))
 var bad:=source.duplicate(true);bad.scene.sha256="0".repeat(64)
 assert(not Collector.build(bad).error.is_empty())
 bad=source.duplicate(true);bad.scene.path="res://../project.godot"
 assert(not Collector.build(bad).error.is_empty())
 bad=source.duplicate(true);bad.actor.erase("timing_sha256")
 assert(not Collector.build(bad).error.is_empty())
 print("RESOURCE_IDENTITY_PREPARATION_PASS valid_direct_closure wrong_pin unsafe_path missing_timing no_input_mutation");quit()
