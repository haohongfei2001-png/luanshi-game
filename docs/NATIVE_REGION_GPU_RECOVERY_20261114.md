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
