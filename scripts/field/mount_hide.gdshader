shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D surface_atlas : source_color, filter_linear_mipmap, repeat_disable;
varying flat float atlas_patch;
varying flat float fallen;
varying flat float hit;
varying float coat_shade;
varying float coat_under;
varying flat float coat_lot;
uniform float stable_clock = 0.0;

vec3 rx(vec3 p,float a){float c=cos(a),s=sin(a);return vec3(p.x,c*p.y-s*p.z,s*p.y+c*p.z);}
vec3 rz(vec3 p,float a){float c=cos(a),s=sin(a);return vec3(c*p.x-s*p.y,s*p.x+c*p.y,p.z);}
void vertex(){
	int bone=int(floor(UV2.x*32.0));
	float weight=clamp(UV2.y,0.0,1.0);
	int state=int(floor(INSTANCE_CUSTOM.r*128.0))%8;
	float collapse=state==7?smoothstep(0.0,0.91,INSTANCE_CUSTOM.g):0.0;
	float gait=state==7?0.0:clamp(INSTANCE_CUSTOM.g,0.0,1.0);
	float phase=INSTANCE_CUSTOM.b*6.2831853;
	float rest=sin(stable_clock*1.22+phase);
	float bounce=sin(phase*2.0)*0.021*gait;
	vec3 p=VERTEX,n=NORMAL;
	// The coat pigment belongs to the hide in bind space, including a raised
	// fetlock. It must not crawl up and down a moving leg or a nodding muzzle.
	coat_shade=max(1.-smoothstep(.29,.66,p.y),smoothstep(1.085,1.241,p.z)*.76);
	coat_under=max(0.,-n.y)*smoothstep(.50,.89,p.y);
	if(bone>=1 && bone<=4){
		bool hind=bone>=3;
		float side=(bone==1 || bone==3)?-1.0:1.0;
		// At marching speed each foot lands separately. The diagonal pairs converge in a trot.
		float phase_shift=bone==1?0.0:(bone==2?3.14159:(bone==3?3.14159+0.63*(1.0-gait):0.63*(1.0-gait)));
		float beat=phase+phase_shift;
		float stride=fract(beat/6.2831853+.25);
		float stance=mix(.60,.42,gait);
		float travel=1./.68; // actual metres travelled per motion cycle
		float sole_y=.013;
		float z0=hind?-.573:.482;
		float swing=clamp((stride-stance)/(1.-stance),0.,1.);
		float reach=.5*stance*travel;
		float ground_z=reach-stride*travel;
		float swing_z=-reach+2.*reach*smoothstep(0.,1.,swing)
		              -(1.-stance)*travel*swing*(1.-swing)*(1.-2.*swing);
		// Running-cycle phase already advances in proportion to distance.
		// A partial-speed trot still has a fully planted support foot.
		float slide=(stride<stance?ground_z:swing_z)*smoothstep(0.,.16,gait);
		float clearance=(hind?.132:.164)*sin(3.14159265*swing)*gait;
		float heel=(stride<stance ? -0.11*(1.-smoothstep(0.,.22,stride/stance))
		                          +0.22*smoothstep(.74,1.,stride/stance)
		                         :mix(.22,-.11,smoothstep(0.,1.,swing)))*gait;
		float upper_angle=-slide*(hind?.85:.94);
		float knee_angle=(hind?-.40:.58)*sin(3.14159265*swing)*gait;
		vec3 knee=vec3(side*.217,.50,hind?-.706:.426);
		vec3 shoulder=vec3(side*.207,1.058,hind?-.557:.358);
		float hinge=1.-smoothstep(.46,.64,p.y);
		float upper=upper_angle*(1.-smoothstep(.88,1.18,p.y));
		vec3 articulated=knee+rx(p-knee,knee_angle*hinge);
		articulated=shoulder+rx(articulated-shoulder,upper);
		vec3 leg_n=rx(rx(n,knee_angle*hinge),upper);
		float upper_bob=bounce*smoothstep(.17,.94,p.y);
		articulated.y+=upper_bob;
		// The toe carries the last part of stance as the heel rises. Correct
		// the lower leg to the actual world-space support line, leaving the
		// forearm/stifle and elbow on the swinging shoulder.
		float lock=1.-smoothstep(.14,.71,p.y);
		vec3 rest_sole=vec3(side*.217,sole_y,z0);
		vec3 contacting=rest_sole+rx(p-rest_sole,heel);
		contacting.z+=slide;
		contacting.y+=clearance+abs(sin(heel))*.077;
		p=mix(articulated,contacting,lock);
		n=mix(leg_n,rx(n,heel),lock);
		p.y=max(.008,p.y);
	}else if(bone==11){
		vec3 poll=vec3(0,1.206,0.356);
		float nod=(sin(phase*2.+.57)*.037*gait+sin(phase+.28)*.022*gait-.010*gait+.012*rest*(1.-gait))*weight;
		p=poll+rx(p-poll,nod); n=rx(n,nod);p.y+=bounce*weight;
	}else if(bone==12){
		vec3 dock=vec3(0,1.29,-0.69);
		float swish=weight*(gait*(0.14*sin(phase+0.36)+0.05*sin(phase*2.0))+.036*sin(stable_clock*1.43+phase)*(1.0-gait));
		float trailing=weight*weight*(.125*gait+.035*sin(phase+.60)*gait);
		p=dock+rx(rz(p-dock,swish),trailing);n=rx(rz(n,swish),trailing);p.y+=bounce;
	}else if(bone==14){
		vec3 hub=vec3(0,0.55,-1.83);
		// Five of twelve spokes per 1.47m stride = 1.78 rad/m at a 0.55m wheel.
		p=hub+rx(p-hub,phase*(5.0/12.0));n=rx(n,phase*(5.0/12.0));
	}else if(bone==0){
		p.y+=bounce*smoothstep(0.71,1.28,p.y)*smoothstep(-1.16,-0.68,p.z);
	}
	if(collapse>0.0){
		float crash=collapse*(INSTANCE_CUSTOM.b<0.5?-1.40:1.40);
		// If the team falls, the attached bed settles at its own axle.
		float horse_mask=smoothstep(-1.2,-0.68,VERTEX.z);
		vec3 pivot=vec3(0,mix(0.52,0.25,horse_mask),0);
		float roll=crash*mix(0.19,1.0,horse_mask);
		p=pivot+rz(p-pivot,roll);n=rz(n,roll);p.y=max(0.025,p.y);
	}
	VERTEX=p; NORMAL=normalize(n);
	vec2 tile=floor(UV*4.0);
	atlas_patch=tile.x+tile.y*4.0;
	float pigment=INSTANCE_CUSTOM.a*4.0;
	coat_lot=floor(pigment);
	fallen=collapse;hit=clamp((fract(pigment)-.03)/.92,0.0,1.0);
}
void fragment(){
	vec3 color=texture(surface_atlas,UV,1.1).rgb;
	if(atlas_patch<1.5) {
		vec3 pigment;
		if(coat_lot<.5) pigment=vec3(.73,.61,.52);
		else if(coat_lot<1.5) pigment=vec3(.59,.65,.67);
		else if(coat_lot<2.5) pigment=vec3(.87,.74,.61);
		else pigment=vec3(.58,.52,.49);
		color*=pigment*mix(vec3(1.),vec3(.53,.59,.62),coat_shade);
		color*=1.-.11*coat_under;
	}
    // Leather and mane keep a dark mass beneath the rider; shaped metal fittings
    // already carry their own bright swatch in the shared tack atlas.
    float grazing=1.0-smoothstep(.07,.36,abs(dot(normalize(NORMAL),normalize(VIEW))));
    ALBEDO=color*(1.0-.08*grazing)*(1.0-fallen*.22)*(1.0+hit*.09);
    ROUGHNESS=.94;
    SPECULAR=0.0;
}

#include "res://scripts/field/cloth_light.gdshaderinc"
