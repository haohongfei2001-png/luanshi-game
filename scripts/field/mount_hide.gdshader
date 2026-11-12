shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D surface_atlas : source_color, filter_linear_mipmap, repeat_disable;
varying flat float atlas_patch;
varying flat float fallen;
varying flat float hit;
varying float coat_shade;
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
	if(bone>=1 && bone<=4){
		bool hind=bone>=3;
		float side=(bone==1 || bone==3)?-1.0:1.0;
		// At marching speed each foot lands separately. The diagonal pairs converge in a trot.
		float phase_shift=bone==1?0.0:(bone==2?3.14159:(bone==3?3.14159+0.63*(1.0-gait):0.63*(1.0-gait)));
		float beat=phase+phase_shift;
		float swing=sin(beat)*(0.22+0.28*gait)*gait;
		float flex=max(0.0,cos(beat))*(hind?-0.64:0.73)*gait;
		float blend=1.0-smoothstep(0.46,0.68,p.y);
		vec3 knee=vec3(side*0.217,0.50,hind?-0.706:0.426);
		p=knee+rx(p-knee,flex*blend); n=rx(n,flex*blend);
		vec3 shoulder=vec3(side*0.207,1.058,hind?-0.557:0.358);
		float hip=swing*(1.0-smoothstep(0.84,1.20,VERTEX.y));
		p=shoulder+rx(p-shoulder,hip); n=rx(n,hip);
		float lift=(hind?0.064:0.071)*max(0.0,cos(beat))*gait;
		p.y+=lift*(1.0-smoothstep(0.12,0.65,VERTEX.y));
		p.y+=bounce*smoothstep(0.05,0.95,VERTEX.y);
		p.y=max(0.012,p.y);
	}else if(bone==11){
		vec3 poll=vec3(0,1.206,0.356);
		float nod=(sin(phase*2.0+0.61)*0.051*gait-0.014*gait+.014*rest*(1.0-gait))*weight;
		p=poll+rx(p-poll,nod); n=rx(n,nod);p.y+=bounce*weight;
	}else if(bone==12){
		vec3 dock=vec3(0,1.29,-0.69);
		float swish=weight*(gait*(0.14*sin(phase+0.36)+0.05*sin(phase*2.0))+.036*sin(stable_clock*1.43+phase)*(1.0-gait));
		p=dock+rz(p-dock,swish);n=rz(n,swish);p.y+=bounce;
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
	coat_shade=max(1.0-smoothstep(.44,.83,VERTEX.y),smoothstep(1.09,1.23,VERTEX.z)*.82);
	coat_shade=max(coat_shade,.22*(1.0-smoothstep(.77,1.17,VERTEX.y)));
	float pigment=INSTANCE_CUSTOM.a*4.0;
	coat_lot=floor(pigment);
	fallen=collapse;hit=clamp((fract(pigment)-.03)/.92,0.0,1.0);
}
void fragment(){
	vec3 color=texture(surface_atlas,UV,1.1).rgb;
	if(atlas_patch<1.5) {
		vec3 bay=coat_lot<.5 ? vec3(.78,.69,.64) : (coat_lot<1.5 ? vec3(.56,.62,.70) : (coat_lot<2.5 ? vec3(.92,.89,.79) : vec3(.63,.56,.61)));
		color*=bay*mix(vec3(1.),vec3(.36,.46,.53),coat_shade);
	}
    // Leather and mane keep a dark mass beneath the rider; shaped metal fittings
    // already carry their own bright swatch in the shared tack atlas.
    float grazing=1.0-smoothstep(.07,.36,abs(dot(normalize(NORMAL),normalize(VIEW))));
    ALBEDO=color*(1.0-.08*grazing)*(1.0-fallen*.22)*(1.0+hit*.09);
    ROUGHNESS=.94;
    SPECULAR=0.0;
}

#include "res://scripts/field/cloth_light.gdshaderinc"
