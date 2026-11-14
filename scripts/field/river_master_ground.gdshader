shader_type spatial;
render_mode diffuse_lambert;
uniform sampler2D soil : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D leaves : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform bool bridgehead=false;
uniform vec3 road_pigment : source_color = vec3(.61,.50,.36);
uniform vec3 grass_pigment : source_color = vec3(.38,.41,.25);
uniform vec3 litter_pigment : source_color = vec3(.43,.38,.25);
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 a=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.-2.*f);
	return mix(mix(hash(a),hash(a+vec2(1.,0.)),f.x),mix(hash(a+vec2(0.,1.)),hash(a+vec2(1.)),f.x),f.y);
}
vec3 ground_sample(sampler2D tex,vec2 p,float metres) {
	vec3 a=texture(tex,p/metres).rgb;
	vec3 b=texture(tex,mat2(vec2(.80,-.60),vec2(.60,.80))*p/(metres*1.71)+vec2(.37,.21)).rgb;
	return mix(a,b,.32);
}
void fragment() {
	vec2 p=world.xz;
	float drift=.30*sin(p.x*.13)+.23*sin(p.x*.31+.4);
	float broken_edge=(noise(p*.63)-.5)*1.4+(noise(p*.14)-.5)*2.;
	float lane=1.-smoothstep(3.,6.7,abs(p.y-drift)+broken_edge);
	float branches=1.-smoothstep(1.8,4.6,abs(p.y-35.)+broken_edge);
	branches=max(branches,1.-smoothstep(1.8,4.6,abs(p.y+35.)+broken_edge));
	lane=max(lane,(1.-smoothstep(-36.,-17.,p.x))*branches);
	float court=smoothstep(47.,52.,p.x)*(1.-smoothstep(85.,90.,p.x))*(1.-smoothstep(15.,21.,abs(p.y)));
	lane=max(lane,court);
	float bank=1.-smoothstep(4.9,8.4,abs(p.x+32.)+broken_edge*.65);
	if(bridgehead) bank=max(bank,(1.-smoothstep(4.2,8.,abs(p.x-24.)+broken_edge*.65))*(1.-smoothstep(23.,29.,abs(p.y))));
	float patches=noise(p*.12)*.62+noise(p*.37)*.38;
	vec3 dust=ground_sample(soil,p,4.6);
	vec3 turf=ground_sample(grass,p,3.1);
	vec3 litter=ground_sample(leaves,p,3.8);
	// Native scan relief remains subordinate to broad terrain materials.
	vec3 luminance=vec3(.2126,.7152,.0722);
	dust=road_pigment*mix(.83,1.14,smoothstep(.025,.55,dot(dust,luminance)));
	turf=grass_pigment*mix(.79,1.13,smoothstep(.025,.55,dot(turf,luminance)));
	litter=litter_pigment*mix(.80,1.12,smoothstep(.025,.55,dot(litter,luminance)));
	float undergrowth=smoothstep(.45,.71,patches);
	vec3 verge=mix(turf,litter,.17+.36*undergrowth);
	float bare=clamp(lane+bank*.60+(patches-.55)*.5,0.,1.);
	vec3 col=mix(verge,dust,bare);
	float rut=0.;
	for(int i=0;i<2;i++){
		float lateral=i==0?-1.18:1.18;
		float d=(p.y-drift-lateral)/.18;
		rut+=exp(-d*d);
	}
	col*=1.-.11*rut*lane;
	ALBEDO=col;
	ROUGHNESS=.97;
	SPECULAR=.07;
}
