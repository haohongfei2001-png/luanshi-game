extends RefCounted
## One live ordinary actor, no simulation writes. Never installed by game scenes.
const GameGround=preload("res://scripts/field/ground.gd")
const Tracker=preload("res://scripts/field/experimental/spear_transition.gd")
const Rigid=preload("res://scripts/field/experimental/spear_rigid_transition.gd")
const Shaft=preload("res://scripts/field/experimental/spear_shaft_transition.gd")
const Palette=preload("res://scripts/field/experimental/spear_palette.gd")
var tracker:=Tracker.new()
var decoder:RefCounted
var node:MultiMeshInstance3D
var material:ShaderMaterial
var offsets:Array[Transform3D]=[]
var enabled:=false

func configure(view:Node3D,batch) -> void:
	enabled=OS.get_environment("SPEAR_TRANSITION")=="1"
	if OS.get_environment("SPEAR_RIGID")=="1": tracker=Rigid.new()
	if OS.get_environment("SPEAR_SHAFT")=="1": tracker=Shaft.new()
	var image:=Image.load_from_file(OS.get_environment("SPEAR_PALETTE") if OS.has_environment("SPEAR_PALETTE") else "res://assets/river_gate/figures/company_motion.png")
	decoder=Palette.new(image)
	material=batch.node.material_override.duplicate()
	material.set_shader_parameter("motion_bank",ImageTexture.create_from_image(image))
	var source:=FileAccess.get_file_as_string(OS.get_environment("SPEAR_SHADER")) if OS.has_environment("SPEAR_SHADER") else material.shader.code
	if enabled:
		var header:=FileAccess.get_file_as_string("res://scripts/field/experimental/spear_transition.gdshaderinc")
		source=source.replace("void vertex() {",header+"\nvoid vertex() {")
		var insertion:="""
    vec3 delta_p,delta_n;
    spear_delta(first,VERTEX,NORMAL,delta_p,delta_n);
    if(first!=second && blend<.999) {
        vec3 other_p,other_n;
        spear_delta(second,VERTEX,NORMAL,other_p,other_n);
        delta_p=mix(other_p,delta_p,blend);
        delta_n=mix(other_n,delta_n,blend);
    }
    pos+=delta_p;
    nrm+=delta_n;
"""
		var marker:="    // The nocked arrow alone"
		assert(source.contains(marker))
		source=source.replace(marker,insertion+marker)
	var shader:=Shader.new()
	shader.code=source
	material.shader=shader
	node=MultiMeshInstance3D.new()
	node.multimesh=MultiMesh.new()
	node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	node.multimesh.use_custom_data=true
	node.multimesh.instance_count=1
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	view.add_child(node)

func draw(view:Node3D,batch,index:int,model:Transform3D,data:Color,time:float) -> Dictionary:
	if node==null: configure(view,batch)
	node.multimesh.mesh=batch.mesh.mesh
	node.multimesh.set_instance_transform(0,model)
	node.multimesh.set_instance_custom_data(0,data)
	var poses:Array[Transform3D]=decoder.poses(data)
	var at:Vector3=decoder.address(data)
	if enabled:
		offsets=tracker.sample(poses,model,int(at.z),time)
		Tracker.upload(material,offsets)
	# Replace only this actor's visual submission, not its simulation or roster.
	batch.mesh.set_instance_transform(index,Transform3D(Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO),Vector3.ZERO))
	var recorded:Array=[]
	for m:Transform3D in offsets:
		recorded.append([[m.basis.x.x,m.basis.x.y,m.basis.x.z],[m.basis.y.x,m.basis.y.y,m.basis.y.z],[m.basis.z.x,m.basis.z.y,m.basis.z.z],[m.origin.x,m.origin.y,m.origin.z]])
	var soles:Array=[]
	for bone:int in [11,14]:
		var corrected:Transform3D=model*(Tracker.plus(poses[bone],offsets[bone]) if enabled else poses[bone])
		var corners:Array=[]
		for dx:float in [-.05,.05]:
			for dz:float in [-.072,.187]:
				var p:Vector3=corrected*(Rigid.PIVOTS[bone]+Vector3(dx,-.117,dz))
				var height:=GameGround.deck_height(Vector2(p.x,p.z),true)
				corners.append({"world":[p.x,p.y,p.z],"deck_height":height,"clearance_m":p.y-height})
		var ankle:Vector3=corrected*Rigid.PIVOTS[bone]
		soles.append({"bone":bone,"ankle_world":[ankle.x,ankle.y,ankle.z],"ankle_deck_height":GameGround.deck_height(Vector2(ankle.x,ankle.z),true),"modeled_boot_corners":corners})
	return {"world_ground_probe":soles,"terrain_contact_acceptance":false,"shaft_experiment":OS.get_environment("SPEAR_SHAFT")=="1","rigid_experiment":OS.get_environment("SPEAR_RIGID")=="1","offset_matrices":recorded,"experimental":true,"transition_enabled":enabled,"clip":int(at.z),
		"palette_height":decoder.bank.get_height(),"uniform_bytes":768 if enabled else 0,
		"extra_palette_texture_reads_per_vertex":0,"extra_draws":1,
		"affine_strain_and_post_skin_lean_not_accepted":true}
