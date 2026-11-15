extends Node
## Actual wall-clock readback only. Never advances Battle or modifies units.
var active:=false
var viewport:Window
var field:Node
var directory:=""
var journal:FileAccess
var started:=0
var next_due:=0
var frames:=0
var total_bytes:=0
var stop_reason:=""
const INTERVAL_US:=41667
func begin(window:Window,controller:Node,path:String)->bool:
 for arg in OS.get_cmdline_args():
  if arg.begins_with("--fixed-fps") or arg.begins_with("--write-movie"):return false
 if FileAccess.file_exists(path+"/frames.jsonl"):return false
 viewport=window;field=controller;directory=path
 DirAccess.make_dir_recursive_absolute(path)
 if DirAccess.open(path).get_space_left()<4*1024*1024*1024:return false
 journal=FileAccess.open(path+"/frames.jsonl",FileAccess.WRITE)
 if journal==null:return false
 started=Time.get_ticks_usec();next_due=started;active=true
 write({"kind":"header","clock":"Time.get_ticks_usec monotonic","mode":"ACTUAL_PHYSICS_TARGET24FPS_NOT_ACCEPTED","sample_interval_us":INTERVAL_US,"source":OS.get_environment("GITHUB_SHA"),"performance":"READBACK_INSTRUMENTED_NOT_BENCHMARK","source_identity":field.battle.map_runtime.identity(),"audio":"NOT_CAPTURED"})
 RenderingServer.frame_post_draw.connect(capture);return true
func write(row:Dictionary)->void:
 if journal==null:return
 journal.store_line(JSON.stringify(row));journal.flush()
func capture()->void:
 if not active:return
 var now:=Time.get_ticks_usec()
 if now-started>35000000 or frames>=900 or total_bytes>1800000000:stop("capture_limit");return
 if now<next_due:return
 next_due=now+INTERVAL_US
 var image:=viewport.get_texture().get_image()
 if image==null or image.get_size()!=Vector2i(2560,1440) or not is_equal_approx(viewport.scaling_3d_scale,1.):stop("invalid_actual_native_attachment");return
 var filename:="frame-%06d.jpg"%frames;var data:=image.save_jpg_to_buffer(.94)
 var file:=FileAccess.open(directory+"/"+filename,FileAccess.WRITE)
 if file==null:stop("frame_open_failure");return
 file.store_buffer(data);file.flush();var error:=file.get_error();file.close()
 if error!=OK:stop("frame_write_failure");return
 var b=field.battle;var units:=[]
 for item in field.ordinary_actor_bindings:
  var unit=b.roster[item.unit_id]
  units.append({"id":unit.id,"team":unit.team,"hp":unit.hp,"state":unit.state,"impacts":unit.impacts,"actual_pos":str(unit.pos),"actor_transform":str(item.actor.global_transform),"binding":field.ordinary_actor_receipts.get(unit.id,{})})
 var state={"tick":b.tick,"ordinary":Array(b.ordinary_counts),"hits":b.hits.duplicate(),"blocks":b.blocked_hits,"losses":b.losses.duplicate(),"hero_hp":b.hero.hp,"hero_impacts":b.hero.impacts,"hero_state":b.hero.state,"hero_pos":str(b.hero.pos),"hero_in_frame":viewport.get_visible_rect().has_point(field.camera.unproject_position(b.map_runtime.unit_point(b.hero.pos))),"new_ordinary":units}
 write({"kind":"frame","file":filename,"monotonic_us":now,"pixels":[image.get_width(),image.get_height()],"texture_metadata":[viewport.get_texture().get_width(),viewport.get_texture().get_height()],"scale":viewport.scaling_3d_scale,"bytes":data.size(),"engine_drawn":Engine.get_frames_drawn(),"readback_encode_write_us":Time.get_ticks_usec()-now,"state":state,"hero_binding":field.actor_receipt,"camera_transform":str(field.camera.global_transform),"camera_profile":field.review_camera_profile})
 frames+=1;total_bytes+=data.size()
func stop(reason:String)->void:
 if not active:return
 active=false;stop_reason=reason
 if RenderingServer.frame_post_draw.is_connected(capture):RenderingServer.frame_post_draw.disconnect(capture)
 write({"kind":"end","reason":reason,"monotonic_us":Time.get_ticks_usec(),"frames":frames,"bytes":total_bytes,"audio":"NOT_CAPTURED"});journal.close();journal=null
func _exit_tree()->void:stop("scene_exit")
