class_name CampaignStore
extends RefCounted
## Free named slots and complete named checkpoints. Disk IO stays under user://.
## A single atomic replacement contains both resource state and settlement receipts.

const World := preload("res://scripts/world_sim.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
const Schema := preload("res://scripts/campaign_schema.gd")
const FORMAT := "luanshi-campaign"
const SAVE_VERSION := 1
const MAX_FILE_BYTES := 16 * 1024 * 1024
const MAX_RAW_BYTES := 128 * 1024 * 1024
const ENCODING := "zstd-base64"
var _campaign := "default"

func _init(campaign_id: String = "default") -> void:
	_campaign = campaign_id

func save_slot(world: WorldSimulation, slot_id: String) -> Dictionary:
	return _save(world, "slots", slot_id)

func load_slot(world: WorldSimulation, slot_id: String) -> Dictionary:
	return _load(world, "slots", slot_id)

func save_checkpoint(world: WorldSimulation, checkpoint_id: String) -> Dictionary:
	return _save(world, "checkpoints", checkpoint_id)

func load_checkpoint(world: WorldSimulation, checkpoint_id: String) -> Dictionary:
	return _load(world, "checkpoints", checkpoint_id)

func list_saves(checkpoints: bool = false) -> Dictionary:
	var location := _location("checkpoints" if checkpoints else "slots", "listing", false)
	if not location.ok:
		return location
	var folder := DirAccess.open(location.directory)
	if folder == null:
		return {"ok": true, "saves": []}
	var saves: Array[String] = []
	for filename in folder.get_files():
		if filename.ends_with(".save.json") and not folder.is_link(filename):
			var id := filename.trim_suffix(".save.json")
			if _safe_id(id):
				saves.append(id)
	saves.sort()
	return {"ok": true, "saves": saves}

func commit_and_save(world: WorldSimulation, outcome: Variant, slot_id: String) -> Dictionary:
	## Prepare on a detached authority. Disk failure leaves the live game unchanged.
	## Crash before rename leaves pending outcome; after rename leaves its one receipt.
	var candidate := World.new()
	var restored := candidate.restore_campaign_state(world.export_campaign_state())
	if not restored.ok:
		return restored
	var receipt := candidate.commit_battle_outcome(outcome)
	if not receipt.ok:
		return receipt
	var written := save_slot(candidate, slot_id)
	if not written.ok:
		return written
	# Already validated state, no possible external input between write and adoption.
	var adopted := world.restore_campaign_state(candidate.export_campaign_state())
	if not adopted.ok:
		return {"ok": false, "reason": "saved_but_adoption_failed", "saved": true}
	return {"ok": true, "receipt": receipt, "slot_id": slot_id}

func encode_campaign(world: WorldSimulation) -> Dictionary:
	var state := world.export_campaign_state()
	var candidate := World.new()
	var validation := candidate.restore_campaign_state(state)
	if not validation.ok:
		return validation
	var encoded := Codec.new().encode(state)
	if not encoded.ok:
		return encoded
	var raw := JSON.stringify(encoded.value).to_utf8_buffer()
	if raw.size() > MAX_RAW_BYTES:
		return _error("save_payload_too_large")
	var payload := Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_ZSTD))
	var envelope := JSON.stringify({"format": FORMAT, "schema_version": SAVE_VERSION,
		"encoding": ENCODING, "uncompressed_bytes": raw.size(),
		"payload": payload, "sha256": payload.sha256_text()})
	var bytes := envelope.to_utf8_buffer()
	if bytes.size() > MAX_FILE_BYTES:
		return _error("save_too_large")
	return {"ok": true, "bytes": bytes}

func decode_campaign(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty() or bytes.size() > MAX_FILE_BYTES:
		return _error("invalid_file_size")
	var source := bytes.get_string_from_utf8()
	# Invalid UTF-8 must not be silently repaired into a different valid document.
	if source.to_utf8_buffer() != bytes or not _bounded_json_depth(source):
		return _error("invalid_encoding_or_depth")
	var json := JSON.new()
	if json.parse(source) != OK:
		return _error("malformed_save")
	var envelope: Variant = json.data
	if not Schema.keys(envelope, ["format", "schema_version", "encoding", "uncompressed_bytes", "payload", "sha256"]) or not envelope.format is String or envelope.format != FORMAT or not envelope.schema_version is float or envelope.schema_version != SAVE_VERSION:
		return _error("unsupported_save_schema")
	# v1 is the first actual loader. No migration from prior debug snapshots exists.
	if not envelope.encoding is String or envelope.encoding != ENCODING or not envelope.uncompressed_bytes is float or not is_finite(envelope.uncompressed_bytes) or envelope.uncompressed_bytes < 1 or envelope.uncompressed_bytes > MAX_RAW_BYTES or floor(envelope.uncompressed_bytes) != envelope.uncompressed_bytes:
		return _error("invalid_payload_size_or_encoding")
	var canonical: Dictionary = envelope.duplicate()
	canonical.schema_version = int(envelope.schema_version)
	canonical.uncompressed_bytes = int(envelope.uncompressed_bytes)
	if JSON.stringify(canonical) != source:
		return _error("noncanonical_save_json")
	if not envelope.payload is String or not envelope.sha256 is String or envelope.sha256 != envelope.payload.sha256_text():
		return _error("save_checksum")
	var compressed := Marshalls.base64_to_raw(envelope.payload)
	if compressed.is_empty() or Marshalls.raw_to_base64(compressed) != envelope.payload:
		return _error("invalid_compressed_payload")
	var raw := compressed.decompress(int(envelope.uncompressed_bytes), FileAccess.COMPRESSION_ZSTD)
	if raw.size() != int(envelope.uncompressed_bytes):
		return _error("invalid_compressed_size")
	var payload := raw.get_string_from_utf8()
	if payload.to_utf8_buffer() != raw or not _bounded_json_depth(payload) or json.parse(payload) != OK:
		return _error("malformed_save_payload")
	if JSON.stringify(json.data) != payload:
		return _error("noncanonical_payload_json")
	var decoded := Codec.new().decode(json.data)
	if not decoded.ok:
		return decoded
	var candidate := World.new()
	var validation := candidate.restore_campaign_state(decoded.value)
	if not validation.ok:
		return validation
	return {"ok": true, "state": decoded.value}

func _save(world: WorldSimulation, kind: String, id: String) -> Dictionary:
	var encoded := encode_campaign(world)
	if not encoded.ok:
		return encoded
	var location := _location(kind, id, true)
	if not location.ok:
		return location
	var temporary: String = location.path + ".tmp-" + Crypto.new().generate_random_bytes(12).hex_encode()
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _error("save_open_failed", FileAccess.get_open_error())
	file.store_buffer(encoded.bytes)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary) # Only this call's newly created temporary.
		return _error("save_write_failed", write_error)
	var verified := _read_bytes(temporary)
	if not verified.ok or verified.bytes != encoded.bytes:
		DirAccess.remove_absolute(temporary)
		return _error("save_verification_failed")
	# Never delete destination to make rename work. If replacement is unsupported,
	# report failure and leave the existing save in place.
	var rename_error := DirAccess.rename_absolute(temporary, location.path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary)
		return _error("save_replace_failed", rename_error)
	return {"ok": true, "id": id, "kind": kind, "schema_version": SAVE_VERSION}

func _load(world: WorldSimulation, kind: String, id: String) -> Dictionary:
	var location := _location(kind, id, false)
	if not location.ok:
		return location
	var read := _read_bytes(location.path)
	if not read.ok:
		return read
	var decoded := decode_campaign(read.bytes)
	if not decoded.ok:
		return decoded
	return world.restore_campaign_state(decoded.state)

func _read_bytes(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _error("save_read_failed", FileAccess.get_open_error())
	var size := file.get_length()
	if size < 1 or size > MAX_FILE_BYTES:
		file.close()
		return _error("invalid_file_size")
	var bytes := file.get_buffer(size)
	var read_error := file.get_error()
	file.close()
	if bytes.size() != size or read_error != OK:
		return _error("save_read_failed", read_error)
	return {"ok": true, "bytes": bytes}

func _location(kind: String, id: String, create: bool) -> Dictionary:
	if not _safe_id(_campaign) or not _safe_id(id) or kind not in ["slots", "checkpoints"]:
		return _error("invalid_save_identifier")
	var path := "user://"
	for segment in ["campaigns", _campaign, kind]:
		var parent := DirAccess.open(path)
		if parent != null and parent.is_link(segment):
			return _error("save_symlink_rejected")
		path = path.path_join(segment)
		if create and not DirAccess.dir_exists_absolute(path):
			var err := DirAccess.make_dir_absolute(path)
			if err != OK:
				return _error("save_directory_failed", err)
	var directory := DirAccess.open(path)
	var filename := id + ".save.json"
	if directory != null and directory.is_link(filename):
		return _error("save_symlink_rejected")
	return {"ok": true, "directory": path, "path": path.path_join(filename)}

func _safe_id(value: String) -> bool:
	if value.is_empty() or value.length() > 48:
		return false
	for index in range(value.length()):
		var code := value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code in [45, 95]):
			return false
	return true

func _bounded_json_depth(source: String) -> bool:
	var depth := 0
	var quoted := false
	var escaped := false
	for index in range(source.length()):
		var code := source.unicode_at(index)
		if quoted:
			if escaped:
				escaped = false
			elif code == 92:
				escaped = true
			elif code == 34:
				quoted = false
		elif code == 34:
			quoted = true
		elif code in [91, 123]:
			depth += 1
			if depth > 100:
				return false
		elif code in [93, 125]:
			depth -= 1
			if depth < 0:
				return false
	return not quoted and depth == 0

func _error(reason: String, code: int = OK) -> Dictionary:
	return {"ok": false, "reason": reason, "error_code": code}
