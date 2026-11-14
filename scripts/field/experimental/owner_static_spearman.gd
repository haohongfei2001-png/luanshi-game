extends Sprite3D
## One fixed-view AI source asset, never an animation or final art acceptance.
## Does not read or write Battle. Caller owns the single visual replacement.
const SOURCE_PATH := "res://assets/owner_generated/spearman-static-probe/spearman-elevated.png"
const SOURCE_SHA256 := "44c7980606caad27e1120aa34e355456372a0b51d0d9a14c50918e522ae77271"
const SOURCE_SIZE := Vector2i(1199, 1312)
# Visual annotations on the unchanged original PNG; not depth reconstruction.
# Bottom visible sole, not an artificial vertical lift above terrain.
const FOOT_ANCHOR := Vector2(590.0, 1244.0)
const HELMET_TOP_Y := 174.0 # excludes the helmet plume, like the old body bounds
const BODY_PIXELS := FOOT_ANCHOR.y - HELMET_TOP_Y
var measured_height: float = 0.0
var baseline_height: float = 0.0
var baseline_camera: Transform3D
var configured := false

func configure(camera: Camera3D, ground: Vector3, target_body_height: float, input_texture: Texture2D = null) -> Error:
 if not is_inside_tree() or not is_instance_valid(camera) or not is_finite(target_body_height) or target_body_height <= 0.0:
  return ERR_INVALID_PARAMETER
 var resolved := input_texture
 if resolved == null:
  resolved = load(SOURCE_PATH) as Texture2D
 if resolved == null or resolved.get_size() != Vector2(SOURCE_SIZE):return ERR_FILE_CORRUPT
 if camera.is_position_behind(ground):return ERR_INVALID_PARAMETER
 var up := camera.global_basis.y.normalized()
 var pixels_per_metre := camera.unproject_position(ground).distance_to(camera.unproject_position(ground + up))
 if pixels_per_metre <= 0.0 or not is_finite(pixels_per_metre):return ERR_INVALID_PARAMETER
 texture=resolved
 centered=false
 offset=Vector2(-FOOT_ANCHOR.x, -(SOURCE_SIZE.y-FOOT_ANCHOR.y))
 pixel_size=target_body_height/(BODY_PIXELS*pixels_per_metre)
 global_position=ground
 # Normal depth is mandatory. No screen-space overlay, priority bias or lift.
 no_depth_test=false
 fixed_size=false
 billboard=BaseMaterial3D.BILLBOARD_ENABLED
 shaded=false # baked source illumination, not dynamic material equivalence
 double_sided=true
 alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
 alpha_scissor_threshold=0.3
 texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 baseline_height=target_body_height
 baseline_camera=camera.global_transform
 configured=true
 measured_height=projected_markers(camera).height_logical_px
 if absf(measured_height-target_body_height)>0.02:return ERR_INVALID_DATA
 return OK

func source_pixel_world(pixel: Vector2, camera: Camera3D) -> Vector3:
 return global_position + camera.global_basis.x.normalized() * (pixel.x-FOOT_ANCHOR.x)*pixel_size + camera.global_basis.y.normalized() * (FOOT_ANCHOR.y-pixel.y)*pixel_size

func projected_markers(camera: Camera3D) -> Dictionary:
 var head:=camera.unproject_position(source_pixel_world(Vector2(FOOT_ANCHOR.x,HELMET_TOP_Y),camera))
 var foot:=camera.unproject_position(source_pixel_world(FOOT_ANCHOR,camera))
 return {"height_logical_px":foot.y-head.y,"head_logical_px":[head.x,head.y],"foot_logical_px":[foot.x,foot.y],"viewport_logical_size":[camera.get_viewport().get_visible_rect().size.x,camera.get_viewport().get_visible_rect().size.y],"scope":"manual source helmet/lowest-sole landmarks; excludes plume/spear; not foot contact or per-pixel depth proof"}

func receipt(camera: Camera3D) -> Dictionary:
 return {"kind":"STATIC_SINGLE_DIRECTION_AI_TEXTURE_PROBE","configured":configured,"source_original_sha256":SOURCE_SHA256,"source_size":[SOURCE_SIZE.x,SOURCE_SIZE.y],"foot_anchor_source_px":[FOOT_ANCHOR.x,FOOT_ANCHOR.y],"helmet_top_source_y":HELMET_TOP_Y,"global_ground_anchor":[global_position.x,global_position.y,global_position.z],"pixel_size_world":pixel_size,"baseline_body_logical_px":baseline_height,"projected":projected_markers(camera),"no_depth_test":no_depth_test,"fixed_size":fixed_size,"alpha_scissor_threshold":alpha_scissor_threshold,"alpha_policy":"unchanged PNG, Godot import fix_alpha_border=true, straight alpha, generated mipmaps","shadow_policy":"OFF; no invented rectangle shadow, no dynamic-shadow equivalence claimed","camera_locked":camera.global_transform.is_equal_approx(baseline_camera),"limitations":["one fixed image-facing pose, not unit facing validation","no animation, walking, attack or hit rendering","baked illumination, no dynamic material equivalence","billboard plane depth, not anatomical per-pixel depth","ground anchor verified mathematically; shoe contact and occlusion require actual graphics","not same-source comparison or performance winner","M5 DEVICE_NOT_RUN; ART_NOT_ACCEPTED"]}
