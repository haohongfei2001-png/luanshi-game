shader_type spatial;
render_mode diffuse_lambert, cull_disabled;
uniform sampler2D fieldbed : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D joinery : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec4 meadow : source_color = vec4(0.39,0.44,0.32,1.0);
uniform vec4 straw : source_color = vec4(0.57,0.55,0.40,1.0);
uniform vec4 loam : source_color = vec4(0.57,0.48,0.37,1.0);
uniform vec4 silt : source_color = vec4(0.43,0.40,0.33,1.0);
uniform vec4 pebble : source_color = vec4(0.61,0.61,0.53,1.0);
uniform vec4 deep_water : source_color = vec4(0.28,0.41,0.40,1.0);
uniform vec4 shallows : source_color = vec4(0.44,0.52,0.46,1.0);
varying vec3 local_pos;
varying vec3 local_normal;
varying float part;
varying vec3 pigment;

void vertex() {
	local_pos=VERTEX;
	local_normal=NORMAL;
	part=UV2.x;
	pigment=COLOR.rgb;
}

void fragment() {
	vec2 p=local_pos.xz;
	vec3 color=pow(max(pigment,vec3(0.0)),vec3(1.80));
	float roughness=0.92;
	float specularity=0.13;
	if (part>0.5 && part<1.5) {
		vec3 soil=texture(fieldbed,p*0.183).rgb;
		float landform=texture(fieldbed,p*0.0019+vec2(0.38,0.62)).g;
		float changes=texture(fieldbed,p*0.041+vec2(0.14,0.44)).r;
		float bank=abs(p.x+32.0);
		float center=0.63*sin(p.x*0.058)+0.15*sin(p.x*0.37);
		float main_lane=abs(p.y-center);
		float spur_lane=abs(abs(p.y)-35.0);
		float lane=mix(min(main_lane,spur_lane),main_lane,smoothstep(-19.0,2.0,p.x));
		float half_width=mix(3.44,2.15,step(spur_lane,main_lane)*(1.0-smoothstep(-19.0,2.0,p.x)));
		float worn=1.0-smoothstep(half_width-0.73,half_width+0.76,lane+(changes-0.5)*1.55);
		float court=(1.0-smoothstep(19.7,22.0,abs(p.y)))*smoothstep(46.0,50.0,p.x)*(1.0-smoothstep(87.0,91.0,p.x));
		float rut_distance=abs(lane-1.20-0.11*sin(p.x*0.58)-0.16*(landform-0.5));
		float rut=(1.0-smoothstep(0.085,0.31+fwidth(lane),rut_distance))
				*smoothstep(0.27,0.57,changes)*worn*(1.0-0.6*court);
		float turf=clamp((landform-0.25)*0.65+(soil.g-0.26)*0.85+0.11*smoothstep(0.4,2.5,local_pos.y),0.0,1.0);
		vec3 pasture=mix(meadow.rgb,straw.rgb,turf)*(0.85+0.28*soil.r);
		vec3 dirt=loam.rgb*(0.75+0.43*soil.r+0.12*changes);
		dirt=mix(dirt,silt.rgb*(0.88+0.24*soil.r),0.57*rut);
		float crown=(1.0-smoothstep(0.12,0.91,lane))*smoothstep(0.48,0.70,soil.g);
		color=mix(pasture,dirt,clamp(max(worn,court*0.83)-0.22*crown,0.0,1.0));
		float shoal=1.0-smoothstep(4.4,6.5,bank+(changes-0.5)*1.4);
		vec3 gravel=mix(silt.rgb,pebble.rgb,smoothstep(0.47,0.78,soil.b))*(0.87+0.21*soil.r);
		color=mix(color,gravel,shoal);
		if (p.x < -49.0 && p.y>18.0 && p.y<43.0) {
			float furrow=smoothstep(-0.57,0.57,sin(p.x*5.8+p.y*0.30+0.65*changes));
			color*=0.80+0.13*furrow;
		}
	} else if (part>1.5 && part<2.5) {
		float bank=abs(p.x+32.0);
		vec2 flow=vec2(p.x*.29,p.y*.047-TIME*.017);
		float ripple=texture(fieldbed,flow).r;
		float wave=texture(fieldbed,vec2(p.x*.41+p.y*.07,p.y*.068-TIME*.024)).g;
		float edge=smoothstep(2.45,4.78,bank);
		color=mix(deep_water.rgb,shallows.rgb,0.79*edge+0.12*wave)*(0.84+0.23*ripple+0.09*wave);
		float crest=smoothstep(0.55,0.78,ripple)*smoothstep(0.43,0.80,wave);
		color+=vec3(0.048,0.061,0.055)*crest*(0.33+edge);
		roughness=0.48; specularity=0.33;
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
			color*=0.73+0.30*compact+0.22*lift;
		}
	}
	ALBEDO=color;
	ROUGHNESS=roughness;
	SPECULAR=specularity;
}
