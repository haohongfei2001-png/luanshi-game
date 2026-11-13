shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D fieldbed : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D joinery : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D soil_cover : filter_linear_mipmap, repeat_disable;
uniform sampler2D floodplain : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D meadow_paint : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D lane_paint : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D verge_track : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 river_silt : source_color = vec4(.39,.40,.31,1.);
uniform vec4 deep_water : source_color = vec4(.13,.31,.34,1.0);
uniform vec4 shallows : source_color = vec4(.33,.48,.42,1.0);
varying vec3 local_pos;
varying vec3 local_normal;
varying float part;
varying vec3 pigment;

void vertex() {
	if(UV2.x>14.5 && UV2.x<15.5) {
		float loose=clamp((6.18-VERTEX.y)/1.7,0.0,1.0);
		VERTEX.x+=loose*.10*sin(TIME*2.2+VERTEX.z*1.9);
	}
	local_pos=VERTEX;
	local_normal=NORMAL;
	part=UV2.x;
	// The builder records the artist’s sRGB swatch in UV and UV2.y as well as COLOR.
	// Keep the compatibility palette and decode it once for a linear colour target.
	if (OUTPUT_IS_SRGB) {
		pigment=pow(max(COLOR.rgb,vec3(0.0)),vec3(1.30));
	} else {
		vec3 swatch=pow(clamp(vec3(UV,UV2.y),vec3(0.0),vec3(1.0)),vec3(1.30));
		vec3 linear_swatch=mix(swatch/12.92,pow((swatch+.055)/1.055,vec3(2.4)),step(vec3(.04045),swatch));
		// Measured against the reference art under the river gate sun and sky.
		// Only vertex-painted surfaces share this calibration. Scanned soil has its own albedo.
		pigment=min(linear_swatch*vec3(2.02,1.92,1.76),vec3(1.0));
	}
}

vec3 painted_ground(vec2 p, float shore) {
    // Soil cover is a measured distance field for the three cart routes. At play
    // scale, keep their pale open centres distinct from the cooler cropped verges.
    vec2 mapped=(p+vec2(168.0,108.0))/vec2(336.0,216.0);
    vec4 cover=texture(soil_cover,mapped);
    vec3 landscape=texture(floodplain,mapped).rgb;
    vec2 uv=vec2(p.x*.134+p.y*.025,p.y*.141-p.x*.022);
    vec3 marks=texture(verge_track,uv*.78).rgb;
    vec2 warp=.10*vec2(sin(p.y*.22+p.x*.06),cos(p.x*.19-p.y*.087));
    vec3 turf=texture(meadow_paint,uv+warp).rgb;
    vec3 clay=texture(lane_paint,vec2(uv.y,-uv.x)*.86+warp*.66).rgb;
    float edge=cover.r+(.47-marks.r)*.22+(.54-marks.b)*.083;
    float lane=smoothstep(.32,.79,edge);
    float wet=max(cover.g,shore);
    vec3 verge=turf*vec3(.84,.99,.95);
    // Mown and uncropped banks differ in broad value, not just their highlights.
    verge*=.83+.17*smoothstep(.22,.62,cover.b)+.16*clamp(landscape.g*1.55,0.0,1.0);
    vec3 colour=mix(verge,clay*vec3(1.09,1.04,.96),lane);
    colour=mix(colour,landscape,.159+.06*(1.0-lane));
    float lip=4.0*lane*(1.0-lane);
    colour*=1.0-lip*(.075+.085*marks.r);
    float rut=1.0-smoothstep(.020,.077,abs(cover.a-.385+(.5-marks.g)*.04));
    colour*=1.0-.19*rut*lane*(.38+.62*marks.g)*(1.0-wet);
    vec3 alluvium=mix(clay,river_silt.rgb,.64)*vec3(.84,.98,.96);
    colour=mix(colour,alluvium, .73*smoothstep(.20,.98,wet));
    return colour;
}

void fragment() {
	vec2 p=local_pos.xz;
	vec3 color=pigment;
	float roughness=0.92;
	float specularity=0.13;
	if (part>0.5 && part<1.5) {
		// This painting fixes the routes, old fields, headlands and canopy beds in
		// world space. Fine surface marks disappear into mipmaps at army scale.
		color=painted_ground(p,0.0);
	} else if (part>1.5 && part<2.5) {
		float bank=abs(p.x+32.0);
		float turn=sin(p.y*.42)*.42+sin(p.y*.15+1.1)*.30;
		vec2 flow=vec2(p.x*.27+turn*.33,p.y*.052-TIME*.017);
		float ripple=texture(fieldbed,flow).r;
		float web=texture(fieldbed,flow*vec2(.57,2.5)+vec2(.19,.28)).g;
		float edge=smoothstep(2.6,5.28,bank+turn*.44);
		float current=texture(fieldbed,vec2(p.x*.058+turn*.09,p.y*.036-TIME*.0033)).g;
		color=mix(deep_water.rgb,shallows.rgb,.84*edge+.09*web)*(.80+.13*ripple+.12*current);
		float thread=1.0-smoothstep(.04,.28,abs(sin((p.x+turn)*2.7+web*1.9-TIME*.49)));
		color+=vec3(.037,.061,.054)*thread*smoothstep(.48,.75,ripple)*(.26+edge);
		roughness=.49; specularity=.29;
	} else if (part>2.5) {
		float side=abs(local_normal.x)>abs(local_normal.z)?local_pos.z:local_pos.x;
		float across=abs(local_normal.y)>0.6?local_pos.z:local_pos.y;
		if (part<3.5 || (part>9.5 && part<11.5)) {
			vec2 grain_uv=vec2(local_pos.x*0.31,(local_pos.z+local_pos.y)*0.94);
			if (part>9.5) grain_uv=part>10.5?vec2(local_pos.y*0.31,(local_pos.x+local_pos.z)*0.94):vec2(local_pos.z*0.31,(local_pos.x+local_pos.y)*0.94);
			float grain=texture(joinery,grain_uv).r;
			color*=0.86+grain*0.26;
			roughness=0.84;
		} else if (part<4.5) {
			float block=texture(joinery,vec2(side,across)*vec2(0.22,0.32)).g;
			color*=0.77+0.39*block;
		} else if (part<5.5) {
			float course=texture(joinery,p*0.48).b;
			// Tile butt overlaps run across both pitches. The existing raised ribs
			// run with the water. World-space derivatives soften a row under one pixel.
			float across_pitch=abs(local_normal.x)>abs(local_normal.z)?p.x:p.y;
			float run=across_pitch*2.52+local_pos.y*.68;
			float seam=abs(fract(run+.5)-.5);
			float mortar=1.0-smoothstep(.035,.088+min(.18,fwidth(run)*.6),seam);
			float wear=smoothstep(.46,.71,texture(fieldbed,p*.28).r);
			color*=(.84+.23*course+.08*wear)*(1.0-.19*mortar);
			roughness=0.75; specularity=0.24;
		} else if (part<6.5) {
			float weave=texture(joinery,vec2(side*0.85,across*1.3)).b;
			color*=0.84+0.28*weave;
		} else if (part<7.5) {
			vec3 foliage=texture(fieldbed,vec2(local_pos.x*0.64+local_pos.z*0.35,local_pos.y*0.48)).rgb;
			color*=0.79+foliage.g*0.40;
		} else if (part<8.5) {
			vec2 bank_uv=vec2(side*0.31,across*0.87);
			float compact=texture(joinery,bank_uv).r;
			float lift=texture(fieldbed,vec2(side*0.068,across*0.73)).r;
			float drip=texture(fieldbed,vec2(side*.12,across*.035)).g;
			float footing=1.0-smoothstep(.55,1.56,local_pos.y+drip*.23);
			float rain=smoothstep(.43,.71,drip)*smoothstep(.18,2.4,local_pos.y);
			float strata=across*2.13+.12*(compact-.5);
			float joint=1.0-smoothstep(.025,.085+min(.14,fwidth(strata)*.55),abs(fract(strata+.5)-.5));
			color*=.74+.29*compact+.16*lift-.105*footing-.065*rain;
			color*=1.0-joint*(.050+.07*rain);
		} else if (part>11.5 && part<12.5) {
			vec3 r=texture(fieldbed,vec2(side*.35,across*.51)).rgb;
			color*=.76+.36*r.r+.09*r.b;
		} else if (part>12.5 && part<13.5) {
			float bank=abs(p.x+32.0);
			float lip=bank+.28*sin(p.y*.39)+.14*sin(p.y*.87+.44);
			color=painted_ground(p,1.0-smoothstep(4.38,6.58,lip));
		} else if(part>15.5 && part<16.5) {
			float grain=texture(joinery,vec2(local_pos.z*.31,(local_pos.x+local_pos.y)*.94)).r;
			float z=abs(p.y);
			float cross_distance=min(z,abs(z-35.0));
			float board=fract((p.x+32.0)/.482+.5);
			float weather=texture(fieldbed,p*vec2(.28,.61)).r;
			float worn=1.0-smoothstep(.12,.46,abs(cross_distance-1.20+.13*(weather-.5)));
			float peg=(1.0-smoothstep(.10,.21,abs(board-.44)))*(1.0-smoothstep(.08,.14,abs(cross_distance-3.41)));
			color*=.68+.50*grain+.12*worn*(.27+weather)-.19*peg;
			roughness=.91-.14*worn;
		} else if(part>=17.5 && part<18.5) {
			vec2 face_uv=vec2(local_pos.z*.39,local_pos.y*2.93);
			float grit=texture(fieldbed,face_uv).r;
			float roots=texture(joinery,vec2(local_pos.z*.48,local_pos.y*2.10)).r;
			color=mix(vec3(.055,.068,.045),vec3(.130,.113,.072),.32+.37*grit+.23*roots);
		}
	}
	ALBEDO=color;
	ROUGHNESS=roughness;
	SPECULAR=specularity;
}
