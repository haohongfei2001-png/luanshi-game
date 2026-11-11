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
	int code=int(floor(INSTANCE_CUSTOM.r*128.0));
	int state=code%8;
	int slot=(code/8)%4;
	bool seated=code>=64 && !animal;
	float p=INSTANCE_CUSTOM.g;
	float walk=sin(INSTANCE_CUSTOM.b*6.28318);
	int joint=int(round(UV2.x));
	vec3 v=VERTEX;
	if (joint==1 || joint==2) {
		float stride=walk*(joint==1 ? 1.0 : -1.0);
		if (seated) {
			float drop=clamp((0.76-v.y)/0.70,0.0,1.0);
			v.x+=(joint==1 ? -1.0 : 1.0)*drop*0.22;
			v.z+=sin(drop*2.58)*0.30;
			v.y+=drop*0.10;
		} else {
			v=bend_x(v,vec3(0,animal ? 0.94 : 0.65,0),stride*(state==5 ? 0.61 : 0.38));
		}
	}
	if (!animal && (joint==3 || joint==4)) {
		vec3 shoulder=vec3(joint==3 ? 0.25 : -0.25,1.25,0);
		float swing=joint==3 ? -0.14*walk : 0.14*walk;
		if (state==1 || state==2) {
			float beat=state==1 ? smoothstep(0.0,0.74,p)-1.9*smoothstep(0.74,1.0,p) : -0.9*(1.0-p);
			// The return strike lands 45% into recovery, the same tick as _state_step.
			bool twice=(kit==8 && (slot==0 || slot==1)) || (kit==3 && slot==1);
			if (twice && state==2) {
				float back=smoothstep(0.0,0.28,p);
				float cut=smoothstep(0.28,0.45,p);
				beat=(-0.9+1.75*back-1.80*cut)*(1.0-smoothstep(0.46,1.0,p));
				if (kit==8 && joint==4) beat=-beat;
			}
			bool evading=slot==3 && (kit==1 || kit==5 || kit==8);
			bool bracing=slot==3 && (kit==2 || kit==3 || kit==6 || kit==7);
			if (evading) {
				v.z-=0.16*(1.0-p);
				swing-=0.55*(1.0-p);
			} else if (bracing) {
				float set=state==1 ? smoothstep(0.0,0.9,p) : 1.0-p;
				swing-=set*(kit==7 && joint==4 ? 1.15 : 0.41);
				v.z+=set*(joint==4 ? 0.16 : 0.09);
			} else if (slot==3 && (kit==0 || kit==4)) {
				float ready=state==1 ? smoothstep(0.0,0.85,p) : 1.0-p;
				v=bend_y(v,shoulder,-0.68*ready);
				swing-=ready*(kit==4 ? 0.92 : 0.68);
			} else if (kit==7 && slot==1) {
				v.z-=beat*(joint==4 ? 0.49 : 0.06);
				swing-=joint==4 ? 0.58 : 0.23;
			} else if (kit==2 && (slot==1 || slot==2)) {
				v.z-=beat*(slot==1 ? 0.40 : 0.52);
				swing+=0.19*beat;
			} else if (((code/32)%2)==1) {
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
		if (state==3) {float lift=kit==7 && joint==4 ? 1.08 : (kit==3 ? 0.28 : (kit==4 ? 0.92 : 0.68));
			swing-=lift;
			if (kit==0 || kit==4) v=bend_y(v,shoulder,-0.68);
			v.z+=kit==3 ? 0.23 : 0.13;}
		v=bend_x(v,shoulder,swing);
	}
	if (!animal && !seated && (state==1 || state==2)) {
		float load=state==1 ? smoothstep(0.0,0.67,p)-1.65*smoothstep(0.68,1.0,p) : -0.65*(1.0-p);
		float weight=smoothstep(0.25,1.18,v.y);
		v.z-=load*weight*(kit==4 ? 0.14 : 0.075);
		v.y-=weight*abs(load)*0.032;
	}
	if (!animal && slot==3 && (kit==1 || kit==5 || kit==8) && (state==1 || state==2) && !seated) {
		float dip=state==1 ? smoothstep(0.0,1.0,p) : 1.0-smoothstep(0.25,1.0,p);
		v.y-=smoothstep(0.1,1.15,v.y)*0.19*dip;
		v.z-=0.18*dip*smoothstep(0.4,1.3,v.y);
	}
	if (state==4) {v=bend_x(v,vec3(0,0.45,0),-0.22*(1.0-p));}
	if (state==7) {v=bend_x(v,vec3(0,0.11,0),-1.45*smoothstep(0.0,0.90,p));}
	else if (state==5) {v=bend_x(v,vec3(0,0.5,0),0.15);}
	VERTEX=v;
	// Some instancing paths multiply vertex COLOR by the optional instance tint.
	// Keep the authored skin, iron and leather palette independent of instance data.
	float dyed=step(1.5,UV2.y);
	vec3 paint=clamp(vec3(UV,UV2.y-2.0*dyed),vec3(0.0),vec3(1.0));
	vec3 surface_paint=OUTPUT_IS_SRGB ? paint : mix(paint/12.92,pow((paint+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),paint));
	tint=mix(surface_paint,livery.rgb*(0.67+0.34*paint.r),dyed);
	tint=mix(tint,vec3(0.95,0.59,0.34),INSTANCE_CUSTOM.a*0.57);
	if (state==7) {tint*=0.64;}
}
void fragment(){ALBEDO=tint; EMISSION=tint*0.23; ROUGHNESS=0.84; SPECULAR=0.21;}
