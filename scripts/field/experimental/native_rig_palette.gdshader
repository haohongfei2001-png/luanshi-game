shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Diagnostic only. No production animation-state mapping or costume override.
// Each instance uses custom.r = first exact sample row, .g = second row,
// .b = blend. Float texels preserve all imported joints and eight weights.
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 albedo : source_color = vec4(0.72,0.72,0.72,1.0);
uniform bool has_albedo_texture = false;

void influence(int bone, int row, vec3 point, vec3 normal, out vec3 p, out vec3 n) {
    int x=bone*6;
    vec4 h=vec4(point,1.0);
    p=vec3(dot(texelFetch(palette,ivec2(x,row),0),h),
           dot(texelFetch(palette,ivec2(x+1,row),0),h),
           dot(texelFetch(palette,ivec2(x+2,row),0),h));
    n=vec3(dot(texelFetch(palette,ivec2(x+3,row),0).xyz,normal),
           dot(texelFetch(palette,ivec2(x+4,row),0).xyz,normal),
           dot(texelFetch(palette,ivec2(x+5,row),0).xyz,normal));
}
void vertex() {
    vec3 p=vec3(0.0), n=vec3(0.0), t=vec3(0.0), b=vec3(0.0);
    for (int i=0;i<8;i++) {
        float weight=i<4?CUSTOM1[i]:CUSTOM3[i-4];
        if (weight<=0.0) {continue;}
        int bone=int(round(i<4?CUSTOM0[i]:CUSTOM2[i-4]));
        vec3 ap,an,bp,bn,unused,at,bt,ab,bb;
        influence(bone,int(round(INSTANCE_CUSTOM.r)),VERTEX,NORMAL,ap,an);
        influence(bone,int(round(INSTANCE_CUSTOM.g)),VERTEX,NORMAL,bp,bn);
        influence(bone,int(round(INSTANCE_CUSTOM.r)),VERTEX,TANGENT,unused,at);
        influence(bone,int(round(INSTANCE_CUSTOM.g)),VERTEX,TANGENT,unused,bt);
        influence(bone,int(round(INSTANCE_CUSTOM.r)),VERTEX,BINORMAL,unused,ab);
        influence(bone,int(round(INSTANCE_CUSTOM.g)),VERTEX,BINORMAL,unused,bb);
        p+=weight*mix(ap,bp,INSTANCE_CUSTOM.b);
        n+=weight*mix(an,bn,INSTANCE_CUSTOM.b);
        t+=weight*mix(at,bt,INSTANCE_CUSTOM.b);
        b+=weight*mix(ab,bb,INSTANCE_CUSTOM.b);
    }
    VERTEX=p; NORMAL=normalize(n);
    if(length(t)>0.00001) {TANGENT=normalize(t);}
    if(length(b)>0.00001) {BINORMAL=normalize(b);}
}
void fragment() {
    vec4 pigment=albedo;
    if(has_albedo_texture) {pigment*=texture(albedo_texture,UV);}
    ALBEDO=pigment.rgb;
    ROUGHNESS=0.85;
}
