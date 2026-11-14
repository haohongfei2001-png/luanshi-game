extends SceneTree
## Decode the shipping palette against the actual imported body/equipment vertices.
const Company:=preload("res://scripts/field/company_art.gd")
var bank:Image
var failures:Array[String]=[]

func _initialize() -> void:
	_run.call_deferred()

func _bone(kit:int,joint:int) -> Transform3D:
	var x:=joint*33+31
	var y:=(kit*31+14)*4
	var hi:=bank.get_pixel(x,y)
	var lo:=bank.get_pixel(x,y+1)
	var q:=Quaternion((hi.r*256.+lo.r)*(2./257.)-1.,(hi.g*256.+lo.g)*(2./257.)-1.,
		(hi.b*256.+lo.b)*(2./257.)-1.,(hi.a*256.+lo.a)*(2./257.)-1.).normalized()
	hi=bank.get_pixel(x,y+2)
	lo=bank.get_pixel(x,y+3)
	var p:=Vector3((hi.r*256.+lo.r)/257.-.5,(hi.g*256.+lo.g)/257.-.5,(hi.b*256.+lo.b)/257.-.5)*6.
	return Transform3D(Basis(q),p)

func _point(point:Vector3,uv:Vector2,bones:Array[Transform3D]) -> Vector3:
	var packed:=floori(uv.x*1024.)
	var first:=packed>>5
	var second:=packed&31
	return (bones[second]*point).lerp(bones[first]*point,clampf(uv.y,0.,1.))

func _bounds(mesh:ArrayMesh,bones:Array[Transform3D],settled_cloth:bool=false) -> Dictionary:
	var arrays:=mesh.surface_get_arrays(0)
	var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var skin:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV2]
	var tex:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	var count:=0
	var lowest:={}
	for i:int in positions.size():
		var packed:=floori(skin[i].x*1024.)
		var first:=packed>>5
		var second:=packed&31
		if first==15 and second==15: continue # The shader hides the released arrow.
		var p:=_point(positions[i],skin[i],bones)
		var tile:=Vector2i(floori(tex[i].x*8.),floori(tex[i].y*4.))
		var cloth:=(tex[i].x>=2. and tex[i].x<3.) or (tile.y==2 and tile.x in [3,7])
		if settled_cloth and cloth and p.y<.047:
			p.y=.012+.035*(.035/(.082-p.y))
		if p.y<low.y:
			lowest={"bind":[positions[i].x,positions[i].y,positions[i].z],"joints":[first,second],"weight":skin[i].y}
		low=low.min(p)
		high=high.max(p)
		count+=1
	return {"vertices":count,"min":[low.x,low.y,low.z],"max":[high.x,high.y,high.z],"lowest":lowest}

func _run() -> void:
	bank=Company.MOTION.get_image()
	if bank.is_compressed(): bank.decompress()
	Company._load_pieces()
	var rows:Array=[]
	for kit:int in 9:
		var bones:Array[Transform3D]=[]
		for joint:int in 16: bones.append(_bone(kit,joint))
		var label:=Company.costume(kit)+"CloseMaster"
		var body:ArrayMesh=Company.pieces[label]
		var weapon_name:=("FieldArms" if kit in [0,1,3,7,8] else "Arms")+str(kit)+"Close"
		var weapon:ArrayMesh=Company.pieces[weapon_name]
		var raw_body:=_bounds(body,bones)
		var body_bounds:=_bounds(body,bones,true)
		var equipment:=_bounds(weapon,bones)
		var row:={"kit":kit,"raw_body":raw_body,"body":body_bounds,"held_mesh":equipment}
		var ranked:={}
		for role:String in ["Officer","Player"]:
			var ranked_body:ArrayMesh=Company.pieces[role+"CloseMaster"]
			ranked[role]={"raw":_bounds(ranked_body,bones),"settled":_bounds(ranked_body,bones,true)}
		row["ranked"]=ranked
		if kit==7:
			row["shield"]=_bounds(Company.pieces["GarrisonShield"],bones)
		rows.append(row)
		if float(body_bounds.min[1])<-.025:
			failures.append("Body under terrain for kit "+str(kit))
		for role:String in ranked:
			if float(ranked[role].settled.min[1])<-.025:
				failures.append(role+" under terrain for kit "+str(kit))
		if float(equipment.min[1])<-.025 or float(equipment.max[1])>.40:
			failures.append("Equipment leaves the ground plane for kit "+str(kit))
		if kit==7 and (float(row.shield.min[1])<-.025 or float(row.shield.max[1])>.40):
			failures.append("Shield leaves the ground plane")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/field-rest"))
	var out:=FileAccess.open("res://artifacts/field-rest/mesh-bounds.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"frames":"settled fall, clip14 key31","rows":rows,"failures":failures},"  "))
	out.close()
	print("FIELD_REST_MESH ",JSON.stringify(rows)," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() or "--report-only" in OS.get_cmdline_user_args() else 1)
