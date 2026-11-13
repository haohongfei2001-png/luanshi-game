shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D ink : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D willow_pendant : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D grove_leaf : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D grove_bark : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D elm_bough : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D willow_ink : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D leaf_marks : filter_linear_mipmap, repeat_enable;
uniform sampler2D canopy_paint : filter_linear_mipmap, repeat_enable;
uniform vec4 deep_leaf : source_color = vec4(.15,.238,.216,1.0);
uniform vec4 elm : source_color = vec4(.31,.401,.284,1.0);
uniform vec4 sun_elm : source_color = vec4(.495,.565,.355,1.0);
uniform vec4 sun_ash : source_color = vec4(.54,.52,.32,1.0);
uniform vec4 elm_under : source_color = vec4(.113,.178,.154,1.);
uniform vec4 elm_body : source_color = vec4(.218,.334,.231,1.);
uniform vec4 elm_light : source_color = vec4(.353,.426,.281,1.);
varying float facing_sky;
varying vec3 paint;
varying float crown;
varying vec2 bark_uv;

void vertex() {
	float breeze=sin(TIME*1.22+VERTEX.x*.83+VERTEX.z*.44)*.025;
	if(UV2.y>2.1) breeze+=.049*sin(TIME*.89+VERTEX.x*.58- VERTEX.z*.44);
	VERTEX.x+=breeze*UV2.x;
	VERTEX.z+=breeze*.53*UV2.x;
	crown=UV2.y;
	facing_sky=NORMAL.y;
	bark_uv=UV;
	paint=crown>.5?vec3(UV2.x,(UV2.y-1.0)*2.0,0.0):COLOR.rgb;
}
void fragment() {
	float opacity=1.0;
	vec3 tone;
	if(crown>=13.5) {
		vec3 bark=texture(grove_bark,UV).rgb;
		float lum=dot(bark,vec3(.27,.57,.16));
		float band=smoothstep(.14,.55,OUTPUT_IS_SRGB?lum:sqrt(max(lum,0.)));
		tone=mix(vec3(.100,.085,.054),vec3(.29,.233,.157),band);
	} else if(crown>=11.9) {
		vec4 leaf=texture(grove_leaf,UV);
		float height=clamp((crown-12.1)/.85,0.,1.);
		float color_value=dot(leaf.rgb,vec3(.25,.58,.17));
		float value=OUTPUT_IS_SRGB?color_value:sqrt(max(color_value,0.));
		float light=.23*value+.49*height+.22*clamp(facing_sky,0.,1.);
		vec3 shade=mix(elm_body.rgb,elm_light.rgb,.18);
		vec3 sun=OUTPUT_IS_SRGB?vec3(.50,.57,.35):vec3(.214,.285,.100);
		tone=mix(shade,elm_light.rgb,smoothstep(.28,.56,light));
		tone=mix(tone,sun,smoothstep(.50,.85,light)*.77);
		opacity=leaf.a;
	} else if(crown>6.0) {
		vec4 brush=texture(elm_bough,UV);
		float sun=clamp((crown-6.1)*1.42,0.0,1.0);
		vec3 mids=mix(vec3(dot(brush.rgb,vec3(.30,.55,.15))),brush.rgb,.66);
		tone=mids*mix(vec3(.54,.62,.72),vec3(.90,.94,.83),sun);
		opacity=brush.a;
	} else if(crown>4.0) {
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
		// Three willow branch UV islands precede the reeds in the last quarter.
		if(UV.x<.749) {
			vec4 twig=texture(willow_pendant,vec2(.26+fract(UV.x*4.0)*.49,UV.y));
			float value=dot(twig.rgb,vec3(.30,.57,.13));
			float chroma=max(twig.g,twig.r)-twig.b;
			float key=1.0-smoothstep(.035,.145,value-max(.0,chroma)*3.6-.58);
			tone=mix(vec3(.068,.104,.075),vec3(.315,.35,.188),.21+.68*light)*(.72+.43*value);
			opacity=twig.a*key*smoothstep(.016,.07,chroma);
			if(UV.x>.5) {
				// Young upper boughs carry short green growth underneath the long
				// free whips. Only this island fills the open top of the crown.
				vec2 u=vec2(.04+.92*fract(UV.x*4.0),.98-.96*UV.y);
				vec4 crown_leaf=texture(elm_bough,u);
				float moss=dot(crown_leaf.rgb,vec3(.29,.59,.12));
				vec3 upper=mix(vec3(.076,.120,.085),vec3(.332,.383,.208),clamp(.18+light*.60+moss*.32,0.0,1.0));
				float upper_leaf=crown_leaf.a*smoothstep(.09,.52,1.0-UV.y);
				vec3 painted=mix(crown_leaf.rgb*vec3(.71,.80,.70),upper,.30)*(.71+.28*light);
				tone=mix(tone,painted,upper_leaf);
				opacity=max(opacity,upper_leaf*.85);
			}
		}
	} else if(crown>.5) {
		vec3 leaf=texture(canopy_paint,UV*1.73).rgb;
		vec3 sun=mix(sun_elm.rgb,sun_ash.rgb,smoothstep(.65,.95,paint.g));
		vec3 mid=elm.rgb*mix(vec3(.88,1.,.95),vec3(1.05,1.,.84),paint.g);
		float grade=clamp(paint.r+.065*leaf.r-.10*leaf.b,0.,1.);
		float shade_band=smoothstep(.275,.40,grade);
		float crown_band=smoothstep(.62,.75,grade);
		tone=mix(deep_leaf.rgb,mid,shade_band);
		tone=mix(tone,sun,crown_band*.84);
		// One painterly shape crosses a few leaves. Mip filtering removes the
		// small stems at formation distance without dissolving the crown outline.
		tone*=1.-.21*leaf.b;
		tone=mix(tone,sun,leaf.r*(.21+.25*crown_band));
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
