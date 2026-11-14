shader_type canvas_item;
render_mode unshaded;
uniform sampler2D cage_tex : filter_nearest, repeat_disable;
uniform sampler2D response_tex : filter_nearest, repeat_disable;
uniform sampler2D cage_rest_tex : filter_nearest, repeat_disable;
uniform sampler2D top_rest_tex : filter_nearest, repeat_disable;
uniform mat3 cage_to_top;
float decode_value(vec3 rgb){uvec3 b=uvec3(round(rgb*255.0));uint n=b.x|(b.y<<8u)|(b.z<<16u);return float(n)/16777215.0*8.0-4.0;}
vec3 encode_value(float value){uint n=uint(round(clamp((value+4.0)/8.0,0.0,1.0)*16777215.0));return vec3(float(n&255u),float((n>>8u)&255u),float((n>>16u)&255u))/255.0;}
void fragment(){
 int v=int(FRAGCOORD.x);int axis=int(FRAGCOORD.y);vec3 delta=vec3(0.0);
 for(int i=0;i<218;i++){
  vec4 h=texelFetch(response_tex,ivec2(v,i),0);if(h.y==0.0){continue;}int c=int(h.x);
  vec3 p=vec3(decode_value(texelFetch(cage_tex,ivec2(c,0),0).rgb),decode_value(texelFetch(cage_tex,ivec2(c,1),0).rgb),decode_value(texelFetch(cage_tex,ivec2(c,2),0).rgb));
  delta+=(p-texelFetch(cage_rest_tex,ivec2(c,0),0).xyz)*h.y;
 }
 vec3 result=texelFetch(top_rest_tex,ivec2(v,0),0).xyz+cage_to_top*delta;
 COLOR=vec4(encode_value(result[axis]),1.0);
}
