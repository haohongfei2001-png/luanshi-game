shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 livery : source_color = vec4(0.16,0.38,0.37,1.0);
uniform int kit = 3;
uniform bool animal = false;
varying vec3 tint;

vec3 bend_x(vec3 p, vec3 pivot, float a) {
	p -= pivot;
	float c=cos(a), s=sin(a);
	return pivot+vec3(p.x,c*p.y-s*p.z,s*p.y+c*p.z);
}
vec3 bend_y(vec3 p, vec3 pivot, float a) {
	p -= pivot;
	float c=cos(a), s=sin(a);
	return pivot+vec3(c*p.x+s*p.z,p.y,-s*p.x+c*p.z);
}

void vertex() {
	int code=int(floor(INSTANCE_CUSTOM.r*64.0));
	int state=code%8;
	int slot=(code/8)%4;
	float p=INSTANCE_CUSTOM.g;
	float walk=sin(INSTANCE_CUSTOM.b*6.28318);
	int joint=int(round(UV2.x));
	vec3 v=VERTEX;
	if (joint==1 || joint==2) {
		float stride=walk*(joint==1 ? 1.0 : -1.0);
		v=bend_x(v,vec3(0,animal ? 0.94 : 0.65,0),stride*(state==5 ? 0.61 : 0.38));
	}
	if (!animal && (joint==3 || joint==4)) {
		vec3 shoulder=vec3(joint==3 ? 0.25 : -0.25,1.25,0);
		float swing=joint==3 ? -0.14*walk : 0.14*walk;
		if (state==1 || state==2) {
			float beat=state==1 ? smoothstep(0.0,0.74,p)-1.9*smoothstep(0.74,1.0,p) : -0.9*(1.0-p);
			if (code>=32) {
				v.z-=beat*0.42;
				swing+=beat*0.36;
			} else if (kit==3 || (kit==0 && slot==2) || kit==7) {
				v.z-=beat*(joint==3 ? 0.48 : 0.18);
				swing+=beat*0.28;
			} else if (kit==6) {
				// Hold the stock level at release, then return the string during recovery.
				float load=state==2 ? sin(3.14159*p) : 0.0;
				v.z+=(joint==4 ? -0.32*load : -0.08*beat);
				swing+=(joint==4 ? 0.72*load : 0.12*load);
			} else if (kit==5) {
				v.z+=beat*(joint==4 ? -0.31 : 0.12);
				swing-=0.18;
			 } else if (kit==1 || kit==4) {
				float chop=kit==4 ? 1.04 : 0.68;
				v=bend_y(v,shoulder,beat*(slot==1 ? 1.28 : 0.47));
				swing+=beat*chop;
			} else {
				float side=(joint==4 && kit==8) ? -1.0 : 1.0;
				v=bend_y(v,shoulder,beat*(kit==2 ? 1.26 : 0.98)*side);
				swing+=beat*(kit==4 ? 0.91 : 0.48);
			}
		}
		if (state==3) {swing-=0.8; v.z+=0.13;}
		v=bend_x(v,shoulder,swing);
	}
	if (state==4) {v=bend_x(v,vec3(0,0.45,0),-0.22*(1.0-p));}
	if (state==7) {v=bend_x(v,vec3(0,0.11,0),-1.45*smoothstep(0.0,0.90,p));}
	else if (state==5) {v=bend_x(v,vec3(0,0.5,0),0.15);}
	VERTEX=v;
	tint=mix(COLOR.rgb,livery.rgb*(0.67+0.34*COLOR.r),clamp(UV2.y,0.0,1.0));
	tint=mix(tint,vec3(0.95,0.59,0.34),INSTANCE_CUSTOM.a*0.57);
	if (state==7) {tint*=0.64;}
}
void fragment(){ALBEDO=tint; ROUGHNESS=0.89;}
