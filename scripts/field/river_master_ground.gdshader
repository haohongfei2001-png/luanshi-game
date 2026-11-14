shader_type spatial;
render_mode diffuse_lambert;
uniform sampler2D soil : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D grass : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D leaves : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform bool bridgehead=false;
varying vec3 world;
void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
}
float patch(vec2 p) {
	return .5+.22*sin(p.x*.39+p.y*.29)+.18*sin(p.x*.18-p.y*.43)+.10*sin(p.x*.82+p.y*.61);
}
vec3 ground_sample(sampler2D tex,vec2 p,float metres) {
	vec3 a=texture(tex,p/metres).rgb;
	vec3 b=texture(tex,mat2(.80,-.60,.60,.80)*p/(metres*1.71)+vec2(.37,.21)).rgb;
	return mix(a,b,.42);
}
void fragment() {
	vec2 p=world.xz;
	float drift=.23*sin(p.x*.27)+.17*sin(p.x*.54+.4)+.085*sin(p.x*1.18);
	float lane=1.-smoothstep(3.2,7.4,abs(p.y-drift));
	float branching=1.-smoothstep(2.,4.9,abs(p.y-35.));
	branching=max(branching,1.-smoothstep(2.,4.9,abs(p.y+35.)));
	float crossroad=(1.-smoothstep(-36.,-17.,p.x))*branching;
	lane=max(lane,crossroad*.9);
	float court=smoothstep(47.,52.,p.x)*(1.-smoothstep(85.,90.,p.x))*(1.-smoothstep(15.,21.,abs(p.y)));
	lane=max(lane,court);
	float bank=1.-smoothstep(5.,8.,abs(p.x+32.));
	if(bridgehead) bank=max(bank,(1.-smoothstep(4.2,7.6,abs(p.x-24.)))*(1.-smoothstep(23.,29.,abs(p.y))));
	float variance=patch(p);
	vec3 dust=ground_sample(soil,p,3.8);
	vec3 turf=ground_sample(grass,p,2.6);
	vec3 litter=ground_sample(leaves,p,3.4);
	// Authored diffuse colour carries the surface. Large quiet areas support
	// small figures; native-resolution scan detail remains in the actual ground.
	dust=mix(dust,vec3(.43,.32,.20),.18);
	turf=mix(turf,vec3(.13,.20,.075),.25);
	vec3 verge=mix(turf,litter,.24+.23*variance);
	float bare=clamp(lane+bank*.55+(variance-.5)*.31,0.,1.);
	vec3 col=mix(verge,dust,bare);
	float rut=0.;
	for(int i=0;i<2;i++){
		float lateral=i==0?-1.18:1.18;
		float d=(p.y-drift-lateral)/.14;
		rut+=exp(-d*d);
	}
	col*=1.-.12*rut*lane;
	ALBEDO=col;
	ROUGHNESS=.97;
	SPECULAR=.08;
}
