extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Catalog:=preload("res://scripts/field/maps/map_catalog.gd")
const Legacy:=preload("res://scripts/field/maps/legacy_map_runtime.gd")
func _initialize():
 var registry:=Catalog.new()
 for bridgehead in [false,true]:
  var battle:=Battle.new();battle.setup(20,61112,Battle.Arms.Kit.SPEAR,true,true,20,bridgehead);battle.started=true
  for tick in 20:battle.step()
  var snapshot:=Save.snapshot(battle);var original:=var_to_bytes(snapshot)
  var resolved:=registry.resolve_save(snapshot);assert(resolved.error==OK and resolved.legacy)
  var map:=Legacy.new(bridgehead)
  for unit in battle.roster:map.unit_point(unit.pos);map.blocked(unit.pos,battle.gate_hp<=0.)
  assert(var_to_bytes(Save.snapshot(battle))==original,"Map lookup must not modify real battle casualties/positions/RNG")
  assert(var_to_bytes(snapshot)==original)
  var restored=Save.restore(snapshot);assert(restored!=null)
  assert(var_to_bytes(Save.snapshot(restored))==original,"Legacy save remains exact")
  var future=snapshot.duplicate(true);future.version=5;future.map_identity={"map_id":"newmap","topology_revision":1,"topology_sha256":"a".repeat(64)}
  assert(Save.restore(future)==null,"Actual old loader must not load new topology onto legacy terrain")
  assert(registry.resolve_save(future).error==ERR_DOES_NOT_EXIST)
  future.version=4;assert(registry.resolve_save(future).error==ERR_INVALID_DATA,"New identity cannot masquerade as old format")
 assert(registry.resolve_save({"version":5}).error==ERR_INVALID_DATA)
 print("MAP_LEGACY_SAVE_BOUNDARY_PASS real_20v20_both_maps exact_snapshot_restore old_engine_rejects_version5 no_teleport_or_casualty_reset; NEW_MAP_BATTLE_NOT_RUN")
 quit()
