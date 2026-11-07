extends SceneTree
const W = preload("res://scripts/world_sim.gd")
const S = preload("res://scripts/campaign_store.gd")
const C = preload("res://scripts/campaign_value_codec.gd")
var checks = 0
var failures = []
var store
var live
var saved_live
var id
var old_sim
func check(ok,label):
	checks += 1
	if not ok: failures.append(label); print("FAIL ",label)
func envelope(raw: PackedByteArray) -> Dictionary:
	var data = Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_ZSTD))
	return {"format":S.FORMAT,"schema_version":S.SAVE_VERSION,"encoding":S.ENCODING,"uncompressed_bytes":raw.size(),"payload":data,"sha256":data.sha256_text()}
func reject(bytes: PackedByteArray,label: String):
	check(not store.decode_campaign(bytes).ok,label+" decoder rejects")
	var file = FileAccess.open("user://campaigns/"+store._campaign+"/slots/bad.save.json",FileAccess.WRITE)
	file.store_buffer(bytes); file.close()
	check(not store.load_slot(live,"bad").ok,label+" disk rejects")
	check(live.export_campaign_state() == saved_live and live.start_battle(id) == old_sim,label+" no mutation")
func _initialize():
	store = S.new("audit_bounds_v2_"+str(OS.get_process_id()))
	live = W.new()
	live.march("river"); live.advance(3)
	id = live.create_battle_ticket().ticket.battle_id
	old_sim = live.start_battle(id)
	saved_live = live.export_campaign_state()
	var valid = store.encode_campaign(live)
	check(valid.ok,"fixture validates")
	check(store.save_slot(live,"original").ok,"fixture persists")
	var raw = JSON.stringify(C.new().encode(saved_live).value).to_utf8_buffer()
	var e = envelope(raw)
	for field in e:
		var missing = e.duplicate(true); missing.erase(field)
		reject(JSON.stringify(missing).to_utf8_buffer(),"missing "+field)
	for v in [-1,0,1.5,128*1024*1024+1,"1",true,null]:
		var x=e.duplicate(true); x.uncompressed_bytes=v
		reject(JSON.stringify(x).to_utf8_buffer(),"invalid uncompressed size "+str(v))
	for v in [0,2,"1",null,true]:
		var x=e.duplicate(true); x.schema_version=v
		reject(JSON.stringify(x).to_utf8_buffer(),"unsupported version "+str(v))
	for v in ["", "unknown", true, 1, null]:
		var x=e.duplicate(true); x.encoding=v
		reject(JSON.stringify(x).to_utf8_buffer(),"invalid encoding "+str(v))
	for bytes in [PackedByteArray(),valid.bytes.slice(0,10),valid.bytes.slice(0,-1),PackedByteArray([255,254]),("[".repeat(101)+"]".repeat(101)).to_utf8_buffer()]:
		reject(bytes,"truncated utf8 or deep raw")
	var oversized = PackedByteArray(); oversized.resize(S.MAX_FILE_BYTES+1)
	reject(oversized,"oversized disk")
	var malformed_payload = raw.get_string_from_utf8().left(-1)+",]"
	reject(JSON.stringify(envelope(malformed_payload.to_utf8_buffer())).to_utf8_buffer(),"payload trailing comma rechecksummed")
	var deep = "[".repeat(101)+"]".repeat(101)
	reject(JSON.stringify(envelope(deep.to_utf8_buffer())).to_utf8_buffer(),"compressed payload depth")
	for v in [["i","9223372036854775808"],["i","-9223372036854775809"],["i","+1"],["i","00"],["f","000000000000f07f"],["f","000000000000f0ff"],["f","000000000000f87f"],["d",[["duplicate",true],["duplicate",false]]]]:
		check(not C.new().decode(v).ok,"codec boundary "+str(v))
	var items=[]; items.resize(C.MAX_COLLECTION+1)
	check(not C.new().decode(["a",items]).ok,"collection bound")
	var nested=true
	for i in range(C.MAX_DEPTH+1): nested=["a",[nested]]
	check(not C.new().decode(nested).ok,"codec depth")
	check(not C.new().decode("a".repeat(C.MAX_STRING+1)).ok,"string bound")
	var retained = W.new()
	check(store.load_slot(retained,"original").ok and retained.export_campaign_state()==saved_live,"original good slot still exact")
	print("BOUNDARY_AUDIT ",checks," checks ",failures.size()," failures ",failures)
	quit(1 if failures.size() else 0)
