shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D fieldbed : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D joinery : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D trail_marks : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D land_paint : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 deep_water : source_color = vec4(0.22,0.37,0.36,1.0);
uniform vec4 shallows : source_color = vec4(0.42,0.56,0.49,1.0);
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
	// Keep the weathered material palette in linear light without darkening it again per pixel.
	pigment=pow(max(COLOR.rgb,vec3(0.0)),vec3(1.30));
}

vec3 painted_ground(vec2 p) {
	vec3 underpaint=texture(land_paint,(p+vec2(168.0,108.0))/vec2(336.0,216.0)).rgb;
	float dry=smoothstep(-0.015,0.023,underpaint.r-underpaint.g);
	vec3 grass=texture(fieldbed,p*vec2(.155,.199)).rgb;
	vec3 close_marks=texture(fieldbed,p*vec2(.48,.58)+vec2(.12,.32)).rgb;
	vec3 grain=texture(fieldbed,p*vec2(0.213,0.261)+vec2(.57,.26)).rgb;
	float turf_value=.86+.22*grass.g+.12*grass.r+.12*(close_marks.g-.44);
	float path_value=.85+.17*grain.r+.105*close_marks.r+.070*smoothstep(.55,.80,close_marks.b);
	vec3 floor_color=underpaint*mix(turf_value,path_value,dry);
	vec4 track=texture(trail_marks,p*vec2(.42,.45));
	return mix(floor_color,track.rgb,track.a*(.14+.69*dry));
}

void fragment() {
	vec2 p=local_pos.xz;
	vec3 color=pigment;
	float roughness=0.92;
	float specularity=0.13;
	if (part>0.5 && part<1.5) {
		// This painting fixes the routes, old fields, headlands and canopy beds in
		// world space. Fine surface marks disappear into mipmaps at army scale.
		color=painted_ground(p);
	} else if (part>1.5 && part<2.5) {
		float bank=abs(p.x+32.0);
		float turn=sin(p.y*.42)*.42+sin(p.y*.15+1.1)*.30;
		vec2 flow=vec2(p.x*.27+turn*.33,p.y*.052-TIME*.017);
		float ripple=texture(fieldbed,flow).r;
		float web=texture(fieldbed,flow*vec2(.57,2.5)+vec2(.19,.28)).g;
		float edge=smoothstep(2.6,5.28,bank+turn*.44);
		color=mix(deep_water.rgb,shallows.rgb,.83*edge+.11*web)*(.87+.18*ripple);
		float thread=1.0-smoothstep(.04,.28,abs(sin((p.x+turn)*2.7+web*1.9-TIME*.49)));
		color+=vec3(.061,.092,.081)*thread*smoothstep(.45,.74,ripple)*(.36+edge);
		roughness=.49; specularity=.29;
	} else if (part>2.5) {
		float side=abs(local_normal.x)>abs(local_normal.z)?local_pos.z:local_pos.x;
		float across=abs(local_normal.y)>0.6?local_pos.z:local_pos.y;
		if (part<3.5 || (part>9.5 && part<11.5)) {
			vec2 grain_uv=vec2(local_pos.x*0.31,(local_pos.z+local_pos.y)*0.94);
			if (part>9.5) grain_uv=part>10.5?vec2(local_pos.y*0.31,(local_pos.x+local_pos.z)*0.94):vec2(local_pos.z*0.31,(local_pos.x+local_pos.y)*0.94);
			float grain=texture(joinery,grain_uv).r;
			color*=0.70+grain*0.51;
			roughness=0.84;
		} else if (part<4.5) {
			float block=texture(joinery,vec2(side,across)*vec2(0.22,0.32)).g;
			color*=0.56+0.75*block;
		} else if (part<5.5) {
			float course=texture(joinery,p*0.48).b;
			color*=0.79+0.39*course;
			roughness=0.75; specularity=0.24;
		} else if (part<6.5) {
			float weave=texture(joinery,vec2(side*0.85,across*1.3)).b;
			color*=0.69+0.57*weave;
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
			color*=.74+.29*compact+.16*lift-.105*footing-.065*rain;
		} else if (part>11.5 && part<12.5) {
			vec3 r=texture(fieldbed,vec2(side*.35,across*.51)).rgb;
			color*=.76+.36*r.r+.09*r.b;
		} else if (part>12.5 && part<13.5) {
			vec3 flecks=texture(fieldbed,p*.37).rgb;
			float bank=abs(p.x+32.0);
			float edge=smoothstep(4.28,6.28,bank+.33*sin(p.y*.39)+.54*(flecks.g-.52));
			vec3 silt=mix(shallows.rgb*.88,vec3(.206,.254,.185),.42+flecks.g*.21);
			silt*=.85+.22*flecks.r+.11*smoothstep(.61,.84,flecks.b);
			color=mix(silt,painted_ground(p),edge);
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
		}
	}
	ALBEDO=color;
	ROUGHNESS=roughness;
	SPECULAR=specularity;
}
