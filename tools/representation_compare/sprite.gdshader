shader_type spatial;
render_mode unshaded,cull_disabled,depth_prepass_alpha;
uniform sampler2DArray atlas : source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform vec2 tile_pixels;
uniform vec2 atlas_pixels;
uniform int columns=1;
uniform int page_rows=1;
uniform int directions=8;
uniform vec2 projected_center;
uniform bool per_frame_center=false;
varying vec2 cell;
varying float layer;
void vertex(){
 int index=int(round(INSTANCE_CUSTOM.r))*directions+int(round(INSTANCE_CUSTOM.g));
 layer=float(index/(columns*page_rows));index=index%(columns*page_rows);
 cell=vec2(float(index%columns),float(index/columns));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
 VERTEX.xy+=per_frame_center ? INSTANCE_CUSTOM.ba : projected_center;
}
void fragment(){
 vec2 pixel=(cell+UV)*tile_pixels;
 vec4 pigment=texture(atlas,vec3(pixel/atlas_pixels,layer));
 ALBEDO=pigment.rgb;ALPHA=pigment.a;ALPHA_SCISSOR_THRESHOLD=.35;
}
