extends SceneTree
## Physics survey only, no legacy visual asset/shader dependency.
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var step:=.125;var rows:=[]
	for z:int in 385:
		var row:=[]
		for x:int in 137:
			var p:=Vector2(29.6+x*step,-24.+z*step)
			row.append(Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p))
		rows.append(row)
	var file:=FileAccess.open(args[0],FileAccess.WRITE);assert(file)
	file.store_string(JSON.stringify({"x0":29.6,"z0":-24.,"step":step,"nx":137,"nz":385,"heights":rows,"contract":"existing gameplay support, not old artwork"}));file.close()
	print("GROUND_SURVEY_EXPORTED ",137*385);quit()
