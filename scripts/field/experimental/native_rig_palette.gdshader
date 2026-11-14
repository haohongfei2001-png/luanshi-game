shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// Diagnostic only. No production animation-state mapping or costume override.
// Each instance uses custom.r = first exact sample row, .g = second row,
// .b = blend. Float texels preserve all imported joints and eight weights.
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 albedo : source_color = vec4(0.72,0.72,0.72,1.0);
uniform bool has_albedo_texture = false;

mat4 bind_pose(int bone, int row) {
    int x=bone*3;
    return transpose(mat4(texelFetch(palette,ivec2(x,row),0),
                          texelFetch(palette,ivec2(x+1,row),0),
                          texelFetch(palette,ivec2(x+2,row),0),vec4(0.0,0.0,0.0,1.0)));
}
void vertex() {
    mat4 pose=mat4(0.0);
    for (int i=0;i<8;i++) {
        float weight=i<4?CUSTOM1[i]:CUSTOM3[i-4];
        if (weight<=0.0) {continue;}
        int bone=int(round(i<4?CUSTOM0[i]:CUSTOM2[i-4]));
        pose+=weight*mix(bind_pose(bone,int(round(INSTANCE_CUSTOM.r))),
                         bind_pose(bone,int(round(INSTANCE_CUSTOM.g))),INSTANCE_CUSTOM.b);
    }
    // Match actual GLES3 skeleton.glsl, not CPU bake's orthonormalized normals.
    // Normal/tangent follow the blended full affine basis, including bone scale.
    VERTEX=(pose*vec4(VERTEX,1.0)).xyz;
    NORMAL=normalize(mat3(pose)*NORMAL);
    if(length(TANGENT)>0.00001) {TANGENT=normalize(mat3(pose)*TANGENT);}
    if(length(BINORMAL)>0.00001) {BINORMAL=normalize(mat3(pose)*BINORMAL);}
}
void fragment() {
    vec4 pigment=albedo;
    if(has_albedo_texture) {pigment*=texture(albedo_texture,UV);}
    ALBEDO=pigment.rgb;
    ROUGHNESS=0.85;
}
