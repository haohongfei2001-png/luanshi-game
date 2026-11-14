shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D native_atlas : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec3 uv_scale = vec3(1.);
uniform vec3 uv_offset = vec3(0.);
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
}
vec3 linear_color(vec3 c) {
	if (!OUTPUT_IS_SRGB) return c;
	return mix(c/12.92,pow((c+vec3(.055))/1.055,vec3(2.4)),step(vec3(.04045),c));
}
vec3 render_color(vec3 c) {
	if (!OUTPUT_IS_SRGB) return c;
	return mix(c*12.92,1.055*pow(max(c,vec3(0.)),vec3(1./2.4))-vec3(.055),step(vec3(.0031308),c));
}
void fragment() {
	vec3 scan = linear_color(texture(native_atlas,UV*uv_scale.xy+uv_offset.xy).rgb);
	float value = dot(scan,vec3(.2126,.7152,.0722));
	vec3 stone = vec3(.29,.285,.245)*pow(clamp(value/.14,.34,1.8),.44);
	float moss = smoothstep(.014,.065,scan.g-scan.r*.91);
	stone = mix(stone,vec3(.12,.15,.085)*pow(clamp(value/.14,.34,1.8),.44),moss*.48);
	float waterline = smoothstep(-1.47,-.78,world.y);
	ALBEDO = render_color(stone*mix(.59,1.,waterline));
	ROUGHNESS = .96;
	SPECULAR = .0;
}
