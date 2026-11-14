extends RefCounted
## Optional physical horizon/environment study, no default world modifications.
const Ground:=preload("res://scripts/field/ground.gd")
static func apply(world:WorldEnvironment,sun:DirectionalLight3D,sky_path:String) -> bool:
 if OS.get_environment("LUANSHI_REGIONAL_SKY")!="1":return false
 if not Ground.authored_landform_enabled or Ground.AuthoredProfile.VERSION!="connected-regional-ridges-and-causeway-05":
  push_error("REGIONAL_SKY_REQUIRES_AUTHORED_SCENE: no implicit default-game change");return false
 var sky:=load(sky_path) as Sky
 if sky==null or not sky.has_meta("expected_sun_rotation_degrees"):
  push_error("REGIONAL_SKY_SOURCE_NOT_VERIFIED");return false
 if not sun.is_inside_tree() or not world.is_inside_tree():
  push_error("REGIONAL_SKY_REQUIRES_LIVE_SCENE: source alignment cannot use an unentered transform");return false
 var expected:Vector3=sky.get_meta("expected_sun_rotation_degrees")
 var expected_direction:=Basis.from_euler(expected*PI/180.).z
 var actual_direction:=sun.global_basis.z.normalized()
 if rad_to_deg(expected_direction.angle_to(actual_direction))>.25:
  push_error("REGIONAL_SKY_SUN_MISMATCH: preserve actual light, do not fake physical source alignment");return false
 var environment:=world.environment.duplicate() as Environment
 environment.background_mode=Environment.BG_SKY
 environment.sky=sky
 environment.sky_rotation=Vector3.ZERO # source shader already aligns actual sun
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
 environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
 environment.ambient_light_energy=1.
 # Preserve camera/tonemapping/exposure and the existing directional light.
 # The exact HDR source supplies atmosphere/ambient/reflections, not a flat
 # composite of the terrain, and cannot replace the playable shared survey.
 world.environment=environment
 world.set_meta("regional_sky_source_sha256",sky.get_meta("source_sha256"))
 world.set_meta("regional_sky_art_status","NOT_ACCEPTED; actual game graphics pending")
 return true
