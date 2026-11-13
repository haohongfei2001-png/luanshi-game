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

# A crown is assembled from bowed leaf-bearing limbs. The open spaces between
# forks expose the structure from rotating play cameras; the foliage is not a
# cutout facing the player. Each limb has a pitched spine and folded sides.
func _bough(patch: Patch,root: Vector3,ray: Vector3,length: float,breadth: float,tilt: float,grade: float,canopy: bool=false,sweep: float=0.) -> void:
	var across:=Vector3(-ray.z,0.0,ray.x)
	var verts:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var uv:=PackedVector2Array()
	for row in 4:
		var t:=float(row)/3.0
		var spine:=root+ray*length*t+across*length*sweep*t*t+Vector3.UP*length*(sin(t*PI)*.19+tilt*t)
		var width:=breadth*(.70+.30*sin(t*PI))*(1.-absf(sweep)*.44*t)
		if canopy:
			width=breadth*(.39+.55*sin(t*PI)+.19*t)
			spine.y+=length*.118*sin(t*PI)
		for col in 3:
			var v:=float(col-1)
			verts.append(spine+across*v*width+Vector3.DOWN*absf(v)*breadth*((.22+.34*t) if canopy else (.12+.18*t)))
			normals.append((Vector3.UP+across*.39*v+ray*(.30*t-.20)).normalized())
			uv.append(Vector2(.5+.5*v,1.0-t))
	for r in 3:
		for c in 2:
			var a:=r*3+c
			for k:int in [a,a+3,a+1,a+1,a+3,a+4]:
				patch.leaves.set_color(Color.WHITE)
				patch.leaves.set_normal(normals[k])
				patch.leaves.set_uv(uv[k])
				patch.leaves.set_uv2(Vector2(1.0-uv[k].y,(8.1 if canopy else 6.1)+grade*.70))
				patch.leaves.add_vertex(verts[k])
	patch.sprays+=1

# One silhouette follows each supporting fork, opening into flattened sprays
# near the tip. Both sides belong to a continuous volume at rotating cameras.
func _leaf_platform(patch: Patch,root: Vector3,ray: Vector3,reach: float,width: float,depth: float,grade: float,seed: float,climb: float) -> void:
	var side:=Vector3(-ray.z,0.,ray.x)
	var points:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var coords:=PackedVector2Array()
	var weights:=PackedFloat32Array()
	var sections:=9
	var across:=8
	for surface in 2:
		for row in sections:
			var t:=float(row)/(sections-1)
			var arch:=sin(t*PI)
			var bend:=.14*sin(seed+.9)*t*t-.067*arch
			var fall:=depth*(climb*t+.56*arch-.23*t*t)
			for col in across:
				var v:=2.*col/(across-1)-1.
				var ribs:=.5+.5*cos(9.3*v+seed*.73)
				var tip:=smoothstep(.49,1.,t)
				var finger:=.12*sin(9.3*v+seed*.73)+.046*sin(14.*v-seed*.31)
				var along:=t+finger*tip-.39*absf(v)*pow(t,2.2)
				var fan:=(.11+.98*pow(maxf(0.,sin(PI*(.035+.88*t))),.77))*(.95+.18*cos(t*12.+seed+signf(v)))
				var x:=v*fan+bend
				var shell:=-.25*(1.-v*v)-.075*arch
				if surface==0: shell=(1.-v*v)*(.58+.40*arch)+.29*ribs*arch+.12*sin(t*9.4+seed)*(1.-absf(v))
				points.append(root+ray*reach*along+side*width*x+Vector3.UP*(fall+depth*(shell-.29*v*v)))
				var n:=(Vector3.UP+side*(.72*v)+ray*(.54*t-.24)).normalized()
				normals.append(n if surface==0 else (Vector3.DOWN+side*v*.73).normalized())
				coords.append(Vector2(t*.72+seed*.083,.5+.5*v))
				weights.append(.18+.38*t)
	var span:=sections*across
	var ids:=PackedInt32Array()
	for surface in 2:
		var base:=surface*span
		for r in range(sections-1):
			for c in range(across-1):
				var i:=base+r*across+c
				if surface==0: ids.append_array([i,i+across,i+1,i+1,i+across,i+across+1])
				else: ids.append_array([i,i+1,i+across,i+1,i+across+1,i+across])
	var rim:=PackedInt32Array()
	for c in across: rim.append(c)
	for r in range(1,sections): rim.append(r*across+across-1)
	for c in range(across-2,-1,-1): rim.append((sections-1)*across+c)
	for r in range(sections-2,0,-1): rim.append(r*across)
	for j in rim.size():
		var i:=rim[j]
		var k:=rim[(j+1)%rim.size()]
		ids.append_array([i,k,i+span,k,k+span,i+span])
	for i in ids:
		patch.leaves.set_color(Color.WHITE)
		patch.leaves.set_normal(normals[i])
		patch.leaves.set_uv(coords[i])
		patch.leaves.set_uv2(Vector2(weights[i],10.1+.70*grade))
		patch.leaves.add_vertex(points[i])
	patch.sprays+=1

func _tree(patch: Patch,p: Vector2,h: float,kind: int,variant: int) -> void:
	var foot:=ground_point(p)
	var spin:=rng.randf_range(0.,TAU)
	var turn:=Basis(Vector3.UP,spin)
	var narrow:=kind==2
	var heel:=foot+turn*Vector3(-.012,.0,.012)*h
	var bole:=foot+turn*Vector3(.035,.20,-.027)*h
	var fork:=foot+turn*Vector3(.030 if variant==0 else -.059,.435,.017)*h
	patch.stone.joint=11
	for i in 4:
		var angle:=spin+i*1.64+.15*sin(i+spin)
		var toe:=foot+Vector3(cos(angle),-.035,sin(angle))*h*(.094+.023*(i%2))
		patch.stone.rod(toe,bole.lerp(foot,.43),h*.014,h*.042,BARK,5)
	patch.stone.rod(heel,bole,h*.057,h*.043,BARK,8)
	patch.stone.rod(bole,fork,h*.043,h*.029,BARK,7)
	# The spreading elm has a low arm and a high leader. The young uprights
	# retain a narrower, asymmetrical crown on the same metre-scale bind.
	var arms: Array[Vector4]=[Vector4(-.41,.595,.13,.289),Vector4(.27,.685,-.20,.270),
		Vector4(.10,.790,.255,.259),Vector4(-.09,.934,-.103,.265)]
	if variant==1: arms=[Vector4(.08,.58,-.28,.244),Vector4(-.22,.712,.21,.278),
		Vector4(.30,.795,.066,.255),Vector4(.01,.953,-.108,.24)]
	if narrow: arms=[Vector4(-.14,.615,.10,.22),Vector4(.13,.755,-.091,.238),Vector4(-.04,.925,.076,.211)]
	for i in arms.size():
		var arm:=arms[i]
		var radial:=turn*Vector3(arm.x,0.,arm.z).normalized()
		var tip:=foot+turn*Vector3(arm.x,arm.y,arm.z)*h
		var stem:=fork+Vector3.UP*(.031*i*h)
		var elbow:=stem.lerp(tip,.44)+radial*h*.043
		var wrist:=elbow.lerp(tip,.64)+Vector3.UP*.029*h
		var fac:=h*(.029-.002*i)
		patch.stone.rod(stem,elbow,fac,fac*.61,BARK,7)
		patch.stone.rod(elbow,wrist,fac*.63,fac*.39,BARK,6)
		patch.stone.rod(wrist,tip,fac*.40,h*.004,BARK.lightened(.07),5)
		var reach:=h*arm.w*(1.47 if narrow else 1.68)
		var width:=h*arm.w*(.80 if narrow else .99)
		var grade:=.22+.15*i
		var lift:=.70 if i==arms.size()-1 else .20
		var root:=elbow.lerp(wrist,.22)
		var turn_side:=1. if (i+variant)%2==0 else -1.
		var leaf_dir:=radial.rotated(Vector3.UP,.20*turn_side)
		_leaf_platform(patch,root,leaf_dir,reach*.89,width*.81,width*.68,grade,spin+2.07*i,lift)
		var cross_ray:=radial.rotated(Vector3.UP,turn_side*(1.42+.11*i))
		var crouch:=wrist-leaf_dir*reach*.09+Vector3.DOWN*width*.11
		patch.stone.rod(wrist,crouch+cross_ray*reach*.41+Vector3.UP*width*.10,fac*.32,h*.0029,BARK,5)
		_leaf_platform(patch,crouch,cross_ray,reach*.65,width*.58,width*.48,grade-.11,spin-.73+1.91*i,lift+.08)
		# Branch-bearing sprays cross the boundary of the solid core along the
		# long axis and both flanks. The visible hem follows the leaf silhouette.
		for fringe in 5:
			var fringe_angles: Array[float]=[-.97,-.44,.08,.60,1.10]
			var off:=fringe_angles[fringe]
			var lateral:=Vector3(-leaf_dir.z,0.,leaf_dir.x)
			var tail:=leaf_dir.rotated(Vector3.UP,off)
			var edge:=root+leaf_dir*reach*(.41+.16*cos(off))+lateral*width*.52*off+Vector3.UP*width*(.36+.23*lift+.08*sin(spin+fringe))
			_bough(patch,edge,tail,reach*(.54+.07*sin(fringe*2.+i)),width*(.38+.06*cos(fringe*1.4)),-.28-.05*(fringe%3),grade,true,turn_side*.13)
		var inland:=cross_ray.rotated(Vector3.UP,turn_side*.25)
		_bough(patch,crouch+cross_ray*reach*.33+Vector3.UP*width*.26,inland,reach*.40,width*.34,-.38,grade-.07,true,turn_side*.17)

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
			_tree(prototype,Vector2.ZERO,1.0,kind,variant)
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
	var cap_tone:=Color("887a66") if paving else TOP
	var face_tone:=Color("70695d") if paving else LIMESTONE
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

# Weathered outcrops are broken along one bedding direction. Tops sink into
# paths people can cross; only the non-traversable river cut exposes deep faces.
func _split_stone(patch: Patch,p: Vector2,extent: float,depth: float,rise: float,yaw: float,bank: bool) -> void:
	var along:=Vector2(cos(yaw),sin(yaw))
	var crossway:=Vector2(-along.y,along.x)
	var cross_section: Array[Vector2]=[Vector2(-.94,-.19),Vector2(-.42,-.62),Vector2(.29,-.53),Vector2(.91,-.25),Vector2(.79,.28),Vector2(.20,.61),Vector2(-.61,.43)]
	var foot:=PackedVector3Array()
	var seam:=PackedVector3Array()
	var brow:=PackedVector3Array()
	var top:=PackedVector3Array()
	for v in cross_section:
		var off:=along*(v.x+rng.randf_range(-.13,.11))*extent+crossway*(v.y+rng.randf_range(-.09,.09))*depth
		var shoulder:=ground_point(p+off)
		var relief:=rise*(.69+.29*v.y+.19*v.x+rng.randf_range(-.09,.11))
		if bank:
			# Border rock continues down into the non-walkable channel, rather
			# than wrapping over the terrain as a flat biscuit.
			relief+=clampf(ground_point(p).y-shoulder.y,-.35,.40)*.66
		if not bank: relief=rise*(.27+.56*v.y+.45*v.x+rng.randf_range(-.10,.08))
		foot.append(shoulder-Vector3.UP*.11)
		seam.append(ground_point(p+off*1.04)+Vector3.UP*relief*.34)
		brow.append(ground_point(p+off*.90+crossway*(-rise*.13))+Vector3.UP*relief*.71)
		top.append(ground_point(p+off*.68+along*.095*extent)+Vector3.UP*relief)
	var apex:=ground_point(p-along*.31*extent+crossway*.14*depth)+Vector3.UP*rise*(1.17 if bank else 1.0)
	var split:=ground_point(p+along*.28*extent-crossway*.15*depth)+Vector3.UP*rise*(.85 if bank else .58)
	var cold:=Color("5c605c").lerp(Color("898575"),rng.randf_range(.04,.68)) if bank else Color("716d60").lerp(Color("847f6c"),rng.randf_range(.03,.72))
	var pale:=cold.lightened(rng.randf_range(.08,.22))
	patch.stone.joint=19
	for n in top.size():
		var m:=(n+1)%top.size()
		var f:=float((2*n+1)%5)*.026
		patch.stone.quad(foot[m],foot[n],seam[n],seam[m],cold.darkened(.20+f))
		patch.stone.quad(seam[m],seam[n],brow[n],brow[m],cold.lightened(f*.62))
		patch.stone.quad(brow[m],brow[n],top[n],top[m],cold.darkened(.020+f*.19))
		if n in [1,2,3]:
			patch.stone.tri(top[m],top[n],split,pale.darkened(.04+f))
		else:
			patch.stone.tri(top[m],top[n],apex,pale.darkened(f))
		if n==0: patch.stone.tri(top[m],split,apex,pale.darkened(.15))
		if n==3: patch.stone.tri(top[m],apex,split,pale.darkened(.04))

# Edge habitat: small arching brush sprays and drooping seed heads at the
# root, sharing the site's two existing batches. No props in the fighting lane.
func _field_margin(patch: Patch,p: Vector2,reach: float,turn: float) -> void:
	var foot:=ground_point(p)
	patch.stone.joint=11
	for i in 4:
		var a:=turn+i*2.40+.23*sin(p.x+float(i))
		var dir:=Vector3(cos(a),0,sin(a))
		var root:=foot+dir*reach*.12
		var fork:=root+dir*reach*.30+Vector3.UP*reach*(.42+.10*(i%2))
		patch.stone.rod(root-Vector3.UP*.018,fork,.022*reach,.009*reach,BARK,4)
		_bough(patch,fork-dir*.14*reach,dir,reach*.77,reach*.33,.11 if i%2 else -.24,.22+.10*i)

func _stands(plan: Dictionary) -> void:
	for place:Array in STANDS.data:
		var p:=Vector2(float(place[0]),float(place[1]))
		var kind:=int(place[3])
		var height:=float(place[2])
		# Low, multi-stem growth alternates with full standards in these stands.
		if kind==1 and p.distance_squared_to(Vector2(-5.46,-10.70))<.20:
			# The established roadside elm and its young neighbour mark the
			# bank of the grazing ground. Keep the verge towards the fight open.
			height=5.68
		elif kind!=0 and height<5.20 and int(place[4])==1:
			height*=.70 if kind==1 else .81
		_plant(_cell(p),p,height,kind,int(place[4]),float(place[5]))
	for group:Array in plan.groves:
		var center:=Vector2(float(group[0]),float(group[1]))
		var radius:=float(group[2])
		for i in roundi(radius*3):
			var a:=rng.randf_range(0.0,TAU)
			var p:=center+Vector2(cos(a),sin(a))*rng.randf_range(radius*0.55,radius*1.35)
			if absf(p.x-Ground.RIVER_X)>4.9: _tuft(_cell(p),p,rng.randf_range(0.30,0.75))
	for group:Array in plan.groves:
		var margin:=Vector2(float(group[0]),float(group[1]))
		var radius:=float(group[2])
		var count:=3 if radius>4.5 else 2
		for k in count:
			var heading:=margin.x*.82+k*2.53
			var p:=margin+Vector2(cos(heading),sin(heading))*radius*(.62+.20*(k%2))
			if absf(p.x-Ground.RIVER_X)>5.0:
				_field_margin(_cell(p),p,.73+.19*(k%3),heading)
	for group:Array in plan.outcrops:
		var center:=Vector2(float(group[0]),float(group[1]))
		var a:=float(group[4])
		var along:=Vector2(cos(a),sin(a))
		var across:=Vector2(-along.y,along.x)
		var span:=float(group[2])
		for i in 4:
			# Each bedding plane breaks into a small fan. One end is buried in
			# the slope so it reads as in-situ rock rather than discs lying on grass.
			var bank_side:float=-1.0 if i%3==0 else 1.0
			var p:=center+along*span*(i/3.0-.5)+across*rng.randf_range(-.83,.72)
			var radius:=rng.randf_range(.64,1.46)
			_split_stone(_cell(p),p,radius,radius*rng.randf_range(.74,1.38),rng.randf_range(.095,.20),a+rng.randf_range(-.48,.38),false)
			for chip in 2:
				var q:=p+across*bank_side*rng.randf_range(.14,.56)*radius+along*rng.randf_range(-.63,.79)
				var small:=rng.randf_range(.13,.34)
				_split_stone(_cell(q),q,small,small*.93,small*.37,a+rng.randf_range(-.6,.8),false)
			for fringe in 3:
				var grass:=p+across*bank_side*rng.randf_range(.12,.69)+along*rng.randf_range(-.46,.62)
				_tuft(_cell(grass),grass,rng.randf_range(.27,.46))
	# These ledges emerge from the non-walkable water on both sides of the river.
	for i in 38:
		var z:float=-65.0+i*3.48+rng.randf_range(-0.96,0.96)
		if absf(z-Ground.crossing(z))<5.1: continue
		var side:float=1.0 if i%2 else -1.0
		var p:=Vector2(Ground.RIVER_X+side*rng.randf_range(3.65,4.27),z)
		_split_stone(_cell(p),p,rng.randf_range(1.0,2.11),rng.randf_range(.87,1.64),rng.randf_range(.84,1.37),1.35+rng.randf_range(-.34,.30),true)
		var q:=p+Vector2(-.49*side,rng.randf_range(.65,1.62))
		_split_stone(_cell(q),q,.65,.83,rng.randf_range(.49,.80),rng.randf_range(.82,1.98),true)

# Banks at the edges of the old fields collect earth and slate where carts
# cut through the sod. The three central remnants top out below ankle height;
# the stone buttress at the gate lies inside the existing blocked wall strip.
# The old pasture is still grazed into short fans along its raised banks.
# Low broad blades have a real root and a curved back when a soldier walks across them.
func _verge_grass(bed: Builder,p: Vector2,h: float,phase: float) -> void:
	var foot:=ground_point(p)
	var dark:=Color("536f52")
	var ripe:=Color("9da66c")
	bed.joint=0
	for blade in 6:
		var a:=phase+2.40*blade
		var axis:=Vector3(cos(a),0.,sin(a))
		var across:=Vector3(-axis.z,0.,axis.x)
		var size:=h*(.79+.23*sin(a*.64+1.6))
		var base:=foot+axis*.046-Vector3.UP*.010
		var knee:=base+axis*size*.43+Vector3.UP*size*.63
		var tip:=base+axis*size*(.91+.29*sin(a))+Vector3.UP*size*.93
		var w:=size*(.115+.034*(blade%2))
		var ink:=dark.lerp(ripe,.31+.091*(blade%4))
		bed.quad(base-across*w*.36,knee-across*w,knee+across*w,base+across*w*.36,ink)
		bed.tri(knee-across*w,tip,knee+across*w,ink.lightened(.12))

func _grazed_banks() -> void:
	var roots: Array[Vector4]=[Vector4(-8.1,-8.4,.16,1.12),Vector4(-3.4,-9.2,-.34,1.04),
		Vector4(7.8,-7.3,-.25,.87),Vector4(10.6,-8.6,.11,.71),Vector4(19.2,9.4,-.32,1.17),
		Vector4(-19.2,11.5,-.23,.94),Vector4(-11.9,7.6,-.48,.80),Vector4(34.7,-5.8,.08,.78)]
	for i in roots.size():
		var r:=roots[i]
		var path:=Vector2(cos(r.z),sin(r.z))
		var across:=Vector2(-path.y,path.x)
		for tuft in 14:
			var t:=float(tuft)/13.
			var sweep:=sin(t*PI)
			var off:=sin(tuft*2.97+i)*(.15+.43*sweep)
			var p:=Vector2(r.x,r.y)+path*((t-.5)*r.w*5.6)+across*(off+.17*sin(t*4.1+i))
			var h:=r.w*(.17+.12*sweep+.035*sin(tuft*2.18))
			_verge_grass(_cell(p).stone,p,h,tuft*1.27+i*.8)
			if tuft%3==1:
				var other:=p+across*.39+path*.17
				_verge_grass(_cell(other).stone,other,h*.77,2.72+tuft)

func _field_banks() -> void:
	# Local coordinates run along the bank, then across it, in metres.
	var shoulders: Array[Vector4]=[Vector4(-7.4,-8.45,.14,1.05),Vector4(8.9,-7.55,-.32,.76),
		Vector4(12.7,-32.9,-.17,1.08),Vector4(-21.3,12.5,-.27,.92),
		Vector4(25.6,8.8,-.40,.91),Vector4(38.0,-5.1,.17,.86)]
	var pieces: Array[Vector4]=[Vector4(-1.39,.09,.96,.74),Vector4(.38,-.12,.73,.57),Vector4(1.30,.53,.44,.41)]
	for shoulder in shoulders:
		var origin:=Vector2(shoulder.x,shoulder.y)
		var heading:=Vector2(cos(shoulder.z),sin(shoulder.z))
		var lateral:=Vector2(-heading.y,heading.x)
		var bed:Builder=_cell(origin).stone
		bed.joint=20
		var previous:=PackedVector3Array()
		for i in 10:
			var u:=-3.50+i*.78
			var swell:=sin(float(i)*PI/9.0)
			var track:=origin+heading*u*shoulder.w+lateral*(.16*sin(i*.90)+.12*cos(i*.67))
			var outer:=ground_point(track-lateral*(.15+.38*swell))
			var brink:=ground_point(track)+Vector3.UP*(.024+.109*swell)
			var crown:=ground_point(track+lateral*(.09+.72*swell))+Vector3.UP*.012
			var row:=PackedVector3Array([outer+Vector3.DOWN*.014,brink,crown])
			if not previous.is_empty():
				var face:=Color("8c8169").lerp(Color("958a72"),.5+.45*sin(i*1.74))
				var top:=Color("969571").lerp(Color("8c906d"),.5+.4*sin(i*.78+.6))
				bed.quad(previous[0],previous[1],row[1],row[0],face)
				bed.quad(previous[1],previous[2],row[2],row[1],top)
			previous=row
		for i in pieces.size():
			var stone:=pieces[i]
			var at:=origin+(heading*stone.x+lateral*stone.y)*shoulder.w
			var rise:=(.105+.037*(i%2))*shoulder.w
			_shelf(_cell(at),at,stone.z*shoulder.w,stone.w*shoulder.w,rise,shoulder.z+.22*sin(i*2.7),true)
		for q:Vector2 in [Vector2(-1.48,.77),Vector2(.69,.56),Vector2(2.11,.62)]:
			var root:Vector2=origin+(heading*q.x+lateral*q.y)*shoulder.w
			_tuft(_cell(root),root,.36*shoulder.w)
	# The lower gate is supported by a battered stone toe under its inner
	# parapet. Keep the entire top inside the non-traversable west curtain.
	for sign_z:float in [-1.0,1.0]:
		for i in 4:
			var heel:=Vector2(Ground.WALL_X-.85,sign_z*(8.30+i*2.72))
			_split_stone(_cell(heel),heel,1.20,.66,.86-.11*float(i%3),PI*.5+.17*sin(i*1.29),true)

# A river bed fractures along bedding shelves. Each roughly squared platform
# has a submerged dark toe, two jagged horizontal strata and a gently tilted cap.
# y is measured from the actual water plane instead of following the steep bank.
func _river_bed(tile: Builder,p: Vector2,length: float,width: float,rise: float,yaw: float,shift: float) -> void:
	var along:=Vector2(cos(yaw),sin(yaw))
	var across:=Vector2(-along.y,along.x)
	var corners: Array[Vector2]=[Vector2(-.94,-.29),Vector2(-.76,-.57),Vector2(-.22,-.59),
		Vector2(.12,-.46),Vector2(.80,-.49),Vector2(.96,-.16),Vector2(.82,.39),
		Vector2(.40,.49),Vector2(.26,.38),Vector2(-.32,.52),Vector2(-.82,.40)]
	var rows: Array[PackedVector3Array]=[]
	var spreads: Array[float]=[.98,1.04,.92,.94,.75]
	var levels: Array[float]=[-.25,.21,.29,.70,.94]
	for ring in levels.size():
		var row:=PackedVector3Array()
		for i in corners.size():
			var at:=corners[i]
			var v:=along*length*(at.x+.037*sin(i*2.96+shift))+across*width*(at.y+.034*cos(i*2.60+shift))
			var q:=p+v*spreads[ring]+across*rise*(.05*ring-.11)
			var tilt:=(at.x*.085-at.y*.114+.035*sin(i*1.23+shift))*rise
			row.append(Vector3(q.x,-.34+rise*levels[ring]+tilt,q.y))
		rows.append(row)
	var cap:PackedVector3Array=rows[4]
	var top:=Vector3(p.x,-.34+rise*.99,p.y)
	var swatches: Array[Color]=[Color("555950"),Color("77786a"),Color("696c60"),Color("8b8a76")]
	tile.joint=21
	for i in corners.size():
		var j:=(i+1)%corners.size()
		for level in 4:
			var tone:=swatches[level].lightened(.022*((i+level)%3))
			tile.quad(rows[level][j],rows[level][i],rows[level+1][i],rows[level+1][j],tone)
		tile.tri(cap[j],cap[i],top,Color("92917e").lightened(.017*float(i%3)))

func _bridge_ledges() -> void:
	# Both heels stay clear of the deck apron. The larger stones live below
	# the navigable turf, in the same water the movement model already blocks.
	var beds: Array[Vector4]=[Vector4(1,-10.4,.81,.84),Vector4(-1,-15.2,.71,.95),Vector4(-1,-5.75,.61,.76)]
	for bank in beds:
		var side:=bank.x
		var center:=Vector2(Ground.RIVER_X+side*4.35,bank.y)
		var yaw:=PI*.5+side*.18
		var scale_factor:=bank.w
		var parts: Array[Vector4]=[Vector4(-1.43,.23,1.30,.96),Vector4(.38,.0,1.53,1.17),
			Vector4(1.52,-.37,.92,.87),Vector4(-.44,-1.11,.90,.86),Vector4(.63,-1.58,.60,.69)]
		for i in parts.size():
			var part:=parts[i]
			var position:=center+Vector2(side*part.y,part.x)*scale_factor
			var h:=bank.z*(.77+.13*float(i%3)) if i<3 else bank.z*(.60 if i==3 else .37)
			_river_bed(_cell(position).stone,position,part.z*scale_factor,part.w*scale_factor,h,
				yaw+.12*sin(float(i)*1.62+bank.y),float(i)+bank.y)
		for i in 3:
			var turf:=center+Vector2(side*(1.62+.25*i),-1.23+i*1.13)*scale_factor
			_field_margin(_cell(turf),turf,.53+.081*i,bank.y+i*2.1)

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
				_shelf(_cell(q),q,rng.randf_range(0.29,0.62),rng.randf_range(0.19,0.40),rng.randf_range(0.018,0.041),rng.randf_range(-0.24,0.19),true)

func build(parent: Node3D,tiles: Dictionary) -> void:
	terrain_tiles=tiles
	leaf_material.shader=preload("res://scripts/field/env_leaf.gdshader")
	leaf_material.set_shader_parameter("ink",preload("res://assets/environment/leaf-sprays.png"))
	leaf_material.set_shader_parameter("willow_ink",preload("res://assets/environment/willow-sprays.png"))
	leaf_material.set_shader_parameter("willow_pendant",preload("res://assets/environment/willow-pendant.png"))
	leaf_material.set_shader_parameter("elm_crown_paint",preload("res://assets/environment/elm-crown-paint.png"))
	leaf_material.set_shader_parameter("elm_spray",preload("res://assets/environment/painted-elm.png"))
	leaf_material.set_shader_parameter("elm_bough",preload("res://assets/environment/elm-bough.png"))
	leaf_material.set_shader_parameter("canopy_paint",preload("res://assets/environment/elm-foliage.svg"))
	leaf_material.set_shader_parameter("leaf_marks",preload("res://assets/environment/fieldbed.png"))
	rng.seed=64127
	_bake_trees()
	var plan:Dictionary=PLAN.data
	_stands(plan)
	_bank_sedge()
	_pavers(plan)
	_field_banks()
	_grazed_banks()
	_bridge_ledges()
	for patch:Patch in cells.values():
		if patch.sprays>0:
			patch.leaves.index()
			var leaves:=MeshInstance3D.new()
			leaves.mesh=patch.leaves.commit()
			leaves.material_override=leaf_material
			parent.add_child(leaves)
