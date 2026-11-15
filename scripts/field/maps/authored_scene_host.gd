extends "res://scripts/field/river_pass_master.gd"
## Internal complete-mother host. Never calls the legacy geometry/material builder.
## Type compatibility only; no runtime assembly, recolouring or added lighting.
var configured:=false
var host_error:Error=ERR_UNCONFIGURED
var authored_gate:Node3D
var expected_identity:Dictionary={}
func configure(scene:PackedScene,identity:Dictionary)->Error:
 if configured or is_inside_tree():return ERR_ALREADY_IN_USE
 if scene==null:return ERR_INVALID_PARAMETER
 var candidate:=scene.instantiate() as Node3D
 if candidate==null:return ERR_INVALID_DATA
 for key in ["map_id","topology_revision","topology_sha256","visual_revision","authored_source_sha256"]:
  if not identity.has(key) or candidate.get_meta(key,null)!=identity[key]:
   candidate.free();return ERR_FILE_CORRUPT
 var lights:=candidate.find_children("*","DirectionalLight3D",true,false)
 var worlds:=candidate.find_children("*","WorldEnvironment",true,false)
 if lights.size()!=1 or worlds.size()!=1 or (worlds[0] as WorldEnvironment).environment==null:
  candidate.free();return ERR_INVALID_DATA
 var gates:Array[Node3D]=[]
 for node in candidate.find_children("*","Node3D",true,false):
  var extras=node.get_meta("extras",{})
  if extras is Dictionary and extras.get("gate_id","")=="gate_main":gates.append(node)
 if gates.size()!=1:
  candidate.free();return ERR_INVALID_DATA
 # Discard only the inherited, unattached empty light. Adopt the author light.
 sun.free();sun=lights[0];master=candidate;authored_gate=gates[0]
 expected_identity=identity.duplicate(true);configured=true;host_error=OK
 return OK
func _ready()->void:
 if not configured:
  host_error=ERR_UNCONFIGURED;push_error("Complete authored mother scene not configured");return
 name="ProductionV2CompleteMother";add_child(master)
func update_battle(battle)->void:
 if not configured or battle.map_runtime.is_legacy:
  push_error("Authored scene cannot display a legacy Battle");return
 if battle.map_runtime.identity().get("topology_sha256")!=expected_identity.topology_sha256:
  push_error("Mother scene and actual Battle topology differ");return
 # First internal mode is explicitly open gate. Hide only semantic door leaf.
 authored_gate.visible=battle.gate_hp>0
func reveal_sightline(_focus:Vector2,_hero:Vector2,_eye:Vector3,_zoom:float,_live:bool,_assault_near:bool=false)->void:
 pass # No legacy roof manipulation or author material mutation.
func composition_audit()->Dictionary:
 return {"complete_mother":configured,"identity":expected_identity.duplicate(true),"runtime_scattering":false,"art_acceptance":"NOT_ACCEPTED","host_error":host_error}
func _notification(what:int)->void:
 if what!=NOTIFICATION_PREDELETE:return
 if is_instance_valid(master) and master.get_parent()==null:master.free()
 if is_instance_valid(sun) and sun.get_parent()==null:sun.free()
