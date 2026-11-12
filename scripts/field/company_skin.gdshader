shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D cloth_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D motion_bank : filter_linear, repeat_disable;
uniform vec4 livery : source_color = vec4(.28,.40,.40,1.);
uniform int kit = 0;
uniform int travelling_attack_legs = -1;
uniform bool player_costume = false;
uniform float travelling_leg_phase = 0.0;
varying flat float flash;
varying flat float cloth_lot;
varying flat float fallen;
varying float sewn_shadow;
varying flat int cloth_panel;
varying vec2 shield_face;

vec3 rotated(vec4 q, vec3 v) {
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}
// Horizontal filtering advances continuously through the 32 keys of a clip.
vec2 clip_address(int weapon, int clip, float progress) {
    bool loop = clip==0 || clip==1 || clip==12 || clip>=15;
    float key = clamp(progress,0.0,1.0) * (loop ? 32.0 : 31.0);
    return vec2(key+.5,float((weapon*31+clip)*4)+.5);
}
void skin(int bone, vec2 tile, vec3 bind_vertex, vec3 bind_normal, out vec3 pos, out vec3 nrm) {
    vec2 texel=1.0/vec2(textureSize(motion_bank,0));
    vec2 address=(tile+vec2(float(bone*33),0))*texel;
    vec2 row=vec2(0.,texel.y);
    vec4 q_hi=textureLod(motion_bank,address,0.);
    vec4 q_lo=textureLod(motion_bank,address+row,0.);
    vec3 t_hi=textureLod(motion_bank,address+2.0*row,0.).rgb;
    vec3 t_lo=textureLod(motion_bank,address+3.0*row,0.).rgb;
    vec4 q=normalize((q_hi*256.+q_lo)*(2./257.)-1.);
    vec3 translation=((t_hi*256.+t_lo)/257.-.5)*6.;
    pos=rotated(q,bind_vertex)+translation;
    nrm=rotated(q,bind_normal);
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
    vec2 tile=clip_address(sample_kit,clip,phase);
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
        vec2 foot_tile=clip_address(kit,travelling_attack_legs,travelling_leg_phase);
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
    ivec2 swatch=ivec2(UV*vec2(8.,4.));
    // Shield panels have separate UV islands. A single bind-space band crosses their seams
    // and follows the left hand through a block or bash.
    shield_face=(VERTEX.xy-vec2(-.273,.966))/vec2(.48,.79);
    bool cape=swatch.y==2 && (swatch.x==3 || swatch.x==7);
    if (cape) {
        // Folded at the shoulder fastening, free at the two tails. The hem lags
        // movement and weapon release without adding a runtime cloth solver.
        float hem_weight=1.0-smoothstep(.55,1.395,VERTEX.y);
        bool moving=state==5 || (state==0 && INSTANCE_CUSTOM.g>.001);
        float travel=moving ? ((clip>=23 || state==5) ? 1.0 : .57) : 0.0;
        float beat=(state==1 || state==2) ? sin(clamp(phase,0.,1.)*3.14159) : 0.;
        float ripple=sin(6.28318*INSTANCE_CUSTOM.b-VERTEX.y*4.1+VERTEX.x*5.0);
        pos.z-=hem_weight*(travel*(.072+.023*ripple)+beat*.045);
        pos.x+=hem_weight*(travel*.024*ripple+beat*(state==1 ? .045 : -.050));
    }
    // Broad painted occlusion stays on the garment as the shoulder or hem turns.
    float armhole=smoothstep(.12,.23,abs(VERTEX.x))*(1.0-smoothstep(.035,.105,abs(VERTEX.y-1.285)));
    float hem=1.0-smoothstep(.52,1.38,VERTEX.y);
    sewn_shadow=.12*armhole+.125*hem+.055*max(-NORMAL.y,0.0);
    VERTEX=pos;
    NORMAL=normalize(nrm);
    float wear=INSTANCE_CUSTOM.a*8.0;
    cloth_lot=floor(wear)/7.0;
    if (swatch==ivec2(0,2) && !player_costume) {
        if (cloth_lot>.72) UV+=vec2(.125,.25);
        else if (cloth_lot>.31) UV.y+=.25;
    }
    cloth_panel=int(floor(UV.x*8.0))+8*int(floor(UV.y*4.0));
    flash=clamp((fract(wear)-.055)/.88,0.0,1.0);
    fallen=state==7 ? smoothstep(0.,.8,phase) : 0.;
}
void fragment() {
    vec3 ink = texture(cloth_atlas, UV).rgb;
    // Team dye runs through fabric panels. Iron, hands, hair, and blade bevels retain
    // their own values even where soldiers overlap in the default orthographic view.
    float dye = 0.0;
    if (cloth_panel == 1 || cloth_panel == 27 || cloth_panel == 19) dye = 0.97;
    else if (cloth_panel == 22 || cloth_panel == 31) dye = 0.84;
    else if (cloth_panel == 11 || cloth_panel == 26) dye = 0.43;
    vec3 bolt = livery.rgb * mix(0.91, 1.09, cloth_lot);
    float fold = dot(ink, vec3(.28, .56, .16));
    float mid = OUTPUT_IS_SRGB ? .73 : .52;
    vec3 colour = mix(ink, bolt * clamp(fold / mid, .64, 1.24), dye);
    if (cloth_panel == 13) {
        float stripe = abs(shield_face.y - .10 * shield_face.x - .025);
        float edge = clamp(fwidth(stripe), .006, .065);
        colour = mix(colour, bolt, .93 * (1.0 - smoothstep(.12-edge, .12+edge, stripe)));
    }
    float silhouette = 1.0 - smoothstep(.045, .30, abs(dot(normalize(NORMAL), normalize(VIEW))));
    colour *= (1.0 - .105 * silhouette) * (1.0 - .42 * sewn_shadow);
    colour *= mix(1.0, .73, fallen);
    ALBEDO = mix(colour, vec3(.65,.35,.19), flash * .24);
    ROUGHNESS = .93;
    SPECULAR = 0.0;
}

#include "res://scripts/field/cloth_light.gdshaderinc"
