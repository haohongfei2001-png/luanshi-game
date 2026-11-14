shader_type canvas_item;
render_mode unshaded;
uniform sampler2D weights_tex : filter_nearest, repeat_disable;
uniform sampler2D rest_tex : filter_nearest, repeat_disable;
uniform sampler2D dq_tex : filter_nearest, repeat_disable;
vec4 mulq(vec4 a,vec4 b){return vec4(a.x*b.x-dot(a.yzw,b.yzw),a.x*b.yzw+b.x*a.yzw+cross(a.yzw,b.yzw));}
vec3 encode_value(float value){uint n=uint(round(clamp((value+4.0)/8.0,0.0,1.0)*16777215.0));return vec3(float(n&255u),float((n>>8u)&255u),float((n>>16u)&255u))/255.0;}
void fragment(){
 int v=int(FRAGCOORD.x);int axis=int(FRAGCOORD.y);
 vec4 q=vec4(0.0),d=vec4(0.0),ref=vec4(0.0);bool first=true;
 for(int i=0;i<5;i++){
  vec4 w=texelFetch(weights_tex,ivec2(v,i),0);if(w.y==0.0){continue;}
  int bone=int(w.x);vec4 b=texelFetch(dq_tex,ivec2(bone,0),0);vec4 bd=texelFetch(dq_tex,ivec2(bone,1),0);
  if(first){ref=b;first=false;}float s=dot(ref,b)<0.0?-1.0:1.0;q+=b*w.y*s;d+=bd*w.y*s;
 }
 float norm=length(q);q/=norm;d/=norm;vec4 conj=vec4(q.x,-q.yzw);
 vec3 p=texelFetch(rest_tex,ivec2(v,0),0).xyz;
 vec3 result=mulq(mulq(q,vec4(0.0,p)),conj).yzw+2.0*mulq(d,conj).yzw;
 COLOR=vec4(encode_value(result[axis]),1.0);
}
