class_name CampaignMigrations
extends RefCounted
## Explicit World5→6→7→8 history. Only World5 has an implicit legacy commander.
## Migrations add metadata, never heal, clamp, settle, allocate or advance time.
const Schema := preload("res://scripts/campaign_schema.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
const LEGACY_SESSION_FIELDS := ["units", "events", "seed", "rng_state", "elapsed", "order", "ended", "result", "player_move", "player_aim", "cooldowns", "damage_dealt"]

static func from_world5(saved: Variant) -> Dictionary:
	if not Schema.keys(saved, ["world", "battle_sessions", "generation_highwater"]) or not Schema.world(saved.world, 5) or not Schema.dictionary(saved.battle_sessions, 1) or not Schema.integer(saved.generation_highwater, saved.world.campaign_generation, Schema.MAX_ID):
		return {"ok": false, "reason": "invalid_legacy_campaign_shape"}
	# Validate before duplicating arbitrary Variant graphs (cycles/objects/depth).
	var encoded := Codec.new().encode(saved)
	if not encoded.ok:
		return encoded
	for id in saved.battle_sessions:
		if not Schema.text(id) or not Schema.keys(saved.battle_sessions[id], LEGACY_SESSION_FIELDS):
			return {"ok": false, "reason": "invalid_legacy_battle_shape"}
	var migrated: Dictionary = saved.duplicate(true)
	var profile := Profiles.profile_reference(Profiles.LEGACY)
	migrated.world.version = 6
	migrated.world.commander["hero_profile"] = profile.duplicate()
	for ticket in migrated.world.battle_tickets.values():
		ticket["hero_profile"] = profile.duplicate()
	for session in migrated.battle_sessions.values():
		session["hero_profile"] = profile.duplicate()
	# Caller MUST validate every migrated field/causal link before adopting it.
	return {"ok": true, "state": migrated}

static func from_world6(saved: Variant) -> Dictionary:
	if not Schema.keys(saved, ["world", "battle_sessions", "generation_highwater"]) or not Schema.world(saved.world, 6) or not Schema.dictionary(saved.battle_sessions, 1) or not Schema.integer(saved.generation_highwater, saved.world.campaign_generation, Schema.MAX_ID):
		return {"ok": false, "reason": "invalid_world6_campaign_shape"}
	var encoded := Codec.new().encode(saved)
	if not encoded.ok: return encoded
	var migrated: Dictionary = saved.duplicate(true)
	migrated.world.version = 7
	migrated.world["mode"] = "technical"
	migrated.world["origin"] = "legacy_campaign"
	migrated.world["youth"] = {}
	for ticket in migrated.world.battle_tickets.values():
		ticket["purpose"] = "technical"
		ticket["command_authority"] = "squad"
	return {"ok": true, "state": migrated}

static func from_world7(saved: Variant) -> Dictionary:
	if not Schema.keys(saved, ["world", "battle_sessions", "generation_highwater"]) or not Schema.world(saved.world, 7) or not Schema.dictionary(saved.battle_sessions, 1) or not Schema.integer(saved.generation_highwater, saved.world.campaign_generation, Schema.MAX_ID):
		return {"ok": false, "reason": "invalid_world7_campaign_shape"}
	var encoded := Codec.new().encode(saved)
	if not encoded.ok: return encoded
	var migrated: Dictionary = saved.duplicate(true)
	migrated.world.version = 8
	migrated.world["couriers"] = []
	for ticket in migrated.world.battle_tickets.values():
		ticket["signal_model"] = "legacy_global_v0"
	for id in migrated.battle_sessions:
		if not Schema.text(id) or not Schema.keys(migrated.battle_sessions[id], LEGACY_SESSION_FIELDS + ["hero_profile"]):
			return {"ok": false, "reason": "invalid_world7_battle_shape"}
		migrated.battle_sessions[id] = preload("res://scripts/battle_sim.gd").migrate_legacy_session(migrated.battle_sessions[id])
	# Preserve original youth provenance, historic reports, exact clocks and stocks.
	return {"ok": true, "state": migrated}
