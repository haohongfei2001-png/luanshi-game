extends Node3D
const Battle := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Figures := preload("res://scripts/field/figures.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const Shader := preload("res://scripts/field/figure.gdshader")
const FRIEND := Color("3e7271")
const FOE := Color("a35340")
const GOLD := Color("c3a45e")

class Batch:
	var node: MultiMeshInstance3D
	var mesh: MultiMesh
	var close_mesh: Mesh
	var wide_mesh: Mesh
	var used := 0
	var mode := true

var battle: Battle
var groups: Dictionary = {}
var horse: Batch
var cart: Batch
var arrows: Batch
var standards: Array[Batch] = []
var runners: Batch
var visible_soldiers := 0
var visible_fighting := 0
var shown_fallen := 0

func _material(col: Color, kit: int, animal: bool=false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader
	mat.set_shader_parameter("livery",col)
	mat.set_shader_parameter("kit",kit)
	mat.set_shader_parameter("animal",animal)
	return mat

func _batch(close_mesh: Mesh,wide_mesh: Mesh,mat: Material,capacity: int) -> Batch:
	var g := Batch.new()
	g.close_mesh = close_mesh
	g.wide_mesh = wide_mesh
	g.node = MultiMeshInstance3D.new()
	g.mesh = MultiMesh.new()
	g.mesh.transform_format = MultiMesh.TRANSFORM_3D
	g.mesh.use_custom_data = true
	g.mesh.mesh = close_mesh
	g.mesh.instance_count = capacity
	g.mesh.visible_instance_count = 0
	g.mesh.custom_aabb = AABB(Vector3(-124,-3,-68),Vector3(248,19,136))
	g.node.multimesh = g.mesh
	g.node.material_override = mat
	add_child(g.node)
	return g

func configure(model: Battle) -> void:
	battle = model
	var near_mesh: Array[Mesh] = []
	var far_mesh: Array[Mesh] = []
	for kit in Arms.NAMES.size():
		near_mesh.append(Figures.fighter(kit,true))
		far_mesh.append(Figures.fighter(kit,false))
	var counts := {}
	for u in battle.roster:
		var key := _key(u)
		counts[key] = int(counts.get(key,0))+1
	for key: int in counts:
		var kit := key % 10
		var col := GOLD if key >= 20 else (FRIEND if key < 10 else FOE)
		groups[key] = _batch(near_mesh[kit],far_mesh[kit],_material(col,kit),counts[key])
	# Keep one small batch per potential player kit. Re-equipping in muster is immediate.
	for kit in Arms.NAMES.size():
		if not groups.has(20+kit):
			groups[20+kit] = _batch(near_mesh[kit],far_mesh[kit],_material(GOLD,kit),1)
	var mount_mesh := Figures.horse()
	horse = _batch(mount_mesh,mount_mesh,_material(FRIEND,0,true),battle.side_size*2+1)
	var wagon := Figures.horse(true)
	cart = _batch(wagon,wagon,_material(FRIEND,0,true),1)
	var b := Builder.new()
	b.rod(Vector3(0,0,-0.41),Vector3(0,0,0.40),0.027,0.016,Color("4b3728"),4)
	b.rod(Vector3(0,0,0.34),Vector3(0,0,0.48),0.055,0.001,Color("a8aaa2"),4)
	var am := b.finish()
	arrows = _batch(am,am,_material(FRIEND,0),64)
	var flag := Builder.new()
	flag.rod(Vector3(0,0,0),Vector3(0,3.65,0),0.045,0.036,Color("796343"))
	flag.dye = 1
	flag.quad(Vector3(0,3.50,0),Vector3(0.90,3.43,0.09),Vector3(0.91,2.70,0.18),Vector3(0,2.67,0),Color.WHITE)
	flag.tri(Vector3(0.89,3.41,0.09),Vector3(1.32,3.34,0.16),Vector3(0.90,3.06,0.15),Color.WHITE)
	flag.dye = 0
	flag.block(Vector3(0.38,3.11,0.02),Vector3(0.13,0.42,0.09),GOLD)
	var fm := flag.finish()
	for team in 2:
		standards.append(_batch(fm,fm,_material(FRIEND if team==0 else FOE,0),battle.companies_per_side))
	runners = _batch(near_mesh[Arms.Kit.SWORD],far_mesh[Arms.Kit.SWORD],_material(Color("c49b5c"),0),8)

func _key(u: Battle.Unit) -> int:
	return u.kit + (20 if u.hero else 10*u.team)

func _put(g: Batch,pos: Vector3,angle: float,data: Color,stretch: float=1.0) -> void:
	var basis := Basis(Vector3.UP,angle).scaled(Vector3.ONE*stretch)
	g.mesh.set_instance_transform(g.used,Transform3D(basis,pos))
	g.mesh.set_instance_custom_data(g.used,data)
	g.used += 1

func _reserve(g: Batch,count: int) -> void:
	if count > g.mesh.instance_count:
		g.mesh.instance_count = maxi(count,g.mesh.instance_count*2)

func sync_view(center: Vector2,half_extent: Vector2,alpha: float,detail: bool) -> void:
	visible_soldiers = 0
	visible_fighting = 0
	shown_fallen = 0
	for g: Batch in groups.values():
		g.used = 0
		if g.mode != detail:
			g.mesh.mesh = g.close_mesh if detail else g.wide_mesh
			g.mode = detail
	horse.used = 0
	cart.used = 0
	arrows.used = 0
	runners.used = 0
	_reserve(arrows,battle.shots.size())
	_reserve(runners,battle.orders.size())
	for g in standards:
		g.used = 0
	for u in battle.roster:
		if u.state == Battle.State.ESCAPED: continue
		var p := u.before.lerp(u.pos,alpha)
		if absf(p.x-center.x)>half_extent.x or absf(p.y-center.y)>half_extent.y: continue
		var base := Ground.unit_point(p)
		var angle := atan2(u.facing.x,u.facing.y)
		var progress := clampf(1.0-u.timer/maxf(u.duration,0.001),0,1) if u.state!=Battle.State.MARCH else 0.0
		var code := u.state + 8*u.move_slot
		var data := Color((code+0.5)/32.0,progress,u.stride,clampf(u.flash/0.22,0,1))
		if u.mounted:
			_put(horse,base,angle,Color((u.state+0.5)/32,progress,u.stride,data.a))
			base.y += 0.81
		if u.hero and battle.vehicle != 0:
			var heading := battle.riding_heading
			if battle.vehicle == 2:
				base -= Vector3(heading.x,0,heading.y)*1.83
			base.y += 0.83 if battle.vehicle==1 else 0.91
		_put(groups[_key(u)],base,angle,data,1.07 if u.hero or u.officer else 1.0)
		if u.officer and u.hp>0:
			_put(standards[u.team],base+Vector3(-0.32,0,0),angle,Color(0,0,0,0))
		elif not u.hero and not u.officer:
			visible_soldiers += 1
			if u.state in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD,Battle.State.STAGGER]:
				visible_fighting += 1
			if u.hp<=0: shown_fallen += 1
	for id in [1,2]:
		var pos: Vector2 = battle.vehicle_pos[id]
		var state := Battle.State.DEAD if battle.vehicle_hp[id]<=0 else Battle.State.MARCH
		var heading := battle.riding_heading if battle.vehicle == id else Vector2.RIGHT
		var stride := battle.hero.stride if battle.vehicle == id else 0.0
		_put(horse if id==1 else cart,Ground.unit_point(pos),atan2(heading.x,heading.y),Color((state+0.5)/32.0,1,stride,0))
	for s in battle.shots:
		var p := s.previous.lerp(s.pos,alpha)
		var fraction := s.distance / maxf(1,s.distance+s.remaining)
		var h := 1.1 + (2.5 if s.arrow else 0.32)*sin(PI*fraction)
		_put(arrows,Ground.unit_point(p)+Vector3.UP*h,atan2(s.direction.x,s.direction.y),Color(0,0,0,0))
	for order in battle.orders:
		if order.channel==Battle.Channel.COURIER:
			var dir := order.pos.direction_to(battle.roster[battle.companies[order.squad].officer_id].pos)
			_put(runners,Ground.unit_point(order.pos),atan2(dir.x,dir.y),Color(0,0,fposmod(order.age*3,1.0),0))
	for g: Batch in groups.values():
		g.mesh.visible_instance_count = g.used
	for g: Batch in [horse,cart,arrows,runners,standards[0],standards[1]]:
		g.mesh.visible_instance_count = g.used
