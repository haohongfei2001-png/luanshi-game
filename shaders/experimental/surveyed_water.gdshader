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
 // Metre-scale wind wave spectrum, not a specular/brightness boost.
 // Heights are 6mm,10mm,20mm at .35m,.75m,2.8m wavelengths.
 // Analytic screen-footprint filtering avoids aliasing distant ripples.
 vec2 a=normalize(vec2(0.94,0.34));
 vec2 b=normalize(vec2(-0.28,0.96));
 vec2 c=normalize(vec2(0.76,-0.65));
 float pa=dot(metric_position,a)*17.95196+TIME*2.8;
 float pb=dot(metric_position,b)*8.37758-TIME*1.9;
 float pc=dot(metric_position,c)*2.24399+TIME*0.9;
 float fa=1.0-smoothstep(1.0,3.0,fwidth(pa));
 float fb=1.0-smoothstep(1.0,3.0,fwidth(pb));
 float fc=1.0-smoothstep(1.0,3.0,fwidth(pc));
 vec2 gradient=0.10771*a*cos(pa)*fa+0.08378*b*cos(pb)*fb+0.04488*c*cos(pc)*fc;
 vec3 normal_world=normalize(vec3(-gradient.x,1.0,-gradient.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal_world,0.0)).xyz);
 ROUGHNESS=0.42;METALLIC=0.0;SPECULAR=0.32;
}
