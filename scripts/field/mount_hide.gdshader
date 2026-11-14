shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D surface_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D coat_pigments : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D native_pose_hi : filter_linear, repeat_disable;
uniform sampler2D native_pose_lo : filter_linear, repeat_disable;
uniform sampler2D native_pose_normal : filter_linear, repeat_disable;
uniform sampler2D native_socket_pose : filter_linear, repeat_disable;
uniform sampler2D mane_ink : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
varying flat float atlas_patch;
varying flat float fallen;
varying flat float hit;
varying float coat_shade;
varying float coat_under;
varying float sock;
varying float nose;
varying flat float coat_lot;
varying float animal_barrel;
uniform vec4 bay_deep : source_color = vec4(.166,.113,.098,1.);
uniform vec4 bay_lit : source_color = vec4(.388,.262,.189,1.);
uniform vec4 iron_deep : source_color = vec4(.159,.164,.156,1.);
uniform vec4 iron_lit : source_color = vec4(.406,.425,.385,1.);
uniform vec4 chestnut_deep : source_color = vec4(.214,.131,.110,1.);
uniform vec4 chestnut_lit : source_color = vec4(.474,.294,.201,1.);
uniform vec4 seal_deep : source_color = vec4(.136,.115,.111,1.);
uniform vec4 seal_lit : source_color = vec4(.305,.253,.221,1.);
uniform vec4 unpigmented : source_color = vec4(.487,.463,.386,1.);
uniform vec4 nose_leather : source_color = vec4(.193,.172,.158,1.);

vec3 rx(vec3 p,float a){float c=cos(a),s=sin(a);return vec3(p.x,c*p.y-s*p.z,s*p.y+c*p.z);}
vec3 rz(vec3 p,float a){float c=cos(a),s=sin(a);return vec3(c*p.x-s*p.y,s*p.x+c*p.y,p.z);}

vec2 native_address(int index, float phase, int clip) {
    return vec2((.5+32.*clamp(phase,0.,1.)+33.*float(clip))/66.,
                (float(index)+.5)/float(textureSize(native_pose_hi,0).y));
}
void native_position(int index, float phase, int clip, out vec3 position, out vec3 normal) {
    vec2 at=native_address(index,phase,clip);
    vec3 high=textureLod(native_pose_hi,at,0.).rgb;
    vec3 low=textureLod(native_pose_lo,at,0.).rgb;
    position=((high*256.+low)/257.-.5)*6.;
    normal=normalize(textureLod(native_pose_normal,at,0.).rgb*2.-1.);
}


void socket_sample(vec3 point, vec3 normal, float phase, int clip, int socket,
                   out vec3 posed_point, out vec3 posed_normal) {
    float row=(.5+32.*clamp(phase,0.,1.)+33.*float(clip))/66.;
    float column=float(socket*3);
    vec4 a=textureLod(native_socket_pose,vec2((column+.5)/6.,row),0.);
    vec4 b=textureLod(native_socket_pose,vec2((column+1.5)/6.,row),0.);
    vec4 c=textureLod(native_socket_pose,vec2((column+2.5)/6.,row),0.);
    vec4 position=vec4(point,1.);
    posed_point=vec3(dot(a,position),dot(b,position),dot(c,position));
    posed_normal=normalize(vec3(dot(a.xyz,normal),dot(b.xyz,normal),dot(c.xyz,normal)));
}
void socket_motion(vec3 point, vec3 normal, float phase, float gait, int socket,
                   out vec3 posed_point, out vec3 posed_normal) {
    vec3 walk_point,walk_normal,trot_point,trot_normal;
    socket_sample(point,normal,phase,0,socket,walk_point,walk_normal);
    socket_sample(point,normal,phase,1,socket,trot_point,trot_normal);
    float pace=smoothstep(.25,.90,gait);
    float moving=smoothstep(0.,.16,gait);
    posed_point=mix(point,mix(walk_point,trot_point,pace),moving);
    posed_normal=normalize(mix(normal,mix(walk_normal,trot_normal,pace),moving));
}

void vertex(){
	int bone=int(floor(UV2.x*32.0));
	float weight=clamp(UV2.y,0.0,1.0);
    bool native_hide=UV.x>=2.;
    int native_index=int(floor(UV2.x*256.))+256*int(floor(UV2.y*32.));
    if(native_hide) {
        vec2 at=native_address(native_index,0.,0);
        bone=int(round(textureLod(native_pose_hi,at,0.).a*255.));
        weight=textureLod(native_pose_lo,at,0.).a;
    }
	int state=int(floor(INSTANCE_CUSTOM.r*128.0))%8;
	float collapse=state==7?smoothstep(0.0,0.91,INSTANCE_CUSTOM.g):0.0;
	float gait=state==7?0.0:clamp(INSTANCE_CUSTOM.g,0.0,1.0);
	float phase=INSTANCE_CUSTOM.b*6.2831853;
	vec3 p=VERTEX,n=NORMAL;
	// The coat pigment belongs to the hide in bind space, including a raised
	// fetlock. It must not crawl up and down a moving leg or a nodding muzzle.
	coat_shade=max(1.-smoothstep(.29,.66,p.y),smoothstep(1.085,1.241,p.z)*.76);
	coat_under=max(0.,-n.y)*smoothstep(.50,.89,p.y);
	animal_barrel=smoothstep(.49,.84,p.y)*(1.-smoothstep(.60,.79,p.z));

    if(native_hide) {
        vec3 walk_point,walk_normal,trot_point,trot_normal;
        native_position(native_index,INSTANCE_CUSTOM.b,0,walk_point,walk_normal);
        native_position(native_index,INSTANCE_CUSTOM.b,1,trot_point,trot_normal);
        float pace=smoothstep(.25,.90,gait);
        float moving=smoothstep(0.,.16,gait);
        p=mix(p,mix(walk_point,trot_point,pace),moving);
        n=normalize(mix(n,mix(walk_normal,trot_normal,pace),moving));
    } else if(bone==14) {
        vec3 hub=vec3(0.,.55,-1.83);
        p=hub+rx(p-hub,phase*(5./12.));
        n=rx(n,phase*(5./12.));
    } else {
        vec3 saddle_point,saddle_normal,head_point,head_normal;
        socket_motion(p,n,INSTANCE_CUSTOM.b,gait,0,saddle_point,saddle_normal);
        if(bone==11 || bone==17) {
            socket_motion(p,n,INSTANCE_CUSTOM.b,gait,1,head_point,head_normal);
            // The bit follows the head. The other end follows its rider or cart.
            p=mix(bone==17?p:saddle_point,head_point,weight);
            n=normalize(mix(bone==17?n:saddle_normal,head_normal,weight));
        } else {
            float body_weight=bone==16?weight:1.;
            p=mix(p,saddle_point,body_weight);
            n=normalize(mix(n,saddle_normal,body_weight));
        }
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
	atlas_patch=UV.x>=3.0?33.0:(UV.x>=2.0?32.0:tile.x+tile.y*4.0);
	// Socks and muzzle markings are anchored to that horse's bind-space
	// legs and nose. They stay put as joints move or the LOD changes.
	float pigment=INSTANCE_CUSTOM.a*4.0;
	coat_lot=floor(pigment);
	float front_mark=smoothstep(.25,.34,VERTEX.z)*smoothstep(.04,.13,VERTEX.x);
	float rear_mark=(1.-smoothstep(-.56,-.41,VERTEX.z))*(1.-smoothstep(-.13,-.04,VERTEX.x));
	float sock_height=.215+.036*sin(VERTEX.z*17.+VERTEX.x*22.);
	sock=(1.-smoothstep(sock_height-.015,sock_height+.015,VERTEX.y))*max(front_mark,rear_mark);
	nose=smoothstep(1.04,1.20,VERTEX.z);
	fallen=collapse;hit=clamp((fract(pigment)-.03)/.92,0.0,1.0);
}
void fragment(){
	vec3 color=texture(surface_atlas,UV,1.1).rgb;
	if(atlas_patch>32.5) {
		vec4 tuft=texture(mane_ink,UV-vec2(3.,0.));
		if(tuft.a<.50) discard;
		color=tuft.rgb;
	} else if(atlas_patch>31.5) {
		vec2 cell=vec2(mod(coat_lot,2.0),floor(coat_lot*.5));
		vec2 ink_uv=(cell+clamp(UV-vec2(2.,0.),vec2(.001),vec2(.999)))*.5;
		vec3 hide=texture(coat_pigments,ink_uv).rgb;
		float value=dot(hide,vec3(.30,.55,.15));
		color=mix(vec3(value),hide,.83)*.95;
	} else if(atlas_patch<1.5) {
		float ink=dot(color,vec3(.30,.56,.14));
		if (!OUTPUT_IS_SRGB) ink=sqrt(max(ink,0.));
		float wash=smoothstep(.22,.58,ink);
		vec3 base=mix(bay_deep.rgb,bay_lit.rgb,wash);
		if(coat_lot>.5 && coat_lot<1.5) base=mix(iron_deep.rgb,iron_lit.rgb,wash);
		else if(coat_lot>1.5 && coat_lot<2.5) base=mix(chestnut_deep.rgb,chestnut_lit.rgb,wash);
		else if(coat_lot>2.5) base=mix(seal_deep.rgb,seal_lit.rgb,wash);
		color=mix(base,base*vec3(.48,.49,.48),coat_shade*.73);
		color=mix(color,nose_leather.rgb,nose*.61);
		if(coat_lot>.5 && coat_lot<2.5) color=mix(color,unpigmented.rgb,sock*.75);
		color*=1.-.13*coat_under;
	}
    // Leather and mane keep a dark mass beneath the rider; shaped metal fittings
    // already carry their own bright swatch in the shared tack atlas.
    float grazing=1.0-smoothstep(.07,.36,abs(dot(normalize(NORMAL),normalize(VIEW))));
    ALBEDO=color*(1.0-.08*grazing)*(1.0-fallen*.22)*(1.0+hit*.09);
    ROUGHNESS=.94;
    SPECULAR=0.0;
}

void light(){
	float facing=dot(NORMAL,LIGHT);
	float width=clamp(fwidth(facing)*.85,.032,.13);
	float half_light=smoothstep(.04-width,.04+width,facing);
	float high=smoothstep(.59-width,.59+width,facing);
	float bands=.55*half_light+.43*high;
	// A broad flank turns gradually from the sky-lit topline into shadow.
	// Retain a compact shadow core and a rounded lit plane on the coat;
	// eyes, skull, leather and carriage keep their original cel thresholds.
	float broad=.35*smoothstep(-.25,.25,facing)+.41*smoothstep(.13,.77,facing)
	           +.20*smoothstep(.59,.94,facing);
	float is_coat=(atlas_patch<1.5 || atlas_patch==32.)?animal_barrel:0.;
	DIFFUSE_LIGHT+=LIGHT_COLOR*(mix(bands,broad,is_coat)*ATTENUATION/PI);
}
