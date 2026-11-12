extends Node3D
const Ground := preload("res://scripts/field/ground.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const WOOD := Color("70513b")
const LIME := Color("a48d71")
const SLATE := Color("4c5858")
const STONE := Color("838274")
const DIRT := Color("a28c67")
var surface_material:=ShaderMaterial.new()
var sun:=DirectionalLight3D.new()
var gate: MeshInstance3D
var ram: Node3D
var ram_beam: Node3D
var roofs: Array[Dictionary]=[]
var has_open_roof:=false

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
	surface_material.set_shader_parameter("fieldbed",preload("res://assets/environment/fieldbed.png"))
	surface_material.set_shader_parameter("joinery",preload("res://assets/environment/joinery.png"))
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
	_bank_litter(vegetation,rng)
	for patch: Builder in vegetation.values(): _mesh(patch,self)
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

func _bank_litter(patches: Dictionary,rng: RandomNumberGenerator) -> void:
	for i in 135:
		var z:=rng.randf_range(-65.0,65.0)
		if absf(z-Ground.crossing(z))<4.30: continue
		var side:float=-1.0 if i%2 else 1.0
		var p:=Vector2(Ground.RIVER_X+side*rng.randf_range(4.08,5.86),z)
		var b:=_vegetation_cell(patches,p)
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

func _crossings(b: Builder) -> void:
	b.joint=2
	var water:=Color("577d78")
	b.quad(Vector3(Ground.RIVER_X-4.8,-0.33,-72),Vector3(Ground.RIVER_X-4.8,-0.33,72),
		Vector3(Ground.RIVER_X+4.8,-0.33,72),Vector3(Ground.RIVER_X+4.8,-0.33,-72),water)
	for z:float in Ground.CROSSINGS:
		var center:=Vector3(Ground.RIVER_X,0,z)
		b.joint=3
		b.block(center-Vector3.UP*0.064,Vector3(13.20,0.24,7.80),WOOD.darkened(0.19))
		b.joint=10
		for i in range(-13,14):
			var length:=7.81+0.07*sin(i*13.0+z)
			var worn:=WOOD.lightened(0.035*posmod(i*7,5))
			b.block(center+Vector3(i*0.482,0.085,0),Vector3(0.47,0.09,length),worn)
		for side:float in [-1.0,1.0]:
			var edge:=center+Vector3(0,0,side*4)
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
				for h:float in [0.78,0.86]:
					b.rod(post+Vector3.UP*h,post+Vector3.UP*(h+0.047),0.128,0.128,Color("998568"),7)
				if absf(x)<3.0:
					b.joint=3
					b.rod(post-Vector3.UP*0.52,post+Vector3(signf(x)*1.10,-0.12,-side*0.05),0.091,0.089,WOOD,5)
	b.joint=0

func _roof_point(base: Vector3,along: Vector3,across: Vector3,length: float,depth: float,rise: float,u: float,t: float) -> Vector3:
	var ridge:=maxf(0.55,length-depth*0.65)
	var width:=lerpf(ridge,length,t)
	var height:=rise*pow(1.0-t,1.60)+t*t*(0.12+0.24*pow(absf(u),3.5))
	return base+along*(u*width)+across*(t*depth)+Vector3.UP*height

func _roof(b: Builder,base: Vector3,w: float,d: float,rise: float,col: Color) -> void:
	var along:=Vector3.RIGHT if w>=d else Vector3.BACK
	var across:=Vector3.BACK if w>=d else Vector3.RIGHT
	var length:=maxf(w,d)
	var depth:=minf(w,d)
	var columns:=ceili(length*2.5)
	var rows:=4
	var ridge:=maxf(0.55,length-depth*0.65)
	b.joint=5
	for sign_side: float in [-1.0,1.0]:
		var normal:=across*sign_side
		for column in columns:
			var u0:float=2.0*column/columns-1.0
			var u1:float=2.0*(column+1)/columns-1.0
			var shade:=col.lightened(0.035*((column*7)%5))
			for row in rows:
				var t0:=float(row)/rows
				var t1:=float(row+1)/rows
				var a:=_roof_point(base,along,normal,length,depth,rise,u0,t0)
				var c:=_roof_point(base,along,normal,length,depth,rise,u0,t1)
				var r:=_roof_point(base,along,normal,length,depth,rise,u1,t0)
				var end:=_roof_point(base,along,normal,length,depth,rise,u1,t1)
				b.quad(a,c,end,r,shade)
				# A rounded cover tile caps the joints of each pan tile.
				var peak:=Vector3.UP*0.043
				b.quad(a-along*0.047,c-along*0.050,c+peak,a+peak,col.lightened(0.10))
				b.quad(a+peak,c+peak,c+along*0.050,a+along*0.047,col)
				if row==rows-1:
					b.rod(c+peak,c+peak+normal*0.095,0.060,0.063,col.lightened(0.09),5)
					b.rod(c-Vector3.UP*0.04,end-Vector3.UP*0.04,0.065,0.065,WOOD,5)
		for end_sign: float in [-1.0,1.0]:
			var top:=base+along*ridge*end_sign+Vector3.UP*rise
			var edge:=_roof_point(base,along,normal,length,depth,rise,end_sign,1.0)
			var half_end:=base+along*(length*end_sign)+Vector3.UP*0.20
			b.tri(top,edge,half_end,col.darkened(0.09))
			b.rod(top,edge,0.070,0.082,col.lightened(0.08),5)
	b.rod(base-along*ridge+Vector3.UP*rise,base+along*ridge+Vector3.UP*rise,0.12,0.12,col.lightened(0.16),7)
	for end_sign: float in [-1.0,1.0]:
		var cap:=base+along*(end_sign*ridge)+Vector3.UP*rise
		b.rod(cap,cap+along*(end_sign*0.31)+Vector3.UP*0.18,0.13,0.075,col.lightened(0.12),6)

# Brackets transfer a projecting eave into its posts. These stay visible under a cutaway.
func _brackets(frame: Builder,base: Vector3,w: float,d: float) -> void:
	frame.joint=3
	for sx: float in [-1.0,1.0]:
		for sz: float in [-1.0,1.0]:
			var foot:=base+Vector3(sx*w*0.62,-0.48,sz*d*0.58)
			frame.block(foot,Vector3(0.34,0.17,0.34),WOOD.darkened(0.13))
			frame.block(foot+Vector3(sx*0.12,0.14,0),Vector3(0.66,0.15,0.24),WOOD)
			frame.block(foot+Vector3(0,0.25,sz*0.15),Vector3(0.25,0.15,0.73),WOOD.lightened(0.06))
			frame.block(foot+Vector3(sx*0.12,0.36,sz*0.16),Vector3(0.68,0.13,0.63),WOOD)

# These roofs can lift away independently while the posts, eaves, and the
# people inside remain. No soldier or combat state changes with the camera.
func _cover(frame: Builder,base: Vector3,w: float,d: float,rise: float) -> void:
	var cover:=Builder.new()
	_roof(cover,base,w,d,rise,SLATE)
	_brackets(frame,base,w,d)
	var node:=_mesh(cover,self)
	roofs.append({"node":node,"center":base+Vector3.UP*rise*0.42,"w":w,"d":d})
	for side: float in [-1,1]:
		frame.block(base+Vector3(0,-0.09,side*d*0.83),Vector3(w*1.86,0.18,0.20),WOOD)
		frame.block(base+Vector3(side*w*0.84,-0.09,0),Vector3(0.19,0.18,d*1.70),WOOD)

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
	var gate_inspection:=live and assault_near and focus.distance_squared_to(Ground.GATE)<245 and zoom< 42.0
	for roof in roofs:
		var occluding: bool=zoom<43 and (_between(p,p+direction,roof) or (live and _between(h,h+direction,roof)) or (focus.distance_squared_to(Ground.GATE)<150 and _between(door,door+direction,roof)))
		var middle: Vector3=roof.center
		if gate_inspection and absf(middle.x-Ground.WALL_X)<3 and absf(middle.z)<11:
			if absf(middle.z)<1.0:
				occluding=true
			else:
				for exit_x: float in [-2.6,1.5,5.0]:
					var lane:=door+Vector3(exit_x,0,signf(middle.z)*2.7)
					if _between(lane,lane+direction,roof):
						occluding=true
						break
		var node: MeshInstance3D=roof.node
		if occluding: has_open_roof=true
		if node.visible==occluding: node.visible=not occluding

func _sight_deck(timber: Builder,at: Vector3,w: float,d: float) -> void:
	var node:=_mesh(timber,self)
	roofs.append({"node":node,"center":at,"w":w,"d":d})

func _tower(b: Builder,p: Vector3) -> void:
	# Keep masonry inside the actual wall footprint. Posts remain when a
	# projecting watch floor cuts away along the player's line of sight.
	b.joint=8
	b.block(p+Vector3(0,1.56,0),Vector3(2.58,3.12,4.96),STONE)
	b.joint=4
	b.block(p+Vector3(0,0.31,0),Vector3(2.76,0.62,5.13),STONE.darkened(0.12))
	var deck:=Builder.new()
	deck.joint=3
	b.joint=11
	for plank in 7:
		deck.block(p+Vector3(0,4.36,(plank-3)*0.75),Vector3(5.48,0.15,0.73),WOOD.lightened(0.07*(plank%2)))
	for x: float in [-1.86,1.86]:
		deck.block(p+Vector3(x,4.18,0),Vector3(0.20,0.24,5.52),WOOD)
		for z: float in [-1.95,1.95]:
			b.rod(p+Vector3(x*0.60,3.06,z),p+Vector3(x,4.23,z),0.13,0.12,WOOD,4)
	_sight_deck(deck,p+Vector3.UP*4.32,2.74,2.75)
	for x: float in [-1.95,1.95]:
		for z: float in [-1.95,1.95]:
			b.block(p+Vector3(x,5.55,z),Vector3(0.28,2.5,0.28),WOOD)
	for side: float in [-1,1]:
		b.block(p+Vector3(0,5.02,side*2.20),Vector3(4.6,0.10,0.12),WOOD)
		b.block(p+Vector3(0,4.72,side*2.20),Vector3(4.6,0.075,0.10),WOOD)
		for x: float in [-1.1,0,1.1]:
			b.block(p+Vector3(x,4.72,side*2.2),Vector3(0.085,0.65,0.095),WOOD)
	_cover(b,p+Vector3(0,6.55,0),3.62,3.37,1.45)

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
		b.block(Vector3(Ground.WALL_X,1.65,z),Vector3(2.6,3.3,length),LIME)
		b.joint=4
		b.block(Vector3(Ground.WALL_X,0.37,z),Vector3(2.9,0.75,length),STONE)
		b.joint=8
		for layer in 4:
			var h:=0.94+layer*0.51
			var start:=Vector3(Ground.WALL_X-1.306,h,side*(Ground.GATE_HALF+0.3))
			var lift_end:=Vector3(start.x,h+0.035,side*(Ground.WALL_Z-0.4))
			b.quad(start,lift_end,lift_end+Vector3.UP*0.035,start+Vector3.UP*0.035,LIME.darkened(0.15))
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
		b.joint=8
		b.block(Vector3(Ground.BACK_X,1.65,rear_center),Vector3(2.3,3.3,rear_length),LIME)
	b.block(Vector3(Ground.BACK_X,3.05,0),Vector3(2.3,0.50,Ground.POSTERN_HALF*2.0),LIME)
	b.block(Vector3(Ground.BACK_X+1.20,2.73,0),Vector3(0.25,0.23,Ground.POSTERN_HALF*2.0+0.45),WOOD)
	var gallery:=Builder.new()
	gallery.joint=3
	for plank in 9:
		gallery.block(Vector3(Ground.WALL_X,4.16,(plank-4)*1.04),Vector3(4.1,0.21,1.02),WOOD.lightened(0.045*(plank%2)))
	_sight_deck(gallery,Vector3(Ground.WALL_X,4.16,0),2.05,4.74)
	_cover(b,Vector3(Ground.WALL_X,6.1,0),3.4,5.0,1.45)
	# Tapered gateposts support the passage even when its roof is out of sight.
	for x:float in [-1.32,1.32]:
		for z:float in [-4.18,4.18]:
			var foot:=Vector3(Ground.WALL_X+x,0,z)
			b.joint=4
			b.block(foot+Vector3.UP*0.14,Vector3(0.71,0.28,0.68),STONE)
			b.joint=11
			b.rod(foot+Vector3.UP*0.23,foot+Vector3.UP*4.12,0.25,0.217,WOOD,8)
		b.joint=10
		b.block(Vector3(Ground.WALL_X+x,4.01,0),Vector3(0.32,0.24,8.75),WOOD)
	# The entrance has its own lintel, lacquered plaque and watch pennants.
	b.block(Vector3(Ground.WALL_X-2.10,4.25,0),Vector3(0.16,0.85,3.5),Color("61483a"))
	b.block(Vector3(Ground.WALL_X-2.20,4.25,0),Vector3(0.06,0.62,2.95),Color("405450"))
	for side: float in [-1,1]:
		var post:=Vector3(Ground.WALL_X-1.65,3.45,side*5.1)
		b.rod(post,post+Vector3.UP*2.1,0.055,0.04,WOOD)
		b.quad(post+Vector3(0,2,0),post+Vector3(-0.08,1.96,side*0.92),post+Vector3(-0.21,1.30,side*0.97),post+Vector3(0,1.32,0),Color("a3543c"))
		b.tri(post+Vector3(-0.21,1.30,side*0.97),post+Vector3(-0.22,1.04,side*0.74),post+Vector3(-0.08,1.38,side*0.55),Color("b59659"))
	for x: float in [65,78]:
		for z: float in [-14,14]:
			b.joint=8
			b.block(Vector3(x,1.4,z),Vector3(7,2.8,4.4),LIME)
			_cover(b,Vector3(x,2.74,z),4.45,3.02,1.12)

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
	for placement: Vector3 in [Vector3(-69,0,-7.3),Vector3(-86,0,7.6)]:
		var cart:=preload("res://assets/environment/grain_cart.gltf").instantiate() as Node3D
		cart.position=placement
		cart.rotation.y=-0.21 if placement.z<0 else 0.48
		add_child(cart)

func _tree(b: Builder,p: Vector3,h: float,variant: int) -> void:
	var crown:=p+Vector3(0.09,h*0.55,-0.06)
	var wood:=Color("6c604c")
	b.joint=11
	b.rod(p,crown,h*0.065,h*0.038,wood,7)
	var palettes: Array[Color]=[Color("596d50"),Color("6c7950"),Color("7c8052"),Color("64764f")]
	var leaf:=palettes[variant]
	var turn:=p.x*1.7+p.z*0.9
	for limb in 4:
		var angle:=turn+limb*TAU/3.0
		var lateral:=Vector3(cos(angle),0,sin(angle))
		var tip:=crown+lateral*(h*(0.19 if limb<3 else 0.03))+Vector3.UP*h*(0.16 if limb<3 else 0.37)
		b.joint=11
		b.rod(crown-Vector3.UP*0.19,tip,h*0.032,h*0.011,wood,5)
		var size:=h*(0.22 if limb<3 else 0.17)
		b.joint=7
		var low:=tip-Vector3.UP*size*0.53
		var mid:=tip+lateral*size*0.14
		var top:=tip+Vector3.UP*size*(0.93 if variant==2 else 0.77)
		b.loft([low,mid,top],[Vector2(size*0.56,size*0.54),Vector2(size*1.1,size*0.94),Vector2(size*0.22,size*0.30)],6,leaf.lightened(0.034*limb))
		if variant==0 and limb<3:
			b.rod(mid+lateral*size*0.62,low+lateral*size*0.81-Vector3.UP*size*0.55,size*0.24,size*0.035,leaf.darkened(0.08),4)
	b.joint=0

func update_battle(battle) -> void:
	gate.visible = battle.gate_hp > 0
	gate.position.y = -(1.0-battle.gate_hp/260.0)*0.45
	ram.position = Ground.unit_point(battle.ram)
	ram.rotation.z = 0.24 if battle.ram_hp <= 0 else 0.0
	ram_beam.position.x = 0.38*sin((1.7-battle.ram_timer)*TAU/1.7) if battle.ram_timer > 0 else 0.0
