extends SceneTree
## Diagnostic only. A depth-tested magenta pass counts the REAL grip/weapon fragments.
## Hidden-roster reference frames are NOT beauty images or game evidence themselves.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Skin:=preload("res://scripts/field/company_skin.gdshader")
var f: Field
var evidence: String
var marker: Shader
var images:=0
var rows: Array=[]
var timings:=PackedInt32Array()
var checks: Array[String]=[]
func fail(why: String) -> void: checks.append(why);push_error(why)
func _initialize() -> void: go.call_deferred()
func draw() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
func tally() -> int:
	var im:=root.get_texture().get_image()
	var mid:=f.camera.unproject_position(Ground.unit_point(f.battle.hero.pos)+Vector3.UP*1.05)
	var region:=Rect2i(Vector2i(mid)-Vector2i(175,170),Vector2i(350,340)).intersection(Rect2i(0,0,im.get_width(),im.get_height()))
	var cut:=im.get_region(region)
	cut.convert(Image.FORMAT_RGBA8)
	var bytes:=cut.get_data()
	var n:=0
	for i in range(0,bytes.size(),4):
		if bytes[i]>178 and bytes[i+1]<85 and bytes[i+2]>178:n+=1
	return n
func sample(label: String, angle: float, photo: bool) -> Dictionary:
	var helper=f.melee_sight
	var g=f.view.groups[20+f.battle.hero.kit]
	var native: ShaderMaterial=g.node.material_override
	var instrument: ShaderMaterial=native.duplicate()
	instrument.shader=marker
	for param in ["cloth_atlas","response_atlas","motion_bank","livery","kit"]:instrument.set_shader_parameter(param,native.get_shader_parameter(param))
	var base_angle:=f.camera_yaw
	var center:=f.camera_center
	var result: Dictionary={}
	for selected in [false,true]:
		helper.offset=angle if selected else 0.0
		f._camera()
		f._draw_field()
		await draw()
		var name:= "assisted" if selected else "original"
		if photo:
			var im:=root.get_texture().get_image()
			im.save_jpg(evidence+"/"+label+"-"+name+".jpg",0.94)
		g.node.material_override=instrument
		await draw()
		var visible:=tally()
		var hide_nodes: Array=[]
		for key in f.view.groups:
			var node: Node3D=f.view.groups[key].node
			if node!=g.node and node.visible:node.hide();hide_nodes.append(node)
		# Only remove opposing/nearby bodies during normalization. The wall, the
		# ram and the player's own torso still write depth in the diagnostic pass.
		for node in [f.view.horse.node,f.view.horse_rank.node,f.view.standards[0].node,f.view.standards[1].node]:
			if node.visible:node.hide();hide_nodes.append(node)
		await draw()
		var unobstructed:=tally()
		for node in hide_nodes:node.show()
		g.node.material_override=native
		result[name]=[visible,unobstructed]
	helper.offset=angle
	if center!=f.camera_center or f.camera_yaw!=base_angle:fail("Matching framing changed")
	return result
func driver(b: Battle,scenario: String) -> void:
	var origin:=b.hero.pos
	var foe: Battle.Unit=null
	var ds:=INF
	for id in b._near(origin,16.0,1):
		var v:=b.roster[id]
		var sq:=origin.distance_squared_to(v.pos)
		if sq<ds and b.active(v) and v.state!=Battle.State.ROUT and Ground.clear_shot(origin,v.pos,b.gate_hp<=0):
			ds=sq;foe=v
	var staging:=b.ram+Vector2(-0.25,-2.75) if scenario=="ram" else Ground.GATE+Vector2(-4.1,-1.9)
	var to:=origin if not foe else foe.pos
	var walk:=Vector2.ZERO
	if scenario!="field" and origin.distance_squared_to(staging)>4.0:walk=origin.direction_to(staging)
	elif foe and ds>1.50:walk=origin.direction_to(foe.pos)
	b.input_state(walk,(to-origin).normalized() if foe else Vector2.RIGHT)
	if foe and ds<8.1 and b.hero.state==Battle.State.MARCH:b.action(0)
	b.step()
func go() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	evidence=OS.get_environment("SIGHT_OUT")
	DirAccess.make_dir_recursive_absolute(evidence)
	marker=Shader.new()
	marker.code=Skin.code.replace("void vertex() {","varying flat float testhand;\nvoid vertex() {").replace("int first=bones/32;","int first=bones/32; testhand=first==8 || first==5 ? 1.0:0.0;").replace("SPECULAR=mix(.25,.56,response.g);","SPECULAR=mix(.25,.56,response.g); if(testhand>0.5){ALBEDO=vec3(1.0,0.0,1.0);EMISSION=vec3(3.0,0.0,3.0);}")
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	f=shell.field
	f.set_process(false)
	f.set_physics_process(false)
	await draw()
	for scenario: String in ["field","ram","gate"]:
		f.new_muster(512);f.hud.plan_requested.emit(1)
		f.battle.equip_hero(3 if scenario!="ram" else 1)
		f.hud.go.pressed.emit()
		f.camera.size=13.0
		var b:=f.battle
		var next_tick:=0
		var n:=0
		for k in 1150:
			if b.result!="":break
			driver(b,scenario)
			f.carry=0.049999
			f.camera_center=b.hero.pos
			var before:=Time.get_ticks_usec()
			f._camera(Battle.DT)
			timings.append(Time.get_ticks_usec()-before)
			var ang:=f.melee_sight.offset
			if b.tick<next_tick or ang<deg_to_rad(2.0) or b.hero.state not in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD]:continue
			var site: String="field"
			if b.hero.pos.distance_to(Ground.GATE)<12:site="gate"
			elif b.hero.pos.distance_to(b.ram)<6:site="ram"
			if scenario=="gate" and site!="gate":continue
			if scenario=="ram" and site!="ram":continue
			var label:="%s-%04d"%[scenario,b.tick]
			var m:=await sample(label,ang,true)
			var row:={"scenario":scenario,"site":site,"tick":b.tick,"seed":Battle.SEED,"ordinary":[512,512],"angle":rad_to_deg(ang),"zoom":f.camera.size,"yaw":f.camera_yaw,"state":b.hero.state,"kit":b.hero.kit,"hits":b.hits.duplicate(),"hero_impacts":b.hero.impacts,"center":str(f.camera_center),"fragments":m}
			rows.append(row)
			print("SIGHT_PAIR ",JSON.stringify(row))
			n+=1;next_tick=b.tick+20
			if n>=6:break
		print("SIGHT_SITE ",scenario," samples=",n," ended_tick=",b.tick," result=",b.result)
		# Returning to the player's own tactical pan must restore their requested angle.
		f.pan_to(Vector2(10,10))
		if f.melee_sight.offset!=0:fail("Pan retained a melee tilt")
	timings.sort()
	print("SIGHT_COST ",JSON.stringify({"n":timings.size(),"p50_us":timings[timings.size()/2],"p95_us":timings[ceili(timings.size()*.95)-1],"p99_us":timings[ceili(timings.size()*.99)-1],"max_us":timings[-1],"method":"entire _camera call including look_at; no readbacks"}))
	if rows.is_empty():fail("No real contacts exercised the camera")
	var file:=FileAccess.open(evidence+"/pairs.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows))
	print("SIGHT_SMOKE ",checks)
	quit(0 if checks.is_empty() else 1)
