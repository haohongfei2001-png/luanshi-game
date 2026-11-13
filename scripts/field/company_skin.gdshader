shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D cloth_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D issue_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D motion_bank : filter_linear, repeat_disable;
uniform vec4 livery : source_color = vec4(.28,.40,.40,1.);
uniform vec4 shoulder_dye : source_color = vec4(0.0);
uniform int kit = 0;
uniform int travelling_attack_legs = -1;
uniform bool player_costume = false;
uniform bool field_carries = false;
uniform float travelling_leg_phase = 0.0;
varying flat float flash;
varying flat float cloth_lot;
varying flat float fallen;
varying float sewn_shadow;
varying flat int cloth_panel;
varying vec2 shield_face;
varying vec3 bind_point;

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
    bind_point=VERTEX;
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
        if (field_carries && slot==3) clip=int(floor(phase*32.0));
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
    // Same four samples per joint. Only a foot-soldier's carried posture
    // changes; alternate windup/recovery strips meet the identical impact pose.
    if (field_carries && code<64 && sample_kit==kit) {
        int lot=int(floor(INSTANCE_CUSTOM.a*8.0));
        int variant=(lot==1 || lot==4) ? 1 : ((lot==2 || lot==5 || lot==7) ? 2 : 0);
        int carrier=kit==3 ? 0 : (kit==4 ? 1 : (kit==7 ? 2 : -1));
        int strip=clip==1 ? 0 : (clip==0 ? 1 : ((clip>=16 && clip<=22) ? clip-14 : ((clip>=2 && clip<=9) ? clip+7 : -1)));
        if (variant>0 && carrier>=0 && strip>=0) {
            tile.y=float(4*(279+carrier*34+(variant-1)*17+strip))+.5;
        }
    }
    // After the 279 standard and 102 carry strips: four finite reaction clips
    // per kit. The two spare guard/stagger slot codes carry the confirmed side.
    if ((clip==10 || clip==11) && (slot==1 || slot==2)) {
        int reaction=(clip==10 ? 0 : 2)+slot-1;
        tile.y=float(4*(381+kit*4+reaction))+.5;
    }
    // Preserve ordinary soldiers' identities across LODs without extra mesh
    // instances. Only first-joint head skin changes below the skull/helmet seam.
    ivec2 swatch=ivec2(UV*vec2(8.,4.));
    if (first==2 && !player_costume &&
            (swatch==ivec2(0,2) || swatch==ivec2(0,1)) && VERTEX.y>1.447) {
        float lot=floor(INSTANCE_CUSTOM.a*8.0);
        float shape=lot<2.5 ? 0.0 : (lot<5.5 ? -1.0 : 1.0);
        float cheek=1.-smoothstep(1.547,1.646,VERTEX.y);
        float jaw=smoothstep(1.447,1.475,VERTEX.y)*(1.-smoothstep(1.492,1.584,VERTEX.y));
        VERTEX.x*=1.0+.115*shape*cheek;
        VERTEX.y+=.005*shape*jaw;
        VERTEX.z+=.0065*shape*jaw*smoothstep(.025,.091,VERTEX.z);
    }
    vec3 pos,nrm;
    skin(first,tile,VERTEX,NORMAL,pos,nrm);
    if(first!=second && blend<.999) {
        vec3 other_pos,other_nrm;
        skin(second,tile,VERTEX,NORMAL,other_pos,other_nrm);
        pos=mix(other_pos,pos,blend);
        nrm=mix(other_nrm,nrm,blend);
    }
    // The nocked arrow alone is rigidly attached to joint 15 (the bowstring
    // endpoints blend this joint with the stave). Keep it on the string through
    // the release tick. The live projectile becomes visible in RECOVER.
    if (kit==5 && first==15 && second==15 &&
            (state!=1 || slot==3 || sample_kit!=kit)) {
        pos=vec3(0.);
    }
    // Lean into the actual opponent. Hands, both ends of a shaft, the blade
    // and the shield all undergo one rigid change about the waist. Flexible
    // cloth carries the transition to the original leg and planted-foot pose.
    // The bound is twenty degrees; the half-angle approximation is normalized.
    if (field_carries && code<64 && (kit==3 || kit==7)) {
        float ready=0.;
        if (state==0 && slot==3) {
            ready=float(int(floor(INSTANCE_CUSTOM.g*1024.0))%32)/31.;
        } else if (state==1 || state==2) {
            ready=INSTANCE_CUSTOM.b*(state==1 ? 1.-smoothstep(0.,.57,phase) : smoothstep(.56,1.,phase));
        }
        if (ready>0.) {
            bool rigid=first==2 || (first>=3 && first<=8) || first==15;
            float load=rigid ? ready : ready*smoothstep(.63,1.04,bind_point.y);
            if (load>0.) {
                // The spearman reaches along the long axis; the shield bearer
                // drops his left shoulder behind the board while stepping in.
                vec3 half_turn=kit==3 ? vec3(.149,-.042,.019) : vec3(.096,.070,.059);
                vec4 q=normalize(vec4(half_turn*load,1.));
                vec3 pivot=vec3(0.,.89,.01);
                pos=pivot+rotated(q,pos-pivot)+vec3(kit==3?.015:-.026,-.033,.027)*load;
                nrm=rotated(q,nrm);
            }
        }
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

    // Shield panels have separate UV islands. A single bind-space band crosses their seams
    // and follows the left hand through a block or bash.
    shield_face=(VERTEX.xy-vec2(-.273,.976))/vec2(.568,1.005);
    bool cape=swatch.y==2 && (swatch.x==3 || swatch.x==7);
    if (cape) {
        // Folded at the shoulder fastening, free at the two tails. The hem lags
        // movement and weapon release without adding a runtime cloth solver.
        float hem_weight=1.0-smoothstep(.55,1.395,VERTEX.y);
        bool moving=state==5 || (state==0 && INSTANCE_CUSTOM.g>.001);
        float travel=moving ? ((clip>=23 || state==5) ? 1.0 : .57) : 0.0;
        // Carry the free hem through the windup / recovery boundary. Its
        // peak follows release instead of snapping back between the two clips.
        float beat=state==1 ? smoothstep(.58,1.,phase) :
                   (state==2 ? 1.-smoothstep(.07,.93,phase) : 0.);
        float ripple=sin(6.28318*INSTANCE_CUSTOM.b-VERTEX.y*4.1+VERTEX.x*5.0);
        pos.z-=hem_weight*(travel*(.109+.029*ripple)+beat*.147);
        pos.x+=hem_weight*(travel*.034*ripple-beat*.065);
    }
    // The free end of a cloth knot catches up after the head turns. Its root stays
    // with the original skull joint, and the same gait phase drives all three LODs.
    if ((swatch==ivec2(2,2) || swatch==ivec2(1,0)) && first==2 && VERTEX.z<-.082) {
        float loose=1.0-smoothstep(1.44,1.627,VERTEX.y);
        float pace=(state==5 || (state==0 && INSTANCE_CUSTOM.g>.001)) ? 1.0 : .18;
        float flick=sin(6.28318*INSTANCE_CUSTOM.b+VERTEX.x*7.0);
        pos.x+=loose*(.012*flick*pace);
        pos.z-=loose*.018*pace;
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
    cloth_panel=UV.x>=2.0 ? 32 : int(floor(UV.x*8.0))+8*int(floor(UV.y*4.0));
    flash=clamp((fract(wear)-.055)/.88,0.0,1.0);
    fallen=state==7 ? smoothstep(0.,.8,phase) : 0.;
}
void fragment() {
    vec4 swatch = cloth_panel==32 ? texture(issue_atlas, UV-vec2(2.0,0.0)) : texture(cloth_atlas, UV);
    vec3 ink = swatch.rgb;
    // Team dye runs through fabric panels. Iron, hands, hair, and blade bevels retain
    // their own values even where soldiers overlap in the default orthographic view.
    float dye = 0.0;
    if (cloth_panel==32) dye=swatch.a;
    else if (cloth_panel == 1 || cloth_panel == 27 || cloth_panel == 19) dye = .96;
    else if (cloth_panel == 22) dye = .82;
    else if (cloth_panel == 26) dye = .66;
    else if (cloth_panel == 11) dye = .54;
    // Diluting indigo or madder in a common grey-brown ground keeps the
    // troop colours legible without painting armour and entire bodies bright.
    vec3 wool_ground=OUTPUT_IS_SRGB ? vec3(.245,.250,.230) : vec3(.049,.051,.043);
    vec3 bolt=mix(livery.rgb,wool_ground,.25+.15*cloth_lot)*mix(.84,1.04,cloth_lot);
    // Common coats were cut from several dye lots. Keep a coloured collar or
    // overskirt even on the pale archer's body; hands/iron never inherit dye.
    if (!player_costume && (cloth_panel==27 || cloth_panel==1)) {
        if (kit==5 || kit==6) {
            vec3 flax=OUTPUT_IS_SRGB ? vec3(.47,.43,.34) : vec3(.18,.15,.095);
            bolt=mix(bolt,flax,.47+.17*cloth_lot);
        } else if (kit==3 || kit==7 || kit==4) {
            bolt*=.85;
        }
    }
    float dyed_shoulder=0.;
    // The upper part of an issued garment is sewn from a deeper bolt of
    // indigo or madder. The officer's iron and an archer's leather belt stay
    // in their original material; only woven cloth has coverage in this mask.
    if (shoulder_dye.a>.5) {
        float yoke=0.;
        if (cloth_panel==32) {
            if (kit==5 || kit==6) {
                // One crossed panel of a short robe continues over the back.
                // Below the girdle the working shirt keeps the lighter flax.
                float overlap=mix(-.16,.44,smoothstep(-.08,.09,bind_point.z));
                float shoulder_line=bind_point.y+overlap*bind_point.x;
                float outer_sleeve=smoothstep(.15,.22,abs(bind_point.x))*smoothstep(1.026,1.105,bind_point.y);
                yoke=max(smoothstep(1.104,1.142,shoulder_line),outer_sleeve);
            } else {
                // The iron courses have zero paint coverage. Only the tunic
                // between the shoulder straps and the edge below the armhole
                // picks up colour, including the turn towards the shield arm.
                yoke=smoothstep(1.015,1.113,bind_point.y);
            }
            dye=mix(dye,max(dye,smoothstep(.24,.76,dye)),.82*yoke);
        } else if (cloth_panel==1 || cloth_panel==19 || cloth_panel==27 || cloth_panel==11) {
            yoke=smoothstep(1.035,1.173,bind_point.y);
            if (cloth_panel==19) yoke=1.;
            dye=mix(dye,.97,yoke);
        }
        if (player_costume && cloth_panel!=19) yoke=0.;
        dyed_shoulder=yoke;
        bolt=mix(bolt,shoulder_dye.rgb*mix(.87,1.015,cloth_lot),yoke);
    }
    float fold = dot(ink, vec3(.28, .56, .16));
    float mid = OUTPUT_IS_SRGB ? .73 : .52;
    // White yarn highlights on dyed wool turn softly. Keep iron, skin and the
    // lacquer rim on the existing albedo response.
    float cloth_value=clamp(fold/mid,.64,mix(1.24,1.09,dyed_shoulder));
    vec3 colour=mix(ink,bolt*cloth_value,dye);
    if (cloth_panel==32 && (kit==5 || kit==6)) {
        // The original cross-collar already forms a woven facing. Preserve its
        // darker value where the front crosses and where the back cuffs the
        // neck; without the facing, sun on madder can read as another skin area.
        float top=smoothstep(1.19,1.345,bind_point.y);
        float turn=1.-smoothstep(.12,.235,abs(bind_point.x));
        float facing=(1.-smoothstep(mid*.28,mid*.84,fold))*top*turn*dye;
        colour*=1.-.24*facing;
    }
    if (!player_costume && cloth_panel==0) {
        // The undyed coat is slightly warmer than its sleeves. Light from above
        // falls off under the folded shoulder, leaving the waist legible from above.
        // A few lots have grey over-dyed sleeves. The same soldier keeps
        // his issued blouse in every camera and pose.
        vec3 worn=mix(vec3(.72,.79,.80),vec3(.86,.86,.80),cloth_lot);
        float overdye=.14+.27*smoothstep(.31,.87,cloth_lot);
        colour=mix(colour*worn,bolt*.91,overdye);
    }
    if (cloth_panel==3 || cloth_panel==30 || cloth_panel==28) {
        // The visible hauberk follows the ribs in one warm, dark iron mass.
        // A broad value turn over the back survives mip levels at 22 metres.
        float ridge=1.-smoothstep(.035,.225,abs(bind_point.x));
        float reflected=smoothstep(.11,.22,abs(bind_point.x));
        colour*=.91+.095*ridge+.045*reflected;
    }
    if (cloth_panel==15 || cloth_panel==12) colour*=.82;
    // The fold runs down the fabric on the sloped upper arm. Its inner
    // valley continues through different triangles on the raised sleeves.
    if (cloth_panel==0 || cloth_panel==1 || cloth_panel==11 || cloth_panel==27) {
        float sleeve=smoothstep(.183,.238,abs(bind_point.x))*
                     smoothstep(1.07,1.12,bind_point.y)*(1.-smoothstep(1.35,1.41,bind_point.y));
        float diagonal=bind_point.y-1.196+.51*bind_point.z+.32*(abs(bind_point.x)-.248);
        float sleeve_fold=smoothstep(-.043,-.006,diagonal)*(1.-smoothstep(-.004,.018,diagonal));
        colour*=1.-.28*sleeve*sleeve_fold;
    }
    // A coarse underfold survives mipmapping; irregular fine weave does not.
    // At the edge of a dark sleeve it stays subordinate to the hand and weapon.
    if (cloth_panel==1 || cloth_panel==22 || cloth_panel==27) {
        vec2 cloth_uv=fract(UV*vec2(8.,4.));
        float tuck=abs(cloth_uv.x-.20-.44*cloth_uv.y);
        float crease=(1.-smoothstep(.018,.12,tuck))*smoothstep(.12,.56,cloth_uv.y);
        colour*=1.-crease*.15;
    }
    if (cloth_panel == 13) {
        // Lacquer sits in two broad fields on either side of an exposed timber rib.
        // Bind-space coordinates run continuously over the curved planks.
        float panel_edge=abs(shield_face.x)+.22*shield_face.y;
        float width=clamp(fwidth(panel_edge),.006,.044);
        float paint=smoothstep(.10-width,.10+width,panel_edge)*
                    (1.-smoothstep(.40-width,.40+width,panel_edge));
        colour=mix(colour,bolt*.88,.83*paint);
    }
    float silhouette = 1.0 - smoothstep(.045, .30, abs(dot(normalize(NORMAL), normalize(VIEW))));
    colour *= (1.0 - .105 * silhouette) * (1.0 - .42 * sewn_shadow);
    colour *= mix(1.0, .73, fallen);
    ALBEDO = mix(colour, vec3(.65,.35,.19), flash * .24);
    ROUGHNESS = .93;
    SPECULAR = 0.0;
}

#include "res://scripts/field/cloth_light.gdshaderinc"
