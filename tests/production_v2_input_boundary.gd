extends SceneTree
const Pilot=preload('res://scripts/field/experimental/production_v2/contact_input_pilot.gd')
const Actions=preload('res://scripts/input_actions.gd')
class MapProbe extends RefCounted:
 var is_legacy:=false
 func identity()->Dictionary:return {'scope':'mock_boundary_only_not_real_map'}
class HeroProbe extends RefCounted:
 var impacts:=0
 var hp:=100.
class BattleProbe extends RefCounted:
 var map_runtime=MapProbe.new()
 var hero=HeroProbe.new()
 var started:=true
 var result:=''
 var tick:=0
class FieldProbe extends Node:
 var battle=BattleProbe.new()
 var paused:=false
class RecorderProbe extends Node:
 var active:=true
 var rows:Array=[]
 func write(row:Dictionary)->void:rows.append(row.duplicate(true))
 func stop(_why:String)->void:active=false
func _initialize()->void:run.call_deferred()
func run()->void:
 Actions.install();var f=FieldProbe.new();var r=RecorderProbe.new();var p=Pilot.new();root.add_child(f);root.add_child(r);root.add_child(p)
 f.battle.map_runtime.is_legacy=true;assert(p.begin(f,r)==ERR_UNAVAILABLE)
 f.battle.map_runtime.is_legacy=false;assert(p.begin(f,r)==OK)
 p.motion(Vector2(.4,-.6));p.sprint(true);p.attack(true);assert(Input.is_physical_key_pressed(KEY_J));assert(Input.is_action_pressed('field_sprint'));p.finish('boundary_cancel')
 assert(not Input.is_physical_key_pressed(KEY_J));assert(not Input.is_action_pressed('field_sprint'));assert(Input.get_vector('move_left','move_right','move_up','move_down')==Vector2.ZERO)
 assert(f.battle.hero.hp==100. and f.battle.tick==0 and f.battle.hero.impacts==0)
 p.free();f.free();r.free();print('PRODUCTION_V2_PILOT_BOUNDARY_RELEASE_PASS;real Controller/map/GPU NOT_RUN');quit()
