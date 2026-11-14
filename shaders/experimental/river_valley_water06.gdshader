shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Actual surveyed bathymetry, not a rectangular tinted board or screen effect.
uniform vec4 shallow_water : source_color = vec4(0.30,0.34,0.27,1.0);
uniform vec4 deep_water : source_color = vec4(0.16,0.24,0.23,1.0);
varying vec2 metric_position;
void vertex(){metric_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 float depth=COLOR.r*4.0;
 float absorption=1.0-exp(-depth*0.85);
 ALBEDO=mix(shallow_water.rgb,deep_water.rgb,absorption);
 // Broad non-collinear finite-depth wave spectrum. No single parallel stripe
 // dominates the whole river; phase advection varies gently along the channel.
 vec2 gradient=vec2(0.0);
 float depth_damping=smoothstep(0.0,0.65,depth);
 for(int i=0;i<12;i++){
  float n=float(i);
  float angle=n*2.39996323+0.3;
  vec2 direction=vec2(cos(angle),sin(angle));
  float wavelength=0.24*pow(1.29,n);
  float k=2.0*PI/wavelength;
  float phase=dot(metric_position,direction)*k+sqrt(9.81*k)*TIME+n*n*0.73;
  float filter_weight=1.0-smoothstep(0.75,2.6,fwidth(phase));
  float slope=0.024/(1.0+n*0.10);
  gradient+=direction*cos(phase)*slope*filter_weight*depth_damping;
 }
 vec3 normal_world=normalize(vec3(-gradient.x,1.0,-gradient.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal_world,0.0)).xyz);
 ROUGHNESS=0.42;METALLIC=0.0;SPECULAR=0.32;
}
