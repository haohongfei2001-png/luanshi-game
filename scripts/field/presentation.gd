extends Node3D
const Battle := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Figures := preload("res://scripts/field/figures.gd")
const CompanyArt := preload("res://scripts/field/company_art.gd")
const MountArt := preload("res://scripts/field/mount_art.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const FIGURE_SHADER := preload("res://scripts/field/figure.gdshader")
const FRIEND := Color("496765")
const FOE := Color("965c49")
const CLOTH_COLOR:=Color("dbcba4")
const GOLD := Color("b69c66")

class Batch:
	var node: MultiMeshInstance3D
	var mesh: MultiMesh
	var used := 0

var battle: Battle
var groups: Dictionary = {}
var contact: Batch
var contact_for_all:=false
var reference_detail := false
var reference_two_lods:=false
var reference_officer_detail:=false
var rank_soldiers:=0
var high_detail_soldiers := 0
var horse: Batch
var horse_rank: Batch
var cart_rank: Batch
var cart: Batch
var arrows: Batch
var standards: Array[Batch] = []
var runners: Batch
var visible_soldiers := 0
var visible_fighting := 0
var shown_fallen := 0

func _material(col: Color, kit: int, animal: bool=false) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FIGURE_SHADER
	mat.set_shader_parameter("livery",col)
	mat.set_shader_parameter("kit",kit)
	mat.set_shader_parameter("animal",animal)
	return mat

func _batch(geometry: Mesh,mat: Material,capacity: int) -> Batch:
	var g := Batch.new()
	g.node = MultiMeshInstance3D.new()
	g.mesh = MultiMesh.new()
	g.mesh.transform_format = MultiMesh.TRANSFORM_3D
	g.mesh.use_custom_data = true
	g.mesh.mesh = geometry
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
	var ranks_mesh: Array[Mesh]=[]
	for kit in Arms.NAMES.size():
		near_mesh.append(CompanyArt.fighter(kit, CompanyArt.costume(kit), true))
		far_mesh.append(CompanyArt.fighter(kit, CompanyArt.costume(kit), false))
		ranks_mesh.append(Figures.ranks(kit))
	var counts := {}
	for u in battle.roster:
		var key := _key(u)
		counts[key] = int(counts.get(key,0))+1
	for key: int in counts:
		var kit := key % 10
		var col := GOLD if key >= 20 else (FRIEND if key < 10 else FOE)
		var mat := CompanyArt.material(col,kit)
		var detailed: Mesh = CompanyArt.fighter(kit, "Player", true) if key>=20 else near_mesh[kit]
		groups[key] = _batch(detailed,mat,counts[key])
		if key<20:
			groups[30+key]=_batch(far_mesh[kit],mat,counts[key])
			groups[30+key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			groups[60+key]=_batch(ranks_mesh[kit],_material(col,kit),counts[key])
			groups[60+key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for u in battle.roster:
		if not u.officer: continue
		var officer_key := 90 + _key(u)
		if not groups.has(officer_key):
			groups[officer_key]=_batch(CompanyArt.fighter(u.kit,"Officer",true),CompanyArt.material(FRIEND if u.team==0 else FOE,u.kit),battle.command_counts[u.team])
	# Keep one small batch per potential player kit. Re-equipping in muster is immediate.
	for kit in Arms.NAMES.size():
		if not groups.has(20+kit):
			groups[20+kit] = _batch(CompanyArt.fighter(kit,"Player",true),CompanyArt.material(GOLD,kit),1)
	var shadow_mesh := Builder.new()
	var rim:=shadow_mesh.ring(Vector3.ZERO,Vector2(0.39,0.27),8)
	for k in 8:
		shadow_mesh.tri(Vector3.ZERO,rim[k],rim[(k+1)%8],Color.WHITE)
	var shade := StandardMaterial3D.new()
	shade.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.albedo_color=Color("504c39a8")
	shade.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	shade.cull_mode=BaseMaterial3D.CULL_DISABLED
	var sm:=shadow_mesh.finish()
	contact=_batch(sm,shade,battle.roster.size())
	contact.node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mount_capacity:=battle.ordinary_counts[0]+battle.ordinary_counts[1]+1
	horse = _batch(MountArt.mesh(false,true),MountArt.material(),mount_capacity)
	horse_rank = _batch(MountArt.mesh(false,false),MountArt.material(),mount_capacity)
	horse_rank.node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cart = _batch(MountArt.mesh(true,true),MountArt.material(),1)
	cart_rank = _batch(MountArt.mesh(true,false),MountArt.material(),1)
	var b := Builder.new()
	b.rod(Vector3(0,0,-0.41),Vector3(0,0,0.40),0.027,0.016,Color("4b3728"),4)
	b.rod(Vector3(0,0,0.34),Vector3(0,0,0.48),0.055,0.001,Color("a8aaa2"),4)
	var am := b.finish()
	arrows = _batch(am,_material(FRIEND,0),64)
	var flag := Builder.new()
	flag.rod(Vector3(0,0,0),Vector3(0,3.65,0),0.045,0.036,Color("796343"))
	flag.dye = 1
	flag.quad(Vector3(0,3.50,0),Vector3(0.90,3.43,0.09),Vector3(0.91,2.70,0.18),Vector3(0,2.67,0),Color.WHITE)
	flag.tri(Vector3(0.89,3.41,0.09),Vector3(1.32,3.34,0.16),Vector3(0.90,3.06,0.15),Color.WHITE)
	flag.dye = 0
	flag.block(Vector3(0.38,3.11,0.02),Vector3(0.13,0.42,0.09),GOLD)
	# A notched tail and two light hems remain legible beyond clothing detail.
	flag.quad(Vector3(0,3.49,0.012),Vector3(0.9,3.42,0.101),Vector3(0.9,3.36,0.105),Vector3(0,3.43,0.012),CLOTH_COLOR)
	flag.tri(Vector3(0.91,2.96,0.15),Vector3(1.36,2.77,0.19),Vector3(0.91,2.72,0.18),GOLD)
	var fm := flag.finish()
	var garrison:=Builder.new()
	garrison.rod(Vector3.ZERO,Vector3(0,3.62,0),0.046,0.034,Color("745636"),4)
	garrison.dye=1
	garrison.quad(Vector3(0,3.48,0),Vector3(0.89,3.39,0.09),Vector3(0.91,2.89,0.16),Vector3(0,2.82,0),Color.WHITE)
	garrison.tri(Vector3(0.07,2.84,0),Vector3(0.42,2.49,0.10),Vector3(0.52,2.87,0.09),Color.WHITE)
	garrison.tri(Vector3(0.49,2.88,0.09),Vector3(0.83,2.56,0.18),Vector3(0.90,2.91,0.16),Color.WHITE)
	garrison.dye=0
	garrison.quad(Vector3(0.12,3.14,0.045),Vector3(0.43,3.32,0.075),Vector3(0.72,3.10,0.13),Vector3(0.42,2.96,0.082),CLOTH_COLOR)
	standards.append(_batch(fm,_material(FRIEND,0),battle.companies_per_side))
	standards.append(_batch(garrison.finish(),_material(FOE,0),battle.command_counts[1]))
	runners = _batch(far_mesh[Arms.Kit.SWORD],CompanyArt.material(Color("ab8962"),0),8)

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

func sync_view(center: Vector2,half_extent: Vector2,alpha: float,zoom: float) -> void:
	visible_soldiers = 0
	high_detail_soldiers=0
	rank_soldiers=0
	contact.used=0
	visible_fighting = 0
	shown_fallen = 0
	for g: Batch in groups.values():
		g.used = 0
	horse_rank.used=0
	cart_rank.used=0
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
		var ground := Ground.unit_point(p)
		var base := ground
		var distance_sq:=p.distance_squared_to(center)
		var travelled:=u.pos.distance_to(u.before)
		var angle := atan2(u.facing.x,u.facing.y)
		var progress := clampf(1.0-u.timer/maxf(u.duration,0.001),0,1) if u.state!=Battle.State.MARCH else 0.0
		var code := u.state + 8*u.move_slot + (32 if u.stock_strike else 0)
		if u.officer and battle.corps.is_wounded(u.id):
			code=Battle.State.ESCAPED # Wounded pose; departed units are culled above.
			progress=0.75 if battle.corps.support_partner(battle,u)>=0 else 0.0
		if (u.mounted and u.hp>0) or (u.hero and battle.vehicle==1): code+=64
		var step_phase:=fposmod(u.stride-(1.0-alpha)*travelled*0.68,1.0)
		var data := Color((code+0.5)/128.0,progress,step_phase,clampf(u.flash/0.22,0,1))
		if u.mounted:
			var unhorsed:=u.state==Battle.State.DEAD and u.mount_hp>0
			var horse_pose:=Battle.State.MARCH if unhorsed else u.state
			var mounts:=horse if zoom<36 and distance_sq<185.0 else horse_rank
			_put(mounts,base,angle,MountArt.pose(horse_pose,progress,u.stride,0.0 if unhorsed else travelled,alpha,data.a))
			var fall:=smoothstep(0.0,0.9,progress) if unhorsed else 0.0
			base.y+=0.73*(1.0-fall)
			var side:=u.facing.orthogonal()*fall*(0.91 if u.id%2==0 else -0.91)
			base+=Vector3(side.x,0,side.y)
		if u.hero and battle.vehicle != 0:
			var heading := battle.riding_heading
			if battle.vehicle == 2 and not battle.seat_origin:
				base -= Vector3(heading.x,0,heading.y)*1.83
			base.y += 0.73 if battle.vehicle==1 else 0.91
		var full := reference_detail or u.hero or (u.officer and (reference_officer_detail or (zoom<30 and distance_sq<190))) or (zoom<17 and distance_sq<110) or (zoom<36 and distance_sq<19)
		var key:=_key(u)
		if not full and not reference_two_lods and (zoom>=40 or (zoom>=23 and distance_sq>170.0)):
			key+=60
			rank_soldiers+=1
		elif not full:
			key+=30
		elif u.officer:
			key+=90
		elif not u.hero:
			high_detail_soldiers+=1
		if key<60 or key>=90:
			# Persistent cloth lots are tied to roster identity across camera/LOD changes.
			data.a=(float((u.id*5+u.squad*3)%8)+0.055+0.88*data.a)/8.0
			if u.state==Battle.State.MARCH: data.g=clampf(travelled*15.0,0.0,1.0)
		if not full or contact_for_all:
			_put(contact,ground+Vector3.UP*0.035,angle,Color(0,0,0,0))
		_put(groups[key],base,angle,data,1.07 if u.hero or u.officer else 1.0)
		if not u.hero and not u.officer:
			visible_soldiers += 1
			if u.state in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD,Battle.State.STAGGER]:
				visible_fighting += 1
			if u.hp<=0: shown_fallen += 1
	# A standard follows the current officer, including a successor drawn from the ranks.
	for company in battle.companies:
		if not battle.corps.can_command(battle,company): continue
		var bearer: Battle.Unit=battle.corps.recipient(battle,company)
		var at:=bearer.before.lerp(bearer.pos,alpha)
		if absf(at.x-center.x)>half_extent.x or absf(at.y-center.y)>half_extent.y: continue
		var role: String=battle.corps.title_of(battle,bearer)
		var height:=1.25 if role=="战场主将" else (1.10 if role=="先锋" else 1.0)
		var base:=Ground.unit_point(at)+Vector3(-0.32,0.81 if bearer.mounted else 0.0,0)
		_put(standards[bearer.team],base,atan2(bearer.facing.x,bearer.facing.y),Color(0,0,0,0),height)
	for id in [1,2]:
		var pos: Vector2 = battle.vehicle_pos[id]
		var state := Battle.State.DEAD if battle.vehicle_hp[id]<=0 else Battle.State.MARCH
		var heading := battle.riding_heading if battle.vehicle == id else battle.parked_heading[id]
		var stride := battle.hero.stride if battle.vehicle == id else 0.0
		var close:=zoom<36 and pos.distance_squared_to(center)<225.0
		var vehicle_batch:=horse if close else horse_rank
		if id==2: vehicle_batch=cart if close else cart_rank
		var moved:=battle.hero.pos.distance_to(battle.hero.before) if battle.vehicle==id else 0.0
		_put(vehicle_batch,Ground.unit_point(pos),atan2(heading.x,heading.y),MountArt.pose(state,1.0,stride,moved,alpha))
	for s in battle.shots:
		var p := s.previous.lerp(s.pos,alpha)
		var fraction := s.distance / maxf(1,s.distance+s.remaining)
		var h := 1.1 + (2.5 if s.arrow else 0.32)*sin(PI*fraction)
		var altitude := lerpf(s.launch_height,Ground.deck_height(p),fraction)+h
		_put(arrows,Vector3(p.x,altitude,p.y),atan2(s.direction.x,s.direction.y),Color(0,0,0,0))
	for order in battle.orders:
		if order.channel==Battle.Channel.COURIER and order.leg!=2:
			var recipient: Battle.Unit=battle.corps.recipient(battle,battle.companies[order.squad])
			var destination:=battle.hero.pos if order.leg==1 else recipient.pos
			var dir := order.pos.direction_to(destination)
			_put(runners,Ground.unit_point(order.pos),atan2(dir.x,dir.y),Color(0,0,fposmod(order.age*3,1.0),0))
	for g: Batch in groups.values():
		g.mesh.visible_instance_count = g.used
	for g: Batch in [contact,horse,horse_rank,cart,cart_rank,arrows,runners,standards[0],standards[1]]:
		g.mesh.visible_instance_count = g.used
