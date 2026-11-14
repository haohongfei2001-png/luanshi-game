extends SceneTree
const Freeze=preload('res://tools/art/gate_structure/freeze_shader_clock.gd')
func _initialize()->void:
 var model=MeshInstance3D.new();model.mesh=BoxMesh.new();root.add_child(model)
 var shader=Shader.new();var source='shader_type spatial;\nvoid vertex(){ VERTEX.x += sin(TIME); }';shader.code=source
 var mat=ShaderMaterial.new();mat.shader=shader;model.material_override=mat
 var freeze=Freeze.new();var report=freeze.freeze(root,6.75)
 assert(report.size()==1 and 'DOT_CAPTURE_TIME' in shader.code)
 assert(report[0].original_code_sha256==source.sha256_text())
 freeze.restore();assert(shader.code==source)
 print('STATIC_SHADER_CLOCK_OVERRIDE_RESTORE_PASS')
 model.free();quit()
