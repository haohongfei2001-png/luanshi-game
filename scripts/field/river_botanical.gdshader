shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
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
		vec3 crown_normal = normalize(crown_point*vec3(.55,.65,.55)+vec3(0.,.65,0.));
		NORMAL = normalize(mix(NORMAL,crown_normal,.88));
		vec3 world = (MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
		float tip = smoothstep(crown_center.y-crown_extent.y,crown_center.y+crown_extent.y,VERTEX.y);
		VERTEX.x += sin(world.x*.63+world.z*.42+TIME*.75)*.018*tip;
	}
}
void fragment() {
	vec2 coordinates = UV*uv_scale.xy+uv_offset.xy;
	vec4 source = vec4(.5,.5,.5,1.);
	if (has_atlas) source = texture(native_atlas,coordinates,botanical_part==0 ? .0 : 1.6);
	if (source.a<.40) discard;
	float value = dot(source.rgb,vec3(.2126,.7152,.0722));
	float detail = smoothstep(.025,.60,value);
	ALBEDO = pigment*mix(.78,1.16,detail);
	if (botanical_part == 0) ALBEDO = mix(source.rgb*pigment*1.6,pigment,.48);
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
