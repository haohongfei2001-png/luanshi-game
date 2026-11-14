shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D native_atlas : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D native_occlusion : hint_default_white, repeat_disable, filter_linear_mipmap;
uniform bool has_occlusion = false;
varying vec3 local_position;
varying vec3 local_normal;
void vertex() {
	local_position=VERTEX;
	local_normal=NORMAL;
}
void fragment() {
	vec3 colour=texture(native_atlas,UV).rgb;
	// Reuse the author's large dressed-stone region on the actual foundation
	// faces, retaining the master mesh and the gate's full military passage.
	float along=abs(local_normal.x)>abs(local_normal.z) ? local_position.z : local_position.x;
	vec2 course=fract(vec2(along/3.4,local_position.y/1.9));
	vec2 stone_uv=vec2(.230,.708)+course*vec2(.218,.281);
	vec3 stone=texture(native_atlas,stone_uv).rgb;
	float foundation=(1.-smoothstep(1.12,1.38,local_position.y))*(1.-smoothstep(.68,.88,abs(local_normal.y)));
	ALBEDO=mix(colour,stone,foundation);
	AO=has_occlusion ? texture(native_occlusion,UV2).r : 1.;
	AO_LIGHT_AFFECT=.25;
	ROUGHNESS=.96;
}
