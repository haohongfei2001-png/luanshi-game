shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D cloth_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D response_atlas : filter_linear_mipmap, repeat_disable;
uniform sampler2D motion_bank : filter_nearest, repeat_disable;
uniform vec4 livery : source_color = vec4(.28,.40,.40,1.);
uniform int kit = 0;
uniform int travelling_attack_legs = -1;
uniform float travelling_leg_phase = 0.0;
varying flat float flash;
varying flat float cloth_lot;
varying flat float fallen;
varying float sewn_shadow;

vec3 rotated(vec4 q, vec3 v) {
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}
void skin(int bone, ivec2 tile, vec3 bind_vertex, vec3 bind_normal, out vec3 pos, out vec3 nrm) {
    ivec2 address=tile+ivec2(bone*3,0);
    vec4 q8=texelFetch(motion_bank,address,0);
    vec4 hi=texelFetch(motion_bank,address+ivec2(1,0),0);
    vec4 lo=texelFetch(motion_bank,address+ivec2(2,0),0);
    int xy=int(hi.a*255.0+.5), zw=int(lo.a*255.0+.5);
    vec4 tail=vec4(float(xy>>4),float(xy%16),float(zw>>4),float(zw%16));
    vec4 q=normalize((q8*4080.0+tail)*(2.0/4095.0)-1.0);
    vec3 translation=((hi.rgb*256.0+lo.rgb)/257.0-.5)*6.0;
    pos=rotated(q,bind_vertex)+translation;
    nrm=rotated(q,bind_normal);
}
ivec2 tile_for(int weapon, int clip, float progress) {
    int frame=clamp(int(progress*31.0+.5),0,31);
    return ivec2((frame%8)*48,(weapon*31+clip)*4+frame/8);
}
void vertex() {
    int code=int(floor(INSTANCE_CUSTOM.r*128.0));
    int state=code%8;
    int slot=(code/8)%4;
    int bones=int(floor(UV2.x*1024.0));
    int first=bones/32;
    int second=bones%32;
    float blend=clamp(UV2.y,0.,1.);
    float phase=INSTANCE_CUSTOM.g;
    int clip=1;
    if(state==0) {
        clip=phase>.001 ? int(floor(phase*32.0)):1;
        phase=INSTANCE_CUSTOM.b;
    } else if(state==1 || state==2) {
        clip=(state==1 ? 2:6)+slot;
    } else if(state==3) {clip=10;}
    else if(state==4) {clip=11;}
    else if(state==5) {clip=12;phase=INSTANCE_CUSTOM.b;}
    else if(state==6) {clip=13;}
    else {clip=14;}
    // Mounted legs use the saddle pose while the upper body keeps its live attack clip.
    if(code>=64 && (state==0 || (first>=9 && first<=14))) {clip=15;phase=INSTANCE_CUSTOM.b;}
    int sample_kit=(code/32)%2==1 && (state==1 || state==2) ? 2:kit;
    ivec2 tile=tile_for(sample_kit,clip,phase);
    vec3 pos,nrm;
    skin(first,tile,VERTEX,NORMAL,pos,nrm);
    if(first!=second && blend<.999) {
        vec3 other_pos,other_nrm;
        skin(second,tile,VERTEX,NORMAL,other_pos,other_nrm);
        pos=mix(other_pos,pos,blend);
        nrm=mix(other_nrm,nrm,blend);
    }
    // Only the on-foot player may keep travelling through a weapon action. The
    // pelvis and coat keep the strike; weight passes to the running pose at the knee.
    if (travelling_attack_legs>=0 && (state==1 || state==2 || state==3) && VERTEX.y<.87) {
        ivec2 foot_tile=tile_for(kit,travelling_attack_legs,travelling_leg_phase);
        vec3 step_pos,step_nrm;
        skin(first,foot_tile,VERTEX,NORMAL,step_pos,step_nrm);
        if(first!=second && blend<.999) {
            vec3 next_pos,next_nrm;
            skin(second,foot_tile,VERTEX,NORMAL,next_pos,next_nrm);
            step_pos=mix(next_pos,step_pos,blend);
            step_nrm=mix(next_nrm,step_nrm,blend);
        }
        float leg_weight=1.0-smoothstep(.43,.86,VERTEX.y);
        pos=mix(pos,step_pos,leg_weight);
        nrm=mix(nrm,step_nrm,leg_weight);
    }
    // Broad painted occlusion stays on the garment as the shoulder or hem turns.
    float armhole=smoothstep(.12,.23,abs(VERTEX.x))*(1.0-smoothstep(.035,.105,abs(VERTEX.y-1.285)));
    float hem=1.0-smoothstep(.52,1.38,VERTEX.y);
    sewn_shadow=.12*armhole+.125*hem+.055*max(-NORMAL.y,0.0);
    VERTEX=pos;
    NORMAL=normalize(nrm);
    float wear=INSTANCE_CUSTOM.a*8.0;
    cloth_lot=floor(wear)/7.0;
    flash=clamp((fract(wear)-.055)/.88,0.0,1.0);
    fallen=state==7 ? smoothstep(0.,.8,phase) : 0.;
}
void fragment(){
    vec3 colour=texture(cloth_atlas,UV).rgb;
    vec3 response=texture(response_atlas,UV).rgb;
    float fibre=dot(colour,vec3(.27,.54,.19));
    // A bolt of faded indigo or madder shows exposed natural fibre in the worn lots.
    float fibre_exposed=.10+.45*smoothstep(.10,.89,cloth_lot);
    vec3 dyed=mix(livery.rgb,colour*vec3(.80,.80,.79),fibre_exposed)*(.58+fibre*.83)*mix(.86,1.02,cloth_lot);
    colour=mix(colour,dyed,response.b);
    colour*=mix(vec3(1.),vec3(.53,.67,.79),sewn_shadow);
    colour*=mix(1.0,.73,fallen);
    ALBEDO=mix(colour,vec3(.57,.29,.15),flash*.23);
    ROUGHNESS=clamp(response.r,.24,1.);
    METALLIC=response.g*.66;
    SPECULAR=mix(.25,.56,response.g);
}
