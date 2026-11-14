extends "res://tests/authored_architecture_capture.gd"
class_name DotNativeRegionCapture
## Hosted graphics only. This wrapper does not change the scene, camera or battle.
func _initialize() -> void:
 var host={"pid":OS.get_process_id(),"platform":OS.get_name(),"processor":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"source":OS.get_environment('GITHUB_SHA'),"asset_source":OS.get_environment("REGION_ASSET_SOURCE") if not OS.get_environment("REGION_ASSET_SOURCE").is_empty() else "ee5d1389944a4e3a3a13487856066e0631f8ca25","art":"NOT_ACCEPTED","M5":"DEVICE_NOT_RUN","scope":"hosted native graphics, not a shipped Mac candidate"}
 DirAccess.make_dir_recursive_absolute(out)
 var file=FileAccess.open(out+'/native-host.json',FileAccess.WRITE)
 file.store_string(JSON.stringify(host,'  '));file.close()
 print('NATIVE_REGION_FOCUS ',JSON.stringify(host))
 super._initialize()

func run() -> void:
 if DisplayServer.get_name()!='headless':
  # Request only this game's native window after the main loop starts pumping
  # events. A helper's 0.4s snapshot during _initialize is not a readiness test.
  for frame in 3:await process_frame
  root.grab_focus()
  var deadline=Time.get_ticks_usec()+3000000
  while not root.has_focus() and Time.get_ticks_usec()<deadline:await process_frame
  var focused=root.has_focus()
  print('NATIVE_WINDOW_READY ',JSON.stringify({'pid':OS.get_process_id(),'focused':focused,'native_window':root.get_window_id(),'display':DisplayServer.get_name()}))
  if not focused:
   push_error('Native game window did not become focused');quit(1);return
 await super.run()
