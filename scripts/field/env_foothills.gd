extends RefCounted
## Original painted branch sprays, field paving and split rock grouped by terrain cell.
const Ground := preload("res://scripts/field/ground.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const PLAN := preload("res://assets/environment/foothills.json")
const BARK := Color("6b6651")
const LIMESTONE := Color("7e8880")
const TOP := Color("a0a28c")
var cells: Dictionary={}
var leaf_material:=ShaderMaterial.new()
var ground_material: ShaderMaterial
var rng:=RandomNumberGenerator.new()
var trees: Array[Dictionary]=[]

class Patch:
	var stone:=Builder.new()
	var leaves:=SurfaceTool.new()
	var sprays:=0
	var has_solids:=false
	func _init() -> void:
		stone.open_ends=true
		leaves.begin(Mesh.PRIMITIVE_TRIANGLES)

func _cell(p: Vector2) -> Patch:
	var key:=Vector2i(floori(p.x/26.0),floori(p.y/26.0))
	if not cells.has(key): cells[key]=Patch.new()
	return cells[key]

static func ground_point(p: Vector2) -> Vector3:
	var beyond:=maxf(absf(p.x)-Ground.LIMIT.x,absf(p.y)-Ground.LIMIT.y)
	var skyline:=smoothstep(0.0,31.0,beyond)*smoothstep(6.0,19.0,absf(p.x-Ground.RIVER_X))
	var rise:=skyline*(7.5+3.2*sin(p.x*0.095+p.y*0.032)+2.0*cos(p.y*0.14))
	return Vector3(p.x,Ground.height(p)+rise,p.y)

func _spray(patch: Patch,base: Vector3,tip: Vector3,side: Vector3,tile: int,light: float) -> void:
	var tx:=float(tile%2)*0.5
	var ty:=float(tile/2)*0.5
	var v0:=ty+0.490 if tile!=1 else ty+0.010
	var v1:=ty+0.010 if tile!=1 else ty+0.490
	var mid:=base.lerp(tip,0.55)+Vector3.UP*side.length()*0.15
	var n:=side.cross(tip-base).normalized()
	if n.y<0.0: n=-n
	n=(n+Vector3.UP*0.85).normalized()
	var points: Array[Vector3]=[base-side*0.61,base+side*0.61,mid-side,mid+side,tip-side*0.73,tip+side*0.73]
	var uv: Array[Vector2]=[Vector2(tx+0.010,v0),Vector2(tx+0.490,v0),Vector2(tx+0.010,lerpf(v0,v1,0.55)),Vector2(tx+0.490,lerpf(v0,v1,0.55)),Vector2(tx+0.010,v1),Vector2(tx+0.490,v1)]
	for i:int in [0,2,1,1,2,3,2,4,3,3,4,5]:
		patch.leaves.set_color(Color(light,light,light))
		patch.leaves.set_uv(uv[i])
		patch.leaves.set_uv2(Vector2(0.0 if i<2 else 0.55 if i<4 else 1.0,0))
		patch.leaves.set_normal(n)
		patch.leaves.add_vertex(points[i])
	patch.sprays+=1

func _tree(patch: Patch,p: Vector2,h: float,kind: int) -> void:
	var at:=ground_point(p)
	var rot:=rng.randf_range(0.0,TAU)
	var tilt:=Vector3(cos(rot),0,sin(rot))*h*(0.15 if kind==0 else 0.072)
	var root:=at+Vector3.UP*h*0.04
	var fork:=at+tilt*0.46+Vector3.UP*h*0.39
	var leader:=at+tilt+Vector3.UP*h*0.94
	patch.stone.joint=11
	for i in 4:
		var a:=rot+i*TAU/4
		var toe:=at+Vector3(cos(a),0,sin(a))*h*rng.randf_range(0.09,0.14)
		patch.stone.rod(toe,fork.lerp(root,0.74),h*0.014,h*0.051,BARK,5)
	patch.stone.rod(root,fork,h*0.069,h*0.048,BARK,7)
	patch.stone.rod(fork,leader,h*0.049,h*0.010,BARK.lightened(0.065),6)
	var tile:=1 if kind==0 else 0 if kind==1 else 3
	for tier in 3:
		var count:=7-tier
		var branch_root:=fork.lerp(leader,[0.0,0.37,0.69][tier])
		for i in count:
			var angle:=rot+tier*1.77+TAU*i/count+rng.randf_range(-0.16,0.16)
			var dir:=Vector3(cos(angle),0,sin(angle))
			var reach:float=h*[0.37,0.31,0.18][tier]*rng.randf_range(0.82,1.16)
			var elbow:Vector3=branch_root+dir*reach*0.58+Vector3.UP*h*0.10
			var end:Vector3=branch_root+dir*reach+Vector3.UP*h*(0.16 if kind==0 else 0.22)
			patch.stone.rod(branch_root,elbow,h*0.027,h*0.017,BARK,5)
			patch.stone.rod(elbow,end,h*0.017,h*0.008,BARK.lightened(0.06),5)
			for s in 4:
				var a:=angle+(s-1.5)*0.79
				var spread:=Vector3(cos(a),0,sin(a))
				var start:=end.lerp(elbow,0.38 if s in [0,3] else 0.17)
				var width:=h*(0.13 if kind==0 else 0.154)*rng.randf_range(0.82,1.20)
				var outer:=start+spread*h*(0.12 if kind==0 else 0.20)
				outer.y+=h*(rng.randf_range(-0.33,-0.23) if kind==0 else rng.randf_range(0.055,0.17))
				var across:=Vector3(-spread.z,0,spread.x)*width
				_spray(patch,start,outer,across,tile,0.42+tier*0.12+rng.randf()*0.17)

func _bake_trees() -> void:
	# SurfaceTool appends transformed prototype vertices in native code. All trees
	# in each cell share their draw surfaces, including wind and shadow casting.
	for kind in 3:
		for variant in 2:
			var prototype:=Patch.new()
			_tree(prototype,Vector2.ZERO,1.0,kind)
			trees.append({"wood":prototype.stone.surface.commit(),"leaves":prototype.leaves.commit()})

func _plant(patch: Patch,p: Vector2,height: float,kind: int) -> void:
	var source:=trees[2*kind+rng.randi_range(0,1)]
	var basis:=Basis(Vector3.UP,rng.randf_range(0.0,TAU)).scaled(Vector3.ONE*height)
	var placement:=Transform3D(basis,ground_point(p))
	patch.stone.surface.append_from(source.wood,0,placement)
	patch.leaves.append_from(source.leaves,0,placement)
	patch.sprays+=1
	patch.has_solids=true

func _tuft(patch: Patch,p: Vector2,size: float,kind: int=2) -> void:
	var at:=ground_point(p)+Vector3.UP*0.012
	var angle:=rng.randf_range(0.0,TAU)
	for i in 3:
		var a:=angle+i*TAU/3
		var fore:=Vector3(cos(a),0,sin(a))
		_spray(patch,at,at+fore*size*0.35+Vector3.UP*size,Vector3(-fore.z,0,fore.x)*size*0.59,kind,rng.randf_range(0.51,0.86))

func _shelf(patch: Patch,p: Vector2,length: float,width: float,height: float,a: float,walkable: bool) -> void:
	patch.has_solids=true
	var side:=Vector2(cos(a),sin(a))
	var across:=Vector2(-side.y,side.x)
	var ring: Array[Vector2]=[Vector2(-0.97,-0.29),Vector2(-0.64,-0.59),Vector2(0.12,-0.64),Vector2(0.91,-0.31),Vector2(0.98,0.13),Vector2(0.49,0.54),Vector2(-0.28,0.63),Vector2(-0.87,0.37)]
	var low: Array[Vector3]=[]
	var ledge: Array[Vector3]=[]
	var capstone: Array[Vector3]=[]
	for v in ring:
		var footprint:=side*v.x*length+across*v.y*width
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
	var palette:=rng.randf_range(-0.06,0.045)
	for i in ring.size():
		var j:=(i+1)%ring.size()
		var face:=LIMESTONE.lightened(palette+0.035*((i+1)%4))
		patch.stone.quad(low[i],ledge[i],ledge[j],low[j],face.darkened(0.20))
		patch.stone.quad(ledge[i],capstone[i],capstone[j],ledge[j],face)
		patch.stone.tri(capstone[j],capstone[i],middle,TOP.lightened(palette+0.025*(i%3)))

func _stands(plan: Dictionary) -> void:
	for group:Array in plan.groves:
		var center:=Vector2(float(group[0]),float(group[1]))
		var radius:=float(group[2])
		var count:=clampi(roundi(radius*0.78),2,8)
		for i in count:
			var a:=i*2.40+rng.randf_range(-0.28,0.28)
			var p:=center+Vector2(cos(a),sin(a))*radius*sqrt((i+0.15)/count)*0.72
			if absf(p.x-Ground.RIVER_X)<4.85: continue
			_plant(_cell(p),p,float(group[3])*rng.randf_range(0.73,1.12),int(group[4]))
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
				if rng.randf()<(0.13 if p.x>30.0 else 0.57): continue
				var q:=p+Vector2((column-2.5+(row%2)*0.32)*extent/3.30,(row-2)*0.51)
				q+=Vector2(rng.randf_range(-0.075,0.075),rng.randf_range(-0.055,0.055))
				_shelf(_cell(q),q,rng.randf_range(0.35,0.64),rng.randf_range(0.31,0.52),rng.randf_range(0.027,0.063),rng.randf_range(-0.24,0.19),true)

func build(parent: Node3D,material: ShaderMaterial) -> void:
	ground_material=material
	leaf_material.shader=preload("res://scripts/field/env_leaf.gdshader")
	leaf_material.set_shader_parameter("ink",preload("res://assets/environment/leaf-sprays.png"))
	rng.seed=64127
	_bake_trees()
	var plan:Dictionary=PLAN.data
	_stands(plan)
	_pavers(plan)
	for patch:Patch in cells.values():
		if patch.has_solids:
			var rocks:=MeshInstance3D.new()
			rocks.mesh=patch.stone.finish()
			rocks.material_override=ground_material
			parent.add_child(rocks)
		if patch.sprays>0:
			patch.leaves.index()
			var leaves:=MeshInstance3D.new()
			leaves.mesh=patch.leaves.commit()
			leaves.material_override=leaf_material
			parent.add_child(leaves)
