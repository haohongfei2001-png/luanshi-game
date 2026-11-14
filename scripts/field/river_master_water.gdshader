shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec3 deep_color : source_color = vec3(.10,.22,.23);
uniform vec3 bank_color : source_color = vec3(.22,.30,.25);
varying vec3 world;
void vertex() {
	world = (MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
}
float hash(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float noise(vec2 p) {
	vec2 a = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.-2.*f);
	return mix(mix(hash(a),hash(a+vec2(1.,0.)),f.x),
		mix(hash(a+vec2(0.,1.)),hash(a+vec2(1.)),f.x),f.y);
}
void fragment() {
	vec2 p = world.xz;
	float nearest = abs(p.x+32.)<12. ? abs(p.x+32.) : abs(p.x-24.);
	float near_bank = smoothstep(2.4,5.8,nearest);
	float bend = sin(p.y*.19)*.24+sin(p.y*.43+p.x*.26)*.12;
	vec2 flow = vec2(p.x+bend,p.y-TIME*.38);
	float broad = noise(flow*vec2(.48,.17));
	float ripples = noise(flow*vec2(2.4,.57)+broad*1.3)*.62
		+noise(flow*vec2(5.1,1.07)-broad)*.38;
	float wrinkle = smoothstep(.51,.56,ripples)-smoothstep(.59,.64,ripples);
	float small_current = noise(flow*vec2(8.3,1.7)+3.7);
	float crest = wrinkle*smoothstep(.49,.76,small_current);
	vec3 color = mix(deep_color,bank_color,near_bank*.64);
	ALBEDO = color*mix(.80,1.17,broad)+vec3(.020,.037,.033)*crest;
	ROUGHNESS = .88;
	SPECULAR = .0;
}
