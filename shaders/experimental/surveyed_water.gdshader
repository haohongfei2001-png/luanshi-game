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
 // Small wind-gravity slopes at metre wavelengths. No vertex displacement,
 // opacity trick, SSR, foam glitter, screen blur or simulated-flow claim.
 vec2 a=vec2(0.94,0.34);
 vec2 b=vec2(-0.28,0.96);
 vec2 gradient=0.035*a*cos(dot(metric_position,a)*4.1+TIME*1.1)
             +0.022*b*cos(dot(metric_position,b)*2.0-TIME*0.7);
 vec3 normal_world=normalize(vec3(-gradient.x,1.0,-gradient.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal_world,0.0)).xyz);
 ROUGHNESS=0.42;METALLIC=0.0;SPECULAR=0.32;
}
