shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D ink : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D willow_ink : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D leaf_marks : filter_linear_mipmap, repeat_enable;
uniform vec4 deep_leaf : source_color = vec4(.15,.238,.216,1.0);
uniform vec4 elm : source_color = vec4(.31,.401,.284,1.0);
uniform vec4 sun_elm : source_color = vec4(.495,.565,.355,1.0);
uniform vec4 sun_ash : source_color = vec4(.54,.52,.32,1.0);
varying vec3 paint;
varying float crown;
varying vec2 bark_uv;

void vertex() {
	float breeze=sin(TIME*1.22+VERTEX.x*.83+VERTEX.z*.44)*.025;
	if(UV2.y>2.1) breeze+=.049*sin(TIME*.89+VERTEX.x*.58- VERTEX.z*.44);
	VERTEX.x+=breeze*UV2.x;
	VERTEX.z+=breeze*.53*UV2.x;
	crown=UV2.y;
	bark_uv=UV;
	paint=crown>.5?vec3(UV2.x,(UV2.y-1.0)*2.0,0.0):COLOR.rgb;
}
void fragment() {
	float opacity=1.0;
	vec3 tone;
	if(crown>4.0) {
		float ridge=clamp((crown-4.33)/.22,0.0,1.5);
		float vein=texture(leaf_marks,vec2(bark_uv.x*3.7,bark_uv.y*.108)).g;
		float groove=.5+.5*sin(bark_uv.x*71.3+bark_uv.y*.92+vein*1.51);
		float grain=smoothstep(.16,.82,.42*ridge+.33*groove+.25*vein);
		tone=mix(vec3(.046,.050,.037),vec3(.139,.124,.083),grain);
	} else if(crown>2.1) {
		vec4 brush=texture(willow_ink,UV);
		float light=clamp((crown-2.5)*2.50,0.0,1.0);
		float crest=smoothstep(.39,.82,light);
		tone=pow(brush.rgb,vec3(1.07))*vec3(.66,.76,.80)*(.63+.66*light);
		tone+=vec3(.010,.016,.011)*crest;
		opacity=brush.a;
	} else if(crown>.5) {
		float marks=texture(leaf_marks,UV*0.85).g;
		vec3 light=mix(sun_elm.rgb,sun_ash.rgb,smoothstep(.65,.95,paint.g));
		vec3 mid=elm.rgb*mix(vec3(.88,1.0,.95),vec3(1.05,1.0,.84),paint.g);
		float value=clamp(paint.r+(marks-.46)*.10,0.0,1.0);
		tone=mix(deep_leaf.rgb,mid,smoothstep(.14,.42,value));
		tone=mix(tone,light,smoothstep(.58,.81,value)*.87);
		vec2 brush_uv=fract(UV*3.0)*.466+vec2(.017,.017);
		vec4 brush=texture(ink,brush_uv);
		tone=mix(tone,brush.rgb*(.71+.43*value),brush.a*(.07+.12*value));
	} else {
		vec4 glyph=texture(ink,UV);
		float interior=mix(.55,.90,paint.r);
		tone=glyph.rgb*interior;
		opacity=glyph.a;
	}
	ALBEDO=tone;
	ROUGHNESS=.97;
	ALPHA=opacity;
	ALPHA_SCISSOR_THRESHOLD=.44;
}
