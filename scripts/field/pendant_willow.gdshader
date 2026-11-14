shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D colour : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 fallback : source_color = vec4(0.0);
varying float crown_height;
void vertex(){
	crown_height=VERTEX.y;
	float breeze=sin(TIME*1.12+VERTEX.x*.81+VERTEX.z*.95);
	float flex=smoothstep(1.25,3.52,VERTEX.y)*smoothstep(.9,2.32,length(VERTEX.xz));
	VERTEX.xz+=vec2(.049,.024)*breeze*flex;
}
void fragment(){
	vec3 source=fallback.a>.5 ? fallback.rgb : texture(colour,UV).rgb;
	vec3 srgb=OUTPUT_IS_SRGB ? source : pow(max(vec3(0.),source),vec3(1./2.2));
	float green=smoothstep(.01,.07,srgb.g-srgb.r*.90)*smoothstep(1.20,2.0,crown_height);
	float l=dot(srgb,vec3(.28,.57,.15));
	vec3 bark=mix(vec3(.183,.138,.100),vec3(.435,.337,.240),smoothstep(.09,.80,l));
	vec3 leaf=mix(vec3(.156,.199,.119),vec3(.630,.631,.305),smoothstep(.19,.83,l));
	vec3 painted=mix(bark,leaf,green);
	ALBEDO=OUTPUT_IS_SRGB ? painted : pow(painted,vec3(2.2));
	ROUGHNESS=1.;
}
