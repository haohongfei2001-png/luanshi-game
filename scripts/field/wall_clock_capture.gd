extends Node
## Bounded real-wall-clock readback. No simulation stepping or frame-rate override.
var viewport:Window
var directory:String
var field:Node
var journal:FileAccess
var next_due:=0
var frames:=0
var bytes:=0
var readback_us:=0
var skipped_slots:=0
var started:=0
var active:=false
const INTERVAL_US:=250000 # Explicit diagnostic default only.
var interval_us:=INTERVAL_US
var frame_limit:=480
var byte_limit:=1500000000
var wall_limit_us:=120000000
var capture_mode:="DIAGNOSTIC_4FPS_NOT_ACTION_ACCEPTANCE"
const MAX_FRAMES:=480
const MAX_BYTES:=1500000000
const MAX_WALL_US:=120000000
func start(window:Window,path:String,game_field:Node=null) -> bool:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--fixed-fps") or arg.begins_with("--write-movie"):return false
	viewport=window;directory=path;field=game_field
	if FileAccess.file_exists(path+"/frames.jsonl"):return false # Never mix or overwrite prior evidence.
	DirAccess.make_dir_recursive_absolute(path)
	journal=FileAccess.open(path+"/frames.jsonl",FileAccess.WRITE)
	if not journal:return false
	var free_bytes:=int(DirAccess.open(path).get_space_left())
	if "--wall-clock-action" in OS.get_cmdline_user_args():
		capture_mode="ACTION_REVIEW_TARGET_24FPS_NOT_YET_ACCEPTED"
		interval_us=41667
		var uhd:="--native-uhd" in OS.get_cmdline_user_args()
		frame_limit=720 if uhd else 1440
		wall_limit_us=30000000 if uhd else 60000000
		# Conservative source JPEG budget plus a separate encoded-output reserve.
		var frame_budget:=12*1024*1024 if uhd else 6*1024*1024
		byte_limit=frame_limit*frame_budget
	var required:=byte_limit+2*1024*1024*1024
	if free_bytes<required:
		write({"kind":"failure","reason":"insufficient_disk_preflight","available_bytes":free_bytes,"required_bytes":required,"mode":capture_mode})
		journal.close();return false
	started=Time.get_ticks_usec();next_due=started;active=true
	write({"kind":"header","clock":"Time.get_ticks_usec monotonic","source":OS.get_environment("RIVER_SOURCE_SHA"),"mode":capture_mode,"disk_available_bytes":free_bytes,"sample_interval_us":interval_us,"max_frames":frame_limit,"max_bytes":byte_limit,"max_wall_us":wall_limit_us,"audio":"NOT_CAPTURED","performance":"READBACK_INSTRUMENTED_NOT_BENCHMARK"})
	RenderingServer.frame_post_draw.connect(capture)
	return true
func write(row:Dictionary) -> void:
	journal.store_line(JSON.stringify(row));journal.flush()
func capture() -> void:
	if not active:return
	var now:=Time.get_ticks_usec()
	if now-started>=wall_limit_us or frames>=frame_limit or bytes>=byte_limit:
		stop("capture_limit");return
	if now<next_due:return
	var missed:=maxi(0,int((now-next_due)/interval_us))
	skipped_slots+=missed
	next_due+=(missed+1)*interval_us
	var image:=viewport.get_texture().get_image()
	var image_done:=Time.get_ticks_usec()
	var filename:="frame-%06d.jpg"%frames
	if image==null or image.is_empty() or not is_equal_approx(viewport.scaling_3d_scale,1.):
		stop("invalid_attachment");return
	var data:=image.save_jpg_to_buffer(.94)
	var encode_done:=Time.get_ticks_usec()
	if bytes+data.size()>byte_limit:stop("byte_limit");return
	var file:=FileAccess.open(directory+"/"+filename,FileAccess.WRITE)
	if not file:stop("file_error");return
	file.store_buffer(data);file.flush()
	var file_error:=file.get_error();file.close()
	if file_error!=OK:
		write({"kind":"failure","reason":"frame_write_error","file":filename,"error":file_error})
		stop("write_failure");return
	var elapsed:=Time.get_ticks_usec()-now
	readback_us+=elapsed;bytes+=data.size()
	var state:Dictionary={}
	if is_instance_valid(field):
		var b=field.battle
		state={"tick":b.tick,"ordinary":Array(b.ordinary_counts),"hits":b.hits.duplicate(),"blocks":b.blocked_hits,"losses":b.losses.duplicate(),"hero_hp":b.hero.hp,"hero_impacts":b.hero.impacts,"hero_state":b.hero.state,"hero_kit":b.hero.kit,"vehicle":b.vehicle,"hero_pos":str(b.hero.pos),"camera_size":field.camera.size,"hero_in_frame":viewport.get_visible_rect().has_point(field.camera.unproject_position(field.Ground.unit_point(b.hero.pos,true)))}
	write({"state":state,"kind":"frame","file":filename,"monotonic_us":now,"image_readback_us":image_done-now,"jpeg_encode_us":encode_done-image_done,"disk_write_us":Time.get_ticks_usec()-encode_done,"readback_encode_write_us":elapsed,"pixels":[image.get_width(),image.get_height()],"scale":viewport.scaling_3d_scale,"bytes":data.size(),"engine_drawn":Engine.get_frames_drawn()})
	frames+=1
func stop(reason:String) -> void:
	if not active:return
	active=false
	if RenderingServer.frame_post_draw.is_connected(capture):RenderingServer.frame_post_draw.disconnect(capture)
	write({"kind":"end","reason":reason,"monotonic_us":Time.get_ticks_usec(),"frames":frames,"bytes":bytes,"skipped_scheduled_slots":skipped_slots,"readback_encode_write_us_total":readback_us,"audio":"NOT_CAPTURED"})
	journal.close()
func _exit_tree() -> void:stop("scene_exit")
