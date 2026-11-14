extends "res://scripts/field/landscape.gd"
## Replacement world art. Simulation landmarks and casualty systems stay shared.
const WORLD := "res://assets/river_gate/world/"
const FORT := WORLD+"architecture/river_fort.glb"
const PIER := WORLD+"masters/modular_wooden_pier/modular_wooden_pier.gltf"
const CLIFF := WORLD+"masters/coastal_cliff_02/coastal_cliff_02.gltf"
const BROADLEAF := WORLD+"masters/island_tree_03/island_tree_03.gltf"
const PINE := WORLD+"masters/pine_tree_01/pine_tree_01.gltf"
var libraries:Dictionary={}
var ground_material:ShaderMaterial
var water_material:ShaderMaterial

func _ready() -> void:
	name="RiverMasterMap"
	_daylight()
	ground_material=ShaderMaterial.new()
	ground_material.shader=preload("res://scripts/field/river_master_ground.gdshader")
	ground_material.set_shader_parameter("bridgehead",bridgehead)
	ground_material.set_shader_parameter("soil",load(WORLD+"ground/brown_mud_dry.jpg"))
	ground_material.set_shader_parameter("grass",load(WORLD+"ground/leafy_grass.jpg"))
	ground_material.set_shader_parameter("leaves",load(WORLD+"ground/forest_ground_04.jpg"))
	water_material=ShaderMaterial.new()
	water_material.shader=preload("res://scripts/field/river_master_water.gdshader")
	_terrain()
	_fortress()
	_river()
	_banks_and_groves()
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
	world.environment.ambient_light_energy=.43
	world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	add_child(world)
	sun.rotation_degrees=Vector3(-48,-31,0)
	sun.light_color=Color("fff1d7")
	sun.light_energy=1.08
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
		parts[String(model.name)]=mesh
	root.free()
	libraries[path]=parts
	return parts

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
	var h:=Ground.height(p)-(.87*Ground.moat_depth(p) if bridgehead else 0.)
	# The distant ridge begins outside every playable coordinate.
	var outside:=maxf(absf(p.x)-Ground.LIMIT.x,absf(p.y)-Ground.LIMIT.y)
	if outside>8.:
		var ridge:=maxf(0.,sin(p.x*.035+p.y*.017)+.55*sin(p.y*.061-p.x*.011))
		h+=smoothstep(8.,58.,outside)*ridge*14.
	var parapet:=Ground.parapet(p)
	return maxf(h,parapet)

func _terrain() -> void:
	for x0 in range(-192,192,32):
		for z0 in range(-128,128,32):
			var vertices:=PackedVector3Array()
			var normals:=PackedVector3Array()
			var indices:=PackedInt32Array()
			var step:=1. if x0>=0 and x0<96 and abs(z0)<=32 else 2.
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
	_piece(FORT,"han_wall_gate_struct",Vector3(Ground.WALL_X,0.,0.))
	for side:float in [-1.,1.]:
		_wall(Vector2(Ground.WALL_X,side*10.4),Vector2(Ground.WALL_X,side*Ground.WALL_Z))
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
	var plank:Mesh=_library(PIER)["modular_wooden_pier_planks"]
	var bounds:=plank.get_aabb()
	var anchor:=bounds.get_center()
	anchor.y=bounds.end.y
	for along in 5:
		for across in 3:
			_piece(PIER,"modular_wooden_pier_planks",Vector3(x-4.8+along*2.4,.13,z-2.52+across*2.52),
				Vector3(.998,1.,1.091),PI*.5,anchor)
	# The mature tied-timber edge includes its braces, knots and driven supports.
	var rail_material:=StandardMaterial3D.new()
	rail_material.albedo_texture=preload("res://assets/third_party/wildfire_bridge/bound_timber.png")
	rail_material.roughness=.94
	rail_material.metallic_specular=.10
	for side:float in [-1.,1.]:
		var rail:=_piece("res://assets/third_party/wildfire_bridge/bridge_edge.glb","BoundTimber",Vector3(x,0.,z+side*3.78),Vector3.ONE,PI if side>0. else 0.)
		rail.material_override=rail_material

func _river() -> void:
	_water(Vector3(Ground.RIVER_X,-.37,0.),Vector2(10.5,256.))
	for z:float in Ground.CROSSINGS: _bridge(Ground.RIVER_X,z)
	if bridgehead:
		_water(Vector3(Ground.MOAT_X,-.38,0.),Vector2(10.3,53.))
		_bridge(Ground.MOAT_X,0.)
	var boat:=preload("res://assets/environment/river_skiff.gltf").instantiate() as Node3D
	boat.position=Vector3(Ground.RIVER_X+1.8,-.35,-11.5)
	boat.rotation.y=.12
	add_child(boat)

func _bank_cliff(x:float,z:float,side:float,index:int) -> void:
	var node:=_piece(CLIFF,"coastal_cliff_02_LOD0",Vector3(x,-1.3,z),
		Vector3(.19,.22,.135),side*PI*.5)
	node.lod_bias=.50
	node.name="AuthoredBank_%d"%index

func _willow(at:Vector2,variant:int,scale_value:float,yaw:float) -> void:
	var tree:Node3D=(load(WORLD+"willows/river_willow_%d.glb"%variant) as PackedScene).instantiate()
	tree.position=Vector3(at.x,_land_height(at),at.y)
	tree.scale=Vector3.ONE*scale_value
	tree.rotation.y=yaw
	for node in tree.find_children("*","GeometryInstance3D",true,false):
		node.visibility_range_end=180.
		node.lod_bias=.8
	add_child(tree)

func _banks_and_groves() -> void:
	# Whole cliff silhouettes sit within the existing unwalkable channel.
	# Both ends of every bridge remain open for the actual army routes.
	var index:=0
	var channels:Array[float]=[Ground.RIVER_X]
	if bridgehead: channels.append(Ground.MOAT_X)
	for channel:float in channels:
		var locations:Array[float]=[-23.,-15.,-8.8,8.8,16.,23.]
		if channel==Ground.RIVER_X: locations=[-61.,-52.,-44.,-26.,-17.,-8.8,8.8,17.,26.,44.,52.,61.]
		for side:float in [-1.,1.]:
			for z:float in locations:
				index+=1
				_bank_cliff(channel+side*3.25,z,side,index)
			if channel==Ground.MOAT_X:
				_willow(Vector2(channel+side*6.25,side*-11.5),0,.91,.5+side)
				_willow(Vector2(channel+side*6.8,side*21.5),1,.92,side*1.2)
			else:
				for z:float in [-50.,-18.,19.,51.]:
					_willow(Vector2(channel+side*6.8,z),index%2,.9,side*.6+z*.11)
	# Interlocking broad-leaf crowns carry the grove from foreground to background.
	var clusters:Array[Vector3]=[
		Vector3(39.,0.,-14.5),Vector3(36.5,0.,-18.),Vector3(42.5,0.,-17.),
		Vector3(31.5,0.,16.5),Vector3(36.,0.,21.),Vector3(44.,0.,19.),
		Vector3(-6.,0.,35.),Vector3(0.,0.,40.),Vector3(-13.,0.,42.),Vector3(8.,0.,44.),
		Vector3(-63.,0.,-33.),Vector3(-74.,0.,-37.),Vector3(-91.,0.,33.),
		Vector3(91.,0.,38.),Vector3(98.,0.,47.),Vector3(76.,0.,53.)]
	for i in clusters.size():
		var p:=Vector2(clusters[i].x,clusters[i].z)
		_plant(BROADLEAF,"island_tree_03_LOD0",p,2.0+.16*(i%4),i*2.13)
		for j in 2:
			var q:=p+Vector2(cos(i+j*2.1),sin(i+j*2.1))*3.2
			_plant(BROADLEAF,"island_tree_03_LOD0",q,.36+.11*j,i+j*.9)
	# A coherent tree line and rocky skyline surrounds the full playable map.
	for i in 22:
		var p:=Vector2(-125.+i*12.,-78.-12.*sin(i*.63))
		var pine:="pine_tree_01_%s_LOD0"%["a","b","c"][i%3]
		_plant(PINE,pine,p,.64+.07*(i%5),i*1.41)
		if i%3==0:
			_plant(CLIFF,"coastal_cliff_02_LOD0",p+Vector2(0.,-8.),.7,i*.16)
	for i in 13:
		var p:=Vector2(-120.+i*21.,91.+8.*sin(i*.74))
		_plant(PINE,"pine_tree_01_b_LOD0",p,.82,i*.71)

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
