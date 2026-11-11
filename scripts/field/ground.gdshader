shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform vec4 meadow : source_color = vec4(0.36, 0.43, 0.32, 1.0);
uniform vec4 verge : source_color = vec4(0.48, 0.49, 0.34, 1.0);
uniform vec4 road : source_color = vec4(0.54, 0.46, 0.34, 1.0);
uniform vec4 stream : source_color = vec4(0.24, 0.38, 0.38, 1.0);
varying vec3 world_pos;
varying float part;
varying vec3 vertex_paint;

float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p) {
	vec2 i=floor(p),f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; part=UV2.x; vertex_paint=COLOR.rgb;}
void fragment() {
	vec2 p=world_pos.xz;
	vec3 tone=vertex_paint;
	if (part>0.5 && part<1.5) {
		float patch=noise2(p*0.17);
		float grit=noise2(p*2.7);
		vec3 grass=mix(meadow.rgb,verge.rgb,patch)*(0.89+0.15*grit);
		float edge=abs(p.y-0.65*sin(p.x*0.058));
		float track=1.0-smoothstep(2.6,4.5,edge+0.95*(patch-0.5));
		float spur=abs(abs(p.y)-35.0);
		track=max(track,(1.0-smoothstep(1.35,2.65,spur+patch-0.5))*(1.0-smoothstep(2.0,22.0,p.x)));
		if (p.x>48.0 && p.x<89.0 && abs(p.y)<22.0) track=max(track,0.74);
		tone=mix(grass,road.rgb*(0.85+0.15*grit),track);
		if (p.x < -49.0 && p.y>17.0 && p.y<43.0) tone*=0.86+0.12*smoothstep(-0.6,0.6,sin(p.x*7.0+p.y*0.32));
	} else if (part>1.5 && part<2.5) {
		tone=stream.rgb*(0.90+0.14*noise2(p*vec2(2.4,0.65)));
	}
	ALBEDO=tone; ROUGHNESS=0.97;
}
