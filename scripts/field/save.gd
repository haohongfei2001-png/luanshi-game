extends RefCounted
## A field exercise has its own slot and identities. It never replaces a career save.
const Battle := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
const FILE := "user://river_gate_quick_v1.bin"
const HEAD := [&"tick",&"started",&"result",&"attacks",&"blocked_hits",&"arrow_count",&"messages_arrived",&"messages_lost",&"notice",&"gate_hp",&"ram_hp",&"ram",&"ram_timer",&"capture",&"hero_move",&"aim",&"vehicle",&"riding_speed",&"riding_heading",&"messages_refused"]
const UNIT := [&"pos",&"before",&"facing",&"locked",&"separation",&"target",&"state",&"timer",&"duration",&"move_slot",&"hp",&"morale",&"fatigue",&"flash",&"stride",&"used_second",&"impacts",&"received",&"lost_tick",&"mounted",&"mount_hp",&"ammo",&"stock_strike"]
const COMPANY := [&"aim",&"mission",&"standing",&"serial",&"delivered",&"regrouping"]
const SHOT := [&"team",&"source",&"pos",&"previous",&"direction",&"speed",&"remaining",&"distance",&"power",&"pierce",&"last_hit",&"arrow",&"over_front",&"launch_height"]
const ORDER := [&"squad",&"serial",&"mission",&"channel",&"pos",&"age",&"delay",&"leg",&"due",&"refused"]

static func _row(item: Object, fields: Array) -> Array:
	var row := []
	for name in fields: row.append(item.get(name))
	return row

static func _rows(items: Array, fields: Array) -> Array:
	var rows := []
	for item in items: rows.append(_row(item,fields))
	return rows

static func snapshot(b: Battle) -> Dictionary:
	return {"version":2,"legacy_missiles":b.legacy_missiles,"side":b.side_size,"seed":b.rng.seed,"rng":b.rng.state,"weapon":b.hero.kit,
		"battle":_row(b,HEAD),"units":_rows(b.roster,UNIT),"companies":_rows(b.companies,COMPANY),
		"orders":_rows(b.orders,ORDER),"shots":_rows(b.shots,SHOT),
		"equipment":b.equipment.duplicate(),"losses":b.losses.duplicate(),"escaped":b.escaped.duplicate(),"hits":b.hits.duplicate(),
		"vehicle_pos":b.vehicle_pos.duplicate(),"vehicle_hp":b.vehicle_hp.duplicate(),"skill_clocks":b.hero_cds.duplicate()}

static func _valid(value: Variant, example: Variant) -> bool:
	if typeof(value)!=typeof(example): return false
	if value is float: return is_finite(value) and absf(value) <= 100000000.0
	if value is Vector2: return value.is_finite() and value.abs().x<10000 and value.abs().y<10000
	if value is String: return value.length()<=256
	return true

static func _apply(item: Object,fields: Array,data: Variant) -> bool:
	if not data is Array or data.size()!=fields.size(): return false
	for i in fields.size():
		if not _valid(data[i],item.get(fields[i])): return false
		item.set(fields[i],data[i])
	return true

static func _list(data: Dictionary,key: String,count: int) -> bool:
	return data.get(key) is Array and data[key].size()==count

static func restore(data: Variant) -> Battle:
	if not data is Dictionary or data.get("version") not in [1,2] or data.get("side") not in Battle.SCALES: return null
	if not data.get("seed") is int or not data.get("rng") is int or not data.get("weapon") is int or data.weapon<0 or data.weapon>8: return null
	var b := Battle.new()
	b.setup(data.side,data.seed,data.weapon)
	var header: Variant=data.get("battle")
	if data.version==1 and header is Array and header.size()==HEAD.size()-1:
		header=header.duplicate()
		header.append(0)
	if not _apply(b,HEAD,header) or b.tick<0 or b.vehicle<0 or b.vehicle>2: return null
	if data.version==1:
		b.legacy_missiles=b.started
	else:
		if not data.get("legacy_missiles") is bool: return null
		b.legacy_missiles=data.legacy_missiles
	if b.gate_hp<0 or b.gate_hp>260 or b.ram_hp<0 or b.ram_hp>150: return null
	if not _list(data,"units",b.roster.size()) or not _list(data,"companies",b.companies.size()): return null
	var killed := [0,0]
	var departed := [0,0]
	var remaining := PackedInt32Array()
	remaining.resize(b.companies.size())
	var spent:=0
	for i in b.roster.size():
		var u := b.roster[i]
		var values: Variant=data.units[i]
		if data.version==1 and values is Array and values.size()==UNIT.size()-2:
			values=values.duplicate()
			values.append(Arms.issue(u.kit))
			values.append(false)
		if not _apply(u,UNIT,values) or u.ammo<0 or u.ammo>Arms.issue(u.kit): return null
		if u.stock_strike and (u.ammo!=0 or u.kit not in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]): return null
		spent+=Arms.issue(u.kit)-u.ammo
		if u.state < 0 or u.state > Battle.State.DEAD or u.move_slot < 0 or u.move_slot > 3 or u.target < -1 or u.target>=b.roster.size(): return null
		if u.hp < 0 or u.hp > u.max_hp or (u.hp==0) != (u.state==Battle.State.DEAD): return null
		if absf(u.pos.x)>Ground.LIMIT.x or absf(u.pos.y)>Ground.LIMIT.y: return null
		if u.hero or u.officer: continue
		if u.state==Battle.State.DEAD: killed[u.team]+=1
		elif u.state==Battle.State.ESCAPED: departed[u.team]+=1
		else: remaining[u.squad]+=1
	if not b.legacy_missiles and spent!=b.arrow_count: return null
	for i in b.companies.size():
		var c := b.companies[i]
		var row: Variant = data.companies[i]
		if row is Array and row.size()==COMPANY.size()-1:
			row=row.duplicate()
			row.append(false)
		if not _apply(c,COMPANY,row) or c.mission<0 or c.mission>=Battle.MISSIONS.size() or c.standing!=remaining[i] or c.delivered>c.serial: return null
	if not data.get("orders") is Array or data.orders.size()>8192 or not data.get("shots") is Array or data.shots.size()>b.roster.size()*8: return null
	for old_row in data.orders:
		var row: Variant=old_row
		if data.version==1 and row is Array and row.size()==ORDER.size()-3:
			row=row.duplicate()
			row.append_array([0,90.0,false])
		var o := Battle.Dispatch.new()
		if not _apply(o,ORDER,row) or o.squad<0 or o.squad>=b.companies_per_side or o.channel<0 or o.channel>=Battle.CHANNELS.size() or o.leg<0 or o.leg>2 or o.age<0 or o.due<0 or o.mission<0 or o.mission>=Battle.MISSIONS.size(): return null
		b.orders.append(o)
	for source_row in data.shots:
		var row: Variant=source_row
		if row is Array and row.size()==SHOT.size()-2:
			row=row.duplicate()
			row.append(false)
			row.append(0.0)
		var s := Battle.Shot.new()
		if not _apply(s,SHOT,row) or s.source<0 or s.source>=b.roster.size() or s.team!=b.roster[s.source].team or s.pierce<1 or s.pierce>2: return null
		b.shots.append(s)
	if data.get("losses")!=killed or data.get("escaped")!=departed or data.get("equipment")!=killed: return null
	for key in ["losses","escaped","equipment","hits","vehicle_pos","vehicle_hp"]:
		var current: Array=b.get(key)
		if not _list(data,key,current.size()): return null
		for i in current.size():
			if not _valid(data[key][i],current[i]): return null
		b.set(key,data[key].duplicate())
	if not data.get("skill_clocks") is PackedFloat32Array or data.skill_clocks.size()!=4: return null
	for cd in data.skill_clocks:
		if not is_finite(cd) or cd<0: return null
	b.hero_cds=data.skill_clocks.duplicate()
	b.rng.state=data.rng
	b._rebuild_grid()
	return b

static func save(b: Battle) -> Error:
	var path := ProjectSettings.globalize_path(FILE)
	var temp := path + ".%d.%d.tmp" % [OS.get_process_id(),Time.get_ticks_usec()]
	var out := FileAccess.open(temp,FileAccess.WRITE)
	if not out: return FileAccess.get_open_error()
	out.store_buffer(var_to_bytes(snapshot(b)))
	out.flush()
	var err := out.get_error()
	out.close()
	if err==OK: err=DirAccess.rename_absolute(temp,path)
	if err!=OK: DirAccess.remove_absolute(temp)
	return err

static func load_quick() -> Battle:
	var file := FileAccess.open(FILE,FileAccess.READ)
	if not file or file.get_length()>8*1024*1024 or file.get_length()<8: return null
	return restore(bytes_to_var(file.get_buffer(file.get_length())))
