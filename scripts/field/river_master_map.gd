extends "res://scripts/field/landscape.gd"
## Replacement world art. Simulation landmarks and casualty systems stay shared.
const WORLD := "res://assets/river_gate/world/"
const FORT := WORLD+"architecture/river_fort.glb"
const PIER := WORLD+"masters/modular_wooden_pier/modular_wooden_pier.gltf"
const CLIFF := WORLD+"masters/coastal_cliff_02/coastal_cliff_02.gltf"
const BOULDERS := WORLD+"masters/rock_moss_set_01/rock_moss_set_01.gltf"
const BROADLEAF := WORLD+"masters/island_tree_01/island_tree_01.gltf"
const WOODLAND := WORLD+"woodland/field_woodland.glb"
const SHRUB := WORLD+"masters/shrub_03/shrub_03.gltf"
const THICKET := WORLD+"masters/searsia_burchellii/searsia_burchellii.gltf"
const FERN := WORLD+"masters/fern_02/fern_02.gltf"
const PINE := WORLD+"masters/pine_tree_01/pine_tree_01.gltf"
var libraries:Dictionary={}
var ground_material:ShaderMaterial
var water_material:ShaderMaterial
var botanical_materials:Dictionary={}

func _ready() -> void:
	name="RiverMasterMap"
	_daylight()
	ground_material=ShaderMaterial.new()
	ground_material.shader=preload("res://scripts/field/river_master_ground.gdshader")
	ground_material.set_shader_parameter("bridgehead",bridgehead)
	ground_material.set_shader_parameter("soil",load(WORLD+"ground/brown_mud_dry.jpg"))
	ground_material.set_shader_parameter("grass",load(WORLD+"ground/leafy_grass.jpg"))
	ground_material.set_shader_parameter("leaves",load(WORLD+"ground/forest_ground_04.jpg"))
	ground_material.set_shader_parameter("gravel",load(WORLD+"ground/sandy_gravel_02.jpg"))
	ground_material.set_shader_parameter("soil_normal",load(WORLD+"ground/brown_mud_dry_nor_gl.jpg"))
	ground_material.set_shader_parameter("grass_normal",load(WORLD+"ground/leafy_grass_nor_gl.jpg"))
	ground_material.set_shader_parameter("gravel_normal",load(WORLD+"ground/sandy_gravel_02_nor_gl.jpg"))
	water_material=ShaderMaterial.new()
	water_material.shader=preload("res://scripts/field/river_master_water.gdshader")
	_terrain()
	_fortress()
	_river()
	_banks_and_groves()
	_ground_dressing()
	_field_quarters()
	ram=preload("res://assets/environment/river_ram.gltf").instantiate() as Node3D
	add_child(ram)
	ram_beam=ram.find_child("SuspendedBeam",true,false) as Node3D
	for wheel in ram.find_children("RamWheel*","Node3D",true,false):
		ram_wheels.append(wheel as Node3D)

func _daylight() -> void:
	var world:=WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("899b9b")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("c0d0cf")
	world.environment.ambient_light_energy=.40
	world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	add_child(world)
	sun.rotation_degrees=Vector3(-48,58,0)
	sun.light_color=Color("fff1d7")
	sun.light_energy=.91
	sun.shadow_enabled=true
	sun.shadow_opacity=.74
	sun.directional_shadow_max_distance=100.
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias=.07
	sun.shadow_normal_bias=.8
	add_child(sun)

func _library(path:String) -> Dictionary:
	if libraries.has(path): return libraries[path]
	var root:Node3D=(load(path) as PackedScene).instantiate()
	var parts:Dictionary={}
	for child in root.find_children("*","MeshInstance3D",true,false):
		var model:=child as MeshInstance3D
		var mesh:=model.mesh
		for surface in mesh.get_surface_count():
			var material:=mesh.surface_get_material(surface) as StandardMaterial3D
			if material==null: continue
			material.roughness=maxf(.82,material.roughness)
			material.metallic=0.
			material.metallic_specular=.12
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if material.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA:
				material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				material.alpha_scissor_threshold=.38
				material.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE

			if path==BOULDERS:
				material.albedo_color=Color("a6b1b5")
			if path==BROADLEAF or path==WOODLAND or path==FERN or path==SHRUB or path==THICKET:
				var kind:=1 if "leaves" in material.resource_name else 0
				if path==WOODLAND:kind=0 if "dead" in material.resource_name else 1
				if path==FERN or path==SHRUB:kind=3
				if path==THICKET:
					var label:=material.resource_name.to_lower()
					kind=0 if ("bark" in label or "wood" in label or "branch" in label) else 3
				mesh.surface_set_material(surface,_botanical_material(material,kind,mesh.get_aabb()))
			if path==FORT and String(model.name) in ["han_wall_long","han_wall_tower","han_wall_gate_struct","GatePiers"]:
				var footing:=ShaderMaterial.new()
				footing.shader=preload("res://scripts/field/river_master_masonry.gdshader")
				footing.set_shader_parameter("native_atlas",material.albedo_texture)
				footing.set_shader_parameter("has_occlusion",material.ao_texture!=null)
				if material.ao_texture:footing.set_shader_parameter("native_occlusion",material.ao_texture)
				mesh.surface_set_material(surface,footing)
		parts[String(model.name)]=mesh
	root.free()
	libraries[path]=parts
	return parts

func _botanical_material(source:StandardMaterial3D,kind:int,bounds:AABB=AABB()) -> ShaderMaterial:
	var key:=str(source.get_instance_id())+"_"+str(kind)+"_"+str(bounds)
	if botanical_materials.has(key):return botanical_materials[key]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/field/river_botanical.gdshader")
	material.set_shader_parameter("has_atlas",source.albedo_texture!=null)
	if source.albedo_texture:material.set_shader_parameter("native_atlas",source.albedo_texture)
	material.set_shader_parameter("uv_scale",source.uv1_scale)
	material.set_shader_parameter("uv_offset",source.uv1_offset)
	material.set_shader_parameter("botanical_part",kind)
	var pigment:=Color("544635")
	if kind==1:pigment=Color("536447")
	elif kind==2:pigment=Color("96904b")
	elif kind==3:pigment=Color("697444")
	material.set_shader_parameter("pigment",pigment)
	if bounds.size.length_squared()>.01:
		material.set_shader_parameter("crown_center",bounds.get_center())
		material.set_shader_parameter("crown_extent",bounds.size*.5)
	botanical_materials[key]=material
	return material

func _piece(path:String,part:String,at:Vector3,size:Vector3=Vector3.ONE,yaw:float=0.,anchor:Vector3=Vector3.ZERO) -> MeshInstance3D:
	var parts:=_library(path)
	assert(parts.has(part),"Missing authored world part "+part)
	var node:=MeshInstance3D.new()
	node.name=part
	node.mesh=parts[part]
	node.basis=Basis(Vector3.UP,yaw).scaled_local(size)
	node.position=at-node.basis*anchor
	node.visibility_range_end=260.
	node.lod_bias=.75
	add_child(node)
	return node

func _plant(path:String,part:String,at:Vector2,size:float,yaw:float=0.) -> MeshInstance3D:
	var mesh:Mesh=_library(path)[part]
	var box:=mesh.get_aabb()
	var origin:=box.get_center()
	origin.y=box.position.y
	return _piece(path,part,Vector3(at.x,_land_height(at),at.y),Vector3.ONE*size,yaw,origin)

func _land_height(p:Vector2) -> float:
	var h:=Ground.height(p,bridgehead)-(Ground.MOAT_BED_DEPTH*Ground.moat_depth(p) if bridgehead else 0.)
	# The distant ridge begins outside every playable coordinate.
	var outside:=maxf(absf(p.x)-Ground.LIMIT.x,absf(p.y)-Ground.LIMIT.y)
	if outside>8.:
		var ridge:=maxf(0.,sin(p.x*.035+p.y*.017)+.55*sin(p.y*.061-p.x*.011))
		h+=smoothstep(8.,58.,outside)*ridge*14.
	var parapet:=Ground.parapet(p)
	return parapet if parapet>0. else h

func _terrain() -> void:
	for x0 in range(-192,192,32):
		for z0 in range(-128,128,32):
			var vertices:=PackedVector3Array()
			var normals:=PackedVector3Array()
			var indices:=PackedInt32Array()
			var step:=.5
			var count:=int(32./step)+1
			for ix in count:
				for iz in count:
					var p:=Vector2(x0+ix*step,z0+iz*step)
					vertices.append(Vector3(p.x,_land_height(p),p.y))
					var dx:=_land_height(p+Vector2(.2,0))-_land_height(p-Vector2(.2,0))
					var dz:=_land_height(p+Vector2(0,.2))-_land_height(p-Vector2(0,.2))
					normals.append(Vector3(-dx,.4,-dz).normalized())
			for ix in count-1:
				for iz in count-1:
					var a:=ix*count+iz
					indices.append_array(PackedInt32Array([a,a+count,a+1,a+1,a+count,a+count+1]))
			var arrays:Array=[]
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX]=vertices
			arrays[Mesh.ARRAY_NORMAL]=normals
			arrays[Mesh.ARRAY_INDEX]=indices
			var mesh:=ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var tile:=MeshInstance3D.new()
			tile.name="Ground_%d_%d"%[x0,z0]
			tile.mesh=mesh
			tile.material_override=ground_material
			add_child(tile)

func _wall(a:Vector2,b:Vector2) -> void:
	var span:=a.distance_to(b)
	var count:=ceili(span/12.8)
	var length:=span/count
	var yaw:=atan2(b.x-a.x,b.y-a.y)
	for i in count:
		var p:=a.lerp(b,(i+.5)/count)
		_piece(FORT,"han_wall_long",Vector3(p.x,0.,p.y),Vector3(1.,1.,length/12.997),yaw)

func _fortress() -> void:
	var station:=Vector3(Ground.WALL_X,0.,0.)
	_piece(FORT,"GatePiers",station)
	var hall:=_piece(FORT,"GateWatchHall",station)
	var box:=hall.mesh.get_aabb()
	var patches:Array=[]
	for label in ["GateWestPitch","GateEastPitch"]:
		var pitch:=_piece(FORT,label,station)
		pitch.visible=false
		var bounds:=pitch.mesh.get_aabb()
		patches.append({"node":pitch,"center":station+bounds.get_center(),"w":bounds.size.x*.5,"d":bounds.size.z*.5,
			"normal":Vector3.LEFT if label=="GateWestPitch" else Vector3.RIGHT})
	roofs.append({"node":hall,"center":station+box.get_center(),"w":box.size.x*.5,"d":box.size.z*.5,"pieces":patches})
	for side:float in [-1.,1.]:
		_wall(Vector2(Ground.WALL_X,side*7.65),Vector2(Ground.WALL_X,side*Ground.WALL_Z))
		_wall(Vector2(Ground.WALL_X,side*Ground.WALL_Z),Vector2(Ground.BACK_X,side*Ground.WALL_Z))
		_wall(Vector2(Ground.BACK_X,side*Ground.POSTERN_HALF),Vector2(Ground.BACK_X,side*Ground.WALL_Z))
		for x:float in [Ground.WALL_X,Ground.BACK_X]:
			_piece(FORT,"han_wall_tower",Vector3(x,0.,side*Ground.WALL_Z))
		for x:float in [63.,78.]:
			_piece(FORT,"han_house_a" if x<70. else "han_storehouse",Vector3(x,0.,side*17.2),Vector3.ONE*.85,PI if side<0. else 0.)
	gate=_piece(FORT,"han_wall_gate",Vector3(Ground.WALL_X,0.,0.))
	# A central, completely open court supports the retained military objectives.
	_piece(FORT,"han_barracks",Vector3(80.,0.,-10.5),Vector3.ONE*.82)
	_piece(FORT,"han_house_b",Vector3(79.,0.,11.),Vector3.ONE*.80)
	_piece(FORT,"han_fortress",Vector3(108.,_land_height(Vector2(108.,39.)),39.),Vector3.ONE*1.14,.24)

func _water(at:Vector3,size:Vector2) -> void:
	var plane:=PlaneMesh.new()
	plane.size=size
	var node:=MeshInstance3D.new()
	node.mesh=plane
	node.material_override=water_material
	node.position=at
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func _bridge(x:float,z:float) -> void:
	_piece(WORLD+"bridge/intact_bridge_span.glb","IntactBridgeSpan",Vector3(x,0.,z))
	# The mature tied-timber edge includes its braces, knots and driven supports.
	var rail_material:=StandardMaterial3D.new()
	rail_material.albedo_texture=preload("res://assets/third_party/wildfire_bridge/bound_timber.png")
	rail_material.roughness=.94
	rail_material.metallic_specular=.10
	for side:float in [-1.,1.]:
		var rail:=_piece("res://assets/third_party/wildfire_bridge/bridge_edge.glb","BoundTimber",Vector3(x,0.,z+side*3.78),Vector3.ONE,PI if side>0. else 0.)
		rail.material_override=rail_material
	if bridgehead:
		var poles:Mesh=_library(PIER)["modular_wooden_pier_poles"]
		var bounds:=poles.get_aabb()
		var anchor:=bounds.get_center()
		anchor.y=bounds.end.y
		for along:float in [-3.8,3.8]:
			for across:float in [-2.15,2.15]:
				_piece(PIER,"modular_wooden_pier_poles",Vector3(x+along,.05,z+across),Vector3.ONE,0.,anchor)

func _river() -> void:
	_water(Vector3(Ground.RIVER_X,Ground.BATTLE_WATER_LEVEL if bridgehead else -.37,0.),Vector2(20.,256.))
	for z:float in Ground.CROSSINGS: _bridge(Ground.RIVER_X,z)
	if bridgehead:
		_water(Vector3(Ground.MOAT_X,Ground.BATTLE_WATER_LEVEL,0.),Vector2(16.,58.))
		_bridge(Ground.MOAT_X,0.)
	var boat:=preload("res://assets/environment/river_skiff.gltf").instantiate() as Node3D
	boat.position=Vector3(Ground.RIVER_X+1.8,Ground.BATTLE_WATER_LEVEL+.02 if bridgehead else -.35,-11.5)
	boat.rotation.y=.12
	add_child(boat)

func _broadleaf_tree(at:Vector2,height:float,yaw:float) -> MeshInstance3D:
	# Retain the complete artist-built bark, branch and leaf-card assembly.
	# The 22 m game comparison selected a coherent crown over isolated tiny leaves.
	var variant:=posmod(roundi(at.x*3.+at.y*5.),2)
	var part:="FieldOakA" if variant==0 else "FieldOakB"
	var mesh:Mesh=_library(WOODLAND)[part]
	var plant:=_plant(WOODLAND,part,at,height/maxf(mesh.get_aabb().size.y,.01),yaw)
	plant.name="WholeBroadleaf"
	plant.visibility_range_end=300.
	plant.lod_bias=2.
	return plant

func _bank_foundation(channel:float,moat:bool) -> void:
	# Place the complete scanned cliff within an excavated bank. Its open back
	# terminates below the soil, while the original eroded face reaches the water.
	var mesh:Mesh=_library(CLIFF)["coastal_cliff_02_LOD0"]
	var bounds:=mesh.get_aabb()
	var anchor:=bounds.get_center()
	anchor.y=bounds.end.y
	var reaches:Array[float]=[-14.1,14.1] if moat else [-55.,-17.5,17.5,55.]
	for side:float in [-1.,1.]:
		for z:float in reaches:
			var center:=channel if moat else Ground.river_center(z)
			var face:=_piece(CLIFF,"coastal_cliff_02_LOD0",
				Vector3(center+side*(5.0 if moat else 5.8),.10,z),Vector3.ONE*.40,
				PI*.5 if side>0. else -PI*.5,anchor)
			face.name="EmbeddedRockBank"
			face.lod_bias=.9

func _bank_rocks(channel:float,moat:bool) -> void:
	var parts:=_library(BOULDERS)
	var names:=parts.keys()
	names.sort()
	assert(names.size()>=3)
	var stations:Array[Vector3]=Ground.BANK_OUTCROPS.duplicate()
	if not moat:stations.append_array(Ground.RIVER_OUTCROPS)
	for i in stations.size():
		var entry:=stations[i]
		var center:=Ground.river_center(entry.y) if bridgehead and not moat else channel
		var shoulder:=3.85 if moat else (4.8 if bridgehead else 3.5)
		for j in 2:
			var part:String=names[(i*5+j*3)%names.size()]
			var mesh:Mesh=parts[part]
			var box:=mesh.get_aabb()
			var anchor:=box.get_center()
			anchor.y=box.position.y
			var width:=entry.z*(.97 if j==0 else .55)
			var size:=width/maxf(box.size.x,box.size.z)
			var at:=Vector3(center+entry.x*(shoulder-.75*j),
				(Ground.BATTLE_WATER_LEVEL-.25 if bridgehead and j==1 else -.48)-box.size.y*size*.12,entry.y+j*entry.z*.31)
			var rock:=_piece(BOULDERS,part,at,Vector3.ONE*size,i*1.83+j*2.1,anchor)
			rock.name="WholeErodedBoulder"
			rock.lod_bias=1.3
			rock.visibility_range_end=210.
		for j in 2:
			var p:=Vector2(center+entry.x*(6.0+.48*j),entry.y+(j-.5)*1.55)
			_native_understory(THICKET,p,1.12+.17*((i+j)%3),i*1.43+j,i+j)
			_native_understory(FERN,p+Vector2(entry.x*.75,.48),.45,i*.8+j,i+j)

func _willow(at:Vector2,variant:int,scale_value:float,yaw:float) -> void:
	var tree:Node3D=(load(WORLD+"willows/river_willow_%d.glb"%variant) as PackedScene).instantiate()
	tree.position=Vector3(at.x,_land_height(at),at.y)
	tree.scale=Vector3.ONE*scale_value
	tree.rotation.y=yaw
	for node in tree.find_children("*","GeometryInstance3D",true,false):
		node.visibility_range_end=180.

		node.lod_bias=1.2
		if node is MeshInstance3D:
			for surface in node.mesh.get_surface_count():
				var source:=node.mesh.surface_get_material(surface) as StandardMaterial3D
				if source:
					var kind:=2 if String(node.name).begins_with("PendantLeaves") else 0
					node.set_surface_override_material(surface,_botanical_material(source,kind,node.mesh.get_aabb()))
	add_child(tree)

func _maple(at:Vector2,variant:int,scale_value:float,yaw:float) -> void:
	var tree:Node3D=(load(WORLD+"willows/river_maple_%d.glb"%variant) as PackedScene).instantiate()
	tree.position=Vector3(at.x,_land_height(at),at.y)
	tree.scale=Vector3.ONE*scale_value
	tree.rotation.y=yaw
	for node in tree.find_children("*","GeometryInstance3D",true,false):
		node.visibility_range_end=180.
		node.lod_bias=.65
	add_child(tree)

func _native_understory(path:String,at:Vector2,height:float,yaw:float,variant:int) -> MeshInstance3D:
	var parts:=_library(path)
	var names:=parts.keys()
	names.sort()
	var part:String=names[posmod(variant,names.size())]
	var mesh:Mesh=parts[part]
	var plant:=_plant(path,part,at,height/maxf(mesh.get_aabb().size.y,.01),yaw)
	plant.visibility_range_end=135.
	plant.lod_bias=1.3
	return plant

func _banks_and_groves() -> void:
	if bridgehead:
		_bank_foundation(Ground.RIVER_X,false)
		_bank_foundation(Ground.MOAT_X,true)
	_bank_rocks(Ground.RIVER_X,false)
	if bridgehead: _bank_rocks(Ground.MOAT_X,true)
	var near_groves:Array[Vector3]=[
		Vector3(37.5,-8.5,6.7),Vector3(34.,-15.,5.7),Vector3(43.,-17.,6.4),
		Vector3(34.,19.,6.2),Vector3(40.,24.,7.1),Vector3(29.,25.,5.8)]
	for i in near_groves.size():
		var entry:=near_groves[i]
		var p:=Vector2(entry.x,entry.y)
		_broadleaf_tree(p,entry.z,i*2.1)
		for j in 3:
			var q:=p+Vector2(cos(i+j*2.4),sin(i+j*2.4))*(1.7+.22*j)
			_native_understory(THICKET,q,1.15+.16*(j%3),i+j*1.9,i+j)
			_native_understory(FERN,q+Vector2(.9,-.4),.42+.06*(j%3),j+.8*i,i+j)
	var willow_positions:Array[Vector3]=[
		Vector3(17.5,-11.5,0.),Vector3(17.5,11.5,1.),
		Vector3(30.5,-25.,1.),Vector3(17.3,23.,0.),
		Vector3(-39.,-15.,0.),Vector3(-24.8,20.,1.),
		Vector3(-40.,47.,1.),Vector3(-24.5,-49.,0.)]
	for i in willow_positions.size():
		var p:=willow_positions[i]
		_willow(Vector2(p.x,p.y),int(p.z),.90+.07*(i%2),i*1.8)
	# Cohesive stands follow existing tactical woodland and ridge footprints.
	# The approach and its line of sight remain the retained playable geometry.
	var wooded_slopes:Array[Vector3]=[
		Vector3(-2.,37.,12.5),Vector3(-18.,49.,9.),
		Vector3(-70.,-42.,10.),Vector3(-87.,-47.,13.),Vector3(-106.,-42.,9.),
		Vector3(-98.,39.,10.),Vector3(-72.,43.,10.),
		Vector3(79.,47.,11.),Vector3(98.,48.,10.),Vector3(112.,-41.,12.)]
	for i in wooded_slopes.size():
		var stand:=wooded_slopes[i]
		var p:=Vector2(stand.x,stand.y)
		for j in 13:
			var radius:=sqrt(float(j)/12.)*stand.z
			var angle:=j*2.399963+i*.83
			var q:=p+Vector2(cos(angle),sin(angle))*radius
			if absf(q.y)<24.:continue
			var height:=6.8+.65*((i+j)%4)
			_broadleaf_tree(q,height,i+j*1.1)
			if j%3==0:
				_native_understory(THICKET,q+Vector2(1.2,1.1),1.4,i+j,i+j)
	# Complete scanned outcrops sit partly within the background ridge.
	for i in 14:
		var p:=Vector2(-141.+i*22.,-96.-5.*sin(i*.8))
		var cliff:=_plant(CLIFF,"coastal_cliff_02_LOD0",p,.60+.05*(i%4),i*.63)
		cliff.position.y-=2.0


func _ground_dressing() -> void:
	var random:=RandomNumberGenerator.new()
	random.seed=61112027
	const STONES:="res://assets/third_party/polyhaven_bank/bank_stones.glb"
	var stone_material:=StandardMaterial3D.new()
	stone_material.albedo_texture=preload("res://assets/third_party/polyhaven_bank/lichen_and_stone.jpg")
	stone_material.albedo_color=Color("9a998c")
	stone_material.roughness=.98
	stone_material.metallic_specular=0.
	stone_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var sources:Array[Dictionary]=[]
	var batches:Dictionary={}
	for index in 6:
		sources.append({"mesh":_library(STONES)["RiverStone%02d"%index],
			"material":stone_material,"name":"EmbeddedGroundStone"})
	var herbs:=_library(FERN)
	var names:=herbs.keys()
	names.sort()
	sources.append({"mesh":herbs[names[0]],"material":null,"name":"NativeVergeFern"})
	for x in range(-116,118,2):
		for z in range(-61,63,2):
			var at:=Vector2(x+random.randf_range(-.85,.85),z+random.randf_range(-.85,.85))
			var roadside:=absf(at.y)
			if at.x < -17.:
				roadside=minf(roadside,minf(absf(at.y-35.),absf(at.y+35.)))
			if roadside>12.5 or Ground.blocked(at,true,bridgehead):continue
			if absf(at.x-Ground.RIVER_X)<7.:continue
			if bridgehead and absf(at.x-Ground.MOAT_X)<7. and absf(at.y)<29.:continue
			if at.x>62. and absf(at.y)>12.:continue
			if Ground.parapet(at)>0.:continue
			var herb:=roadside>4.8 and random.randf()<.18
			if not herb and random.randf()>.38:continue
			var kind:=6 if herb else random.randi_range(0,5)
			var key:=Vector3i(floori(at.x/24.),floori(at.y/24.),kind)
			if not batches.has(key):
				var entry:Dictionary=sources[kind].duplicate()
				entry.transforms=[]
				entry.origin=Vector3(key.x*24.+12.,0.,key.y*24.+12.)
				batches[key]=entry
			var batch:Dictionary=batches[key]
			var bounds:AABB=batch.mesh.get_aabb()
			var anchor:=bounds.get_center()
			anchor.y=bounds.position.y
			var size:=random.randf_range(.20,.38)/maxf(bounds.size.y,.01) if herb else random.randf_range(.12,.33)/maxf(bounds.size.x,.01)
			var basis:=Basis(Vector3.UP,random.randf_range(0.,TAU)).scaled_local(Vector3.ONE*size)
			var position:=Vector3(at.x,_land_height(at)-(.02 if herb else bounds.size.y*size*.48),at.y)
			batch.transforms.append(Transform3D(basis,position-basis*anchor-batch.origin))
	for batch:Dictionary in batches.values():
		var instances:=MultiMesh.new()
		instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=batch.mesh
		instances.instance_count=batch.transforms.size()
		for index in batch.transforms.size():
			instances.set_instance_transform(index,batch.transforms[index])
		var node:=MultiMeshInstance3D.new()
		node.name=batch.name
		node.position=batch.origin
		node.multimesh=instances
		node.material_override=batch.material
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visibility_range_end=150.
		add_child(node)

func _field_quarters() -> void:
	for side:float in [-1.,1.]:
		for i in 4:
			_piece(FORT,"han_house_b",Vector3(-62.-i*10.,0.,side*(14.+i%2*3.)),Vector3.ONE*.64,PI if side>0. else 0.)
	_piece(FORT,"han_barracks",Vector3(-94.,0.,-4.5),Vector3.ONE)
	for p:Vector3 in [Vector3(-67.,0.,-6.5),Vector3(-82.,0.,7.5)]:
		var cart:=preload("res://assets/environment/grain_cart.gltf").instantiate() as Node3D
		cart.position=p
		cart.rotation.y=.25
		add_child(cart)

