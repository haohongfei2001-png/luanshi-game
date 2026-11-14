shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D ashlar : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 place;
varying vec3 plane;

void vertex() {
	place=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	plane=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}

void fragment() {
	// Courses follow the turn of the jamb. The top uses the same stones
	// through the cap; the wall does not acquire a stripe when the camera orbits.
	vec2 face=abs(plane.x)>abs(plane.z) ? vec2(place.z,-place.y) : vec2(place.x,-place.y);
	bool top=abs(plane.y)>.65;
	if (top) face=place.xz;
	vec3 stone=texture(ashlar,face/3.2).rgb;
	vec3 soil=texture(earth,(face+vec2(.47,0.0))/3.9).rgb;
	float lip=1.56+.08*sin(place.z*1.9+place.x*.3);
	float wall=smoothstep(lip-.026,lip+.026,place.y);
	if (top || place.y>3.7 || (abs(place.z)<4.12 && abs(plane.z)>.60)) wall=0.0;
	ALBEDO=mix(stone,soil,wall);
	ROUGHNESS=1.0;
}
