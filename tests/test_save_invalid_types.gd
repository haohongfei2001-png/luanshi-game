extends SceneTree
const W = preload("res://scripts/world_sim.gd")
const C = preload("res://scripts/campaign_value_codec.gd")
## Independent mutation oracle. Injected encounter endings are validation fixtures, not combat proof.
var failures := 0
var paths=[]
var seed
var live
var before
func walk(v,path:Array,depth:int):
	if depth>10:return
	paths.append(path)
	if v is Dictionary:
		for k in v: walk(v[k],path+[k],depth+1)
	elif v is Array and not v.is_empty():
		if path[-1] is String and path[-1] == "events":
			var kinds = {}
			for i in range(v.size()):
				var kind = v[i].get("kind",v[i].get("type",""))
				if not kinds.has(kind): walk(v[i],path+[i],depth+1); kinds[kind]=true
		else: walk(v[0],path+[0],depth+1)
func set_at(s,path:Array,v):
	var cur=s
	for i in range(path.size()-1): cur=cur[path[i]]
	cur[path[-1]]=v
func get_at(s,path:Array):
	var cur=s
	for k in path:cur=cur[k]
	return cur
func _initialize():
	var w=W.new();w.march("river");w.advance(3)
	var id=w.create_battle_ticket().ticket.battle_id
	var b=w.start_battle(id)
	b.issue_order("attack")
	var args=OS.get_cmdline_user_args()
	if args.has("committed"):
		for u in b.units:
			if u.team==1:b._hurt(u,1000.0,false)
		b._check_result();w.commit_battle_outcome(b.outcome())
	elif args.has("dead"):
		b._hurt(b.player(),1000.0,false);b._check_result();w.commit_battle_outcome(b.outcome())
	seed=C.new().decode(C.new().encode(w.export_campaign_state()).value).value
	live=W.new(555)
	before=live.export_campaign_state()
	walk(seed,[],0)
	var n=0
	for path in paths:
		if path.is_empty():continue
		for v in [true,1.25,"bad",[],{}]:
			if typeof(get_at(seed,path))==typeof(v):continue
			var s=seed.duplicate(true);set_at(s,path,v)
			n+=1
			live=W.new(555)
			before=live.export_campaign_state()
			var result=live.restore_campaign_state(s)
			if result.get("ok",true):
				failures += 1
				push_error("Unexpected acceptance: " + str(path))
			if live.export_campaign_state()!=before:
				failures += 1
				push_error("Partial mutation: " + str(path))
	print("SAVE_INVALID_TYPES ", n, " cases / ", failures, " failures")
	quit(0 if failures == 0 else 1)
