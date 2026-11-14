extends RefCounted
## Naked UBC control only. Does not demonstrate Chinese armor or weapon quality.
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const Adapter=preload("res://scripts/field/experimental/native_rig_material.gd")
const CLIPS={"Idle":24,"Walk":32,"Sword_Attack":24,"Hit_Chest":8,"Death01":24}
var clips:Dictionary={}
var entries:Array=[]
var source:Node3D
var palette_bytes:=0
var mesh_triangles:=0
var explicit_lod_inventory:Array=[]
func prepare(parent:Node,measure_bounds:bool=false)->void:
 source=load("res://assets/ubc_lab/ubc_animated.glb").instantiate();parent.add_child(source)
 var skeleton:Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0]
 var player:AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0]
 player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for native:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  var packed=Palette.pack_textured_mesh(native.mesh,native.skin.get_bind_count());assert(not packed.has("error"),str(packed))
  entries.append({"native":native,"mesh":packed.mesh,"tables":packed.tables,"frames":[],"materials":[],"transform":source.global_transform.affine_inverse()*native.global_transform})
 var offset=0
 for clip:String in CLIPS:
  var length=player.get_animation(clip).length
  clips[clip]={"offset":offset,"count":CLIPS[clip],"length":length,"bounds":[1e20,1e20,-1e20,-1e20]}
  for frame in CLIPS[clip]:
   var time=length*float(frame)/float(CLIPS[clip]-1 if clip in ["Death01","Hit_Chest","Sword_Attack"] else CLIPS[clip])
   player.play(clip);player.seek(time,true);player.advance(0.0);skeleton.force_update_all_bone_transforms()
   for entry:Dictionary in entries:
    var pose=Palette.capture(skeleton,entry.native.skin);assert(not pose.has("error"),str(pose));entry.frames.append(pose.transforms)
    if measure_bounds:
     var box: AABB=pose_bounds(entry.native.mesh,pose.transforms)
     var pitch=lerpf(deg_to_rad(31.),deg_to_rad(51.),smoothstep(7.,23.,22.));var yaw=deg_to_rad(-33.)
     var direction=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
     var right=Vector3.UP.cross(direction).normalized();var up=direction.cross(right).normalized()
     for d in 16:
      var turn=Basis(Vector3.UP,TAU*d/16.)
      for corner in 8:
       var point=turn*(entry.transform*box.get_endpoint(corner))-Vector3(0,.95,0)
       var x=right.dot(point);var y=up.dot(point)
       clips[clip].bounds[0]=minf(clips[clip].bounds[0],x);clips[clip].bounds[1]=minf(clips[clip].bounds[1],y)
       clips[clip].bounds[2]=maxf(clips[clip].bounds[2],x);clips[clip].bounds[3]=maxf(clips[clip].bounds[3],y)
  offset+=CLIPS[clip]
 var dedup={}
 for entry:Dictionary in entries:
  var bank=Palette.encode(entry.frames);assert(not bank.has("error"),str(bank))
  var key=bank.image.get_data().hex_encode().sha256_text()
  if not dedup.has(key):dedup[key]=ImageTexture.create_from_image(bank.image);palette_bytes+=bank.bytes
  for surface in entry.mesh.get_surface_count():
   var adapted=Adapter.adapt(entry.native.get_active_material(surface));assert(not adapted.has("error"),str(adapted))
   var material:ShaderMaterial=adapted.material
   material.set_shader_parameter("palette",dedup[key]);material.set_shader_parameter("influence_table",ImageTexture.create_from_image(entry.tables[surface].image));material.set_shader_parameter("influence_groups",entry.tables[surface].groups)
   entry.mesh.surface_set_material(surface,material);entry.materials.append(material)
   mesh_triangles+=entry.mesh.surface_get_array_index_len(surface)/3
  entry.erase("frames")
 if OS.has_environment("COMPARE_LOD_TIER"):
  var tier=int(OS.get_environment("COMPARE_LOD_TIER"));assert(tier>=0 and tier<=3)
  for entry:Dictionary in entries:
   var selected=preload("res://tools/representation_compare/explicit_lod.gd").select(entry.mesh,tier)
   assert(not selected.has("error"),str(selected));entry.mesh=selected.mesh
   explicit_lod_inventory.append({"mesh":entry.native.name,"tier":tier,"surfaces":selected.inventory})
 source.visible=false
func batches(parent:Node,count:int)->Array:
 var result=[]
 for entry:Dictionary in entries:
  var node=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true;mm.mesh=entry.mesh;mm.instance_count=count
  mm.custom_aabb=AABB(Vector3(-150,-5,-100),Vector3(300,60,200));node.multimesh=mm;parent.add_child(node)
  for i in count:mm.set_instance_color(i,Color.WHITE)
  result.append(node)
 return result
func set_actor(batches:Array,index:int,where:Transform3D,frame:int)->void:
 for k in batches.size():
  var mm:MultiMesh=batches[k].multimesh;mm.set_instance_transform(index,where*entries[k].transform);mm.set_instance_custom_data(index,Color(float(frame),0,0,0))
func light(parent:Node,transparent:bool=false)->void:
 var world=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(0,0,0,0) if transparent else Color("899b9b")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color("c0d0cf");world.environment.ambient_light_energy=.40;world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR if transparent else Environment.TONE_MAPPER_FILMIC;parent.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,58,0);sun.light_color=Color("fff1d7");sun.light_energy=.91;parent.add_child(sun)

func pose_bounds(mesh:ArrayMesh,poses:Array)->AABB:
 var box=AABB();var first=true
 for surface in mesh.get_surface_count():
  var a=mesh.surface_get_arrays(surface);var n:int=a[Mesh.ARRAY_VERTEX].size();var slots:int=a[Mesh.ARRAY_WEIGHTS].size()/n
  for v in n:
   var point=Vector3.ZERO
   for influence in slots:
    var index=v*slots+influence;var weight:float=a[Mesh.ARRAY_WEIGHTS][index]
    if weight>0.:point+=(poses[a[Mesh.ARRAY_BONES][index]]*a[Mesh.ARRAY_VERTEX][v])*weight
   if first:box=AABB(point,Vector3.ZERO);first=false
   else:box=box.expand(point)
 return box
