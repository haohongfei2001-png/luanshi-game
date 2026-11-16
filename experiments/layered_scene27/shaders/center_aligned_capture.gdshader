shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D source_radiance:source_color,filter_linear_mipmap;
uniform sampler2D capture_depth_rf:filter_nearest,repeat_disable;
uniform sampler2D capture_triangle_owner_rf:filter_nearest,repeat_disable;
uniform mat4 capture_world_to_clip;
uniform vec3 capture_origin;
uniform vec3 capture_basis_x;
uniform vec3 capture_basis_y;
uniform vec3 capture_basis_z;
uniform float capture_tan_half_fov;
uniform vec4 authored_world_plane;
uniform float authored_triangle_id;
uniform bool has_observed_art=true;
uniform float depth_tolerance_m=.02;
varying vec4 capture_position;
void vertex(){capture_position=capture_world_to_clip*MODEL_MATRIX*vec4(VERTEX,1.);}
void fragment(){
 vec2 uv=capture_position.xy/capture_position.w*vec2(.5,-.5)+vec2(.5);
 vec3 result=vec3(.30,.18,.34);
 if(has_observed_art && capture_position.w>0. && all(greaterThanEqual(uv,vec2(0.))) && all(lessThan(uv,vec2(1.)))){
  vec2 center=(floor(uv*vec2(1672.,941.))+vec2(.5))/vec2(1672.,941.);
  float owner=texture(capture_triangle_owner_rf,center).r;
  vec3 ray=capture_basis_x*((center.x*2.-1.)*(2560./1440.)*capture_tan_half_fov)+capture_basis_y*((1.-center.y*2.)*capture_tan_half_fov)-capture_basis_z;
  float denominator=dot(authored_world_plane.xyz,ray);
  if(owner< -1.5){result=vec3(.75,.28,.04);}
  else if(abs(owner-authored_triangle_id)<.25 && abs(denominator)>1.e-8){
   float current_depth=-(dot(authored_world_plane.xyz,capture_origin)+authored_world_plane.w)/denominator;
   if(current_depth>0. && abs(current_depth-texture(capture_depth_rf,center).r)<=depth_tolerance_m){result=texture(source_radiance,uv).rgb;}
  }
 }
 ALBEDO=result;
}
