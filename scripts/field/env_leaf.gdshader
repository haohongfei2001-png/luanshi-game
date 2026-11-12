shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform sampler2D ink : source_color, filter_linear_mipmap, repeat_disable;
varying float leaf_light;

void vertex() {
	// Only the outer shoots move. Branches and all grounding stay fixed.
	float breeze=sin(TIME*1.22+VERTEX.x*0.83+VERTEX.z*0.44)*0.025;
	VERTEX.x+=breeze*UV2.x;
	VERTEX.z+=breeze*0.53*UV2.x;
	leaf_light=COLOR.r;
}

void fragment() {
	vec4 foliage=texture(ink,UV);
	ALBEDO=foliage.rgb*(0.79+0.42*leaf_light);
	ROUGHNESS=0.96;
	ALPHA=foliage.a;
	ALPHA_SCISSOR_THRESHOLD=0.44;
}
