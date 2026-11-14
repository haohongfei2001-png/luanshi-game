shader_type sky;
uniform sampler2D source_panorama : filter_linear_mipmap, repeat_enable;
uniform mat3 world_to_source;
void sky() {
 vec3 d=normalize(world_to_source*EYEDIR);
 float u=atan(d.x,-d.z)/(2.0*PI);
 if(u<0.0){u+=1.0;}
 COLOR=texture(source_panorama,vec2(u,acos(clamp(d.y,-1.0,1.0))/PI)).rgb;
}
