extends SceneTree
const Capture:=preload("res://scripts/field/wall_clock_capture.gd")
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var location:=OS.get_environment("CAPTURE_LIFECYCLE_ROOT")
	if location.is_empty():location="user://"
	var base:=ProjectSettings.globalize_path(location+"/capture-lifecycle-%d"%Time.get_ticks_usec())
	for mode:String in ["normal","frame_limit","byte_limit","wall_limit"]:
		var recorder:=Capture.new();root.add_child(recorder)
		var path:=base+"/"+mode
		assert(recorder.start(root,path))
		assert(RenderingServer.frame_post_draw.is_connected(recorder.capture))
		if "--wall-clock-action" in OS.get_cmdline_user_args():
			assert(recorder.interval_us==41667)
			assert(recorder.frame_limit==(720 if "--native-uhd" in OS.get_cmdline_user_args() else 1440))
		match mode:
			"normal":recorder.stop("synthetic_test_stop")
			"frame_limit":recorder.frames=recorder.frame_limit;recorder.capture()
			"byte_limit":recorder.bytes=recorder.byte_limit;recorder.capture()
			"wall_limit":recorder.started-=recorder.wall_limit_us+1;recorder.capture()
		assert(not recorder.active)
		assert(not RenderingServer.frame_post_draw.is_connected(recorder.capture))
		assert(not recorder.start(root,path),"Existing evidence must not be mixed on restart")
		recorder.queue_free();await process_frame
	print("WALL_CLOCK_LIFECYCLE_SYNTHETIC_PASS no graphical frames captured")
	quit(0)
