extends RefCounted
## Deliberately narrow material adapter. Reject any author feature not represented
## instead of silently removing alpha, detail maps, emission or UV transforms.
const SHADER = preload("res://scripts/field/experimental/textured_native_rig.gdshader")
static func adapt(source: StandardMaterial3D) -> Dictionary:
	if source==null:return {"error":"expected original StandardMaterial3D"}
	var baseline:=StandardMaterial3D.new()
	var supported:=["cull_mode","vertex_color_use_as_albedo","albedo_color","albedo_texture","metallic","metallic_specular","metallic_texture","metallic_texture_channel","roughness","roughness_texture","roughness_texture_channel","normal_enabled","normal_scale","normal_texture"]
	for property:Dictionary in source.get_property_list():
		var key:String=property.name
		if not property.usage&PROPERTY_USAGE_STORAGE or key.begins_with("resource") or key.begins_with("metadata/") or key=="script":continue
		if source.get(key)!=baseline.get(key) and key not in supported:return {"error":"unsupported author material feature","property":key}
	if source.cull_mode!=BaseMaterial3D.CULL_DISABLED:return {"error":"diagnostic source requires explicit two-sided original material"}
	var material:=ShaderMaterial.new();material.shader=SHADER
	for pair:Array in [["albedo",source.albedo_color],["use_vertex_color",source.vertex_color_use_as_albedo],["normal_scale",source.normal_scale],["roughness",source.roughness],["metallic",source.metallic],["specular",source.metallic_specular]]:
		material.set_shader_parameter(pair[0],pair[1])
	for kind:String in ["albedo","normal","roughness","metallic"]:
		var texture:Texture2D=source.get(kind+"_texture")
		material.set_shader_parameter("use_"+kind,texture!=null and (kind!="normal" or source.normal_enabled))
		if texture:material.set_shader_parameter(kind+"_texture",texture)
	for kind:String in ["roughness","metallic"]:
		var mask:=Vector4.ZERO
		var channel:int=source.get(kind+"_texture_channel")
		if channel==BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE:mask=Vector4(1./3.,1./3.,1./3.,0.)
		else:mask[channel]=1.
		material.set_shader_parameter(kind+"_channel",mask)
	return {"material":material,"source":source.resource_name,"approved_features":supported}
