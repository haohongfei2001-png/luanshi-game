shader_type spatial;
render_mode diffuse_lambert;
uniform vec4 deep : source_color=vec4(.10,.29,.31,1.);
uniform vec4 pale : source_color=vec4(.28,.46,.43,1.);
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
	vec2 p=world.xz;
	float current=sin(p.y*8.+p.x*2.+TIME*1.8+sin(p.y*.65-p.x*3.))*sin(p.y*2.7-TIME*.85+p.x*.6);
	float river=abs(p.x+32.);
	float moat=abs(p.x-24.);
	float edge=smoothstep(3.2,4.7,min(river,moat));
	float gleam=smoothstep(.55,.95,current)*.23;
	ALBEDO=mix(deep.rgb,pale.rgb,edge*.60+gleam);
	ROUGHNESS=.48;
	SPECULAR=.28;
}
