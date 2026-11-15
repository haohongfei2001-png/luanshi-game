shader_type spatial;
// Exact scoped source18 PBR semantics. No vertex/skin/tangent writes.
// cull_disabled supplies DO_SIDE_CHECK: renderer flips backface NORMAL once.
// Do not manually flip NORMAL/TANGENT/BINORMAL. NORMAL_MAP uses renderer RG decode.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_texture : filter_linear_mipmap, repeat_enable;
uniform vec4 base_factor = vec4(1.0); // glTF factors already linear; NOT source_color.
uniform float metallic_factor = 1.0;
uniform float roughness_factor = 1.0;
uniform float normal_scale = 1.0;
uniform float specular_factor = 0.5;
uniform bool has_base_texture = false;
uniform bool has_orm_texture = false;
uniform int base_coord = 0;
uniform int normal_coord = 0;
uniform int orm_coord = 0;
uniform vec2 base_scale = vec2(1.0);
uniform vec2 normal_scale_uv = vec2(1.0);
uniform vec2 orm_scale = vec2(1.0);
uniform vec2 base_offset = vec2(0.0);
uniform vec2 normal_offset = vec2(0.0);
uniform vec2 orm_offset = vec2(0.0);
uniform float base_rotation = 0.0;
uniform float normal_rotation = 0.0;
uniform float orm_rotation = 0.0;
varying vec2 source_uv2;
void vertex() { source_uv2 = CUSTOM0.xy; }
vec2 mapped_uv(int index, vec2 scale_uv, vec2 offset_uv, float angle, vec2 uv0, vec2 uv1, vec2 uv2) {
 vec2 v = (index == 2 ? uv2 : (index == 1 ? uv1 : uv0)) * scale_uv;
 return vec2(cos(angle)*v.x-sin(angle)*v.y, sin(angle)*v.x+cos(angle)*v.y) + offset_uv;
}
void fragment() {
 vec3 color = base_factor.rgb;
 if (has_base_texture) { color *= texture(base_texture, mapped_uv(base_coord, base_scale, base_offset, base_rotation, UV, UV2, source_uv2)).rgb; }
 vec3 orm = vec3(1.0);
 if (has_orm_texture) { orm = texture(orm_texture, mapped_uv(orm_coord, orm_scale, orm_offset, orm_rotation, UV, UV2, source_uv2)).rgb; }
 ALBEDO = color;
 METALLIC = metallic_factor * orm.b;
 ROUGHNESS = roughness_factor * orm.g;
 SPECULAR = specular_factor;
 NORMAL_MAP = texture(normal_texture, mapped_uv(normal_coord, normal_scale_uv, normal_offset, normal_rotation, UV, UV2, source_uv2)).rgb;
 NORMAL_MAP_DEPTH = normal_scale;
 // Source18 target materials are OPAQUE; deliberately never write ALPHA.
 // There is no occlusionTexture: ORM.R must NOT invent occlusion semantics.
}
