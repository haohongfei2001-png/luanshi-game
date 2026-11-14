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
uniform sampler2D shoulder_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D shoulder_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sediment_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sediment_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
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
  // Shared metric section masks: packed road, low cover, damp sediment.
  // No independent random blotches; geometric slope suppresses cover on banks.
  float cover=COLOR.b*(1.0-smoothstep(0.08,0.30,grade));
  float sediment=max(COLOR.g,COLOR.a*0.52);
  cover*=1.0-sediment;
  vec3 earth=texture(earth_albedo,metric_uv).rgb;
  vec3 turf=texture(shoulder_albedo,UV/2.0).rgb;
  vec3 mud=texture(sediment_albedo,UV/1.3).rgb;
  ALBEDO=mix(mix(earth,turf,cover),mud,sediment);
  // Source normal maps retain their actual widths. Roughness below is an
  // authored material response, not an invented source roughness texture.
  vec3 n0=texture(earth_normal,metric_uv).rgb*2.0-1.0;
  vec3 n1=texture(shoulder_normal,UV/2.0).rgb*2.0-1.0;
  vec3 n2=texture(sediment_normal,UV/1.3).rgb*2.0-1.0;
  NORMAL_MAP=normalize(mix(mix(n0,n1,cover),n2,sediment))*0.5+0.5;
  NORMAL_MAP_DEPTH=mix(0.24,0.48,max(cover,sediment));
  ROUGHNESS=mix(max(0.86,texture(earth_roughness,metric_uv).r),0.92,cover);
  ROUGHNESS=mix(ROUGHNESS,0.78,sediment);
  SPECULAR=0.12;
 }
}
