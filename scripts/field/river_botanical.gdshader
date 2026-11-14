shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled, alpha_to_coverage;
uniform sampler2D native_atlas : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform bool has_atlas = true;
uniform int botanical_part = 0;
uniform vec3 pigment : source_color = vec3(.30,.36,.16);
uniform vec3 uv_scale = vec3(1.);
uniform vec3 uv_offset = vec3(0.);
uniform vec3 crown_center = vec3(0.,2.8,0.);
uniform vec3 crown_extent = vec3(2.,2.5,2.);
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
	if (botanical_part > 0) {
		vec3 crown_point = (VERTEX-crown_center)/max(crown_extent,vec3(.1));
		vec3 crown_normal = normalize(crown_point*vec3(.70,.75,.70)+vec3(0.,.22,0.));
		NORMAL = normalize(mix(NORMAL,crown_normal,.70));
		vec3 world = (MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
		float tip = smoothstep(crown_center.y-crown_extent.y,crown_center.y+crown_extent.y,VERTEX.y);
		VERTEX.x += sin(world.x*.63+world.z*.42+TIME*.75)*.018*tip;
	}
}
vec3 linear_color(vec3 color) {
	if (!OUTPUT_IS_SRGB) return color;
	return mix(color/12.92,pow((color+vec3(.055))/1.055,vec3(2.4)),step(vec3(.04045),color));
}
vec3 render_color(vec3 color) {
	if (!OUTPUT_IS_SRGB) return color;
	color = max(color,vec3(0.));
	return mix(color*12.92,1.055*pow(color,vec3(1./2.4))-vec3(.055),step(vec3(.0031308),color));
}
void fragment() {
	vec2 coordinates = UV*uv_scale.xy+uv_offset.xy;
	vec4 source = vec4(.5,.5,.5,1.);
	if (has_atlas) source = texture(native_atlas,coordinates);
	ALPHA = source.a;
	ALPHA_SCISSOR_THRESHOLD = .40;
	ALPHA_ANTIALIASING_EDGE = .30;
	ALPHA_TEXTURE_COORDINATE = coordinates*vec2(textureSize(native_atlas,0));
	vec3 native_color = linear_color(source.rgb);
	vec3 paint = linear_color(pigment);
	vec3 color = mix(native_color,paint,.30);
	if (botanical_part == 0) color = mix(native_color*paint*1.6,paint,.48);
	ALBEDO = render_color(color);
	float crown_depth = smoothstep(crown_center.y-crown_extent.y,crown_center.y+crown_extent.y,local_position.y);
	AO = botanical_part>0 ? mix(.48,1.,crown_depth) : .94;
	AO_LIGHT_AFFECT = .35;
	ROUGHNESS = .95;
	SPECULAR = .0;
}
void light() {
	float facing = dot(NORMAL,LIGHT);
	float band = .22+.39*smoothstep(.16,.28,facing)+.39*smoothstep(.62,.74,facing);
	DIFFUSE_LIGHT += band*LIGHT_COLOR*ATTENUATION/3.14159265;
}
