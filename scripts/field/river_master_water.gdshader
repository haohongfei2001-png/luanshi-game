shader_type spatial;
render_mode diffuse_lambert;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 a=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.-2.*f);
	return mix(mix(hash(a),hash(a+vec2(1.,0.)),f.x),mix(hash(a+vec2(0.,1.)),hash(a+vec2(1.)),f.x),f.y);
}
void fragment(){
	vec2 p=world.xz;
	float bend=(noise(vec2(p.x*.7,p.y*.24-TIME*.08))-.5)*1.6;
	float flowing=noise(vec2((p.x+bend)*3.1,p.y*.64-TIME*.17));
	float fine=noise(vec2(p.x*8.1-bend,p.y*1.4-TIME*.29));
	float streak=smoothstep(.73,.91,flowing*.7+fine*.3);
	float deep=abs(p.x+32.)<12.?abs(p.x+32.):abs(p.x-24.);
	float shallows=smoothstep(3.25,5.4,deep);
	vec3 bed=mix(vec3(.016,.052,.059),vec3(.047,.094,.082),shallows*.68);
	ALBEDO=bed+vec3(.085,.12,.115)*streak;
	ROUGHNESS=.38;
	SPECULAR=.28;
	NORMAL=normalize(NORMAL+vec3((fine-.5)*.05,0.,(flowing-.5)*.05));
}
