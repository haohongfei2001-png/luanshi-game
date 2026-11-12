extends RefCounted
## Original painted branch sprays, field paving and split rock grouped by terrain cell.
const Ground := preload("res://scripts/field/ground.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const PLAN := preload("res://assets/environment/foothills.json")
const STANDS := preload("res://assets/environment/stand-placements.json")
const BARK := Color("605d49")
const LIMESTONE := Color("64716a")
const TOP := Color("818a78")
var cells: Dictionary={}
var leaf_material:=ShaderMaterial.new()
var terrain_tiles: Dictionary
var rng:=RandomNumberGenerator.new()
var trees: Array[Dictionary]=[]

class Patch:
	var stone:Builder
	var leaves:=SurfaceTool.new()
	var sprays:=0
	func _init(tile: Builder=null) -> void:
		stone=tile if tile!=null else Builder.new()
		if tile==null: stone.open_ends=true
		leaves.begin(Mesh.PRIMITIVE_TRIANGLES)

static func tile_key(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x/42.0),floori(p.y/36.0))

func _cell(p: Vector2) -> Patch:
	# Ground and trunks share existing 42 × 36 m opaque draws. A leaf crown
	# can be culled at half that span without splitting the supporting terrain.
	var key:=Vector2i(floori(p.x/21.0),floori(p.y/18.0))
	if not cells.has(key): cells[key]=Patch.new(terrain_tiles[tile_key(p)])
	return cells[key]

static func ground_point(p: Vector2) -> Vector3:
	var beyond:=maxf(absf(p.x)-Ground.LIMIT.x,absf(p.y)-Ground.LIMIT.y)
	var skyline:=smoothstep(0.0,31.0,beyond)*smoothstep(6.0,19.0,absf(p.x-Ground.RIVER_X))
	var rise:=skyline*(7.5+3.2*sin(p.x*0.095+p.y*0.032)+2.0*cos(p.y*0.14))
	return Vector3(p.x,Ground.height(p)+rise,p.y)

func _spray(patch: Patch,base: Vector3,tip: Vector3,side: Vector3,tile: int,light: float,river_grass: bool=false) -> void:
	var tx:=.75 if river_grass else float(tile%2)*.5
	var ty:=float(tile/2)*.5
	var u0:=tx+.010
	var u1:=tx+(.238 if river_grass else .490)
	var v0:=.99 if river_grass else (ty+.490 if tile!=1 else ty+.010)
	var v1:=.01 if river_grass else (ty+.010 if tile!=1 else ty+.490)
	var mid:=base.lerp(tip,0.55)+Vector3.UP*side.length()*0.15
	var n:=side.cross(tip-base).normalized()
	if n.y<0.0: n=-n
	n=(n+Vector3.UP*0.85).normalized()
	var points: Array[Vector3]=[base-side*0.61,base+side*0.61,mid-side,mid+side,tip-side*0.73,tip+side*0.73]
	var uv: Array[Vector2]=[Vector2(u0,v0),Vector2(u1,v0),Vector2(u0,lerpf(v0,v1,0.55)),Vector2(u1,lerpf(v0,v1,0.55)),Vector2(u0,v1),Vector2(u1,v1)]
	for i:int in [0,2,1,1,2,3,2,4,3,3,4,5]:
		patch.leaves.set_color(Color(light,light,light))
		patch.leaves.set_uv(uv[i])
		patch.leaves.set_uv2(Vector2(0.0 if i<2 else .55 if i<4 else 1.0,2.5+light*.4 if river_grass else 0.0))
		patch.leaves.set_normal(n)
		patch.leaves.add_vertex(points[i])
	patch.sprays+=1

# Each profile describes a branching crown in local tree heights. The crown
# forks intentionally differ in height, reach and width within the same tree.
const CROWNS := [
	[Vector4(-.20,.63,.03,.25),Vector4(.16,.70,-.12,.24),Vector4(.05,.79,.18,.22),Vector4(-.06,.85,-.02,.207),Vector4(.25,.63,.12,.16)],
	[Vector4(-.22,.58,.11,.203),Vector4(.20,.65,-.14,.223),Vector4(.02,.70,.23,.207),Vector4(-.09,.79,-.16,.223),Vector4(.09,.90,.03,.182),Vector4(.28,.74,.09,.14)],
	[Vector4(-.06,.48,.02,.17),Vector4(.10,.61,-.05,.163),Vector4(-.08,.72,.10,.156),Vector4(.04,.82,-.03,.148),Vector4(-.02,.93,.01,.112)]
]

func _canopy_vertex(surface: SurfaceTool,point: Vector3,normal: Vector3,grade: float,kind: int) -> void:
	surface.set_normal(normal)
	surface.set_color(Color(clampf(grade,0.03,0.98),float(kind)*0.5,0.0))
	surface.set_uv(Vector2(point.x*1.4+point.z*.51,point.y*1.63+point.z*.57))
	surface.set_uv2(Vector2(clampf(grade,0.03,0.98),1.0+float(kind)*0.25))
	surface.add_vertex(point)

# A fork carries two or three overlapping clusters of leaves. Scalloped edges and
# an offset high point show their direction even when a canopy frames a close fight.
func _lobe(patch: Patch,p: Vector3,radius: float,tall: float,kind: int,rotation: float) -> void:
	var widths: Array[float]=[.52,1.0,.82,.33]
	var levels: Array[float]=[-.46,-.04,.54,.85]
	var points: Array[Vector3]=[]
	var normals: Array[Vector3]=[]
	var grades: Array[float]=[]
	var sides:=12 if kind==1 else 10
	var sweep:=Vector3(cos(rotation),0,sin(rotation))
	var side:=Vector3(-sweep.z,0,sweep.x)
	for ring in levels.size():
		for i in sides:
			var a:=TAU*i/sides+.045*sin(i*1.7+ring)
			var across:=sin(a)
			var along:=cos(a)
			var notch:=.14 if i%3==1 else -.025
			var taper:=1.0+.115*sin(a*3.0+rotation)-notch+.064*cos(a*5.0+.7)
			var reach:=radius*widths[ring]*taper
			var branch:=sweep*(reach*along*1.19+radius*.115*ring/3.0)+side*reach*across*.82
			var lift:=tall*(levels[ring]-.18*along+.072*cos(a*2.0+rotation)-notch)
			points.append(p+branch+Vector3.UP*lift)
			normals.append(((sweep*along+side*across)*(.59+widths[ring]*.27)+Vector3.UP*(levels[ring]+.20)*1.23).normalized())
			grades.append(.13+ring*.235+.054*sin(a*3.0+rotation))
	for ring in range(levels.size()-1):
		for i in sides:
			var j:=(i+1)%sides
			var low:=ring*sides
			var up:=low+sides
			for index:int in [low+i,low+j,up+i,low+j,up+j,up+i]:
				_canopy_vertex(patch.leaves,points[index],normals[index],grades[index],kind)
	var centre:=p+sweep*radius*.16+Vector3.UP*tall*.91
	var last:=(levels.size()-1)*sides
	for i in sides:
		_canopy_vertex(patch.leaves,points[last+i],normals[last+i],grades[last+i],kind)
		_canopy_vertex(patch.leaves,points[last+(i+1)%sides],normals[last+(i+1)%sides],.81,kind)
		_canopy_vertex(patch.leaves,centre,Vector3.UP,.86,kind)
	patch.sprays+=1

func _tree(patch: Patch,p: Vector2,h: float,kind: int) -> void:
	var foot:=ground_point(p)
	var spin:=rng.randf_range(0.0,TAU)
	var turn:=Basis(Vector3.UP,spin)
	var bend:=turn*Vector3(0.08,0.0,-0.045)*h
	var fork:=foot+Vector3.UP*h*0.37+bend
	patch.stone.joint=11
	for i in 4:
		var a:=spin+i*TAU/4.0+rng.randf_range(-0.3,0.32)
		var toe:=foot+Vector3(cos(a),0,sin(a))*h*rng.randf_range(.07,.113)
		patch.stone.rod(toe,foot+Vector3.UP*h*.11,h*.013,h*.046,BARK,4)
	patch.stone.rod(foot,fork,h*(.057 if kind!=2 else .048),h*.033,BARK,6)
	var tile:=1 if kind==0 else 0 if kind==1 else 3
	for index:int in CROWNS[kind].size():
		var knot:Vector4=CROWNS[kind][index]
		var center:=foot+turn*Vector3(knot.x,knot.y,knot.z)*h+bend*0.37
		var elbow:=fork.lerp(center,0.63)+turn*Vector3(.028,.005,-.031)*h
		var radius:=knot.w*h*rng.randf_range(.91,1.07)
		var base:=fork.lerp(foot,0.13 if index<2 else 0.0)
		patch.stone.rod(base,elbow,h*.027,h*.016,BARK,5)
		patch.stone.rod(elbow,center,h*.016,h*.006,BARK.lightened(.05),4)
		var tall:=radius*(1.18 if kind==2 else 0.87 if kind==1 else 0.76)
		var heading:=spin+index*1.94
		var limb:=Vector3(cos(heading),0,sin(heading))
		var fork_side:=Vector3(-limb.z,0,limb.x)
		_lobe(patch,center-limb*radius*.13,radius*.86,tall*.72,kind,heading+.18)
		_lobe(patch,center+limb*radius*.43+Vector3.UP*tall*.27,radius*.63,tall*.61,kind,heading-.65)
		if kind==1 and index%2==0:
			_lobe(patch,center-fork_side*radius*.41-Vector3.UP*tall*.17,radius*.52,tall*.53,kind,heading+1.13)
		# Sparse real sprays soften the outline. The light and dark crown volumes
		# carry the silhouette, including on distant trees and after rotation.
		var sprays:=8 if kind==0 else 5
		for j in sprays:
			var a:float=spin+index*.93+j*TAU/sprays+rng.randf_range(-.27,.27)
			var radial:=Vector3(cos(a),0,sin(a))
			var start:=center+radial*radius*.82+Vector3.UP*tall*rng.randf_range(-.14,.45)
			var end:=start+radial*radius*(.51 if kind==0 else .59)
			end.y+=radius*(rng.randf_range(-1.24,-.65) if kind==0 else rng.randf_range(-.28,.41))
			var across:=Vector3(-radial.z,0,radial.x)*radius*(.43 if kind==0 else .46)
			_spray(patch,start,end,across,tile,rng.randf_range(.46,.82))

func _willow_part(library: Node,name_in_asset: String) -> ArrayMesh:
	var node:=library.find_child(name_in_asset,true,false) as MeshInstance3D
	var part:=SurfaceTool.new()
	part.create_from(node.mesh,0)
	# Static terrain already contains unindexed triangles. Appending glTF
	# indices to that buffer would make only the newly indexed piece draw.
	part.deindex()
	return part.commit()

func _bake_trees() -> void:
	# The two swept-bole willow assets and the inland tree prototypes use the
	# same static, spatially culled draw batches. Local +X points over water.
	var willows:=preload("res://assets/environment/bank-willows.gltf").instantiate()
	for prefix:String in ["Veteran","Coppice"]:
		trees.append({"wood":_willow_part(willows,prefix+"Bark"),"leaves":_willow_part(willows,prefix+"Foliage")})
	willows.free()
	for kind in range(1,3):
		for variant in 2:
			var prototype:=Patch.new()
			_tree(prototype,Vector2.ZERO,1.0,kind)
			trees.append({"wood":prototype.stone.surface.commit(),"leaves":prototype.leaves.commit()})

func _plant(patch: Patch,p: Vector2,height: float,kind: int,variant: int,yaw: float) -> void:
	var shape:=1 if kind==0 and height<5.48 else variant
	var source:=trees[2*kind+shape]
	var source_height:=5.63 if shape==0 else 4.91
	var scale_factor:=height/source_height if kind==0 else height
	var basis:=Basis(Vector3.UP,yaw).scaled(Vector3.ONE*scale_factor)
	var placement:=Transform3D(basis,ground_point(p))
	if kind==0:
		# Both imported parts retain their own bark or foliage tags. Cull the
		# whole willow in a single grove draw, independently of the terrain tile.
		patch.leaves.append_from(source.wood,0,placement)
	else:
		patch.stone.surface.append_from(source.wood,0,placement)
	patch.leaves.append_from(source.leaves,0,placement)
	patch.sprays+=1

func _tuft(patch: Patch,p: Vector2,size: float,kind: int=2) -> void:
	var at:=ground_point(p)+Vector3.UP*0.012
	var angle:=rng.randf_range(0.0,TAU)
	for i in 3:
		var a:=angle+i*TAU/3
		var fore:=Vector3(cos(a),0,sin(a))
		_spray(patch,at,at+fore*size*0.35+Vector3.UP*size,Vector3(-fore.z,0,fore.x)*size*0.59,kind,rng.randf_range(0.51,0.86))

func _bank_sedge() -> void:
	# Broken patches leave gravel bars and bridge landings exposed. The older
	# growth is low, broad and darker at its foot beside the cut bank.
	var plants:=RandomNumberGenerator.new()
	plants.seed=38017
	for bank:float in [-1.0,1.0]:
		for k in 26:
			var z:float=-63.0+k*4.98+plants.randf_range(-1.2,1.2)
			if absf(z-Ground.crossing(z))<5.3 or plants.randf()<.26: continue
			var center:=Vector2(Ground.RIVER_X+bank*plants.randf_range(5.4,7.13),z)
			for j in plants.randi_range(3,6):
				var q:=center+Vector2(plants.randf_range(-.54,.75),plants.randf_range(-1.17,1.25))
				var base:=ground_point(q)
				base.y=maxf(base.y,-.08)
				var patch:=_cell(q)
				for fan in 3:
					var heading:=fan*TAU/3.0+plants.randf_range(-.45,.48)
					var dir:=Vector3(cos(heading),0,sin(heading))
					var h:=plants.randf_range(.38,.89)
					var tip:=base+dir*h*.66+Vector3.UP*h
					var across:=Vector3(-dir.z,0,dir.x)*plants.randf_range(.29,.60)
					_spray(patch,base,tip,across,3,plants.randf_range(.30,.70),true)

func _shelf(patch: Patch,p: Vector2,length: float,width: float,height: float,a: float,walkable: bool) -> void:
	var side:=Vector2(cos(a),sin(a))
	var across:=Vector2(-side.y,side.x)
	var ring: Array[Vector2]=[Vector2(-0.97,-0.29),Vector2(-0.64,-0.59),Vector2(0.12,-0.64),Vector2(0.91,-0.31),Vector2(0.98,0.13),Vector2(0.49,0.54),Vector2(-0.28,0.63),Vector2(-0.87,0.37)]
	var low: Array[Vector3]=[]
	var ledge: Array[Vector3]=[]
	var capstone: Array[Vector3]=[]
	for v in ring:
		var footprint:=(side*v.x*length+across*v.y*width)*rng.randf_range(0.88,1.11)
		var q:=p+footprint
		var base:=ground_point(q)
		var relief:=height*(0.80+0.18*v.y+rng.randf_range(-0.07,0.07))
		if walkable: relief=minf(relief,0.19)
		low.append(base-Vector3.UP*0.025)
		ledge.append(base+Vector3.UP*relief*0.67)
		capstone.append(ground_point(p+footprint*0.91)+Vector3.UP*relief)
	var middle:=ground_point(p+side*length*0.17)
	middle.y+=minf(height*1.02,0.21) if walkable else height*1.02
	patch.stone.joint=12
	var palette:=rng.randf_range(-0.08,0.04)
	var paving:=height<0.08
	var cap_tone:=Color("a3947c") if paving else TOP
	var face_tone:=Color("887b68") if paving else LIMESTONE
	for i in ring.size():
		var j:=(i+1)%ring.size()
		var face:=face_tone.lightened(palette+0.035*((i+1)%4))
		if paving:
			# Inset path fragments have one narrow edge at boot height.
			patch.stone.quad(low[i],capstone[i],capstone[j],low[j],face)
		else:
			patch.stone.quad(low[i],ledge[i],ledge[j],low[j],face.darkened(0.20))
			patch.stone.quad(ledge[i],capstone[i],capstone[j],ledge[j],face)
		patch.stone.tri(capstone[j],capstone[i],middle,cap_tone.lightened(palette+0.025*(i%3)))

func _stands(plan: Dictionary) -> void:
	for place:Array in STANDS.data:
		var p:=Vector2(float(place[0]),float(place[1]))
		_plant(_cell(p),p,float(place[2]),int(place[3]),int(place[4]),float(place[5]))
	for group:Array in plan.groves:
		var center:=Vector2(float(group[0]),float(group[1]))
		var radius:=float(group[2])
		for i in roundi(radius*3):
			var a:=rng.randf_range(0.0,TAU)
			var p:=center+Vector2(cos(a),sin(a))*rng.randf_range(radius*0.55,radius*1.35)
			if absf(p.x-Ground.RIVER_X)>4.9: _tuft(_cell(p),p,rng.randf_range(0.30,0.75))
	for group:Array in plan.outcrops:
		var center:=Vector2(float(group[0]),float(group[1]))
		var a:=float(group[4])
		var along:=Vector2(cos(a),sin(a))
		var across:=Vector2(-along.y,along.x)
		var span:=float(group[2])
		for i in 7:
			var p:=center+along*span*(i/6.0-0.5)+across*rng.randf_range(-0.9,0.9)
			var radius:=rng.randf_range(0.48,1.5)
			_shelf(_cell(p),p,radius,radius*rng.randf_range(0.58,1.06),float(group[3])*rng.randf_range(0.43,0.85),a+rng.randf_range(-0.32,0.32),true)
			if i%2==0: _tuft(_cell(p),p+across*0.59,rng.randf_range(0.37,0.74))
	# These ledges emerge from the non-walkable water on both sides of the river.
	for i in 38:
		var z:float=-65.0+i*3.48+rng.randf_range(-0.96,0.96)
		if absf(z-Ground.crossing(z))<5.1: continue
		var side:float=1.0 if i%2 else -1.0
		var p:=Vector2(Ground.RIVER_X+side*rng.randf_range(3.65,4.27),z)
		_shelf(_cell(p),p,rng.randf_range(0.86,1.9),0.84,rng.randf_range(0.53,0.92),1.35+rng.randf_range(-0.22,0.22),false)

func _pavers(plan: Dictionary) -> void:
	for bed:Array in plan.masonry:
		var p:=Vector2(float(bed[0]),float(bed[1]))
		var extent:=float(bed[2])
		# Remnants of the surfaced cart road become more continuous at the gatehouse.
		for row in 5:
			for column in 6:
				if rng.randf()<(0.09 if p.x>30.0 else 0.64): continue
				var q:=p+Vector2((column-2.5+(row%2)*0.32)*extent/3.30,(row-2)*0.51)
				q+=Vector2(rng.randf_range(-0.075,0.075),rng.randf_range(-0.055,0.055))
				_shelf(_cell(q),q,rng.randf_range(0.35,0.61),rng.randf_range(0.32,0.53),rng.randf_range(0.018,0.041),rng.randf_range(-0.24,0.19),true)

func build(parent: Node3D,tiles: Dictionary) -> void:
	terrain_tiles=tiles
	leaf_material.shader=preload("res://scripts/field/env_leaf.gdshader")
	leaf_material.set_shader_parameter("ink",preload("res://assets/environment/leaf-sprays.png"))
	leaf_material.set_shader_parameter("willow_ink",preload("res://assets/environment/willow-sprays.png"))
	leaf_material.set_shader_parameter("canopy_paint",preload("res://assets/environment/elm-foliage.svg"))
	leaf_material.set_shader_parameter("leaf_marks",preload("res://assets/environment/fieldbed.png"))
	rng.seed=64127
	_bake_trees()
	var plan:Dictionary=PLAN.data
	_stands(plan)
	_bank_sedge()
	_pavers(plan)
	for patch:Patch in cells.values():
		if patch.sprays>0:
			patch.leaves.index()
			var leaves:=MeshInstance3D.new()
			leaves.mesh=patch.leaves.commit()
			leaves.material_override=leaf_material
			parent.add_child(leaves)
