extends SceneTree
## Restored/fast-forwarded hits are historical, not a new engaged render window.
const Recorder:=preload('res://scripts/field/frame_log.gd')
class FakeBattle extends RefCounted:
 const TRACE_STAGES=['test']
 var trace_phase_us:=PackedInt64Array([7])
 var hits:=[12,8]
 var tick:=135
 var started:=true
 var result:=''
class FakeField extends Node:
 var battle=FakeBattle.new()
 var paused:=false
 var sim_us:=0
 var view_us:=0
 var camera_center:=Vector2.ZERO
var problems:Array[String]=[]
func check(condition:bool,message:String)->void:
 if not condition:problems.append(message);push_error(message)
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var recorder=Recorder.new()
 var path='user://frame-log-contact-baseline-%d.jsonl'%OS.get_process_id()
 recorder.file=FileAccess.open(path,FileAccess.WRITE)
 if recorder.file==null:push_error('Cannot create isolated profiler test log');quit(1);return
 var field=FakeField.new();root.add_child(field)
 recorder.sample(field)
 check(recorder.observed_hits==20,'Initial hit baseline must preserve historical count')
 check(recorder.last_contact_tick==-1 and recorder.previous==0,'Historical hit total must not start a live contact segment')
 field.battle.tick+=1;recorder.sample(field)
 check(recorder.last_contact_tick==-1 and recorder.previous==0,'Advancing ticks without a new hit must remain unmeasured')
 field.battle.hits[1]+=1;field.battle.tick+=1;recorder.sample(field)
 check(recorder.last_contact_tick==137 and recorder.previous>0,'A newly observed real hit must start the live segment')
 check(recorder.first_hits==21 and recorder.first_tick==137,'Live baseline must exclude the trigger hit from future hit deltas')
 # Switching to another restored battle must end the previous segment and reset
 # contact recency. No GPU/window is needed to check this evidence boundary.
 field.battle=FakeBattle.new();field.battle.hits=[50,30];field.battle.tick=400
 recorder.sample(field)
 check(recorder.observed_hits==80 and recorder.last_contact_tick==-1 and recorder.previous==0,'A different restored battle must not inherit contact or fabricate a new one')
 field.battle.hits[0]+=1;recorder.sample(field)
 check(recorder.last_contact_tick==400 and recorder.previous>0,'New battle can start only after its next actual observed hit')
 recorder.file.close();recorder.file=null
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 field.free()
 print('FRAME_LOG_CONTACT_BASELINE_', 'PASS' if problems.is_empty() else 'FAIL', ' ',JSON.stringify(problems))
 quit(0 if problems.is_empty() else 1)
