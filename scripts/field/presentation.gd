extends Node3D
const Battle := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Figures := preload("res://scripts/field/figures.gd")
const CompanyArt := preload("res://scripts/field/company_art.gd")
const MountArt := preload("res://scripts/field/mount_art.gd")
const Builder := preload("res://scripts/field/mesh_builder.gd")
const FIGURE_SHADER := preload("res://scripts/field/figure.gdshader")
const FRIEND := Color("456e86")
const FOE := Color("aa5844")
const CLOTH_COLOR:=Color("dbcba4")
const PLAYER_CLOTH:=Color("304f6f")
const GOLD := Color("b69c66")

class Batch:
	var node: MultiMeshInstance3D
	var mesh: MultiMesh
	var used := 0
	var submitted_count := 0

var battle: Battle
var batches: Array[Batch] = []
var groups: Dictionary = {}
var contact: Batch
var contact_for_all:=false
var reference_detail := false
var reference_two_lods:=false
var reference_officer_detail:=false
var rank_soldiers:=0
var lod_by_id:=PackedByteArray()
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

func _batch(geometry: Mesh,mat: Material,capacity: int,custom_data: bool=true) -> Batch:
	var g := Batch.new()
	g.node = MultiMeshInstance3D.new()
	g.mesh = MultiMesh.new()
	g.mesh.transform_format = MultiMesh.TRANSFORM_3D
	g.mesh.use_custom_data = custom_data
	g.mesh.mesh = geometry
	g.mesh.instance_count = capacity
	g.mesh.visible_instance_count = 0
	g.mesh.custom_aabb = AABB(Vector3(-124,-3,-68),Vector3(248,19,136))
	g.node.multimesh = g.mesh
	g.node.material_override = mat
	add_child(g.node)
	batches.append(g)
	return g

func configure(model: Battle) -> void:
	battle = model
	lod_by_id.resize(battle.roster.size())
	lod_by_id.fill(255)
	var near_mesh: Array[Mesh] = []
	var far_mesh: Array[Mesh] = []
	var ranks_mesh: Array[Mesh]=[]
	for kit in Arms.NAMES.size():
		near_mesh.append(CompanyArt.fighter(kit, CompanyArt.costume(kit), true))
		far_mesh.append(CompanyArt.fighter(kit, CompanyArt.costume(kit), false))
		ranks_mesh.append(CompanyArt.fighter(kit, CompanyArt.costume(kit), false, true))
	var counts := {}
	for u in battle.roster:
		var key := _key(u)
		counts[key] = int(counts.get(key,0))+1
	for key: int in counts:
		var kit := key % 10
		var col := PLAYER_CLOTH if key >= 20 else (FRIEND if key < 10 else FOE)
		var mat := CompanyArt.material(col,kit,key>=20)
		var detailed: Mesh = CompanyArt.fighter(kit, "Player", true) if key>=20 else near_mesh[kit]
		groups[key] = _batch(detailed,mat,counts[key])
		if key<20:
			# The hand-stitched body is visible in the colour pass. At shadow-map
			# scale the matching wrist, shaft and robe silhouette fits the same pose.
			groups[key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			groups[200+key]=_batch(far_mesh[kit],mat,counts[key])
			groups[200+key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			groups[30+key]=_batch(far_mesh[kit],mat,counts[key])
			groups[30+key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			groups[60+key]=_batch(ranks_mesh[kit],mat,counts[key])
			groups[60+key].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for u in battle.roster:
		if not u.officer: continue
		var officer_key := 90 + _key(u)
		if not groups.has(officer_key):
			var side_colour:=FRIEND if u.team==0 else FOE
			var mat:=CompanyArt.material(side_colour,u.kit)
			var capacity:int=battle.command_counts[u.team]
			groups[officer_key]=_batch(CompanyArt.fighter(u.kit,"Officer",true),mat,capacity)
			groups[officer_key+30]=_batch(CompanyArt.fighter(u.kit,"Officer",false),mat,capacity)
			groups[officer_key+60]=_batch(CompanyArt.fighter(u.kit,"Officer",false,true),mat,capacity)
			groups[officer_key+30].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			groups[officer_key+60].node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Keep one small batch per potential player kit. Re-equipping in muster is immediate.
	for kit in Arms.NAMES.size():
		if not groups.has(20+kit):
			groups[20+kit] = _batch(CompanyArt.fighter(kit,"Player",true),CompanyArt.material(PLAYER_CLOTH,kit,true),1)
	var shadow_mesh := Builder.new()
	var rim:=shadow_mesh.ring(Vector3.ZERO,Vector2(0.53,0.41),8)
	for k in 8:
		shadow_mesh.tri(Vector3.ZERO,rim[k],rim[(k+1)%8],Color.WHITE)
	var shade:=ShaderMaterial.new()
	shade.shader=preload("res://scripts/field/foot_contact.gdshader")
	var sm:=shadow_mesh.finish()
	contact=_batch(sm,shade,battle.roster.size(),false)
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

func _put(g: Batch,pos: Vector3,orientation: Basis,data: Color,stretch: float=1.0,caster: Batch=null) -> void:
	var basis:=orientation if stretch==1.0 else orientation.scaled(Vector3.ONE*stretch)
	var transform_3d:=Transform3D(basis,pos)
	g.mesh.set_instance_transform(g.used,transform_3d)
	g.mesh.set_instance_custom_data(g.used,data)
	g.used += 1
	if caster!=null:
		caster.mesh.set_instance_transform(caster.used,transform_3d)
		caster.mesh.set_instance_custom_data(caster.used,data)
		caster.used+=1

func _reserve(g: Batch,count: int) -> void:
	if count > g.mesh.instance_count:
		g.mesh.instance_count = maxi(count,g.mesh.instance_count*2)
		g.submitted_count = -1 # A resized buffer needs a fresh visibility submission.

func sync_view(center: Vector2,half_extent: Vector2,alpha: float,zoom: float) -> void:
	visible_soldiers = 0
	high_detail_soldiers=0
	rank_soldiers=0
	visible_fighting = 0
	shown_fallen = 0
	for batch in batches:
		batch.used = 0
	_reserve(arrows,battle.shots.size())
	_reserve(runners,battle.orders.size())
	# Orthographic zoom determines how much of the army actually occupies face-scale pixels.
	MountArt.material().set_shader_parameter("stable_clock",(float(battle.tick)+alpha)*Battle.DT)
	var cam:=get_viewport().get_camera_3d()
	var right:=Vector2.RIGHT
	var vertical_xz:=Vector2.ZERO
	var vertical_y:=0.0
	var window:=get_viewport().get_visible_rect().size
	var vertical_limit:=zoom*.5+4.2
	var horizontal_limit:=zoom*.5*window.x/maxf(1.0,window.y)+4.2
	var center_height:=Ground.unit_point(center).y
	if cam:
		right=Vector2(cam.global_basis.x.x,cam.global_basis.x.z)
		vertical_xz=Vector2(cam.global_basis.y.x,cam.global_basis.y.z)
		vertical_y=cam.global_basis.y.y
	var portrait_radius:=lerpf(9.5,5.2,smoothstep(7.2,16.8,zoom))
	var portrait_radius_sq:=portrait_radius*portrait_radius
	for u in battle.roster:
		if u.state == Battle.State.ESCAPED: continue
		var p := u.before.lerp(u.pos,alpha)
		if absf(p.x-center.x)>half_extent.x or absf(p.y-center.y)>half_extent.y: continue
		var offset:=p-center
		if cam and absf(offset.dot(right))>horizontal_limit: continue
		var ground := Ground.unit_point(p)
		# Test the oriented window in camera space. Keep enough padding for the
		# longest blade, a raised banner, a mounted head and their projected shadows.
		if cam and absf(offset.dot(vertical_xz)+(ground.y-center_height+1.0)*vertical_y)>vertical_limit: continue
		var base := ground
		var distance_sq:=p.distance_squared_to(center)
		var travelled:=u.pos.distance_to(u.before)
		var angle := atan2(u.facing.x,u.facing.y)
		if u.facing_before!=Vector2.ZERO and u.facing_before!=u.facing:
			angle=lerp_angle(atan2(u.facing_before.x,u.facing_before.y),angle,alpha)
		var orientation:=Basis(Vector3.UP,angle)
		var progress := clampf(1.0-(u.timer+(1.0-alpha)*Battle.DT)/maxf(u.duration,0.001),0,1) if u.state!=Battle.State.MARCH else 0.0
		var code := u.state + 8*u.move_slot + (32 if u.stock_strike else 0)
		if u.officer and battle.corps.is_wounded(u.id):
			code=Battle.State.ESCAPED # Wounded pose; departed units are culled above.
			progress=0.75 if battle.corps.support_partner(battle,u)>=0 else 0.0
		if (u.mounted and u.hp>0) or (u.hero and battle.vehicle==1): code+=64
		var stride:=u.visual_stride if u.visual_stride>=0 else u.stride
		var step_phase:=fposmod(stride-(1.0-alpha)*travelled*(.42 if u.visual_run else .68),1.0)
		var data := Color((code+0.5)/128.0,progress,step_phase,clampf(u.flash/0.22,0,1))
		if u.mounted:
			var unhorsed:=u.state==Battle.State.DEAD and u.mount_hp>0
			var horse_pose:=Battle.State.MARCH if unhorsed else u.state
			var mounts:=horse if zoom<36 and distance_sq<185.0 else horse_rank
			_put(mounts,base,orientation,MountArt.pose(horse_pose,progress,u.stride,0.0 if unhorsed else travelled,alpha,data.a,u.id))
			var fall:=smoothstep(0.0,0.9,progress) if unhorsed else 0.0
			var gait:=clampf(travelled/(Battle.DT*4.0),0,1)
			var hoof_phase:=fposmod(u.stride-(1.0-alpha)*travelled*.68,1.)
			base.y+=(.73+.021*gait*sin(hoof_phase*TAU*2.0))*(1.0-fall)
			var side:=u.facing.orthogonal()*fall*(0.91 if u.id%2==0 else -0.91)
			base+=Vector3(side.x,0,side.y)
		if u.hero and battle.vehicle != 0:
			var heading := battle.riding_heading
			if battle.vehicle == 2 and not battle.seat_origin:
				base -= Vector3(heading.x,0,heading.y)*1.83
			base.y += 0.73 if battle.vehicle==1 else 0.91
		var was_close:=lod_by_id[u.id]==0
		var was_rank:=lod_by_id[u.id]==2
		var full:=reference_detail or u.hero or (u.officer and (reference_officer_detail or (zoom<30 and distance_sq<(209.0 if was_close else 178.0)))) or (zoom<17 and distance_sq<portrait_radius_sq*(1.14 if was_close else 1.0)) or (zoom<36 and distance_sq<(23.0 if was_close else 17.0))
		var tier:=0
		if not full:
			tier=1
			if not reference_two_lods and (zoom>=40 or (zoom>=23 and distance_sq>(151.0 if was_rank else 181.0))):
				tier=2
				rank_soldiers+=1
		elif not u.hero and not u.officer:
			high_detail_soldiers+=1
		lod_by_id[u.id]=tier
		var key:=_key(u)+30*tier+(90 if u.officer else 0)
		# Idle breathing uses simulation time; footsteps keep the travelled phase.
		data.a=(float((u.id*5+u.squad*3)%8)+0.055+0.88*data.a)/8.0
		var gait:=-1
		if travelled>.001:
			var delta:=u.pos-u.before
			var relative:=atan2(delta.x,delta.y)-angle
			var direction:=posmod(roundi(relative/(PI*.25)),8)
			gait=(23+direction) if u.visual_run else (0 if direction==0 else 15+direction)
		if u.state==Battle.State.MARCH:
			data.g=(float(gait)+.5)/32.0 if gait>=0 else 0.0
			if gait<0 and not u.mounted:
				data.b=fposmod(u.stride+(float(battle.tick)+alpha)*Battle.DT*(.37+.023*(u.id%7)),1.)
		if u.hero:
			var material: ShaderMaterial=groups[key].node.material_override
			material.set_shader_parameter("travelling_attack_legs",gait if battle.vehicle==0 else -1)
			material.set_shader_parameter("travelling_leg_phase",step_phase)
		# The sole shader reads only mesh coordinates, so this batch contains transforms alone.
		contact.mesh.set_instance_transform(contact.used,Transform3D(orientation,ground+Vector3.UP*.026))
		contact.used+=1
		var caster: Batch=groups[200+key] if tier==0 and not u.hero and not u.officer and not contact_for_all else null
		# Keep footwear on the ground. Modest stable stature variation travels through all three LODs.
		var stature:=1.07 if u.hero or u.officer else (1.0 if u.mounted else .966+.0085*((u.id*7+u.squad*5)%9))
		_put(groups[key],base,orientation,data,stature,caster)
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
		_put(standards[bearer.team],base,Basis(Vector3.UP,atan2(bearer.facing.x,bearer.facing.y)),Color(0,0,0,0),height)
	for id in [1,2]:
		var pos: Vector2 = battle.vehicle_pos[id]
		var state := Battle.State.DEAD if battle.vehicle_hp[id]<=0 else Battle.State.MARCH
		var heading := battle.riding_heading if battle.vehicle == id else battle.parked_heading[id]
		var stride := battle.hero.stride if battle.vehicle == id else 0.0
		var close:=zoom<36 and pos.distance_squared_to(center)<225.0
		var vehicle_batch:=horse if close else horse_rank
		if id==2: vehicle_batch=cart if close else cart_rank
		var moved:=battle.hero.pos.distance_to(battle.hero.before) if battle.vehicle==id else 0.0
		_put(vehicle_batch,Ground.unit_point(pos),Basis(Vector3.UP,atan2(heading.x,heading.y)),MountArt.pose(state,1.0,stride,moved,alpha,0.0,id))
	for s in battle.shots:
		var p := s.previous.lerp(s.pos,alpha)
		var fraction := s.distance / maxf(1,s.distance+s.remaining)
		var h := 1.1 + (2.5 if s.arrow else 0.32)*sin(PI*fraction)
		var altitude := lerpf(s.launch_height,Ground.deck_height(p),fraction)+h
		_put(arrows,Vector3(p.x,altitude,p.y),Basis(Vector3.UP,atan2(s.direction.x,s.direction.y)),Color(0,0,0,0))
	for order in battle.orders:
		if order.channel==Battle.Channel.COURIER and order.leg!=2:
			var recipient: Battle.Unit=battle.corps.recipient(battle,battle.companies[order.squad])
			var destination:=battle.hero.pos if order.leg==1 else recipient.pos
			var dir := order.pos.direction_to(destination)
			_put(runners,Ground.unit_point(order.pos),Basis(Vector3.UP,atan2(dir.x,dir.y)),Color(0,0,fposmod(order.age*3,1.0),0))
	for batch in batches:
		if batch.used!=batch.submitted_count:
			batch.mesh.visible_instance_count=batch.used
			batch.submitted_count=batch.used
