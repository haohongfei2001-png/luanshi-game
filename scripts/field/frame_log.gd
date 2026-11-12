extends RefCounted
## Opt-in process-local recorder for the exported game. Each row contains actual
## rendered intervals. Pauses, mode changes and concluded battles split segments.
var file: FileAccess
var wall := PackedFloat32Array()
var gpu := PackedFloat32Array()
var cpu := PackedFloat32Array()
var previous := 0
var input_slot := -1
var input_stamp := 0
var input_ms := PackedFloat32Array()
var first_tick := -1
var first_hits := 0
var observed_hits:=0
var last_contact_tick:=-1
var first_sim := 0
var first_view := 0
var active_seconds := 0.0
var observed: Object
var first_camera := Vector2.ZERO
var attachment_size:=Vector2i.ZERO
var size_pending:=false

func open(viewport: Viewport) -> void:
	var dir := ProjectSettings.globalize_path("user://frame-times")
	if DirAccess.make_dir_recursive_absolute(dir)!=OK: return
	var name := "%s/river-gate-%d-%d.jsonl" % [dir,int(Time.get_unix_time_from_system()),OS.get_process_id()]
	file = FileAccess.open(name,FileAccess.WRITE)
	if not file: return
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),true)
	var revision:=FileAccess.get_file_as_string("res://assets/build-revision.txt").strip_edges() if FileAccess.file_exists("res://assets/build-revision.txt") else "source checkout"
	_write({"kind":"host","revision":revision,"platform":OS.get_name(),"cpu":OS.get_processor_name(),"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"build":ProjectSettings.get_setting("application/config/version"),
		"driver":DisplayServer.get_name(),"vsync":DisplayServer.window_get_vsync_mode(),"file":file.get_path().get_file()})
	print("FIELD_PROFILE_FILE "+name)
	if DisplayServer.get_name()!="headless":
		viewport.size_changed.connect(_queue_size_measurement.bind(viewport))
		_queue_size_measurement(viewport)

func _queue_size_measurement(viewport: Viewport) -> void:
	if size_pending: return
	size_pending=true
	interrupt("viewport_resized")
	attachment_size=Vector2i.ZERO
	RenderingServer.frame_post_draw.connect(_measure_size.bind(viewport),CONNECT_ONE_SHOT)

func _measure_size(viewport: Viewport) -> void:
	size_pending=false
	if not is_instance_valid(viewport): return
	# Root ViewportTexture reports logical canvas dimensions on a stretched window.
	# Read back once at launch/resize and keep the GPU readback out of frame intervals.
	var pic:=viewport.get_texture().get_image()
	if pic==null or pic.is_empty(): return
	attachment_size=pic.get_size()
	_write({"kind":"render_attachment","actual_px":[attachment_size.x,attachment_size.y]})

func accepted(slot: int,at: int) -> void:
	if file:
		input_slot=slot
		input_stamp=at

func pose_submitted(b) -> void:
	if input_slot<0: return
	if b.hero.move_slot==input_slot and b.hero.state in [b.State.WINDUP,b.State.RECOVER,b.State.GUARD]:
		RenderingServer.frame_post_draw.connect(_drawn.bind(input_slot,input_stamp,b.tick),CONNECT_ONE_SHOT)
	input_slot=-1

func _drawn(slot: int,stamp: int,tick: int) -> void:
	var ms: float=(Time.get_ticks_usec()-stamp)/1000.0
	if input_ms.size()>=256: input_ms.remove_at(0)
	input_ms.append(ms)
	_write({"kind":"accepted_action_to_frame_post_draw","slot":slot,"tick":tick,"ms":ms})

func _write(row: Dictionary) -> void:
	file.store_line(JSON.stringify(row))
	file.flush()

func sample(scene) -> void:
	if not file or size_pending: return
	var b=scene.battle
	if observed!=b:
		interrupt("new_battle")
		observed=b
		active_seconds=0
		observed_hits=0
		last_contact_tick=-1
	var hits: int=b.hits[0]+b.hits[1]
	if hits>observed_hits:
		last_contact_tick=b.tick
		observed_hits=hits
	if not b.started or scene.paused or b.result!="" or last_contact_tick<0:
		interrupt("paused_or_finished",scene)
		return
	if b.tick-last_contact_tick>40:
		interrupt("no_recent_contact",scene)
		return
	var now:=Time.get_ticks_usec()
	if previous==0:
		previous=now
		_begin(scene)
		return
	var ms: float=(now-previous)/1000.0
	previous=now
	wall.append(ms)
	active_seconds+=ms/1000.0
	var rid: RID=scene.get_viewport().get_viewport_rid()
	var gpu_ms:=RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var cpu_ms:=RenderingServer.viewport_get_measured_render_time_cpu(rid)
	if gpu_ms>0: gpu.append(gpu_ms)
	if cpu_ms>0: cpu.append(cpu_ms)
	if wall.size()>=180:
		_flush(scene)
		_begin(scene)

func _begin(scene) -> void:
	first_tick=scene.battle.tick
	first_hits=scene.battle.hits[0]+scene.battle.hits[1]
	first_sim=scene.sim_us
	first_view=scene.view_us
	first_camera=scene.camera_center

func _stats(values: PackedFloat32Array) -> Variant:
	if values.is_empty(): return null
	var sorted:=values.duplicate()
	sorted.sort()
	var sum:=0.0
	for v in sorted: sum+=v
	return {"samples":sorted.size(),"mean_ms":sum/sorted.size(),"p50_ms":sorted[ceili(sorted.size()*0.50)-1],"p95_ms":sorted[ceili(sorted.size()*0.95)-1],"p99_ms":sorted[ceili(sorted.size()*0.99)-1]}

func _flush(scene) -> void:
	if wall.is_empty(): return
	var b=scene.battle
	var vp: Viewport=scene.get_viewport()
	var target:=attachment_size
	var logical:=vp.get_texture().get_size()
	var window:=DisplayServer.window_get_size()
	var memory:=OS.get_static_memory_usage()
	_write({"kind":"frames","seed":b.rng.seed,"ordinary_rosters":[b.ordinary_counts[0],b.ordinary_counts[1]],"per_side":b.side_size if b.ordinary_counts[0]==b.ordinary_counts[1] else null,"start_tick":first_tick,"end_tick":b.tick,
		"engaged_wall_seconds":active_seconds,"viewport":[vp.get_visible_rect().size.x,vp.get_visible_rect().size.y],
		"window_px":[window.x,window.y],"reported_viewport_texture_px":[logical.x,logical.y],"render_target_px":[target.x,target.y] if target.x>0 else null,
		"estimated_internal_px":[roundi(target.x*vp.scaling_3d_scale),roundi(target.y*vp.scaling_3d_scale)] if target.x>0 else null,"internal_scale":vp.scaling_3d_scale,"preset":scene.detail_preset,"shadows":scene.map.sun.shadow_enabled,"shadow_max_m":scene.map.sun.directional_shadow_max_distance,"camera_size":scene.camera.size,"camera_travel":first_camera.distance_to(scene.camera_center),
		"visible_soldiers":scene.view.visible_soldiers,"visible_combat_poses":scene.view.visible_fighting,
		"hits_in_window":b.hits[0]+b.hits[1]-first_hits,"losses":b.losses,"gate_hp":b.gate_hp,"outcome":b.result,
		"sim_cpu_ms":float(scene.sim_us-first_sim)/1000.0,"view_script_ms":float(scene.view_us-first_view)/1000.0,
		"wall":_stats(wall),"render_cpu":_stats(cpu),"render_gpu":_stats(gpu),"memory_bytes":memory if memory>0 else null,"raw_wall_ms":Array(wall)})
	wall.clear()
	gpu.clear()
	cpu.clear()

func interrupt(reason: String,scene=null) -> void:
	if not file or previous==0: return
	if scene!=null: _flush(scene)
	elif not wall.is_empty():
		_write({"kind":"partial_frames","wall":_stats(wall),"raw_wall_ms":Array(wall)})
	_write({"kind":"segment_end","reason":reason,"recorded_seconds":active_seconds})
	previous=0
	active_seconds=0
	wall.clear()
	gpu.clear()
	cpu.clear()
