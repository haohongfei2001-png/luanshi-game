shader_type spatial;
render_mode diffuse_lambert;
uniform vec3 deep_color : source_color = vec3(.11,.25,.26);
uniform vec3 bank_color : source_color = vec3(.25,.33,.27);
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 a=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.-2.*f);
	return mix(mix(hash(a),hash(a+vec2(1.,0.)),f.x),mix(hash(a+vec2(0.,1.)),hash(a+vec2(1.)),f.x),f.y);
}
float ripple(vec2 p) {
	float bend = sin(p.y*.31+p.x*.9)*.24+sin(p.y*.73-p.x*.52)*.12;
	return sin(p.x*4.7+bend*8.+p.y*.9-TIME*1.4)*.014
		+sin(p.x*8.3-bend*5.-p.y*1.6+TIME*.95)*.006;
}
void fragment() {
	vec2 p=world.xz;
	float nearest=abs(p.x+32.)<12. ? abs(p.x+32.) : abs(p.x-24.);
	float near_bank=smoothstep(2.4,5.8,nearest);
	float dx=(ripple(p+vec2(.035,0.))-ripple(p-vec2(.035,0.)))/.07;
	float dz=(ripple(p+vec2(0.,.035))-ripple(p-vec2(0.,.035)))/.07;
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vec3(-dx,1.,-dz)),0.)).xyz);
	float current=noise(vec2(p.x*.55+sin(p.y*.32)*.21,p.y*.24-TIME*.055));
	float crest=smoothstep(.032,.047,ripple(p)*1.7+current*.017);
	ALBEDO=mix(deep_color,bank_color,near_bank*.72)*mix(.87,1.11,current);
	ALBEDO+=vec3(.035,.055,.044)*crest;
	ROUGHNESS=.42;
	SPECULAR=.26;
}
