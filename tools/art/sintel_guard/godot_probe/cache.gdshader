shader_type spatial;
render_mode cull_disabled;
uniform sampler2D position_cache : filter_nearest, repeat_disable;
uniform sampler2D normal_cache : filter_nearest, repeat_disable;
uniform int vertex_count;
uniform float sample_frame=0.0;
vec3 read_cache(sampler2D cache, int frame, int id) {
 int offset=frame*vertex_count+id;
 return texelFetch(cache,ivec2(offset%1024,offset/1024),0).xyz;
}
void vertex(){
 int first=int(floor(sample_frame));int second=min(first+1,48);float weight=fract(sample_frame);
 VERTEX=mix(read_cache(position_cache,first,VERTEX_ID),read_cache(position_cache,second,VERTEX_ID),weight);
 NORMAL=normalize(mix(read_cache(normal_cache,first,VERTEX_ID),read_cache(normal_cache,second,VERTEX_ID),weight));
}
void fragment(){ALBEDO=vec3(.28,.34,.38);ROUGHNESS=.85;}
