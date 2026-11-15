shader_type spatial;
render_mode ambient_light_disabled,specular_disabled;
uniform sampler2D source_radiance:source_color,filter_linear_mipmap;
uniform mat4 capture_world_to_clip;
varying vec4 source_projected;
void vertex(){source_projected=capture_world_to_clip*MODEL_MATRIX*vec4(VERTEX,1.);}
vec2 source_uv(){return source_projected.xy/source_projected.w*vec2(.5,-.5)+vec2(.5);}
void fragment(){ALBEDO=texture(source_radiance,source_uv()).rgb;ROUGHNESS=1.;}
void light(){DIFFUSE_LIGHT+=mix(vec3(.46),vec3(1.),ATTENUATION);}
