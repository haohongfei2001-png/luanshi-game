# Complete-mother Controller / standard Skeleton internal entry

## Acceptance state first

**No new mother scene GPU or art acceptance.** Source terrain004 below is only an explicitly labelled functional interface fixture. The actual complete mother/topology2 is still being authored and must rerun navigation/capacity/combat. Rejected source11 clothes are used only to test a real Skeleton/Controller interface. They are not a released character, accepted art or thousand-Skeleton budget proof.

Contact attempts must not be conflated:
1. `map-v2-controller-contact-first`: actual Controller input reached an enemy; tick271, hero hit1, received4, naturally died. New standard Skeleton played real walk/sprint/thrust/hit/death; death reached2.4s/phase1. CPU only.
2. `map-v2-controller-contact-final`: **route failure**, pilot stopped at tick21 (outer final receipt tick23), HP100,0hit. Exit0 means capture finished, not route success. Original evidence preserved.
3. `map-v2-controller-contact-rejoin`: after the verified source connector fix, actual input reached enemy; tick280, hit2, received4, natural death. Three J downs,38 observed held physics ticks, inputs released.45° pitch/50°FOV throughout; body feet equal the actual source support at death. New death clip reaches2.400000s/phase1. This is a new actual observation, not a survival guarantee or deterministic wall-clock replay.

The fixture instantiates the real13,870,144-byte source11 GLB,163 bones,14 clips. Two actual instances share original mesh resources and have distinct Skeleton objects. Imported clip sampling and state mapping are CPU-tested, not rendered-pixel acceptance. Unsupported strafe/backward remains an explicitly reported held pose, not fabricated animation. Hero11 SHA `7ba5abcf7380ad5dd17e208784c6df1974bfb04497aee801a406be005a9b8d18`; timing SHA `026348ec37bc53fb94596ff3ac0d00e85254f316d28eea41ca620a29a7f7d0a0`. Actor/binding from44caea1e, pure input pilot successor d4dc3c60.

## Actual connector bug and correction

At source004 point(-7.597082,-3.206696), route[0]=(-7.5,-2.5) is reachable with actual can_step, distance0.713333m. All next six route nodes are not directly reachable. The former0.9m fallback threshold incorrectly forbade the only legal connector. Fixed by allowing the validated initial connector **only after all forward choices fail**, retaining actual support/body/portal checks. No radius reduction, obstacle removal, teleport or direct-to-target crossing.

`bank_connector_regression.gd` executes both the original422-step cross-map route and this bridge-bank route (110steps to within0.25m). The earlier109-step research trace used a looser1.2m goal threshold; do not confuse the two test contracts. Soft soldiers/corpses can overlap: valid static obstacle/support checks do NOT mean soldiers never intersect.

## Runtime boundary

`authored_field_controller.gd` inherits the real shipping Controller input and fixed-step loop. Base code adds narrow virtual camera-ground/world-sync hooks. The explicit internal subclass uses per-Battle map_runtime, source support ray intersections, source bounds, real unit transforms, real attacks and deaths. No copied simulation or unit HP/position writes.

The complete mother host never calls legacy terrain/material builders. It requires root map/topology/visual/source identity, exactly one author Sun and WorldEnvironment, and exactly one nested-extras gate_main door-leaf root. Camera code preserves author shadow properties. No second light, roughness override, recolouring or old Ground geometry behind the new set. Invalid identities/duplicate lights are rejected by actual Godot fixture tests.

Only the single new WIP hero is replaced; the actual old army renderer is explicitly labelled diagnostic and now queries the new authoritative ground. Detached dead-horse legacy paths are not fabricated on new terrain. New-map siege/campaign/quickload/quick-save/mount UI are out of scope and blocked, not silently routed to the old map. Ordinary combat/orders remain real. New source support may change, so source004 numbers do not transfer to topology2.

## Protected-release compatible entry and identities

`class_name DotProductionV2Entry`, in `scripts/review/production_v2_entry.gd`, is intended as `application/run/main_loop_type` in a temporary export project config restored in finally. Protected Metal release templates ignore `--script`; do not pretend that flag starts this entry.

Require `LUANSHI_PRODUCTION_V2=1`. Arguments after `--`: one existing `res://.../runtime-manifest.json`, optionally `--validate-setup`. Validate mode loads/verifies the real resources, builds source navigation/muster and actual Controller but does not start battle. It must be tested in a PCK from an independent empty working directory before native delivery.

Manifest uses existing MapIdentity fields plus:
- internal_mode=`open_gate_field_no_campaign`
- ordinary_per_side exactly20/100/250/512, seed61112
- actor:{path,sha256,timing_path,timing_sha256}
- resource_identities: export collector output keyed by every resource path, preserving original_source_sha256 separately from packed_resource_path/packed_resource_sha256/identity_method.

Godot may remove source GLB files and load imported remaps from PCK. Entry independently hashes actual packed resources with existing resource_identity.gd and compares export-bound identities; it does not echo source SHA as runtime-observed bytes. Actual dependencies are recursively discovered with ResourceLoader.get_dependencies, including UID fallback paths, and the complete set must equal the declaration before every packed hash is verified. Source11 imports to one scene plus eight external PNG/ctex resources, not a self-contained scene despite embedded GLB images. Preserve the exporter UID table to avoid UID fallback warnings. The exporter must include JSON/timing/licenses and the complete actual texture/shader closure. Final mother/export assets have not been supplied yet, so standalone new PCK validation remains NOT_RUN.

## Evidence / next command

Coordinator recovery storage retains all original JSON/logs and failed attempts. Reproduce the CPU fixture:

```
godot --headless --path . --script tests/map_runtime/controller_skeleton_fixture.gd -- SIDE_CAR_JSON SOURCE_LAYOUT_JSON SOURCE11_GLB SOURCE11_TIMING_JSON OUTPUT_JSON contact
```

Source004 is diagnostic only. Use the checked timeout wrapper; inspect actual route/outcome fields, never process exit alone. Complete old-default tools/test.sh passed after Controller/presentation hooks, including youth restart/attrition saves. Later source-query caching is a separate exact-equivalence test, not an art or FPS result.

The actual source11 PCK closure was additionally exercised in an independent empty working directory: all9 resources PASS with no raw GLB/PNG; a missing ctex is rejected with exit3. This verifies resource identity helpers only, not the still-unavailable complete mother PCK.
