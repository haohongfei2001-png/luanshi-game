shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D ink : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D leaf_marks : filter_linear_mipmap, repeat_enable;
uniform vec4 deep_leaf : source_color = vec4(.18,.265,.22,1.0);
uniform vec4 elm : source_color = vec4(.353,.44,.296,1.0);
uniform vec4 sun_elm : source_color = vec4(.535,.60,.374,1.0);
uniform vec4 sun_ash : source_color = vec4(.59,.56,.346,1.0);
varying vec3 paint;
varying float crown;

void vertex() {
	float breeze=sin(TIME*1.22+VERTEX.x*.83+VERTEX.z*.44)*.025;
	VERTEX.x+=breeze*UV2.x;
	VERTEX.z+=breeze*.53*UV2.x;
	paint=COLOR.rgb;
	crown=UV2.y;
}
void fragment() {
	float opacity=1.0;
	vec3 tone;
	if(crown>.5) {
		float marks=texture(leaf_marks,UV*0.85).g;
		vec3 light=mix(sun_elm.rgb,sun_ash.rgb,smoothstep(.65,.95,paint.g));
		vec3 mid=elm.rgb*mix(vec3(.88,1.0,.95),vec3(1.05,1.0,.84),paint.g);
		float value=clamp(paint.r+(marks-.46)*.23,0.0,1.0);
		tone=mix(deep_leaf.rgb,mid,smoothstep(.03,.57,value));
		tone=mix(tone,light,smoothstep(.52,.98,value)*.89);
	} else {
		vec4 glyph=texture(ink,UV);
		float interior=mix(.50,.84,paint.r);
		tone=glyph.rgb*interior;
		opacity=glyph.a;
	}
	ALBEDO=tone;
	ROUGHNESS=.97;
	ALPHA=opacity;
	ALPHA_SCISSOR_THRESHOLD=.44;
}
