shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
// Opt-in exact-pose diagnostic. Native vertex attributes, including extra UVs,
// stay intact. No animation state, facing, or authored weight is invented here.
uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D influence_table : filter_nearest, repeat_disable;
uniform int influence_groups = 1;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform bool use_albedo = false;
uniform bool use_normal = false;
uniform bool use_roughness = false;
uniform bool use_metallic = false;
uniform float normal_scale = 1.0;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform float specular = 0.5;
uniform vec4 roughness_channel = vec4(1.0,0.0,0.0,0.0);
uniform vec4 metallic_channel = vec4(1.0,0.0,0.0,0.0);
vec4 weight_texel(int index) {
    int width=textureSize(influence_table,0).x;
    return texelFetch(influence_table,ivec2(index%width,index/width),0);
}
mat4 bind_pose(int bone,int frame) {
    int x=bone*3;
    return transpose(mat4(texelFetch(palette,ivec2(x,frame),0),
                          texelFetch(palette,ivec2(x+1,frame),0),
                          texelFetch(palette,ivec2(x+2,frame),0),vec4(0.0,0.0,0.0,1.0)));
}
void vertex() {
    mat4 pose=mat4(0.0);
    for(int group=0;group<4;group++) {
        if(group>=influence_groups) {break;}
        int index=VERTEX_ID*influence_groups*2+group*2;
        vec4 joints=weight_texel(index);
        vec4 weights=weight_texel(index+1);
        for(int slot=0;slot<4;slot++) {
            if(weights[slot]<=0.0) {continue;}
            pose+=weights[slot]*bind_pose(int(round(joints[slot])),int(round(INSTANCE_CUSTOM.r)));
        }
    }
    VERTEX=(pose*vec4(VERTEX,1.0)).xyz;
    // Native GLES3 skins normal/tangent, then rebuilds binormal from their
    // cross product and authored handedness, not a separately skinned vector.
    float handedness=sign(dot(cross(NORMAL,TANGENT),BINORMAL));
    NORMAL=normalize(mat3(pose)*NORMAL);
    if(length(TANGENT)>0.00001) {
        TANGENT=normalize(mat3(pose)*TANGENT);
        BINORMAL=normalize(cross(NORMAL,TANGENT))*handedness;
    }
}
void fragment() {
    vec4 pigment=albedo;
    if(use_albedo) {pigment*=texture(albedo_texture,UV);}
    if(use_vertex_color) {pigment*=COLOR;}
    ALBEDO=pigment.rgb;
    ROUGHNESS=roughness*(use_roughness?dot(texture(roughness_texture,UV),roughness_channel):1.0);
    METALLIC=metallic*(use_metallic?dot(texture(metallic_texture,UV),metallic_channel):1.0);
    SPECULAR=specular;
    if(use_normal) {NORMAL_MAP=texture(normal_texture,UV).rgb;NORMAL_MAP_DEPTH=normal_scale;}
}
