extends "res://tests/authored_architecture_capture.gd"
class_name DotNativeRegionCapture
## Hosted graphics only. This wrapper does not change the scene, camera or battle.
func _initialize() -> void:
 var host={"pid":OS.get_process_id(),"platform":OS.get_name(),"processor":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"source":OS.get_environment('GITHUB_SHA'),"asset_source":"ee5d1389944a4e3a3a13487856066e0631f8ca25","art":"NOT_ACCEPTED","M5":"DEVICE_NOT_RUN","scope":"hosted native graphics, not a shipped Mac candidate"}
 DirAccess.make_dir_recursive_absolute(out)
 var file=FileAccess.open(out+'/native-host.json',FileAccess.WRITE)
 file.store_string(JSON.stringify(host,'  '));file.close()
 print('NATIVE_REGION_FOCUS ',JSON.stringify(host))
 super._initialize()
