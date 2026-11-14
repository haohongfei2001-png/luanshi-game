# Native region graphics recovery, not an art release

## Why this isolated branch exists

The real `ee5d1389944a4e3a3a13487856066e0631f8ca25` Linux scene capture
ran successfully, but its actual traversal produced only 21 frames over
43.476887 seconds on llvmpipe. Its route result was **NOT_COMPLETED**, reaching
one of two targets. The encoder's `capture_complete` means a recording was
closed, not that the route, actions, frame rate, or art passed.

This branch reuses the already-produced architecture, continuous 112×96 m
ground, and woodland on the repository's existing GitHub-hosted macOS runner.
It avoids re-baking Blender assets and does not access the owner's computer,
start Codex work, buy assets, create accounts, or publish a release.

## Immutable input and recovery

- Existing asset run: `43627776697`, source `ee5d1389944a4e3a3a13487856066e0631f8ca25`.
- Architecture artifact: `14127177778`, self-contained GLB SHA256
  `9590b664efb4316d1374c79f517d4f52e6b1a17d5a04a5eaa220fd4a021f4692`.
- Derivative artifacts: index `14126604039`, payloads `14126978235` and
  `14126364620`. `bounded_artifact_groups.py` verifies every chunk and complete
  file before restoring. Original sources, attribution, and recipes remain
  preserved; no source license is changed.
- Ground SCN SHA256: `8a87880eadd3448bbc4c5fdd5c9a29e9304ba098db83c32f14eb1d34dade1513`.
- Woodland SCN SHA256: `9ba916f6270af9264aa5ca24c5b4da28cb6057be568585464ac3be0b85b5e10f`.
- Import: official Godot 4.6.3 editor, verified original SHA512.
- Actual Mac runtime: existing `35e80b3a8822a9df9be390814b62f44c0a9c69e8`
  engine with the already-used Mobile mutex fix and static ANGLE. The exact
  binary/provenance hashes are checked. This is **not** the later character
  tangent patch, and no engine default is changed.

## Scope and honest gates

The first native run uses the exact old camera/old-character capture as a
**pipeline baseline**, not as the new visual direction. Size 22 is obsolete
as a mandatory artistic gate. New Wild Rift-inspired adult screen occupancy
and perspective candidates are being implemented separately and will be
reviewed with the new scene and characters. No output in this branch is
automatically accepted as a playable or art-qualified release.

The new actual capture preserves native 2560×1440 and 3840×2160/internal 1.0,
the same frozen Battle state within the run, real wall-clock timestamps, and
mapped movement input. Metal and Linux OpenGL are different renderer/engine
conditions; do not label them a strictly identical renderer comparison.

The wrapper accepts only disposable GitHub macOS runners. It verifies the
direct game process before using the repository's existing Cocoa focus
helper. It does not inject global keys or use Accessibility. A 240-second
timeout and all script/shader errors fail the actual capture. Video encoding
preserves real intervals without interpolating missing frames or speeding up
the game. A separate route validator rejects missing, duplicate, or incomplete
results. Even a completed route does not pass attack, hit, shield, riding,
thousand-soldier performance, or art acceptance.

Initial local validation: nine integrity/gate tests pass; exact three runtime
assets restore with matching hashes; 176-file static dependency closure has no
missing files. A fresh official 4.6.3 Linux import passed in 34.15 s, entry
parse in 0.35 s, and genuine full-scene headless setup in 9.51 s at tick 135,
20 ordinary soldiers per side. These are not graphical performance results.
Actual hosted Mac execution is **NOT_RUN** at this commit. Results must
be appended only after inspecting its exact run and returned evidence.

All actual art remains **ART_NOT_ACCEPTED**. M5 is **DEVICE_NOT_RUN**. RC24 and
RC25 remain untouched. No failed screenshots are sent as qualified work.
Owner's latest accepted whole-scene direction and matte/rustic correction are
preserved in draft PR #67; that PR remains draft following an explicit merge
denial and must not be merged, marked ready, or bypassed by this branch.

## Next recovery command

Push only the isolated `dot/native-region-review` branch after local checks;
its dedicated workflow runs without creating a release or changing main.
Read the final `native-region-evidence-<SHA>` process/host/route receipts and
movie groups. If native execution works, reuse it for the new camera and
rebuilt region rather than repeating the rejected old framing.

## First hosted attempt: exact diagnosed failure, not graphics success

Run `43630015984`, source `a87108e616b7752b8bb33bc8d2f19d1feb267c41`,
completed asset restoration, Mac editor import, entry parse, and actual scene
headless setup. The already-built production template then explicitly refused
`--path` because it was compiled without path overrides. No graphical scene,
movement, or performance evidence was produced. Failure artifact `14128116627`
preserves the exact error and Apple M1 Virtual, three-core, 7 GB host report.

The repair exports a normal adjacent `.pck` using the official editor and leaves
the runtime protection unchanged. Only this internal QA export temporarily
includes the test/tool resource paths; its original export settings are restored
byte-for-byte. Public scripts remain text in this QA pack so the evidence can
hash the original source instead of missing it behind a compiled remap. The
actual template reads its adjacent resource pack normally,
without `--path` or `--main-pack`. Pack and engine hashes are independently
verified before launch. This remains an internal test, not a shipping package.

Local repair validation: 11 integrity/gate tests pass. The normal QA PCK
export and a full-scene headless startup from that pack were exercised with the
official editor; the hosted protected template remains pending a fresh run.
This does not claim that a Linux editor is the actual Mac runtime.

## Next isolated camera integration (no default change)

The actual experimental camera subset from
`9c214ca46836dbd8f22eb75e25f12fdeecda98d4` is integrated without its separate
Linux workflow. Empty review profiles restore the existing default projection
and transform. The experiment uses the real frustum/height-slab culling helper;
it does not stop offscreen Battle simulation or move the camera to the culling
rectangle center. Three bounded native frames use 32-degree pitch, FOV 55,
yaw -65/-75, and a nominal 10% adult box at the look target, four meters ahead
of the hero. These are project candidates, not Riot's official camera values.

Local checks passed the six camera configurations, restoration to the default,
unchanged Battle state, and three full-scene matched candidate setups. An
independent frame integrity validator was also run on the actual Linux
`43630015256` three-frame evidence. It verifies native pixels, source SHA,
Battle snapshot file/hash, camera metadata and decodable PNGs. Missing or
duplicate frames, wrong source/snapshot, reduced render scale, altered army,
seed or camera profile are rejected. None of these gates is an art judgment.

The camera-only mode intentionally does **not** claim a traversal, action
recording, performance benchmark, new character, or accepted whole scene.

## Second hosted attempt: native startup stall retained

Run `43630764803`, source `3fd677b91f4c20aef2131724d97fb9fa4aa73df8`,
successfully restored assets, imported the Mac project, validated setup, and
exported its normal 515,281,744-byte QA pack. The protected native template
reported Metal 4.0, Forward Mobile, Apple Paravirtual device (Apple5), but did
not reach the scripted entry or produce a frame before the 240-second bound.
No route or action ran. Artifact `14127737835` preserves this exact timeout;
it is not a successful GPU benchmark or proof that the art works on Mac.

The next bounded run adds early read-only process samples of the verified
direct game child, before and after a single early activation diagnostic via
the existing Cocoa helper. It does not extend the timeout, weaken errors,
change OS security, or assume that focusing will resolve the stall. The
camera-only attempt is bounded to 120 seconds. If it still stalls, use the
captured stack evidence instead of repeatedly raising timeouts.

The integrated camera branch also completed the full default-OFF `tools/test.sh`
regression with exit 0 and no script/shader/error markers, including existing
battle, officers, 20/100/250/512 scale, save/history, economy, youth career,
world migration, restart and attrition cases. This is functional preservation,
not a native graphics or art pass.

## Third hosted attempt: wrong entry conclusively diagnosed

Run `43631942777`, source `c035adb0713bbbf9390642ac9c058bee079474a3`,
failed at the 120-second camera bound and produced **no native images**.
Artifact `14128123661`, ZIP SHA-256
`dabaf4926f96de4087b3e0219470a82cc9eee1bafda8d973d320914cf1c43b50`,
retains the 12/45-second own-process samples and a successful early Cocoa
activation (`game_active=1`). The first sample is initial Metal shader
compilation; the second is normal scene `_ready` and material/mesh compilation.
They do not establish a focus or OS deadlock.

The exact upstream engine [main.cpp at 35e80b3](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/main/main.cpp#L4223-L4234)
clears the command-line `script`, `game_path`, and `main_loop_type` when
`OVERRIDE_PATH_ENABLED` is absent. Thus the protected template silently ignored
our `--script` and started the ordinary configured game scene. Earlier
headless checks used an editor, so they did not expose this template difference.
The evidence is preserved rather than called a successful graphics run.

The next correction keeps the exact protected binary. The internal QA export
uses normal `application/run/main_loop_type=DotNativeRegionCapture` settings
and a tiny inert bootstrap scene. A scene is required by Godot's initial
project validation even with a custom MainLoop. The original project and export
configuration are restored byte-for-byte in `finally`; shipped defaults are
not altered. The native command no longer requests `--script` or any path
override. Local normal-project entry and packed entry must both reach the
explicit `NATIVE_REGION_FOCUS` plus real 20v20/tick135 setup markers without
`--script`; they are still not an actual Mac graphic or art result.

Release-template GDScript assertions must not be the final acceptance gate.
External Python validates source, exact image dimensions and internal scale,
mode/camera/seed/count, snapshot file bytes, PNG decoding, and complete output.
All runtime logs are independently scanned for script/shader/errors.

Local entry correction verified: 14 integrity/entry/gate tests pass. Normal
project launch (no `--script`) completed real headless scene setup in 8.40 s.
The exported 507,503,596-byte QA pack (SHA-256
`5542531860aa5ac49b339e9f2dd35419cca29f6881bb677e1347c71943976200`)
also reached the custom entry and 20v20/tick135 setup in 8.68 s, without a
script override. Both original configuration files match their pre-export
bytes. These editor-based Linux checks do not certify Mac Metal startup.

## Release assertion side effects corrected before judging any image

The same exact upstream GDScript compiler removes the **entire expression**
of an assertion when `DEBUG_ENABLED` is absent. This revealed three real
editor/template differences in the review helpers: PNG `save_png`, regex
`compile`, and traversal recorder `start` were called inside assertions.
They now execute outside assertions with explicit failure exits/errors, with
a source regression test. This is not a relaxation: missing images, incorrect
shader time and absent recording remain failures. The earlier c4756d5 run
is preserved as an entry diagnostic only and cannot qualify art or output.
Source: https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/modules/gdscript/gdscript_compiler.cpp

## Exported runtime closure repaired, with a real negative control

Run `43632900392` / source `c4756d5` failed after 15.57 s with
`Could not resolve class res://tests/authored_architecture_capture.gd`.
Artifact `14128992323` preserves the original error, not a graphics pass.
The exact export log contained the capture but none of its five `tools/art`
runtime helpers: `tools/art/.gdignore` excluded them. Earlier local pack checks
were flawed because running from the checkout let missing resources resolve
from disk. This is explicitly corrected, not concealed as an engine fault.

The five pure runtime helpers now live canonically in `scripts/review`.
Their old authoring paths are thin compatibility subclasses, so authoring
commands retain their entry points without duplicate implementations. No
simulation, asset shape or default gameplay is changed. The real capture
references the exported canonical paths. Shader-clock and matched-state
requirements now execute explicitly in release, not debug-only assertions.

A genuine negative control runs the old exact 507,503,596-byte pack from an
empty temporary cwd: it reproduces the missing-base-class error. With the
runtime helpers included, a new 507,516,164-byte pack (SHA-256
`645d831445ea1c17fc1303d6f63bb6aaab2181a56f78baae0767dd0481ad4c82`)
passes the same isolated 20v20/tick135 headless startup in 7.34 s. The initial
negative-control command had an unrelated user-log-directory error; only its
repeat with the normal scoped XDG paths is used as the dependency evidence.

The exporter now requires this empty-cwd pack startup on every hosted build,
records it in the pack receipt, and refuses native launch without it. This
proves resource closure with the official editor, not native graphics or art.
The Mac template execution remains a separate required gate.

## First protected-template entry reached; window timing remains separate

Run `43633827443`, source `46dbf614`, passed fresh Mac import and the isolated
pack setup. The protected template then reached `NATIVE_REGION_FOCUS` with
actual Mobile/Metal, Apple M1 Virtual and the exact 35e80 engine: the exported
entry and missing-resource failures are resolved. It still produced no image.
The external Cocoa helper requested activation during `_initialize`, sampled
`game_active=0` after only 0.4 s, and our guard ended the run after 23.56 s.
An earlier startup diagnostic had observed `game_active=1`; these are different
times, not evidence of a permanent OS refusal. Artifact `14129915124` retains
the original failure and logs (ZIP SHA-256
`4479e10a32aa0755e5aeab9494b150d0aa94329000b0f0a9fd3a20acfaa45384`).

The next run requests focus through the game's own root Window only after
three real process frames, waits at most three seconds for its actual
`has_focus()` state, and emits a PID-bound native-window-ready receipt. The
external runner still fails if that event is absent, unfocused, from another
PID, or not macOS. No global keyboard, Accessibility, OS security change or
owner-computer access is used. Headless setup explicitly skips this graphical
window step and cannot qualify it. This replaces a premature observer, not
a requirement for actual native rendering.

The canonical-runtime migration also passed the five existing authoring
compatibility tests (surface seams, winding, water clipping, support and
shader-time override/restore). Native images, action and M5 remain unverified.

## Verified native Metal frame integrity result (not art acceptance)

Source `c983db2dcc7c633116fa4eeae5e0784ebc052f1c`,
[run 43634640376](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43634640376),
completed successfully on the existing Apple M1 Virtual / Apple Paravirtual
Metal device, not an owner computer or M5. The normal protected template,
source-closed PCK and game's own native window all worked.

Artifact `14129183206`, 16,783,092-byte ZIP SHA-256
`c64318763aed53bc8a0a496244887457cfa720babe56116856d7b8769e46a8c2`,
was downloaded and independently revalidated: two 2560x1440 views and one
3840x2160 view, internal scale 1.0, seed61112/tick135/20 per side, unchanged
snapshot within all three frames. All returned import/export/setup/runtime
logs were scanned independently with no SCRIPT ERROR, SHADER ERROR or ERROR.

| View | PNG SHA-256 |
|---|---|
| QHD road65 | d286797d513341f269216cc79666a9827ab0ce1de6f082e6eb685e88e320bb21 |
| QHD road75 | d5b34bf8b5012b66b0c9987ad84ead31bcaecd345068a84eae3051bef08ddbcb |
| UHD road65 | 43b573492aa6f4b5608c870150829cc2d4b321ebb4426f9c439a02ecf74607b1 |

The new source-closed pack is 515,309,564 bytes, SHA-256
`74ad8fb19822b5c705afb737def3943dc1871c68ebc193fa2a8689b86d59ceee`.
Runtime took 106.27 seconds including startup, shader compilation and PNG
readback; that number is **not a frame-rate benchmark**. macOS `time -l`
reported maximum RSS 695,009,280 bytes and peak memory footprint 2,171,768,576
bytes; neither is a physical GPU-VRAM measurement.

These pixels still use the frozen **ee5d138 scene assets**, with the new camera
study, not the later 677 basin or 03 road/gate/character work. The Linux and
Mac snapshots differ, so only each run's internal view pairs are asserted
identical; this is not a cross-backend identical-state comparison.
**Art NOT_ACCEPTED; action/traversal NOT_RUN; performance NOT_MEASURED;
MacBook Air M5 DEVICE_NOT_RUN.** No failed image was delivered as qualified art.

Next: reuse the verified capture mechanism for the complete 03 road, new
structurally closed stone/timber gateway and latest single full-character
oracle. Preserve their precise source/artifact hashes, full-army behavior and
strict frame gates. Do not rebake unchanged professional mothers. The separate
minimal Metal character parity oracle uses the same pinned engine.

## Follow-up evidence guards before complete-scene integration

The live frame recorder previously initialized its observed-hit count to zero
when first attaching to a Battle. A restored or fast-forwarded fixture with
historical hits therefore fabricated a fresh-contact interval before observing
any new attack. It now baselines the existing count, waits for the next real
increase, and resets contact recency on a different Battle. A headless test
first reproduced four explicit failures in the original code, then passed the
fix. The full default regression suite also passed. No battle mechanics or
historical performance reports were rewritten; no new FPS result is claimed.

The upcoming `gate-context-study` is explicitly static: full road03, closed
stone/timber gate and one 43-mesh authoring actor. It must preserve the actual
head-to-boot normalized screen height across the 32/38-degree camera candidates,
with real native viewport metadata, the same Battle, runtime and actor source
hashes, and no artificial ground lift. Seven frame-validator tests include
wrong viewport, source drift, fabricated action acceptance and a consistently
reported but shrunken actor. The 17 input/mode tests also pass. The exported
empty-working-directory closure check must load the actual single actor, not
only the old default crowd. A bounded 240 seconds covers cold setup plus three
readbacks; it is not a performance relaxation. New-scene graphics remain
**NOT_RUN** until the exact reusable asset bundle is loaded and captured.

## Complete road03 / stone-timber / single-actor native integration

The next native run consumes already built runtime files from successful
[run 43637786209](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43637786209),
source `4bbc88b38aea59a5a1e2c4cbc5b93fa21dcf62bd`.
Exactly five `complete-region-runtime-*` groups are used, not the separate
editable-source artifacts. The four files are pinned in
`tools/native_region/restore_complete.py`; the terrain profile must also match
the actual game source. The CI-produced gateway bytes differ from the local
build and are recorded as such, rather than relabelled as an identical build.

The 43-mesh single-unit author oracle uses the six cache parts plus manifest
from run43635849360/source945b2c676705460f97ba0d9e5c9d892f2a64390d.
All six part hashes, the full archive hash, and all 91 extracted member hashes
were independently revalidated through the new restoration function. The
external raw cache remains excluded from imported `res://` resources, with
attribution retained. It replaces one real unit's visualization only at a
fixed author walk phase; no Battle values, fixed identity, crowd architecture,
full animation mapping, foot/grip acceptance or performance result is implied.

The exact merged capture source parses in Godot4.6.3, the release-side-effect
and traversal guards pass, and native input/restoration/still unit tests pass.
The source-closed exported pack and actual new-scene native frames are still
**NOT_RUN** at this checkpoint. They are the next CI steps, with ordinary
capture failures preserved, not converted into art acceptance.

### First complete-scene attempt stopped by obsolete-mode dependency

Run43638485073/source8b29d7cd verified all four runtime files and all91 actor
members on the actual hosted Mac. It stopped **before editor, export or GPU
execution**, because the static source scanner took the union of every capture
mode and still required `assets/river_authored/shore/region.scn`. Road03 had
explicitly retired those two isolated rock strips; its runtime code never
loads them under `--road-section-study`. No image was produced.

The scanner now selects the explicit `road-section` dependency mode and the
actual native workflow. Only that retired resource is non-required for this
mode; older basin checks still require it, and missing active grass still
fails. Python3 workflow entry references are now scanned too. Five focused
negative/positive tests pass. This corrects a false source dependency, not an
art gate or a missing resource hidden from real execution. The empty-cwd pack
and actual native setup checks remain mandatory and unchanged.


## Complete region actually rendered: e3d8d245, evidence gate failed afterward

Run **43638813145**, source **e3d8d24568b936e09c58602345297262472f47d8**,
artifact **14131402326** produced all three requested native PNGs and the
actual Metal process exited **0**. The overall CI is **FAILED**, specifically
in the post-capture metadata validator. Do not rename this run a CI pass.
Six returned import/setup/export/game logs contain no `SCRIPT ERROR`,
`SHADER ERROR` or leading `ERROR:`. Exact PNG SHA256, sizes, original logical
projection values, logs and scope are in `evidence/native-region-e3d8d245/file-integrity.json`.

- 4bbc88b complete scene runtime and 945b2c6 external single-author actor were
  restored from their verified CI artifacts. Original 91-member actor cache
  remained unchanged. This is one static real-unit visual replacement, not
  mapped battle actions or army-ready character rendering.
- The PCK is 670,056,296 bytes, SHA256
  `46c128c080e2905c6b7cb53b619294cabfc7dba9a01eed41b00613bc8429181b`.
- Apple M1 Virtual / Apple Paravirtual Apple5 / native Metal Mobile. Max RSS
  992,346,112 bytes; peak footprint 3,077,706,176 bytes. The 153.83-second
  startup/readback process is **not FPS or sustained performance**. M5 not run.

Two evidence-code errors are corrected prospectively, without editing the
old receipt or lowering asset/pixel gates:

1. Godot exports a GLB as an imported PackedScene. The original raw GLB may
   be absent from the PCK, so hashing its source path returns empty even when
   its actual imported resource loaded correctly. The new exporter separately
   records verified original-source SHA256 and imported-resource path/SHA256.
   An **empty-working-directory exported process** must observe those exact
   packed bytes; native screenshots must repeat the identical resource index.
   No expected hash is passed off as an observed runtime hash.
2. `Camera3D.unproject_position` uses the canvas-stretched **logical viewport**,
   here 1422×800, not the actual 2560×1440 or 3840×2160 attachment. New receipts
   label logical units explicitly and separately record the derived native
   attachment projection. The earlier 99.09 logical-unit height corresponds
   to approximately 178.36 native 2K pixels or 267.54 native 4K pixels, about
   12.3863% of image height. These are geometry projections, not manual visible
   silhouette measurements. PNG/output/internal resolution remains native 1.0.

Local validation: 12 still-gate tests, 17 input/mode tests and six imported-
resource identity tests pass. A tiny real PCK with omitted raw GLB loaded its
imported PackedScene from an empty cwd and returned the exact imported byte
hash. The complete scene headless setup/identity observation also passed in
10.14 s against the explicitly labeled **local derivation**, not the CI asset
hashes. Initial local attempts exposed missing borrowed grass and unset XDG
write directories; those failed attempts are retained locally, not called
passes. The actual hosted correction remains pending at this source.

### Actual art review, not integrity acceptance

Coordinator personally viewed the new context65 native 2K; an independent
reviewer viewed all three originals and the owner-approved whole-scene target.
Both conclude **ART_FAIL**. Stonework, natural source tree trunks and the new
actor's clothing/armor structure are visibly present and worth retaining.
However the wood gatehouse is still cut out of frame, broad uniform dirt and
regular moat lips dominate, water is a flat gray-green mass, vegetation is
isolated rather than a coherent bank/forest edge, and legacy soldiers/horse/
ram differ sharply in completion. This is not fixed by sharpening, exposure,
more scattered grass or declaring the reference optional.

The 38° context candidate is rejected: it pushes the hero lower and removes
more destination architecture. Preserve adult scale and solve the actual hero
and gatehouse projections together, then rebuild the complete bridgehead →
bank/road shoulder → gate entrance spatial structure. New whole-garment and
full-source character runtime work continues independently. No default visual
promotion, qualified package, owner art pass, M5 pass or PR #67 merge occurs.
