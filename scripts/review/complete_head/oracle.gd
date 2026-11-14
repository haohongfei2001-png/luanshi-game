class_name CompleteHeadOracle
extends SceneTree
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const Adapter=preload("res://scripts/field/experimental/native_rig_material.gd")
var out:String
var views:Array=[]
var entries:Array=[]
var normal_bank_enabled:bool=OS.get_environment("HEAD_NORMAL_BANK")=="1"
var normal_bank_bytes:int=0
var cycle_mode:bool=false
func _initialize()->void:run.call_deferred()
func stop(message:String)->void:push_error(message);quit(1)
func v3(values:Array)->PackedVector3Array:
 var a=PackedVector3Array();for p in values:a.append(Vector3(p[0],p[1],p[2]))
 return a
func v2(values:Array)->PackedVector2Array:
 var a=PackedVector2Array();for p in values:a.append(Vector2(p[0],p[1]))
 return a
func transform(r:Array)->Transform3D:
 return Transform3D(Basis(Vector3(r[0][0],r[1][0],r[2][0]),Vector3(r[0][1],r[1][1],r[2][1]),Vector3(r[0][2],r[1][2],r[2][2])),Vector3(r[0][3],r[1][3],r[2][3]))
func viewport(target:Vector3)->SubViewport:
 var v=SubViewport.new();v.size=Vector2i(512,512);v.own_world_3d=true;v.render_target_update_mode=SubViewport.UPDATE_ALWAYS;v.msaa_3d=Viewport.MSAA_4X;v.mesh_lod_threshold=0.;v.positional_shadow_atlas_size=2048 if cycle_mode else 0;root.add_child(v)
 var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.035,.045,.055);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color.WHITE;world.environment.ambient_light_energy=.45;v.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-65 if cycle_mode else -35,-25,0);sun.shadow_enabled=cycle_mode;sun.directional_shadow_max_distance=5.;v.add_child(sun);v.set_meta("diagnostic_sun",sun)
 if cycle_mode:
  var ground=MeshInstance3D.new();ground.mesh=PlaneMesh.new();ground.mesh.size=Vector2(2,2);ground.position=target-Vector3(0,.31,0)
  var ground_material=StandardMaterial3D.new();ground_material.albedo_color=Color(.27,.29,.25);ground_material.roughness=1.;ground.material_override=ground_material;v.add_child(ground);v.set_meta("diagnostic_ground",ground)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=10.;camera.size=1.05 if cycle_mode else .7;v.add_child(camera);camera.position=target+(Vector3(1,1.2,2) if cycle_mode else Vector3(1,.35,2));camera.look_at(target-Vector3(0,.1,0) if cycle_mode else target);camera.current=true
 return v
func run()->void:
 out=OS.get_environment("HEAD_OUTPUT");if out.is_empty():out="user://complete-head-oracle"
 DirAccess.make_dir_recursive_absolute(out)
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/head/head-source.json"))
 if not data is Dictionary or data.meshes.size()!=4:stop("Missing complete four-part source");return
 if OS.get_environment("HEAD_VALIDATE_PACK")=="1":
  for part in data.meshes:
   if part.weights.size()!=part.position.size()*int(part.slots) or part.bones.size()!=163:stop("Source bone/weight cardinality changed");return
   if part.material.has("texture") and load("res://assets/head/"+part.material.texture)==null:stop("Source RGBA image missing from pack");return
  print("COMPLETE_HEAD_PACK_CLOSURE_PASS");quit(0);return
 if DisplayServer.get_name()=="headless":stop("Actual graphics required");return
 if OS.get_environment("HEAD_REQUIRE_METAL")=="1" and (RenderingServer.get_current_rendering_driver_name()!="metal" or RenderingServer.get_current_rendering_method()!="mobile"):stop("Actual Metal Mobile required");return
 cycle_mode=data.get("walk_cycle",false)
 var source_indices:Array=data.get("normal_bank_source_indices",range(data.poses.size()))
 var box=AABB();var first=true
 for part in data.poses[0].parts:
  for p in v3(part.reference_positions):
   if first:box=AABB(p,Vector3.ZERO);first=false
   else:box=box.expand(p)
 views=[viewport(box.get_center()),viewport(box.get_center())]
 var inventory=[]
 for part in data.meshes:
  var material=StandardMaterial3D.new();material.cull_mode=BaseMaterial3D.CULL_DISABLED
  var c:Array=part.material.linear_color;material.albedo_color=Color(c[0],c[1],c[2],c[3]).linear_to_srgb();material.roughness=part.material.roughness;material.metallic=part.material.metallic
  if part.material.has("texture"):material.albedo_texture=load("res://assets/head/"+part.material.texture)
  if part.material.alpha_linked:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;material.alpha_scissor_threshold=.25
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=v3(part.position);arrays[Mesh.ARRAY_NORMAL]=v3(part.normal);arrays[Mesh.ARRAY_TEX_UV]=v2(part.uv);arrays[Mesh.ARRAY_INDEX]=PackedInt32Array(part.indices)
  if part.all_uv_layers.size()>2:stop("More than two source UV layers not represented");return
  for key in part.all_uv_layers:
   if key!=part.active_uv:arrays[Mesh.ARRAY_TEX_UV2]=v2(part.all_uv_layers[key])
  var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(0,material)
  var full=[{"joints":PackedInt32Array(part.joints),"weights":PackedFloat32Array(part.weights)}];var packed=Palette.pack_textured_mesh(mesh,163,full)
  if packed.has("error"):stop(str(packed));return
  var unmasked=material.duplicate();unmasked.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED;unmasked.alpha_scissor_threshold=StandardMaterial3D.new().alpha_scissor_threshold
  var result=Adapter.adapt(unmasked);if result.has("error"):stop(str(result));return
  var shader:ShaderMaterial=result.material
  if part.material.alpha_linked:
   var variant=Shader.new();variant.code=shader.shader.code.replace("ALBEDO=pigment.rgb;","ALBEDO=pigment.rgb; ALPHA=pigment.a; ALPHA_SCISSOR_THRESHOLD=.25;");shader.shader=variant
  if normal_bank_enabled:
   var variant=Shader.new()
   variant.code=shader.shader.code.replace("void vertex() {", "uniform sampler2D authored_normal_bank : filter_nearest, repeat_disable;\nuniform int authored_normal_frame = 0;\nuniform int authored_normal_frame_b = 0;\nuniform float authored_normal_blend = 0.0;\nvoid vertex() {")
   variant.code=variant.code.replace("NORMAL=normalize(mat3(pose)*NORMAL);", "NORMAL=normalize(mix(texelFetch(authored_normal_bank,ivec2(VERTEX_ID,authored_normal_frame),0).xyz,texelFetch(authored_normal_bank,ivec2(VERTEX_ID,authored_normal_frame_b),0).xyz,authored_normal_blend));")
   shader.shader=variant
   var bank_image=Image.create(part.position.size(),source_indices.size(),false,Image.FORMAT_RGBAH)
   for frame in source_indices.size():
    var frame_part=data.poses[source_indices[frame]].parts[entries.size()]
    var object_basis=transform(frame_part.object_transform).basis
    for vi in part.position.size():
     var n:Array=frame_part.reference_normals[vi]
     # World oracle normals -> local, before Godot applies inverse transpose.
     var local_normal=(object_basis.transposed()*Vector3(n[0],n[1],n[2])).normalized()
     bank_image.set_pixel(vi,frame,Color(local_normal.x,local_normal.y,local_normal.z,1.))
   normal_bank_bytes+=bank_image.get_data().size()
   shader.set_shader_parameter("authored_normal_bank",ImageTexture.create_from_image(bank_image))
  shader.set_shader_parameter("influence_table",ImageTexture.create_from_image(packed.tables[0].image));shader.set_shader_parameter("influence_groups",packed.tables[0].groups);packed.mesh.surface_set_material(0,shader)
  var batch=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true;mm.mesh=packed.mesh;mm.instance_count=1;mm.set_instance_color(0,Color.WHITE);mm.set_instance_custom_data(0,Color(0,0,0,0));mm.custom_aabb=AABB(Vector3(-5,-5,-5),Vector3(10,10,10));batch.multimesh=mm;views[1].add_child(batch)
  var reference=MeshInstance3D.new();views[0].add_child(reference)
  entries.append({"part":part,"arrays":arrays,"reference":reference,"batch":batch,"shader":shader,"material":material})
  inventory.append({"name":part.name,"vertices":part.position.size(),"bones":part.bones.size(),"slots":part.slots,"original_over8_vertices":part.over8_original_vertices,"alpha_preserved":part.material.alpha_linked,"all_source_uv_layers":part.all_uv_layers.keys()})
 var rows=[]
 var pose_index:int=0
 for pose in data.poses:
  var turn=Transform3D.IDENTITY
  if cycle_mode:
   var heading=Basis(Vector3.UP,float(pose.phase)*TAU)
   turn=Transform3D(heading,box.get_center()-heading*box.get_center())
  var na:int=pose_index;var nb:int=pose_index;var blend:float=0.
  if cycle_mode:
   for j in source_indices.size()-1:
    var left:float=data.poses[source_indices[j]].phase;var right:float=data.poses[source_indices[j+1]].phase
    if pose.phase>=left and pose.phase<=right:
     na=j;nb=j+1;blend=(pose.phase-left)/(right-left);break
  for i in entries.size():
   var e=entries[i];var p=pose.parts[i];if p.name!=e.part.name:stop("Source mesh order changed");return
   var matrices=[];for row in p.palette:matrices.append(transform(row))
   var bank=Palette.encode([matrices]);if bank.has("error"):stop(str(bank));return
   if normal_bank_enabled:
    e.shader.set_shader_parameter("authored_normal_frame",na);e.shader.set_shader_parameter("authored_normal_frame_b",nb);e.shader.set_shader_parameter("authored_normal_blend",blend)
   e.shader.set_shader_parameter("palette",ImageTexture.create_from_image(bank.image));e.batch.multimesh.set_instance_transform(0,turn*transform(p.object_transform))
   var a:Array=e.arrays.duplicate();a[Mesh.ARRAY_VERTEX]=v3(p.reference_positions);a[Mesh.ARRAY_NORMAL]=v3(p.reference_normals);var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a);mesh.surface_set_material(0,e.material);e.reference.mesh=mesh;e.reference.transform=turn
  for frame in 4:await process_frame
  await RenderingServer.frame_post_draw
  for i in 2:
   var status=views[i].get_texture().get_image().save_png(out+"/"+pose.name+("-author.png" if i==0 else "-shared.png"));if status!=OK:stop("Actual PNG save failed");return
  if cycle_mode:
   for v in views:v.get_meta("diagnostic_ground").visible=false
   for frame in 3:await process_frame
   await RenderingServer.frame_post_draw
   for i in 2:
    var isolated_status=views[i].get_texture().get_image().save_png(out+"/"+pose.name+("-author-isolated.png" if i==0 else "-shared-isolated.png"))
    if isolated_status!=OK:stop("Isolated actor PNG failed");return
   for v in views:v.get_meta("diagnostic_ground").visible=true
   if pose.name in ["cycle-00","cycle-07","cycle-12","cycle-19"]:
    views[0].get_meta("diagnostic_sun").shadow_enabled=false
    for frame in 3:await process_frame
    await RenderingServer.frame_post_draw
    var shadow_status=views[0].get_texture().get_image().save_png(out+"/"+pose.name+"-author-shadow-off.png")
    if shadow_status!=OK:stop("Shadow off diagnostic save failed");return
    views[0].get_meta("diagnostic_sun").shadow_enabled=true
  pose_index+=1
  rows.append({"name":pose.name,"authored_motion":pose.authored_motion,"synthetic_bones":pose.synthetic_bones,"phase":pose.phase,"normal_bank_indices":[na,nb],"normal_bank_blend":blend,"world_turn_degrees":float(pose.phase)*360. if cycle_mode else 0.});print("COMPLETE_HEAD_CAPTURE ",pose.name)
 var report={"walk_cycle":cycle_mode,"actor_isolation_mask":cycle_mode,"ground_and_directional_shadow":cycle_mode,"shadow_settings":{"viewport_atlas":2048 if cycle_mode else 0,"directional_max_distance":5.,"camera_far":10.},"shadow_on_off_checks":(["cycle-00","cycle-07","cycle-12","cycle-19"] if cycle_mode else []),"normal_mode":(("shared_authored_RGBA16F_interpolated_walk" if cycle_mode else "shared_authored_RGBA16F_exact_samples") if normal_bank_enabled else "weighted_bind_normal"),"normal_bank_bytes":normal_bank_bytes,"normal_bank_limit":"Six sparse samples interpolated for held-out Walk only; no arbitrary facial deformation or whole-actor claim" if cycle_mode else "Only seven exact sampled poses, no interpolation or arbitrary facial deformation claim; shared per template, not per actor","source_sha256":data.source_sha256,"fixture_sha256":FileAccess.get_sha256("res://assets/head/head-source.json"),"engine":Engine.get_version_info(),"driver":RenderingServer.get_current_rendering_driver_name(),"method":RenderingServer.get_current_rendering_method(),"renderer":RenderingServer.get_video_adapter_name(),"rows":rows,"inventory":inventory,"reference":"Actual Blender complete nine-influence evaluated positions and corner normals, not native8 Skin","materials":"source RGBA/UV and calibrated reduced diffuse PBR; same alpha scissor .25 on both; no SSS/transmission equivalence","art_pass":false,"M5":"NOT_TESTED","army_performance":"NOT_TESTED"}
 var f=FileAccess.open(out+"/report.json",FileAccess.WRITE);if f==null:stop("Report creation failed");return
 f.store_string(JSON.stringify(report,"  "));f.close();quit(0)
