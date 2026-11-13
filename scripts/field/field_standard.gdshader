shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform vec4 cloth : source_color = vec4(.20,.31,.43,1.);
uniform vec4 reverse : source_color = vec4(.15,.22,.28,1.);
uniform vec4 binding : source_color = vec4(.72,.63,.46,1.);
uniform vec4 pole : source_color = vec4(.38,.27,.17,1.);
uniform vec4 ferrule : source_color = vec4(.34,.36,.34,1.);
uniform bool garrison = false;
varying float part;

void vertex() {
	part=UV2.x;
	if (part<.5) {
		float t=clamp(UV.x,0.,1.);
		float phi=INSTANCE_CUSTOM.r*6.2831853;
		float wave=sin(phi-3.65*t+.52*UV.y);
		float curl=sin(2.*phi-5.8*t-.61*UV.y);
		VERTEX.z+=t*(.128*wave+.040*curl);
		VERTEX.y+=t*t*(.043*wave+.018*curl);
		NORMAL=normalize(NORMAL+vec3(-.25*t*cos(phi-3.65*t),0.,0.));
	}
}

void fragment() {
	vec3 paint;
	if (part<.5) {
		vec2 uv=UV;
		float lip=max(fwidth(uv.y),.006);
		float hem=1.-smoothstep(.043-lip,.043+lip,min(uv.y,1.-uv.y));
		float sleeve=1.-smoothstep(.058,.078,uv.x);
		// An unlettered split lozenge or an offset two-bar device is woven
		// into both faces of the cloth. All marks follow the same fold.
		vec2 sign_uv=uv-vec2(.405,.49);
		float motif;
		if (garrison) {
			float diamond=abs(sign_uv.x)*1.68+abs(sign_uv.y);
			motif=1.-smoothstep(.030,.030+lip,abs(diamond-.20));
		} else {
			float chevron=abs(sign_uv.y+sign_uv.x*.60);
			motif=(1.-smoothstep(.034,.034+lip,abs(chevron-.108)))*
				(1.-smoothstep(.113,.119+lip,abs(sign_uv.x)));
		}
		float fold=clamp(.24+.48*uv.y+.19*sin(uv.x*8.1+.61*uv.y),0.,1.);
		paint=mix(reverse.rgb,cloth.rgb,.30+.66*smoothstep(.28,.68,fold));
		paint=mix(paint,binding.rgb,max(.69*hem,max(.77*sleeve,.92*motif)));
	} else {
		paint=part<1.5?pole.rgb:(part<2.5?binding.rgb:ferrule.rgb);
	}
	ALBEDO=paint;
	ROUGHNESS=.97;
}
