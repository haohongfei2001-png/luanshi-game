extends SceneTree
## Offline scene authoring. Saves real editable Godot scene/mesh resources.
## Runtime never scatters vegetation or manufactures the master terrain.
const Ground:=preload("res://scripts/field/ground.gd")
const FORT:="res://assets/river_gate/world/architecture/river_fort.glb"
const NATURE:="res://assets/river_pass/nature/"
const OUT:="res://assets/river_pass/master/"
var master:=Node3D.new()
var libraries:Dictionary={}
var terrains:=0
var native_instances:=0
func _initialize() -> void:
	_build.call_deferred()
func group(label:String) -> Node3D:
	var node:=Node3D.new();node.name=label;master.add_child(node);node.owner=master;return node
func own(node:Node) -> void:
	# Fully authored native subtrees must not also instantiate their source scene.
	# Otherwise PackedScene replaces imported children and leaves orphan RIDs.
	node.scene_file_path=""
	node.owner=master
	for c:Node in node.get_children():own(c)
func library(path:String) -> Dictionary:
	if libraries.has(path):return libraries[path]
	var source:Node3D=load(path).instantiate()
	var result:Dictionary={}
	for m:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var path_out:=OUT+"fort_"+String(m.name)+".res"
		ResourceSaver.save(m.mesh,path_out,ResourceSaver.FLAG_COMPRESS)
		result[String(m.name)]=load(path_out)
	source.free();libraries[path]=result;return result
func part(parent:Node3D,label:String,pos:Vector3,scale_value:Vector3=Vector3.ONE,yaw:float=0.) -> MeshInstance3D:
	var m:=MeshInstance3D.new();m.name=label;m.mesh=library(FORT)[label];m.position=pos;m.scale=scale_value;m.rotation.y=yaw
	parent.add_child(m);m.owner=master;return m
func h(p:Vector2) -> float:
	var ledge:=Ground.parapet(p)
	return ledge if ledge>0. else Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p)
func native(parent:Node3D,label:String,p:Vector2,height:float,yaw:float=0.) -> Node3D:
	var n:Node3D=load(label if label.begins_with("res://") else NATURE+label+".gltf").instantiate()
	var bounds:=AABB();var first:=true
	for mesh:MeshInstance3D in n.find_children("*","MeshInstance3D",true,false):
		var transform:=mesh.transform
		var ancestor:=mesh.get_parent()
		while ancestor!=n:
			transform=ancestor.transform*transform;ancestor=ancestor.get_parent()
		var box:=transform*mesh.mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
		mesh.visibility_range_end=250.
		mesh.lod_bias=1.
	var factor:=height/maxf(bounds.size.y,.01)
	n.scale=Vector3.ONE*factor;n.rotation.y=yaw
	n.position=Vector3(p.x,h(p)-bounds.position.y*factor,p.y)
	parent.add_child(n);own(n);native_instances+=1;return n
func terrain() -> void:
	var region:=group("SculptedTerrain")
	var material:=ShaderMaterial.new();material.shader=load("res://scripts/field/river_master_ground.gdshader")
	material.set_shader_parameter("bridgehead",true)
	var root_path:="res://assets/river_gate/world/ground/"
	for slot:String in ["soil","grass","leaves","gravel","soil_normal","grass_normal","gravel_normal"]:
		var file:String={"soil":"brown_mud_dry.jpg","grass":"leafy_grass.jpg","leaves":"forest_ground_04.jpg","gravel":"sandy_gravel_02.jpg","soil_normal":"brown_mud_dry_nor_gl.jpg","grass_normal":"leafy_grass_nor_gl.jpg","gravel_normal":"sandy_gravel_02_nor_gl.jpg"}[slot]
		material.set_shader_parameter(slot,load(root_path+file))
	ResourceSaver.save(material,OUT+"terrain_material.tres")
	for x0 in range(-160,160,32):
		for z0 in range(-128,128,32):
			var step:=.5 # Matching edge subdivisions: no terrain tile T-junctions.
			var count:=int(32./step)+1
			var v:=PackedVector3Array();var normals:=PackedVector3Array();var indices:=PackedInt32Array()
			for ix in count:
				for iz in count:
					var p:=Vector2(x0+ix*step,z0+iz*step)
					v.append(Vector3(p.x,h(p),p.y))
					var dx:=h(p+Vector2(.1,0))-h(p-Vector2(.1,0));var dz:=h(p+Vector2(0,.1))-h(p-Vector2(0,.1))
					normals.append(Vector3(-dx,.2,-dz).normalized())
			for ix in count-1:
				for iz in count-1:
					var a:=ix*count+iz;indices.append_array(PackedInt32Array([a,a+count,a+1,a+1,a+count,a+count+1]))
			var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=v;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
			var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(0,material)
			var path:=OUT+"land_%d_%d.res"%[x0,z0];ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)
			var node:=MeshInstance3D.new();node.name="Land_%d_%d"%[x0,z0];node.mesh=load(path);region.add_child(node);node.owner=master;terrains+=1
func water() -> void:
	var region:=group("RiverAndMoat")
	var mat:=ShaderMaterial.new();mat.shader=load("res://scripts/field/river_master_water.gdshader")
	for row:Vector4 in [Vector4(-32.,0.,34.,256.),Vector4(24.,0.,20.,58.)]:
		var mesh:=PlaneMesh.new();mesh.size=Vector2(row.z,row.w)
		var node:=MeshInstance3D.new();node.name="Water";node.mesh=mesh;node.material_override=mat;node.position=Vector3(row.x,Ground.BATTLE_WATER_LEVEL,row.y);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(node);node.owner=master
func bridges() -> void:
	var region:=group("BridgesAndLandings")
	for point:Vector2 in [Vector2(-32.,-35.),Vector2(-32.,0.),Vector2(-32.,35.),Vector2(24.,0.)]:
		var span:Node3D=load("res://assets/river_gate/world/bridge/intact_bridge_span.glb").instantiate();span.position=Vector3(point.x,0,point.y);region.add_child(span);own(span)
		# Replace the old tall tied-timber rails with complete mature stone
		# embankment/landing modules below the retained physical deck.
		for side:float in [-1.,1.]:
			for end:float in [-1.,1.]:
				var p:=point+Vector2(end*5.4,side*4.2)
				var rock:=native(region,"RockPath_Round_Wide",p,.65,PI*.5)
				rock.position.y=-.54
func wall(parent:Node3D,a:Vector2,b:Vector2) -> void:
	var count:=ceili(a.distance_to(b)/12.8);var length:=a.distance_to(b)/count
	for i in count:
		var p:=a.lerp(b,(i+.5)/count);part(parent,"han_wall_long",Vector3(p.x,0,p.y),Vector3(1,1,length/12.997),atan2(b.x-a.x,b.y-a.y))
func fort() -> void:
	var region:=group("GateAndGarrison")
	part(region,"GatePiers",Vector3(48,0,0))
	var hall:=part(region,"GateWatchHall",Vector3(48,0,0));hall.name="GateHall"
	var gate:=part(region,"han_wall_gate",Vector3(48,0,0));gate.name="Gate"
	for side:float in [-1.,1.]:
		wall(region,Vector2(48,side*7.65),Vector2(48,side*23))
		wall(region,Vector2(48,side*23),Vector2(89,side*23))
		wall(region,Vector2(89,side*1.65),Vector2(89,side*23))
		for x:float in [48.,89.]:part(region,"han_wall_tower",Vector3(x,0,side*23))
		# Edge arcades and warehouses give the court a deliberate rear boundary.
		for x:float in [62.,76.]:part(region,"han_storehouse",Vector3(x,0,side*18.4),Vector3.ONE*.78,PI if side<0 else 0.)
	var town:=group("RearSettlement")
	for row:Vector3 in [Vector3(99,0,-16),Vector3(110,0,-9),Vector3(101,0,17),Vector3(113,0,25),Vector3(96,0,34)]:
		part(town,"han_house_a",Vector3(row.x,h(Vector2(row.x,row.z)),row.z),Vector3.ONE*.85,.35 if row.z<0 else -.2)
	part(town,"han_fortress",Vector3(114,h(Vector2(114,-28)),-28),Vector3.ONE)
func groves() -> void:
	var foreground:=group("ForegroundRiparianWoodland")
	var middle:=group("MiddleTerraceWoodland")
	var background:=group("RidgeForestAndCliffs")
	# Designed irregular pockets. The central movement strip is never seeded.
	var stands:Array[Dictionary]=[
	 {"p":Vector2(33,-10.8),"r":Vector2(3.0,4.),"count":3,"height":5.2,"layer":foreground},
	 {"p":Vector2(40,13),"r":Vector2(3.2,4.2),"count":3,"height":5.3,"layer":foreground},
	 {"p":Vector2(15,-14),"r":Vector2(5,7),"count":5,"height":7.,"layer":foreground},
	 {"p":Vector2(13,20),"r":Vector2(5,7),"count":5,"height":7.,"layer":foreground},
	 {"p":Vector2(37,-22),"r":Vector2(8,5),"count":9,"height":7.8,"layer":middle},
	 {"p":Vector2(40,31),"r":Vector2(8,8),"count":10,"height":8.,"layer":middle},
	 {"p":Vector2(-4,-30),"r":Vector2(22,13),"count":24,"height":8.5,"layer":middle},
	 {"p":Vector2(-4,36),"r":Vector2(18,14),"count":20,"height":8.,"layer":middle},
	 {"p":Vector2(40,-52),"r":Vector2(28,14),"count":28,"height":10.,"layer":background},
	 {"p":Vector2(82,49),"r":Vector2(20,12),"count":20,"height":9.,"layer":background},
	 {"p":Vector2(-84,-47),"r":Vector2(30,13),"count":20,"height":8.,"layer":background},
	 {"p":Vector2(126,-39),"r":Vector2(22,18),"count":18,"height":11.,"layer":background}]
	var types:=["CommonTree_1","CommonTree_2","CommonTree_4","TwistedTree_1"]
	var index:=0
	for stand:Dictionary in stands:
		for i in int(stand.count):
			var angle:=i*2.39996+index*.72;var radius:=sqrt((i+.5)/float(stand.count))
			var p:Vector2=stand.p+Vector2(cos(angle),sin(angle))*stand.r*radius
			if Ground.blocked(p,true,true) or (absf(p.y)<7.2 and p.x>25. and p.x<47.):continue
			var tree:String=types[(i+index)%types.size()]
			if stand.layer==background and i%4==0:tree="Pine_1" if i%2==0 else "Pine_3"
			native(stand.layer,tree,p,float(stand.height)*(.82+.09*(i%4)),angle)
			if i%2==0:
				native(stand.layer,"Bush_Common",p+Vector2(1.6,-1.2),.85+.10*(i%3),angle+.5)
				native(stand.layer,"Fern_1",p+Vector2(-1.2,.6),.45,angle)
		index+=1
	# A small number of complete large rock masters anchor forest masses.
	for p:Vector2 in [Vector2(33,-17),Vector2(39,23),Vector2(7,-35),Vector2(-12,39),Vector2(45,-44),Vector2(87,47),Vector2(118,-35)]:
		native(middle,"Rock_Medium_2",p,2.0,.7)
func shore() -> void:
	var region:=group("AuthoredShoreGroups")
	var sites:Array[Vector3]=Ground.BANK_OUTCROPS.duplicate();sites.append_array(Ground.RIVER_OUTCROPS)
	for channel:float in [-32.,24.]:
		for i in sites.size():
			var e:=sites[i]
			if channel==24. and absf(e.y)>24.:continue
			var center:=Ground.PassProfile.moat_center(e.y) if channel==24. else Ground.river_center(e.y)
			var p:=Vector2(center+e.x*(4.1 if channel==24. else 5.1),e.y)
			var rock:=native(region,"RockPath_Round_Wide" if i%2==0 else "Rock_Medium_1",p,.55+.16*(i%3),i*1.8)
			rock.position.y=Ground.BATTLE_WATER_LEVEL-.18
			var margin:=Vector2(center+e.x*(7.0 if channel==24. else 8.4+Ground.river_shore_variation(e.y)),e.y)
			native(region,"Grass_Wispy_Tall",margin,.65,i*.8)
			if i%3==0:native(region,"Bush_Common",margin+Vector2(e.x*.6,1.2),.8,i)
func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	master.name="RiverPassMaster"
	terrain();water();bridges();fort();groves();shore()
	var pavilions:=group("OuterRoadPavilions")
	# Original complete architectural assets outside the current combat bounds,
	# not fake non-colliding obstacles inserted into an active formation.
	native(pavilions,"res://assets/river_pass/pavilion/pavilion.glb",Vector2(131.,10.),6.2,.3)
	native(pavilions,"res://assets/river_pass/pavilion/pavilion.glb",Vector2(-131.,-12.),5.8,-.2)
	var sun:=DirectionalLight3D.new();sun.name="Sun";sun.rotation_degrees=Vector3(-48,58,0);sun.light_color=Color("fff1df");sun.light_energy=.91;sun.shadow_enabled=true;sun.directional_shadow_max_distance=100;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS;master.add_child(sun);sun.owner=master
	var world:=WorldEnvironment.new();world.name="Atmosphere";world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("889b9c");world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color("bbc8c8");world.environment.ambient_light_energy=.4;world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;master.add_child(world);world.owner=master
	var ram:Node3D=load("res://assets/environment/river_ram.gltf").instantiate();ram.name="Ram";master.add_child(ram);own(ram)
	master.set_meta("source_layout","river-pass-master-v1");master.set_meta("native_instances",native_instances);master.set_meta("terrain_tiles",terrains)
	var packed:=PackedScene.new();assert(packed.pack(master)==OK);assert(ResourceSaver.save(packed,OUT+"river_pass.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("RIVER_PASS_BUILT ",JSON.stringify({"terrain_tiles":terrains,"native_instances":native_instances,"groups":master.get_child_count(),"visual":"NOT_RUN"}))
	master.free();quit(0)
