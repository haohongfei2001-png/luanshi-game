extends SceneTree
## Whole river-margin composition, source LOD0/UV/PBR retained. No source scale inflation.
const Ground:=preload("res://scripts/field/ground.gd")
const Plan:=preload("res://scripts/field/regional_landscape_plan.gd")
const Native:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize():run.call_deferred()
func own(node:Node,scene:Node):
 for child in node.get_children():
  child.scene_file_path="" # flatten nested PackedScene, do not serialize it AND its owned children
  child.owner=scene;own(child,scene)
func save(root_node:Node,path:String):
 own(root_node,root_node)
 var packed:=PackedScene.new();assert(packed.pack(root_node)==OK);assert(ResourceSaver.save(packed,path)==OK)
func region(label:String) -> Node3D:
 var node:=Node3D.new();node.name=label;root.add_child(node)
 node.set_script(load("res://scripts/field/experimental_regional_landscape_guard.gd"))
 node.set_meta("expected_profile_version",Ground.AuthoredProfile.VERSION)
 node.set_meta("art_status","NOT_ACCEPTED; entire landscape normal-camera review required")
 return node
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==4,"tree-lods.scn grass.glb terrain05.scn output-directory")
 assert(Ground.authored_landform_enabled and Ground.native_woodland_enabled and OS.get_environment("LUANSHI_REGIONAL_LANDSCAPE")=="1")
 DirAccess.make_dir_recursive_absolute(args[3])
 var receipt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]+".json"))
 assert(receipt.source==Ground.NativeWoodland.SOURCE_SHA256 and receipt.output_sha256==FileAccess.get_sha256(args[0]),"Source LOD receipt/hash mismatch")
 var master:PackedScene=load(args[0]);assert(master)
 var woodland:=region("RegionalRiverValleyCanopies06")
 var roots:=[];var shared_mesh:Mesh
 for row:Array in Plan.TREE_GROUPS:
  var tree:=master.instantiate() as Node3D;woodland.add_child(tree)
  var p:=Vector2(row[0],row[1]);tree.position=Vector3(p.x,Surface.height(p)-.08,p.y);tree.rotation.y=deg_to_rad(row[3])
  var low:=INF;var high:=-INF
  for offset:Vector2 in Ground.NativeWoodland.LOCAL_POLYGON:
   var h:=Surface.height(p+offset.rotated(-tree.rotation.y));low=minf(low,h);high=maxf(high,h)
  assert(high-low<=.42,"Reject root platform at %s; range=%s"%[str(p),str(high-low)])
  roots.append({"position":[p.x,p.y],"ground_height":tree.position.y,"root_ground_range_m":high-low})
  for mesh:MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
   if shared_mesh==null:
    shared_mesh=mesh.mesh;shared_mesh.resource_local_to_scene=false
   mesh.mesh=shared_mesh;mesh.lod_bias=1.0
 woodland.set_meta("layout_sha256",FileAccess.get_sha256("res://scripts/field/regional_landscape_plan.gd"))
 woodland.set_meta("trees",Plan.TREE_GROUPS.size());woodland.set_meta("source_lod0_retained",true)
 save(woodland,args[3].path_join("woodland06.scn"));woodland.free()
 var grass:=Native.load_native(args[1]);var mesh:Mesh=grass.find_children("*","MeshInstance3D",true,false)[0].mesh
 var poses:Array[Transform3D]=[];var rng:=RandomNumberGenerator.new();rng.seed=6111406
 for iz in range(-98,99):
  for ix in range(-8,133):
   var p:=Vector2(ix,iz)*.34+Vector2(rng.randf_range(-.12,.12),rng.randf_range(-.12,.12))
   if rng.randf()>Plan.grass_density(p) or Ground.blocked(p,true,true):continue
   var y:=Surface.height(p);var up:=Surface.normal_at(p)
   if y<Ground.BATTLE_WATER_LEVEL+.4 or up.y<.83:continue
   var yaw:=rng.randf_range(-PI,PI);var forward:=Vector3(sin(yaw),0.,cos(yaw));var right:=up.cross(forward).normalized();forward=right.cross(up).normalized()
   var scale:=rng.randf_range(1.,1.7)
   poses.append(Transform3D(Basis(right,up,forward).scaled(Vector3.ONE*scale),Vector3(p.x,y,p.y)))
 var meadow:=region("ContinuousRiverMarginGroundcover06");var instances:=MultiMeshInstance3D.new();instances.name="NativeLowGrassMeadow"
 instances.set_script(load("res://scripts/field/authored_grass_instances.gd"));instances.set("authored_mesh",mesh);instances.set("authored_transforms",poses)
 # Fine grass does not cast thousands of hard sparkle shadows. It receives lighting.
 instances.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 meadow.add_child(instances);instances.multimesh=null;save(meadow,args[3].path_join("grass06.scn"));meadow.free();grass.free()
 # Exact original support/collision is retained: only metric cover mask and the
 # separate water surface material change. No offline-picture terrain replacement.
 var terrain:Node3D=(load(args[2]) as PackedScene).instantiate();root.add_child(terrain)
 terrain.set_script(load("res://scripts/field/experimental_regional_landscape_guard.gd"))
 var changed:=0;var water_count:=0
 for node:MeshInstance3D in terrain.find_children("*","MeshInstance3D",true,false):
  var material:=node.material_override as ShaderMaterial
  if material==null and node.mesh.get_surface_count()>0:material=node.mesh.surface_get_material(0) as ShaderMaterial
  if material==null:continue
  var shader_path:=material.shader.resource_path
  if "surveyed_water" in shader_path:
   var replacement:=material.duplicate() as ShaderMaterial;replacement.shader=load("res://shaders/experimental/river_valley_water06.gdshader");node.material_override=replacement;water_count+=1
  elif "surveyed_landform" in shader_path:
   var original:=node.mesh;var output:=ArrayMesh.new()
   for surface in original.get_surface_count():
    var arrays:=original.surface_get_arrays(surface);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
    for i in vertices.size():
     var p:=Vector2(vertices[i].x,vertices[i].z)
     colors[i].b=Plan.cover(p)*(1.-colors[i].g)
    arrays[Mesh.ARRAY_COLOR]=colors;output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);output.surface_set_material(surface,original.surface_get_material(surface))
   node.mesh=output;changed+=1
 assert(changed>0 and water_count>0,"Do not silently emit an unchanged landscape")
 save(terrain,args[3].path_join("terrain06.scn"));terrain.free()
 var report:={"tree_groups":Plan.TREE_GROUPS.size(),"roots":roots,"grass_tufts":poses.size(),"terrain_cover_tiles":changed,"water_surfaces":water_count,"collision_geometry":"unchanged05","real_graphics":"NOT_RUN","visual_acceptance":"NOT_ACCEPTED","lod_pixels_and_performance":"NOT_RUN"}
 FileAccess.open(args[3].path_join("build.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("REGIONAL_LANDSCAPE06_BUILT ",JSON.stringify(report));quit()
