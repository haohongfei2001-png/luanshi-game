extends SceneTree
const Host:=preload("res://scripts/field/maps/authored_scene_host.gd")
class Runtime extends RefCounted:
 var is_legacy:=false
 func identity()->Dictionary:return {"topology_sha256":"a".repeat(64)}
var identity:={"map_id":"fixture.only.not.art","topology_revision":1,"topology_sha256":"a".repeat(64),"visual_revision":1,"authored_source_sha256":"b".repeat(64)}
func fixture(extra_sun:bool=false)->PackedScene:
 var node:=Node3D.new()
 for k in identity:node.set_meta(k,identity[k])
 var sun:=DirectionalLight3D.new();sun.light_energy=.731;node.add_child(sun);sun.owner=node
 if extra_sun:
  var second:=DirectionalLight3D.new();node.add_child(second);second.owner=node
 var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.tonemap_exposure=.917;node.add_child(world);world.owner=node
 var doorway:=Node3D.new();doorway.name="SemanticDoorLeaf";doorway.set_meta("extras",{"gate_id":"gate_main"});node.add_child(doorway);doorway.owner=node
 var mass:=MeshInstance3D.new();mass.name="FullGateMass";mass.mesh=BoxMesh.new();var mat:=StandardMaterial3D.new();mat.roughness=.123;mass.material_override=mat;node.add_child(mass);mass.owner=node
 var scene:=PackedScene.new();assert(scene.pack(node)==OK);node.free();return scene
func _initialize():run.call_deferred()
func run():
 var reject:=Host.new();var bad:=identity.duplicate();bad.topology_revision=2
 assert(reject.configure(fixture(),bad)==ERR_FILE_CORRUPT);reject.free()
 reject=Host.new();assert(reject.configure(fixture(true),identity)==ERR_INVALID_DATA);reject.free()
 var host:=Host.new();assert(host.configure(fixture(),identity)==OK);root.add_child(host)
 assert(host.get_child_count()==1);assert(is_equal_approx(host.sun.light_energy,.731))
 assert(is_equal_approx(host.master.get_node("FullGateMass").material_override.roughness,.123))
 var world:WorldEnvironment=host.master.find_children("*","WorldEnvironment",true,false)[0];assert(is_equal_approx(world.environment.tonemap_exposure,.917))
 var battle={"map_runtime":Runtime.new(),"gate_hp":0.};host.update_battle(battle)
 assert(not host.authored_gate.visible);assert(host.master.get_node("FullGateMass").visible)
 host.reveal_sightline(Vector2.ZERO,Vector2.ZERO,Vector3.ZERO,20.,true,true)
 assert(is_equal_approx(host.master.get_node("FullGateMass").material_override.roughness,.123))
 host.free();print("AUTHORED_COMPLETE_SCENE_HOST_PASS fixture_only identity_reject duplicate_sun_reject original_material_environment_preserved semantic_leaf_only; REAL_MOTHER_GPU_NOT_RUN");quit()
