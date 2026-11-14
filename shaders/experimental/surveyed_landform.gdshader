shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Metric material zones come from authored terrain, never screen noise.
uniform vec4 road_color : source_color = vec4(0.55,0.46,0.32,1.0);
uniform vec4 loam_color : source_color = vec4(0.34,0.32,0.22,1.0);
uniform vec4 bank_color : source_color = vec4(0.46,0.42,0.31,1.0);
uniform vec4 woodland_color : source_color = vec4(0.32,0.39,0.24,1.0);
uniform bool earth_enabled = false;
uniform float earth_width_m = 2.0;
uniform sampler2D earth_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D earth_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_normal;
void vertex(){world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float grade=1.0-clamp(world_normal.y,0.0,1.0);
 vec3 soil=mix(loam_color.rgb,woodland_color.rgb,COLOR.b);
 soil=mix(soil,road_color.rgb,COLOR.r);
 soil=mix(soil,bank_color.rgb,smoothstep(0.06,0.4,grade));
 soil*=1.0-0.12*COLOR.g;
 ALBEDO=soil;ROUGHNESS=0.94;METALLIC=0.0;SPECULAR=0.12;
 if(earth_enabled){
  vec2 metric_uv=UV/earth_width_m;
  // Real 2 m source scale. No procedural noise, baked shadow or amplified gloss.
  // Restrained broad zone tint only; source texture is not declared final art.
  vec3 earth=texture(earth_albedo,metric_uv).rgb;
  ALBEDO=earth*mix(vec3(1.0),vec3(0.88,0.94,0.82),COLOR.b*0.45);
  ROUGHNESS=max(0.82,texture(earth_roughness,metric_uv).r);
  NORMAL_MAP=texture(earth_normal,metric_uv).rgb;
  NORMAL_MAP_DEPTH=0.45;
 }
}
