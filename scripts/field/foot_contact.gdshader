shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec2 patch;
void vertex() { patch=VERTEX.xz/vec2(.51,.39); }
void fragment() {
    float distance_to_sole=dot(patch,patch);
    ALBEDO=vec3(.073,.080,.075);
    ALPHA=.35*(1.0-smoothstep(.04,1.0,distance_to_sole));
}
