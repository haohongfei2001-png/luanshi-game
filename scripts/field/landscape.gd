extends Node3D
const Ground := preload("res://scripts/field/ground.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const WOOD := Color("70513b")
const LIME := Color("ad9d79")
const SLATE := Color("465657")
const STONE := Color("838274")
const DIRT := Color("a28c67")
var surface_material:=ShaderMaterial.new()
var sun:=DirectionalLight3D.new()
var gate: MeshInstance3D
var ram: MeshInstance3D
var ram_beam: MeshInstance3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("a7b6a5")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("e2e3ce")
	world.environment.ambient_light_energy = 0.52
	add_child(world)
	sun.rotation_degrees = Vector3(-53,-31,0)
	sun.light_color = Color("ffedce")
	sun.light_energy = 0.76
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.76
	sun.directional_shadow_max_distance = 75.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	surface_material.shader=preload("res://scripts/field/ground.gdshader")
	var grain:=PackedByteArray()
	grain.resize(128*128)
	var grain_rng:=RandomNumberGenerator.new()
	grain_rng.seed=71261
	for i in grain.size(): grain[i]=grain_rng.randi() & 255
	var image:=Image.create_from_data(128,128,false,Image.FORMAT_R8,grain)
	image.generate_mipmaps()
	surface_material.set_shader_parameter("grain_map",ImageTexture.create_from_image(image))
	_ground_tiles()
	var river:=Builder.new()
	_crossings(river)
	_mesh(river,self)
	var city:=Builder.new()
	_fort(city)
	_mesh(city,self)
	var tents:=Builder.new()
	_camp(tents)
	_mesh(tents,self)
	var vegetation:={}
	var rng := RandomNumberGenerator.new()
	rng.seed = 8725
	for i in 164:
		var p := Vector2.ZERO
		if i < 60:
			var angle := rng.randf_range(0,TAU)
			p = Ground.GROVE + Vector2(cos(angle),sin(angle))*sqrt(rng.randf())*13.0
		else:
			p = Vector2(rng.randf_range(-112,110),rng.randf_range(-62,62))
			if absf(p.y) < 40 or absf(p.x-Ground.RIVER_X)<7: continue
		_tree(_vegetation_cell(vegetation,p),Ground.unit_point(p),rng.randf_range(1.9,3.9),i%4)
	for i in 110:
		var z := rng.randf_range(-63,63)
		if absf(z-Ground.crossing(z)) < 5: continue
		var p := Vector2(Ground.RIVER_X+(-1 if i%2 else 1)*rng.randf_range(4.6,5.6),z)
		var foot := Ground.unit_point(p)
		_vegetation_cell(vegetation,p).rod(foot,foot+Vector3(0.12,0.70,0.10),0.045,0.01,Color("a6a16d"),3)
	for patch: Builder in vegetation.values(): _mesh(patch,self)
	var door := Builder.new()
	for x: float in [-0.50,0.50]:
		door.block(Vector3(x,1.75,0),Vector3(0.23,3.50,Ground.GATE_HALF*2),WOOD.darkened(0.27))
	for z in range(-3,4):
		door.block(Vector3(-0.66,1.75,z),Vector3(0.09,3.5,0.065),WOOD)
	for h: float in [0.7,2.65]:
		door.block(Vector3(-0.71,h,0),Vector3(0.10,0.16,7.95),SLATE)
	gate = _mesh(door,self)
	gate.position = Ground.unit_point(Ground.GATE)
	var chassis := Builder.new()
	chassis.block(Vector3(0,0.54,0),Vector3(3.9,0.22,1.48),WOOD)
	for x: float in [-1.30,1.30]:
		for z: float in [-0.80,0.80]:
			chassis.rod(Vector3(x,0.48,z-0.08),Vector3(x,0.48,z+0.08),0.48,0.48,WOOD.darkened(0.18),10)
			chassis.rod(Vector3(x,0.68,z*0.83),Vector3(x,2.06,z*0.30),0.10,0.10,WOOD)
	chassis.rod(Vector3(-1.55,2.0,0),Vector3(1.55,2.0,0),0.12,0.12,WOOD)
	ram = _mesh(chassis,self)
	var beam := Builder.new()
	beam.rod(Vector3(-2.14,1.18,0),Vector3(2.40,1.18,0),0.22,0.21,WOOD.darkened(0.14),8)
	beam.rod(Vector3(2.1,1.18,0),Vector3(2.55,1.18,0),0.24,0.17,SLATE,8)
	ram_beam = _mesh(beam,ram)

func _mesh(builder: Builder,parent: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = builder.finish()
	mesh.material_override=surface_material
	parent.add_child(mesh)
	return mesh

func _point(x: float,z: float) -> Vector3:
	return Vector3(x,Ground.height(Vector2(x,z)),z)

func _vegetation_cell(patches: Dictionary,p: Vector2) -> Builder:
	var key:=Vector2i(floori(p.x/36),floori(p.y/36))
	if not patches.has(key): patches[key]=Builder.new()
	return patches[key]

func _ground_tiles() -> void:
	for x0 in range(-126,126,42):
		for z0 in range(-72,72,36):
			var land:=Builder.new()
			land.joint=1
			for x in range(x0,x0+42,3):
				for z in range(z0,z0+36,3):
					land.quad(_point(x,z),_point(x,z+3),_point(x+3,z+3),_point(x+3,z),Color.WHITE)
			_mesh(land,self)

func _crossings(b: Builder) -> void:
	b.joint=2
	var water := Color("577d78")
	b.quad(Vector3(Ground.RIVER_X-4.8,-0.33,-72),Vector3(Ground.RIVER_X-4.8,-0.33,72),
		Vector3(Ground.RIVER_X+4.8,-0.33,72),Vector3(Ground.RIVER_X+4.8,-0.33,-72),water)
	b.joint=0
	for z: float in Ground.CROSSINGS:
		var center := Vector3(Ground.RIVER_X,0,z)
		b.block(center,Vector3(13.2,0.26,7.9),WOOD)
		for i in range(-12,13):
			b.block(center+Vector3(i*0.52,0.117,0),Vector3(0.45,0.029,7.8),WOOD.lightened(0.045*(i%3)))
		for sign_z: float in [-1,1]:
			var edge := center+Vector3(0,0,sign_z*4)
			b.block(edge+Vector3(0,0.83,0),Vector3(13.2,0.13,0.14),WOOD)
			for x: float in [-5.9,-2.1,2.1,5.9]:
				b.block(edge+Vector3(x,0.02,0),Vector3(0.22,2.1,0.22),WOOD.darkened(0.18))

func _roof(b: Builder,base: Vector3,w: float,d: float,rise: float,col: Color) -> void:
	var ridge := maxf(0.4,w-d*0.58)
	for side: float in [-1,1]:
		var outer_a := base+Vector3(-w,0.24,d*side)
		var outer_b := base+Vector3(w,0.24,d*side)
		var low_a := base+Vector3(-w*0.86,0.0,d*side*0.85)
		var low_b := base+Vector3(w*0.86,0.0,d*side*0.85)
		var top_a := base+Vector3(-ridge,rise,0)
		var top_b := base+Vector3(ridge,rise,0)
		b.quad(outer_a,outer_b,low_b,low_a,col.lightened(0.05))
		b.quad(low_a,low_b,top_b,top_a,col)
		b.tri(outer_a,low_a,top_a,col)
		b.tri(outer_b,top_b,low_b,col)
	for side: float in [-1,1]:
		b.tri(base+Vector3(side*w,0.24,-d),base+Vector3(side*w,0.24,d),base+Vector3(side*ridge,rise,0),col.darkened(0.10))
	b.rod(base+Vector3(-ridge-0.35,rise,0),base+Vector3(ridge+0.35,rise,0),0.12,0.12,col.darkened(0.15))

func _tower(b: Builder,p: Vector3) -> void:
	b.block(p+Vector3(0,2.15,0),Vector3(5.1,4.3,5.1),STONE)
	b.block(p+Vector3(0,4.36,0),Vector3(5.65,0.28,5.65),WOOD)
	for x: float in [-1.95,1.95]:
		for z: float in [-1.95,1.95]:
			b.block(p+Vector3(x,5.55,z),Vector3(0.28,2.5,0.28),WOOD)
	_roof(b,p+Vector3(0,6.55,0),3.62,3.37,1.45,SLATE)

func _fort(b: Builder) -> void:
	for side: float in [-1,1]:
		var inner := Ground.WALL_X+1.4
		var outer := Ground.WALL_X+4.6
		var ramp_start := Vector3(inner,0.03,side*5.5)
		var crest := Vector3(inner,3.25,side*(5.5+3.25/0.43))
		var end := Vector3(inner,3.25,side*(Ground.WALL_Z-1.2))
		var w := Vector3(outer-inner,0,0)
		b.quad(ramp_start,crest,crest+w,ramp_start+w,STONE.lightened(0.10))
		b.quad(crest,end,end+w,crest+w,LIME)
		b.tri(ramp_start+w,crest+w,Vector3(outer,0,crest.z),STONE)
		b.quad(crest+w,end+w,Vector3(outer,0,end.z),Vector3(outer,0,crest.z),STONE)
		var z := side*(Ground.WALL_Z+Ground.GATE_HALF)*0.5
		var length := Ground.WALL_Z-Ground.GATE_HALF
		b.block(Vector3(Ground.WALL_X,1.65,z),Vector3(2.6,3.3,length),LIME)
		b.block(Vector3(Ground.WALL_X,0.37,z),Vector3(2.9,0.75,length),STONE)
		for i in range(6,23,2):
			b.block(Vector3(Ground.WALL_X-1.07,3.59,side*i),Vector3(0.47,0.66,1.33),LIME)
		b.block(Vector3((Ground.WALL_X+Ground.BACK_X)*0.5,1.68,side*Ground.WALL_Z),Vector3(Ground.BACK_X-Ground.WALL_X,3.35,2.1),LIME)
		for x in range(49,90,2):
			b.block(Vector3(x,3.58,side*(Ground.WALL_Z+0.79)),Vector3(1.19,0.64,0.49),LIME)
		for x: float in [Ground.WALL_X,Ground.BACK_X]:
			_tower(b,Vector3(x,0,side*Ground.WALL_Z))
		_tower(b,Vector3(Ground.WALL_X,0,side*(Ground.GATE_HALF+2.6)))
		var rear_length := Ground.WALL_Z - Ground.POSTERN_HALF
		var rear_center := side * (Ground.WALL_Z + Ground.POSTERN_HALF) * 0.5
		b.block(Vector3(Ground.BACK_X,1.65,rear_center),Vector3(2.3,3.3,rear_length),LIME)
	b.block(Vector3(Ground.BACK_X,3.05,0),Vector3(2.3,0.50,Ground.POSTERN_HALF*2.0),LIME)
	b.block(Vector3(Ground.BACK_X+1.20,2.73,0),Vector3(0.25,0.23,Ground.POSTERN_HALF*2.0+0.45),WOOD)
	b.block(Vector3(Ground.WALL_X,4.16,0),Vector3(4.1,0.5,9.5),WOOD)
	_roof(b,Vector3(Ground.WALL_X,6.1,0),3.4,5.0,1.45,SLATE)
	for x: float in [65,78]:
		for z: float in [-14,14]:
			b.block(Vector3(x,1.4,z),Vector3(7,2.8,4.4),LIME)
			_roof(b,Vector3(x,2.74,z),4.45,3.02,1.12,SLATE)

func _camp(b: Builder) -> void:
	for side: float in [-1,1]:
		for i in 5:
			var p := Vector3(-64-i*6.1,0,side*(10+(i%2)*6))
			var a := p+Vector3(-2.1,0,-1.75)
			var c := p+Vector3(2.1,0,1.75)
			var top := p+Vector3(0,2.75,0)
			b.tri(a,Vector3(c.x,0,a.z),top,Color("b49e77"))
			b.tri(Vector3(c.x,0,a.z),c,top,Color("bda781"))
			b.tri(c,Vector3(a.x,0,c.z),top,Color("9b8764"))
			b.tri(Vector3(a.x,0,c.z),a,top,Color("b09b77"))
		for j in range(-100,-53,2):
			b.rod(Vector3(j,0,side*24),Vector3(j,1.65+(j%3)*0.09,side*24),0.13,0.065,WOOD)

func _tree(b: Builder,p: Vector3,h: float,variant: int) -> void:
	b.rod(p,p+Vector3(0,h*0.69,0),h*0.071,h*0.037,WOOD)
	var col: Color = [Color("536f51"),Color("65774d"),Color("717c52"),Color("627452")][variant]
	b.loft([p+Vector3(0,h*0.48,0),p+Vector3(-0.12,h*0.77,0.07),p+Vector3(0.12,h,0)],
		[Vector2(h*0.27,h*0.23),Vector2(h*0.32,h*0.31),Vector2(h*0.077,h*0.06)],7,col)

func update_battle(battle) -> void:
	gate.visible = battle.gate_hp > 0
	gate.position.y = -(1.0-battle.gate_hp/260.0)*0.45
	ram.position = Ground.unit_point(battle.ram)
	ram.rotation.z = 0.24 if battle.ram_hp <= 0 else 0.0
	ram_beam.position.x = 0.38*sin((1.7-battle.ram_timer)*TAU/1.7) if battle.ram_timer > 0 else 0.0
