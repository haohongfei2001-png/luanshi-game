shader_type spatial;
render_mode cull_disabled;
uniform sampler2D position_cache : filter_nearest, repeat_disable;
uniform sampler2D normal_cache : filter_nearest, repeat_disable;
uniform sampler2D diffuse_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 base_color = vec4(0.4,0.4,0.4,1.0); // Explicit LINEAR source BSDF values, no sRGB re-decoding.
uniform bool has_diffuse = false;
uniform bool uses_alpha = false;
uniform float roughness_value = 0.8;
uniform float metal_value = 0.0;
uniform int vertex_count;
uniform float sample_frame = 0.0;
uniform int frame_limit;
vec3 read_value(sampler2D tex, int frame, int id) {
 int index=frame*vertex_count+id;
 return texelFetch(tex,ivec2(index%1024,index/1024),0).xyz;
}
void vertex() {
 int a=int(floor(sample_frame));int b=min(a+1,frame_limit);
 VERTEX=mix(read_value(position_cache,a,VERTEX_ID),read_value(position_cache,b,VERTEX_ID),fract(sample_frame));
 NORMAL=normalize(mix(read_value(normal_cache,a,VERTEX_ID),read_value(normal_cache,b,VERTEX_ID),fract(sample_frame)));
}
void fragment() {
 vec4 c=base_color;
 if(has_diffuse)c*=texture(diffuse_texture,UV);
 ALBEDO=c.rgb;ROUGHNESS=roughness_value;METALLIC=metal_value;
 ALPHA=uses_alpha?c.a:1.0;
 ALPHA_SCISSOR_THRESHOLD=0.4;
}
