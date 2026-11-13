extends Node3D
const Ground := preload("res://scripts/field/ground.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const Foothills := preload("res://scripts/field/env_foothills.gd")
const TownGate := preload("res://scripts/field/river_gatehouse.gd")
const WOOD := Color("796752")
const LIME := Color("946d58")
const SLATE := Color("525b61")
const STONE := Color("838274")
const DIRT := Color("a28c67")
const SKIFF_WATERLINE := Vector3(Ground.RIVER_X+2.04,-.33,-7.91)
var surface_material:=ShaderMaterial.new()
var sun:=DirectionalLight3D.new()
var gate: MeshInstance3D
var ram: Node3D
var ram_beam: Node3D
var ram_wheels: Array[Node3D]=[]
var ram_model_id:=0
var last_ram_position:=Vector2.ZERO
var ram_roll:=0.0
var roofs: Array[Dictionary]=[]
var has_open_roof:=false

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("9daea5")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("d5dfd6")
	world.environment.ambient_light_energy = 0.56
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
	surface_material.set_shader_parameter("cartway",preload("res://assets/environment/river-cartway.svg"))
	surface_material.set_shader_parameter("valley_wash",preload("res://assets/environment/floodplain-paint.png"))
	surface_material.set_shader_parameter("soil_cover",preload("res://assets/environment/soil-cover.png"))

	surface_material.set_shader_parameter("field_margins",preload("res://assets/environment/field-margins.svg"))
	surface_material.set_shader_parameter("verge_track",preload("res://assets/environment/verge-and-track.svg"))
	surface_material.set_shader_parameter("shale_paint",preload("res://assets/environment/river-shale.png"))
	surface_material.set_shader_parameter("meadow_paint",preload("res://assets/environment/valley-turf.png"))
	surface_material.set_shader_parameter("grazing_detail",preload("res://assets/environment/grazed-meadow.png"))
	surface_material.set_shader_parameter("track_detail",preload("res://assets/environment/loess-wagonway.png"))
	surface_material.set_shader_parameter("lane_paint",preload("res://assets/environment/valley-loess.png"))
	surface_material.set_shader_parameter("fieldbed",preload("res://assets/environment/fieldbed.png"))
	surface_material.set_shader_parameter("joinery",preload("res://assets/environment/joinery.png"))
	var terrain:={}
	_ground_tiles(terrain)
	var river:=Builder.new()
	_crossings(river)
	_shore(river)
	_moored_skiff(river)
	_mesh(river,self)
	var city:=Builder.new()
	_fort(city)
	_dress_gate(city)
	_mesh(city,self)
	var tents:=Builder.new()
	_camp(tents)
	_mesh(tents,self)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8725
	Foothills.new().build(self,terrain)
	_bank_litter(terrain,rng)
	for tile: Builder in terrain.values(): _mesh(tile,self)
	var door:=Builder.new()
	for side:float in [-1.0,1.0]:
		door.joint=11
		var leaf:=Vector3(0,1.75,side*Ground.GATE_HALF*0.50)
		door.block(leaf,Vector3(0.52,3.50,Ground.GATE_HALF-0.06),WOOD.darkened(0.21))
		for board in 6:
			var z:=side*(0.04+(board+0.5)*0.652)
			door.block(Vector3(-0.292,1.75,z),Vector3(0.08,3.46,0.629),WOOD.lightened(0.037*(board%3)))
		door.joint=0
		for h:float in [0.59,1.55,2.78]:
			door.block(Vector3(-0.36,h,leaf.z),Vector3(0.082,0.109,3.79),SLATE.darkened(0.19))
			for z:float in [0.47,1.45,2.47,3.48]:
				door.rod(Vector3(-0.41,h,z*side),Vector3(-0.45,h,z*side),0.051,0.039,SLATE,6)
	gate=_mesh(door,self)
	gate.position=Ground.unit_point(Ground.GATE)
	ram=preload("res://assets/environment/river_ram.gltf").instantiate() as Node3D
	add_child(ram)
	ram_beam=ram.find_child("SuspendedBeam",true,false) as Node3D
	for wheel in ram.find_children("RamWheel*","Node3D",true,false):
		ram_wheels.append(wheel as Node3D)

func _mesh(builder: Builder,parent: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = builder.finish()
	mesh.material_override=surface_material
	parent.add_child(mesh)
	return mesh

func _point(x: float,z: float) -> Vector3:
	return Foothills.ground_point(Vector2(x,z))

func _ground_tiles(tiles: Dictionary) -> void:
	for x0 in range(-168,168,42):
		for z0 in range(-108,108,36):
			var land:=Builder.new()
			tiles[Foothills.tile_key(Vector2(x0,z0))]=land
			land.joint=1
			for x in range(x0,x0+42,3):
				for z in range(z0,z0+36,3):
					land.quad(_point(x,z),_point(x,z+3),_point(x+3,z+3),_point(x+3,z),Color.WHITE)

func _bank_litter(patches: Dictionary,rng: RandomNumberGenerator) -> void:
	for i in 135:
		var z:=rng.randf_range(-65.0,65.0)
		if absf(z-Ground.crossing(z))<4.30: continue
		var side:float=-1.0 if i%2 else 1.0
		var p:=Vector2(Ground.RIVER_X+side*rng.randf_range(4.08,5.86),z)
		var b:Builder=patches[Foothills.tile_key(p)]
		var foot:=_point(p.x,p.y)
		if i%3==0:
			b.joint=4
			var s:=rng.randf_range(0.11,0.35)
			b.loft([foot-Vector3.UP*0.025,foot+Vector3.UP*s*0.24,foot+Vector3.UP*s*0.49],
				[Vector2(s,s*0.69),Vector2(s*0.96,s*0.70),Vector2(s*0.42,s*0.35)],5,Color("9b9783"))
		else:
			b.joint=7
			for stem in 4:
				var q:=foot+Vector3(rng.randf_range(-0.13,0.13),0,rng.randf_range(-0.21,0.21))
				var h:=rng.randf_range(0.32,0.76)
				var tip:=q+Vector3(side*h*0.36,h,rng.randf_range(-0.26,0.26))
				var reed:=Color("92925e") if stem%2 else Color("a79d70")
				b.tri(q-Vector3(0.032,0,0.041),q+Vector3(0.038,0,0.043),tip,reed)
				if stem==0:
					b.rod(q,tip,0.014,0.011,reed,4)
					b.rod(tip-Vector3.UP*0.08,tip+Vector3.UP*0.06,0.031,0.022,Color("7d6a50"),4)
		b.joint=0

func _shore(b: Builder) -> void:
	b.joint=13
	for side:float in [-1.0,1.0]:
		var last: Array[Vector3]=[]
		for step in range(-108,109):
			var z:=float(step)
			var clear:=smoothstep(4.1,8.5,absf(z-Ground.crossing(z)))
			var bend:=clear*(0.64*sin(z*.32+side*1.9)+0.44*sin(z*.16-side))
			# Gravel collects downstream of bridge landings. The silhouette lies
			# inside the non-walkable channel and remains under the wetted slope.
			var spit:=0.0
			for heel:float in [-43.0,-9.0,10.0,44.0]:
				var dz:float=z-heel*side
				spit+=exp(-dz*dz/(5.2 if dz<0.0 else 19.0))
			var water_edge:=4.43+bend-0.94*spit
			# Between landings the turf overhangs a shallow exposed peat face.
			# The broken toe projects into the same non-traversable water.
			var undercut:=clear*smoothstep(-.22,.68,sin(z*.24+side*1.4)+.48*sin(z*.79))
			var inner:=Vector3(Ground.RIVER_X+side*(water_edge-.44),-.388,z)
			var shelf:=Vector3(Ground.RIVER_X+side*(water_edge+.24),-.263+.040*sin(z*.64),z)
			var recess:=Vector3(Ground.RIVER_X+side*(water_edge+.49+.19*undercut),-.214+.025*sin(z*.67),z)
			var sod:=Vector3(Ground.RIVER_X+side*(water_edge+.60-.32*undercut),-.140+.16*undercut,z)
			var high:=Vector3(Ground.RIVER_X+side*(5.62+bend*.54),-.078+.037*sin(z*.38+side),z)
			var lip:=_point(Ground.RIVER_X+side*(6.94+bend*.34),z)+Vector3.UP*.009
			var row: Array[Vector3]=[inner,shelf,recess,sod,high,lip]
			if not last.is_empty():
				for band in range(row.size()-1):
					b.joint=18 if band==2 and undercut>.24 else 13
					if band==2 and undercut>.24:
						if side<0.0: b.quad(last[band],row[band],row[band+1],last[band+1],Color.WHITE)
						else: b.quad(row[band],last[band],last[band+1],row[band+1],Color.WHITE)
					else:
						_upward_quad(b,last[band],row[band],row[band+1],last[band+1],Color.WHITE)
			last=row
	b.joint=0

func _moored_skiff(bank: Builder) -> void:
	# The working bank lies upstream of the middle bridge, in the unwalkable channel.
	var origin:=SKIFF_WATERLINE
	var skiff:=preload("res://assets/environment/river_skiff.gltf").instantiate() as Node3D
	skiff.position=origin
	add_child(skiff)
	var bow:=origin+Vector3(.09,.55,-2.49)
	var post:=Vector3(Ground.RIVER_X+4.88,.30,-10.96)
	bank.joint=11
	bank.rod(post-Vector3(.035,.77,0),post+Vector3(.025,.16,0),.103,.083,WOOD,7)
	var sag:=bow.lerp(post,.54)-Vector3.UP*.19
	bank.joint=6
	var flax:=Color("a89572")
	bank.rod(bow,sag,.031,.029,flax,6)
	bank.rod(sag,post,.029,.033,flax,6)
	for ring in 2:
		var tie:=post-Vector3.UP*(ring*.061)
		bank.rod(tie-Vector3.UP*.029,tie+Vector3.UP*.029,.112,.111,flax,7)
	bank.joint=0

# Multi-course landings grow out of the existing blocked riverbank. The cap
# returns end below the deck; the playable width and foot heights are unchanged.
func _bridge_landing(b: Builder,center: Vector3,bank: float,side: float) -> void:
	var courses: Array[Color]=[Color("686d68"),Color("7b8076"),Color("888c80")]
	for row in 3:
		var elevation:float=-.52+.209*row
		var inset:=.055*row
		for i in 3:
			var u:=float(i)/2.
			var start:=4.67+u*2.50+.13*(row%2)
			var cheek:=side*(3.95+u*.58)
			var p:=center+Vector3(bank*start,elevation,cheek)
			var reach:=1.38-.16*u
			b.joint=4
			b.block(p,Vector3(reach,.212,.51-inset),courses[row].darkened(.032*((i+row)%3)))
			if row==2:
				var cap:=p+Vector3(bank*.03,.119,0)
				b.block(cap,Vector3(reach+.073,.092,.60-inset),Color("9a9a86"))

func _river_surface(b: Builder) -> void:
	b.joint=2
	var water:=Color("577d78")
	var west:=Ground.RIVER_X-6.8
	var east:=Ground.RIVER_X+6.8
	var level:=SKIFF_WATERLINE.y
	# Cut the water between the inside and the outside of the hull at its
	# waterline. A single water quad used to fill the seats and bottom boards.
	var stations: Array[Vector2]=[Vector2(-2.30,0.),Vector2(-2.19,.25),Vector2(-1.45,.54),
		Vector2(-.55,.65),Vector2(.60,.64),Vector2(1.52,.49),Vector2(2.13,.20),Vector2(2.19,0.)]
	var previous:=SKIFF_WATERLINE.z+stations[0].x
	b.quad(Vector3(west,level,-108),Vector3(west,level,previous),Vector3(east,level,previous),Vector3(east,level,-108),water)
	var previous_width:=0.
	for i in range(1,stations.size()):
		var next:=SKIFF_WATERLINE.z+stations[i].x
		var w:=stations[i].y
		var mid:=SKIFF_WATERLINE.x
		b.quad(Vector3(west,level,previous),Vector3(west,level,next),Vector3(mid-w,level,next),Vector3(mid-previous_width,level,previous),water)
		b.quad(Vector3(mid+previous_width,level,previous),Vector3(mid+w,level,next),Vector3(east,level,next),Vector3(east,level,previous),water)
		previous=next
		previous_width=w
	b.quad(Vector3(west,level,previous),Vector3(west,level,108),Vector3(east,level,108),Vector3(east,level,previous),water)

func _crossings(b: Builder) -> void:
	_river_surface(b)
	for z:float in Ground.CROSSINGS:
		var center:=Vector3(Ground.RIVER_X,0,z)
		b.joint=3
		b.block(center-Vector3.UP*0.064,Vector3(13.20,0.24,7.80),WOOD.darkened(0.19))
		b.joint=16
		for i in range(-13,14):
			var length:=7.80+0.085*sin(i*13.0+z)
			var seam:=1.02*sin(i*1.14+z*0.13)
			var worn:=Color("716657").lerp(Color("897c68"),.42+.23*sin(i*.64+z*.32)+.12*cos(i*1.41+z))
			var board_top:=.085+.006*sin(i*4.32+z)
			for edge_sign:float in [-1.0,1.0]:
				var end:=edge_sign*length*0.5
				b.block(center+Vector3(i*0.482,board_top,(end+seam)*0.5),Vector3(0.47,0.09,absf(end-seam)-0.021),worn.lightened(0.025*edge_sign))
		for side:float in [-1.0,1.0]:
			var edge:=center+Vector3(0,0,side*4)
			b.joint=3
			for bank:float in [-1.,1.]:
				_bridge_landing(b,center,bank,side)
			b.joint=3
			for start_x:float in [-5.97,-2.04,2.05]:
				b.rod(edge+Vector3(start_x+0.13,0.35,0),edge+Vector3(start_x+1.99,0.80,0),0.056,0.055,WOOD,5)
			b.joint=12
			for pier:float in [-2.03,2.03]:
				var stone:=edge+Vector3(pier,-0.30,side*0.16)
				b.loft([stone,stone+Vector3.UP*0.33,stone+Vector3.UP*0.42],
					[Vector2(0.48,0.80),Vector2(0.39,0.68),Vector2(0.32,0.60)],6,Color("858c80"))
			b.joint=4
			var abutment:=center+Vector3(side*5.85,-0.36,0)
			b.block(abutment,Vector3(1.34,0.66,8.07),STONE.darkened(0.06))
			b.joint=3
			b.block(edge+Vector3(0,0.86,0),Vector3(13.23,0.11,0.14),WOOD.lightened(0.09))
			b.block(edge+Vector3(0,0.46,0),Vector3(13.0,0.085,0.095),WOOD)
			b.block(edge+Vector3(0,-0.11,0),Vector3(13.24,0.24,0.22),WOOD.darkened(0.12))
			for x:float in [-5.98,-2.03,2.03,5.98]:
				b.joint=11
				var post:=edge+Vector3(x,0,0)
				b.rod(post-Vector3.UP*0.70,post+Vector3.UP*1.03,0.13,0.109,WOOD,7)
				b.rod(post+Vector3.UP*0.99,post+Vector3.UP*1.12,0.14,0.104,WOOD.lightened(0.11),7)
				if absf(x)>4.0:
					b.joint=4
					var kerb:=post+Vector3(signf(x)*.43,0.,side*.19)
					b.loft([kerb-Vector3.UP*.09,kerb+Vector3.UP*.17,kerb+Vector3.UP*.27],
						[Vector2(.30,.37),Vector2(.29,.35),Vector2(.23,.30)],8,Color("8c8d7e"))
					b.joint=11
				if absf(x)>4.0 and signf(x)==side:
					# Rag strips on two corner posts show wind and mark the landing.
					# Both tails stay outboard of the playable bridge deck.
					b.joint=15
					var at:=post+Vector3(.0,.87,side*.12)
					var fold:=at+Vector3(.27,-.080,side*.18)
					var tip:=at+Vector3(.72,-.136,side*.46)
					var dye:=Color("884a42")
					b.quad(at,fold,fold-Vector3.UP*.087,at-Vector3.UP*.108,dye.darkened(.12))
					b.quad(fold,tip,tip-Vector3.UP*.071,fold-Vector3.UP*.087,dye)
					b.tri(tip,tip+Vector3(.22,-.072,side*.10),tip-Vector3.UP*.071,dye)
					b.joint=11
				for h:float in [0.78,0.86]:
					b.rod(post+Vector3.UP*h,post+Vector3.UP*(h+0.047),0.128,0.128,Color("998568"),7)
				if absf(x)<3.0:
					b.joint=3
					b.rod(post-Vector3.UP*0.52,post+Vector3(signf(x)*1.10,-0.12,-side*0.05),0.091,0.089,WOOD,5)
		# The downstream piles and mooring hawser give the bridge a working
		# bank without placing extra props across its walkable deck.
		var landing:=center+Vector3(-7.17,0,4.75)
		b.joint=11
		for n in 2:
			var stake:=landing+Vector3(.28*n,0,.24*n)
			b.rod(stake-Vector3.UP*.28,stake+Vector3(.045,.90+.32*n,.03),.16,.115,WOOD.darkened(.16),7)
			b.joint=6
			for wrap in 3:
				var y:=.61+wrap*.075
				b.rod(stake+Vector3(.025,y,.013),stake+Vector3(.028,y+.052,.019),.153,.149,Color("a59475"),7)
			b.joint=11
		b.joint=6
		var rope:=Color("9b8766")
		var line_start:=landing+Vector3(.05,.74,.02)
		var dip:=line_start.lerp(center+Vector3(-5.97,.79,4),.54)-Vector3.UP*.23
		b.rod(line_start,dip,.035,.033,rope,5)
		b.rod(dip,center+Vector3(-5.97,.79,4),.033,.036,rope,5)

	b.joint=0

func _upward_quad(b: Builder,a: Vector3,c: Vector3,d: Vector3,end: Vector3,paint: Color) -> void:
	# Orient each outward quad towards the sky, including cut and tapered panels.
	if (c-a).cross(end-a).y<0.0:
		b.quad(a,end,d,c,paint)
	else:
		b.quad(a,c,d,end,paint)

func _between(target: Vector3,eye: Vector3,roof: Dictionary) -> bool:
	var center: Vector3=roof.center
	var ray:=eye-target
	if ray.y<0.05 or center.y<=target.y: return false
	var t: float=(center.y-target.y)/ray.y
	if t<0 or t>1: return false
	var cross_at:=target+t*ray
	return absf(cross_at.x-center.x)<float(roof.w)+0.9 and absf(cross_at.z-center.z)<float(roof.d)+0.9

func reveal_sightline(focus: Vector2,hero: Vector2,eye: Vector3,zoom: float,live: bool,assault_near: bool=false) -> void:
	if not has_open_roof and focus.x<24 and hero.x<24: return
	has_open_roof=false
	var p:=Ground.unit_point(focus)+Vector3.UP*0.85
	var h:=Ground.unit_point(hero)+Vector3.UP*0.85
	var door:=Ground.unit_point(Ground.GATE)+Vector3.UP*1.2
	# In an orthographic camera the rays through every subject are parallel.
	var direction:=eye-Ground.unit_point(focus)
	# A survey over the gate should show the complete building. At fighting
	# distance reveal a sightline through the actual roof to the hero or lane.
	var close_lens:=zoom<=25.0
	var gate_inspection:=live and close_lens and assault_near and focus.distance_squared_to(Ground.GATE)<150.0
	for roof in roofs:
		var middle:Vector3=roof.center
		var gatehouse:=absf(middle.x-Ground.WALL_X)<3.0 and absf(middle.z)<11.0
		var hero_ray:=live and _between(h,h+direction,roof)
		var focus_ray:=(_between(p,p+direction,roof) and (not gatehouse or close_lens))
		var occluding:=zoom<43.0 and (hero_ray or focus_ray)
		if gate_inspection and gatehouse and not occluding:
			for exit_x:float in [-2.6,1.5,5.0]:
				var lane:=door+Vector3(exit_x,0,signf(middle.z)*2.7)
				if _between(lane,lane+direction,roof):
					occluding=true
					break
		var node: MeshInstance3D=roof.node
		if occluding: has_open_roof=true
		if node.visible==occluding: node.visible=not occluding
		if roof.has("pieces"):
			for piece:Dictionary in roof.pieces:
				var far_eave:MeshInstance3D=piece.node
				var normal:Vector3=piece.normal
				far_eave.visible=occluding and direction.dot(normal)<0.0 and not _between(p,p+direction,piece) and not _between(h,h+direction,piece) and not _between(door,door+direction,piece)

func _dress_gate(b: Builder) -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=14709
	for side:float in [-1.0,1.0]:
		for row in 3:
			var z:=Ground.GATE_HALF+0.035
			while z<Ground.WALL_Z-0.15:
				var length:=minf(rng.randf_range(0.80,1.68),Ground.WALL_Z-z)
				var y:=row*0.31
				var out:=Ground.WALL_X-1.51+row*0.044+rng.randf_range(-0.032,0.025)
				var a:=Vector3(out,y+0.021,side*(z+0.018))
				var c:=Vector3(out,y+0.021,side*(z+length-0.024))
				var d:=Vector3(out+0.045,y+0.302,side*(z+length-0.055))
				var end:=Vector3(out+0.033,y+0.31,side*(z+0.062))
				b.joint=12
				var tone:=Color("93988d").lightened(rng.randf_range(-0.10,0.11))
				b.quad(a,c,d,end,tone.darkened(0.06))
				b.quad(end,d,d+Vector3(0.17,0.036,0),end+Vector3(0.16,0.031,0),tone)
				b.quad(a,end,end+Vector3(0.11,0,0),a+Vector3(0.11,0,0),tone.darkened(0.25))
				z+=maxf(0.15,length)
		for i in range(6,23,2):
			b.joint=12
			b.block(Vector3(Ground.WALL_X-1.07,3.948,side*i),Vector3(0.59,0.084,1.43),Color("969689"))
		# Gate jambs turn into the throat. Battles can still pass below the lintel.
		for row in 6:
			var h:=0.25+row*0.56
			b.joint=12
			b.block(Vector3(Ground.WALL_X-1.31,h,side*4.19),Vector3(0.64,0.51,0.45+(row%2)*0.16),Color("949487").lightened((row%3)*0.026))
		var flag:=Vector3(Ground.WALL_X-1.12,3.29,side*5.74)
		b.joint=11
		b.rod(flag,flag+Vector3.UP*4.67,0.079,0.047,WOOD,7)
		var tip:=flag+Vector3.UP*4.46
		b.joint=15
		var cloth:=Color("8e493e")
		var mid:=tip+Vector3(-0.19,-0.12,side*0.72)
		var tail:=tip+Vector3(-0.31,-0.10,side*1.42)
		b.quad(tip,mid,mid-Vector3.UP*1.63,tip-Vector3.UP*1.73,cloth)
		b.quad(mid,tail,tail-Vector3.UP*1.55,mid-Vector3.UP*1.63,cloth.lightened(0.065))
		b.tri(mid-Vector3.UP*1.63,tail-Vector3.UP*1.55,tail-Vector3.UP*1.96,cloth.darkened(0.07))
		# Stitched, matte linen signal, cut to the folds on the two-sided cloth.
		var seam:=Vector3(-.012,0,0)
		var badge:=Color("bcaa7e")
		var middle:=mid+seam-Vector3.UP*.85
		b.quad(tip+seam-Vector3.UP*.47,mid+seam-Vector3.UP*.68,middle,tip+seam-Vector3.UP*.64,badge)
		b.quad(mid+seam-Vector3.UP*.68,tail+seam-Vector3.UP*.41,tail+seam-Vector3.UP*.57,middle,badge)
		b.joint=10
		b.rod(tip-Vector3(0,0,side*.09),tail+Vector3(0,0,side*.045),.044,.037,WOOD,5)
		b.joint=15
		var edge:=Vector3(-0.015,-0.18,0)
		b.quad(tip+edge,mid+edge,mid+edge-Vector3.UP*0.089,tip+edge-Vector3.UP*0.089,Color("b8a47d"))
	b.joint=10
	b.block(Vector3(Ground.WALL_X-1.45,3.68,0),Vector3(0.57,0.30,8.66),Color("71574a"))
	b.block(Vector3(Ground.WALL_X-1.50,3.92,0),Vector3(0.69,0.14,8.92),Color("8b7258"))

func _fort(b: Builder) -> void:
	for side: float in [-1,1]:
		var inner := Ground.WALL_X+1.4
		var outer := Ground.WALL_X+4.6
		var ramp_start := Vector3(inner,0.03,side*5.5)
		var crest := Vector3(inner,3.25,side*(5.5+3.25/0.43))
		var end := Vector3(inner,3.25,side*(Ground.WALL_Z-1.2))
		var w := Vector3(outer-inner,0,0)
		b.joint=4
		b.quad(ramp_start,crest,crest+w,ramp_start+w,STONE.lightened(0.10))
		b.quad(crest,end,end+w,crest+w,LIME)
		b.tri(ramp_start+w,crest+w,Vector3(outer,0,crest.z),STONE)
		b.quad(crest+w,end+w,Vector3(outer,0,end.z),Vector3(outer,0,crest.z),STONE)
		var z := side*(Ground.WALL_Z+Ground.GATE_HALF)*0.5
		var length := Ground.WALL_Z-Ground.GATE_HALF
		b.joint=8
		b.block(Vector3(Ground.WALL_X,1.65,z),Vector3(2.6,3.3,length),Color("8d8068"))
		b.joint=4
		b.block(Vector3(Ground.WALL_X,0.37,z),Vector3(2.9,0.75,length),STONE)
		b.joint=8
		for layer in 4:
			var h:=0.94+layer*0.51
			var start:=Vector3(Ground.WALL_X-1.306,h,side*(Ground.GATE_HALF+0.3))
			var lift_end:=Vector3(start.x,h+0.035,side*(Ground.WALL_Z-0.4))
			b.quad(start,lift_end,lift_end+Vector3.UP*0.035,start+Vector3.UP*0.035,Color("7d735f"))
		for i in range(6,23,2):
			b.block(Vector3(Ground.WALL_X-1.07,3.59,side*i),Vector3(0.47,0.66,1.33),Color("9b9079"))
		TownGate.mount_curtain(self,Vector3(Ground.WALL_X,0,side*Ground.WALL_Z),
				Vector3(Ground.BACK_X,0,side*Ground.WALL_Z))
		for x: float in [Ground.WALL_X,Ground.BACK_X]:
			TownGate.mount_corner(self,Vector3(x,0,side*Ground.WALL_Z),roofs)
		var sentry_z:=side*(Ground.GATE_HALF+4.90)
		# A battered stone footing marks the two flanks of the earthen gate.
		# All masonry remains over the existing wall, clear of the ram's lane.
		var face:=Ground.WALL_X-1.29
		for sign_z:float in [-1.0,1.0]:
			var joist:=sentry_z+sign_z*1.87
			var toe:=Vector3(face-.53,.025,joist)
			var head:=Vector3(face-.055,3.12,joist)
			var width:=Vector3(0,0,.42)
			var head_width:=width*.68
			var back:=Vector3(face+.19,0,joist)
			b.joint=12
			b.quad(toe-width,toe+width,head+head_width,head-head_width,Color("898979"))
			b.quad(toe+width,back+width,back+Vector3.UP*3.12+head_width,head+head_width,Color("7c8074"))
			b.quad(toe-width,head-head_width,back+Vector3.UP*3.12-head_width,back-width,Color("7c8074"))
		TownGate.mount_curtain(self,Vector3(Ground.BACK_X,0,side*Ground.POSTERN_HALF),
				Vector3(Ground.BACK_X,0,side*Ground.WALL_Z))
	b.block(Vector3(Ground.BACK_X,3.05,0),Vector3(2.3,0.50,Ground.POSTERN_HALF*2.0),LIME)
	b.block(Vector3(Ground.BACK_X+1.20,2.73,0),Vector3(0.25,0.23,Ground.POSTERN_HALF*2.0+0.45),WOOD)
	TownGate.mount(self,Ground.WALL_X,roofs)
	# The plaque is mounted on the gatehouse in the world. It uses the same
	# redistributable Chinese face as the existing HUD when it is installed.
	b.block(Vector3(Ground.WALL_X-2.85,4.45,0),Vector3(0.16,0.69,3.10),Color("61483a"))
	b.block(Vector3(Ground.WALL_X-2.95,4.45,0),Vector3(0.06,0.52,2.75),Color("344a46"))
	var font_path:="res://assets/fonts/NotoSansSC-Regular.otf"
	if ResourceLoader.exists(font_path):
		var plaque:=Label3D.new()
		plaque.font=load(font_path) as Font
		plaque.text="河  關"
		plaque.font_size=64
		plaque.pixel_size=0.0083
		plaque.outline_size=0
		plaque.modulate=Color("d8bd83")
		plaque.double_sided=false
		plaque.position=Vector3(Ground.WALL_X-2.995,4.45,0)
		plaque.rotation.y=-PI*0.5
		add_child(plaque)
	for side: float in [-1,1]:
		var post:=Vector3(Ground.WALL_X-1.65,3.45,side*5.1)
		b.rod(post,post+Vector3.UP*2.1,0.055,0.04,WOOD)
		b.quad(post+Vector3(0,2,0),post+Vector3(-0.08,1.96,side*0.92),post+Vector3(-0.21,1.30,side*0.97),post+Vector3(0,1.32,0),Color("a3543c"))
		b.tri(post+Vector3(-0.21,1.30,side*0.97),post+Vector3(-0.22,1.04,side*0.74),post+Vector3(-0.08,1.38,side*0.55),Color("b59659"))
	for x: float in [65,78]:
		# Reserve the front of the court for its independent holding companies.
		# The eaves finish before the inner foot of the side wall.
		for z: float in [-19.2,19.2]:
			TownGate.mount_quarters(self,Vector3(x,0,z),x>70.,roofs)

func _tent(b: Builder,p: Vector3,shade: Color,reverse: float) -> void:
	var along:=Vector3.BACK*reverse
	var side:=Vector3.RIGHT
	var length:=2.05
	var peak:=2.53
	# Stitched panels drape from the ridge before their tension lines reach the pegs.
	var sections: Array[Vector2]=[Vector2(0,peak),Vector2(0.82,1.42),Vector2(1.65,0.43)]
	b.joint=6
	for sign_x: float in [-1.0,1.0]:
		for strip in 4:
			var z0:float=-length+strip*length*0.5
			var z1:=z0+length*0.5
			for band in range(sections.size()-1):
				var upper:=sections[band]
				var lower:=sections[band+1]
				var a:=p+along*z0+side*(upper.x*sign_x)+Vector3.UP*upper.y
				var c:=p+along*z0+side*(lower.x*sign_x)+Vector3.UP*lower.y
				b.quad(a,c,c+along*(z1-z0),a+along*(z1-z0),shade.lightened(0.025*((strip+band)%3)))
				b.rod(a,c,0.026,0.026,shade.darkened(0.14),4)
		var foot:=p+along*length+side*(1.64*sign_x)+Vector3.UP*0.42
		var ridge:=p+along*length+Vector3.UP*peak
		b.tri(foot,ridge,p+along*(length+0.09)+side*(1.03*sign_x)+Vector3.UP*0.31,shade.darkened(0.08))
		b.tri(p-along*length+side*(1.64*sign_x)+Vector3.UP*0.42,p-along*length+Vector3.UP*peak,p-along*length+Vector3.UP*0.15,shade.darkened(0.11))
		for end_sign: float in [-1.0,1.0]:
			var edge:=p+along*(length*0.83*end_sign)+side*(1.64*sign_x)+Vector3.UP*0.45
			var peg:=p+along*(length*end_sign)+side*(2.09*sign_x)
			b.rod(edge,peg+Vector3.UP*0.13,0.022,0.022,Color("a39272"),4)
			b.rod(peg,peg+Vector3(0.04,0.22,0),0.041,0.033,WOOD,4)
	b.joint=11
	for end_sign: float in [-1.0,1.0]:
		var pole:=p+along*(length*0.98*end_sign)
		b.rod(pole,pole+Vector3.UP*(peak+0.07),0.063,0.045,WOOD,6)
	b.joint=3

func _woven_basket(b: Builder,base: Vector3,radius: float,h: float,full: bool) -> void:
	var straw:=Color("9c885a")
	b.joint=6
	var heights: Array=[base,base+Vector3.UP*h*.27,base+Vector3.UP*h*.88,base+Vector3.UP*h]
	b.loft(heights,[Vector2.ONE*radius*.67,Vector2.ONE*radius*.93,Vector2.ONE*radius,Vector2.ONE*radius*.96],8,straw)
	for fraction:float in [.32,.67,.97]:
		var r:float=radius*(.92 if fraction<.5 else 1.01)
		var at:=base+Vector3.UP*h*fraction
		var ring:=b.ring(at,Vector2.ONE*r,8)
		for i in ring.size():
			b.rod(ring[i],ring[(i+1)%ring.size()],.023,.023,straw.darkened(.23),4)
	var center:=base+Vector3.UP*(h+.006)
	var rim:=b.ring(center,Vector2.ONE*radius*.87,8)
	for i in rim.size():
		b.tri(center,rim[i],rim[(i+1)%rim.size()],Color("83785a") if full else Color("454b41"))
	if full:
		for i in 3:
			var bundle:=center+Vector3(cos(i*2.4)*radius*.32,-.03,sin(i*2.4)*radius*.32)
			b.loft([bundle,bundle+Vector3.UP*.14,bundle+Vector3.UP*.23],[Vector2(.21,.14),Vector2(.15,.11),Vector2(.035,.031)],6,Color("b6a17b"))

func _quartermaster(b: Builder,p: Vector3) -> void:
	var red:=Color("865448")
	var canvas:=Color("9eab9b")
	# A raised supply shade has open sides and four tensioned, overlapped panels.
	var peaks: Array[Vector3]=[]
	for z:float in [-1.19,1.19]:
		for x:float in [-2.16,2.16]:
			var foot:=p+Vector3(x,0,z)
			var top:=foot+Vector3(.03,2.18 if z<0.0 else 1.68,.04)
			b.joint=11
			b.rod(foot,top+Vector3.UP*.17,.079,.056,WOOD.darkened(.08),6)
			peaks.append(top)
	b.joint=3
	b.rod(peaks[0],peaks[1],.071,.065,WOOD,6)
	b.rod(peaks[2],peaks[3],.066,.061,WOOD,6)
	b.joint=6
	for i in 4:
		var f0:=i*.25
		var f1:=(i+1)*.25
		var a:Vector3=peaks[0].lerp(peaks[1],f0)
		var c:Vector3=peaks[0].lerp(peaks[1],f1)
		var d:Vector3=peaks[2].lerp(peaks[3],f1)
		var end:Vector3=peaks[2].lerp(peaks[3],f0)
		var sag:=Vector3(0,-.13,0)
		var a_mid:=a.lerp(end,.56)+sag
		var c_mid:=c.lerp(d,.56)+sag
		var tint:=canvas.lightened(.035*(i%2))
		_upward_quad(b,a,c,c_mid,a_mid,tint)
		_upward_quad(b,a_mid,c_mid,d,end,tint.darkened(.05))
		var lip:=Vector3(0,-.18,-.06)
		b.quad(a,a+lip,c+lip,c,red if i==0 else canvas.darkened(.21))
	# Two shuttered stores and actual baskets sit beneath the canopy.
	for i in 2:
		var chest:=p+Vector3(.38+i*.93,.31,.35)
		b.joint=3
		b.block(chest,Vector3(.84,.61,.72),WOOD.lightened(.06+.06*i))
		for band:float in [-.26,.26]:
			b.joint=4
			b.block(chest+Vector3(band,.03,0),Vector3(.065,.63,.735),SLATE.darkened(.12))
	_woven_basket(b,p+Vector3(-1.05,0,-.76),.44,.66,true)
	_woven_basket(b,p+Vector3(-1.69,0,-.27),.34,.54,false)
	_woven_basket(b,p+Vector3(-1.32,0,.50),.39,.62,true)
	# Small faded cloth markers hang from the ridge end, below the skyline.
	b.joint=6
	var top:=peaks[0]+Vector3.UP*.08
	b.tri(top,top+Vector3(-.12,-.62,.06),top+Vector3(-.32,-.31,.12),red)
	b.tri(top+Vector3(0,-.07,.045),top+Vector3(.17,-.51,.16),top+Vector3(.32,-.31,.20),canvas)

func _cookfire(b: Builder,p: Vector3) -> void:
	b.joint=12
	var ash:=p+Vector3.UP*.027
	b.loft([ash-Vector3.UP*.06,ash],[Vector2(.68,.54),Vector2(.65,.51)],9,Color("4e5549"))
	for i in 7:
		var a:=i*TAU/7.0
		var brick:=p+Vector3(cos(a)*.62,.026,sin(a)*.50)
		b.loft([brick-Vector3.UP*.06,brick+Vector3.UP*.10,brick+Vector3.UP*.18],
			[Vector2(.23,.18),Vector2(.24,.20),Vector2(.16,.12)],5,STONE.lightened(.036*(i%3)))
	b.joint=11
	var hook:=p+Vector3(.03,1.46,.12)
	for i in 3:
		var a:=.4+i*TAU/3.0
		b.rod(p+Vector3(cos(a)*.91,0,sin(a)*.71),hook+Vector3(i*.046,.09,0),.062,.044,WOOD.darkened(.19),5)
	b.joint=4
	var pot:=p+Vector3(0,.31,.03)
	b.rod(hook,pot+Vector3.UP*.39,.018,.018,SLATE.darkened(.36),4)
	b.loft([pot,pot+Vector3.UP*.17,pot+Vector3.UP*.37],
		[Vector2(.25,.23),Vector2(.44,.39),Vector2(.36,.33)],8,SLATE.darkened(.23))

func _camp(b: Builder) -> void:
	var cloth: Array[Color]=[Color("b4a58b"),Color("a3977c"),Color("beb09a"),Color("9c927c")]
	for side: float in [-1.0,1.0]:
		for i in 5:
			var p:=Vector3(-64.0-i*6.1,0,side*(10.0+(i%2)*6.0))
			_tent(b,p,cloth[(i+int(side+1.0))%cloth.size()],-side)
		b.joint=11
		for j in range(-100,-53,2):
			b.rod(Vector3(j,0,side*24),Vector3(j+0.04,1.65+(j%3)*0.09,side*24),0.13,0.065,WOOD)
		b.joint=3
		for h:float in [0.50,1.10]:
			b.rod(Vector3(-100,h,side*24),Vector3(-54,h-0.04,side*24),0.085,0.071,WOOD.darkened(0.12),5)
	_quartermaster(b,Vector3(-65.25,0,-18.65))
	_cookfire(b,Vector3(-70.18,0,-20.62))
	_cookfire(b,Vector3(-82.43,0,19.18))
	for placement: Vector3 in [Vector3(-69,0,-7.3),Vector3(-86,0,7.6)]:
		var cart:=preload("res://assets/environment/grain_cart.gltf").instantiate() as Node3D
		cart.position=placement
		cart.rotation.y=-0.21 if placement.z<0 else 0.48
		add_child(cart)

func update_battle(battle) -> void:
	gate.visible = battle.gate_hp > 0
	gate.position.y = -(1.0-battle.gate_hp/260.0)*0.45
	if ram_model_id!=battle.get_instance_id():
		ram_model_id=battle.get_instance_id()
		last_ram_position=battle.ram
		ram_roll=0.
		for wheel in ram_wheels: wheel.rotation.z=0.
	if last_ram_position!=battle.ram:
		var distance:float=last_ram_position.distance_to(battle.ram)
		ram_roll=fposmod(ram_roll-distance/.48,TAU)
		last_ram_position=battle.ram
		for wheel in ram_wheels: wheel.rotation.z=ram_roll
	ram.position=Ground.unit_point(battle.ram)
	ram.rotation.z = 0.24 if battle.ram_hp <= 0 else 0.0
	ram_beam.position.x = 0.38*sin((1.7-battle.ram_timer)*TAU/1.7) if battle.ram_timer > 0 else 0.0
