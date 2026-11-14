extends SceneTree
const Identity:=preload("res://scripts/field/maps/map_identity.gd")
const Catalog:=preload("res://scripts/field/maps/map_catalog.gd")
func fixture(revision:int)->Dictionary:
 return {"schema":1,"map_id":"test-fixture-only-not-a-game-map","topology_revision":revision,"visual_revision":1,"topology_sha256":"f".repeat(64),"authored_source_sha256":"a".repeat(64),"scene":{"path":"res://unit-test/scene.scn","sha256":"b".repeat(64),"derived_from_source_sha256":"a".repeat(64)},"navigation":{"path":"res://unit-test/nav.res","sha256":"c".repeat(64),"derived_from_source_sha256":"a".repeat(64)}}
func _initialize():
 var hashes={"res://unit-test/scene.scn":"b".repeat(64),"res://unit-test/nav.res":"c".repeat(64)}
 var first:=Identity.new();var source=fixture(1);assert(first.configure(source,hashes)==OK)
 source.topology_revision=99;assert(first.identity().topology_revision==1)
 var exposed=first.manifest();exposed.scene.sha256="d".repeat(64);assert(first.manifest().scene.sha256=="b".repeat(64))
 assert(first.configure(fixture(2),hashes)==ERR_ALREADY_IN_USE)
 var second:=Identity.new();assert(second.configure(fixture(2),hashes)==OK)
 var catalog:=Catalog.new();assert(catalog.register(first)==OK);assert(catalog.register(second)==OK);assert(catalog.register(first)==ERR_ALREADY_EXISTS)
 var old={"version":4,"bridgehead":true,"unit_pos":[3,5]};var old_bytes=var_to_bytes(old)
 var legacy=catalog.resolve_save(old);assert(legacy.error==OK and legacy.legacy);assert(var_to_bytes(old)==old_bytes)
 var save={"map_identity":first.identity(),"unit_pos":[1,2]};var snapshot=var_to_bytes(save)
 assert(catalog.resolve_save(save).profile==first);assert(var_to_bytes(save)==snapshot)
 save.map_identity.topology_revision=2;assert(catalog.resolve_save(save).profile==second)
 save.map_identity.topology_revision=3;assert(catalog.resolve_save(save).error==ERR_DOES_NOT_EXIST)
 save.map_identity.topology_revision=1;save.map_identity.topology_sha256="d".repeat(64);assert(catalog.resolve_save(save).error==ERR_FILE_CORRUPT)
 var wrong=fixture(3);wrong.navigation.derived_from_source_sha256="e".repeat(64);assert(Identity.new().configure(wrong,hashes)==ERR_INVALID_DATA)
 wrong=fixture(3);wrong.navigation.path="res://../escape";assert(Identity.new().configure(wrong,hashes)==ERR_INVALID_DATA)
 var corrupt=hashes.duplicate();corrupt["res://unit-test/nav.res"]="e".repeat(64);assert(Identity.new().configure(fixture(3),corrupt)==ERR_FILE_CORRUPT)
 var visual=fixture(1);visual.visual_revision=2;visual.authored_source_sha256="d".repeat(64)
 visual.scene.derived_from_source_sha256=visual.authored_source_sha256;visual.navigation.derived_from_source_sha256=visual.authored_source_sha256
 var refreshed:=Identity.new();assert(refreshed.configure(visual,hashes)==OK);assert(refreshed.matches(first.identity()),"Pure visual/source revision must not invalidate saved topology identity")
 var json_profile:=Identity.new();assert(json_profile.configure(JSON.parse_string(JSON.stringify(fixture(1))),hashes)==OK);assert(json_profile.matches(first.identity()),"Actual JSON numeric parsing must preserve identity")
 var other:=Catalog.new();assert(other.resolve_save({"map_identity":first.identity()}).error==ERR_DOES_NOT_EXIST)
 print("MAP_IDENTITY_ISOLATION_PASS immutable_snapshot exact_revision source_nav_closure old_save_untouched separate_catalogs; BATTLE_BINDING_AND_NEW_ART_NOT_RUN")
 quit()
