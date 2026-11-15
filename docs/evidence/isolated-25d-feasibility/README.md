# Isolated 2.5D environment feasibility: recovery and current evidence

**Final: STRICT FEASIBILITY FAIL, do not promote this prototype.** Actual Metal movement/combat and pan run, but real gate-roof/lintel occlusion is visibly wrong. Complete final result appended below; main remains untouched.

## Scope, not a new accepted mother scene

Default OFF experimental project on branch `dot/25d-environment-feasibility`. Main, PR67, production environment/native/actor files untouched. Actual unchanged Battle/Unit and authored navigation, 19 real units: 11 source18 spear actors, 8 explicitly labelled other-kit capsule diagnostics. No static people baked into the environment. No 512-per-side test or M5 test. Not original Controller input acceptance. User authorized 3D/2.5D/mixed experiments; this is not an approved art direction or shipping camera replacement.

Source background is owner-authorized AI derivative from the approved composition, built-in image generation, 1672×941 actual source pixels. Native GPU 2K/4K output does not make its material native 2K/4K. At the 22m camera candidate over a 36m projection plate, only about 1022×575 source pixels span the view. Fixed orthographic orientation, finite pan, manually constructed depth masks. Rotation and dynamic environment light explicitly unsupported in this isolated mode, not silently removed from main.

## Reconstructible source

Local project `experiments/environment25d`.

- Runtime plate SHA256 `9471178db61606963fd5a1d4f8acb17ad08b0acd9637bf802e28426493355da5`.
- Source18 GLB 14,173,132 bytes, SHA256 `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`.
- Exact-restoration gzip 10,442,257 bytes, SHA256 `caf49a68890e78644448489a8df7e2bafe2d2dc1617f6270fa886248e65737d7`, Git blob `583d99e1ad15cbee89fa1d6189ca334c419a5382`. Full 13-member license packet retained and hash verified, including original UAL CRLF License. Boots CC BY4 and coat CC BY3 are not called CC0.
- `restore_assets.py` verifies compressed/expanded bytes and all license hashes. `SOURCE.json` hashes the 21 unchanged runtime dependencies.
- Full source/resource export via official editor; protected Metal release uses registered MainLoop plus inert bootstrap and adjacent PCK, not ignored CLI `--script`. Empty-cwd import and actual 11-actor instantiation tested. Raw source hashes are empty in exported runtime reports because the exporter remaps/omits originals; do not misread this as newly verified raw bytes. Their exact bytes are verified before import, and real resource closure is loaded in the packed setup.

## Completed runs, with failures retained

1. `43688703476`, source `d161f76…`: requested 2560×1440 but actual native window capture 1024×645. Strict pixel gate failed. 75 actual frames exist, real hits [14,15] / losses [3,1], tick111. Process real wall51.15s versus old summed engine delta10.016s. This is NOT an original-speed recording. Complete archive `first-gpu-failure.zip`, SHA256 `991ed482fe62f4f055a80cec8cd08c359e959194219b8e637fe77605ab8ed0d0`.
2. `43689230305`, source `16b1430166ab9d099452f7247ff0d3aa38990fbd`: actual direct GPU target 2560×1440 and 3840×2160 verified, window still1024-wide. Pixel gate passes. 2K combat recording window25.23wall seconds advances only1.20simulation seconds/24ticks; 0hits/0deaths, 1/6 route points. Other runs similarly incomplete. This measures throughput WITH synchronous PNG readback/encoding, not uncaptured FPS or final renderer performance. Full archive `second-gpu-original-engine-control.zip`, SHA256 `d4cae61d471ff9d93b5714b4f8f0489e42dedcebf61c84f7c04ff13713771868`; summary in extracted directory `SUMMARY.json`.
3. `43689982904`, source `54b67f02d96d4210874aaeeefd02f6609f963b98`: pinned Metal template correctly restored and started. But my experiment's initialization calls were incorrectly inside `assert`; release removes those expressions, producing NaN foot/camera, purple tick0 image, and combat SIGSEGV(-11). This is an experiment-entry bug, not an engine/art/source18 finding. Invalid purple frame and raw logs preserved in `metal-attempt1.zip`, SHA256 `ad13eb7d756156b4b6ece896e269308ced546702aac8c50cf808a0ce40d7f73b`. No valid Metal comparison yet.
4. Repair `1ce0ecc030db0b5ec5467fd34e1f6e3c396abc6a`, tree `bf4aa221b08a049b379aeb41144cc9bd8a2c28cc` exactly equals local tree: initialization now explicit checked calls, no side effects in assert; runtime setup/finite-foot gates; 12s zero-readback window; JPEG wall-time recording + few original PNGs. Linux non-editor template_debug packed/headless setup now11actors, Battle140ticks35hits5deaths,6/6 route, invalid[]. That is packed CPU correctness only, NOT a release-elision test. The initial report called this local binary release; a later actual OS.is_debug_build() probe proved true and assert side effects still execute (template_debug). This correction preserves the original result but retracts that label. Evidence: template-kind-probe.json. True Mac release setup still pending at this section.

## Engine correction, not source18 blame

Original official4.6.3 GLES/ANGLE has previously demonstrated native Skin tangent attribute/UNORM decoder error. Exact project evidence `67ff0cd` records same-source Linux original4/4poseFAIL vs patched4/4PASS and patched12/12blendPASS. Thus silver-grid rendering in our official GLES images cannot be attributed to source18 alone.

The reusable Mac template is a different validated route: source35e80b3…, Mobile Metal mutex fix, binary SHA256 `9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3`, restored from existing run43580708251/artifact14108148499. It is not the GLES tangent-patched Linux binary. The new comparison changes engine+renderer; assets, material/normal maps, lights, camera/topology, roster and Battle stay constant. Same tick0 images planned. Separate confirmed source18 importer UV-contract issues are retained independently; no material/source18 edits in this experiment.

## Current visual/functional verdict

I personally inspected actual 2K original-engine midframe. Coherent nearshore→bridge→gate spatial composition is visibly much closer to the owner target than an empty platform, but it is projected environment material, not a finished 3D mother scene. Visible actor clothing/materials, other-kit capsules, prelit-vs-dynamic integration remain ART_FAIL/WIP. 2K footpoints touch visible vegetation/rock patches in the broad support region, and roof/complete wall occlusion is not established by arithmetic projection alone. All route/occlusion/pan proof still requires actual traversing GPU frames, not headless reachability or source provenance. Do not promote this as the production route on current evidence.


## Final verified Metal run, 2026-11-15

Run `43690415954`, job `132739689130`, source `1ce0ecc030db0b5ec5467fd34e1f6e3c396abc6a`, artifact `14151854509`, completed SUCCESS. Full original ZIP retained as `metal-corrected-gpu.zip`, 243,194,590 bytes, SHA256 `c5001a773e7c4aa45b04378b792ed252ccbaef6c5a9050aab246571da1148cfe`, independently checked after download. Relevant originals/JSON/logs and original-time videos in `metal-corrected-gpu/`; exact per-file hashes and result summaries in `FINAL-VERDICT.json`.

- Same-tick0 GLES and Metal control images now both contain the actual scene, actor states, camera and roster. No asset/material/normal/light changes. This is an engine+renderer comparison, not isolated GLES patch efficacy.
- Real 2560×1440 Metal combat: 11 actual spear actors and 8 explicitly diagnostic non-spear capsules, actual Battle111ticks, 29hits, losses[3,1], hero HP0. It has real attack/death, not a static crowd. Controller input acceptance and all-action source18 art pass are not implied.
- Actual traversal: source-foot moves from [855.7,516.5] over bridge and through the gate toward [1337.6,233.3], camera translates with it and then clamps to finite source bounds. 5/6 waypoints reached, hero killed in court before sixth, finaltick124/5enemyhits. No invulnerability/teleport/unit HP edits. Declared support validity remains true, but that alone does not prove visual contact.
- Direct 4K targets are 3840×2160, stills only; source remains1672×941. Synchronous PNG4K save/readback alone takes roughly4–6s per captured frame, so these are not motion/performance evidence.
- Separate 12.01154s zero-readback window: 638 `_process` callbacks, 53.12processHz, median interval16.704ms, p95 20.892ms. This is a short 19-unit hosted-Mac process-rate observation, not certified presented-frame FPS, M5 result, or thousand-person performance. Battle ends at tick111 due to hero death and tick freezes afterward, so 5.55simulation/12.01wall is NOT a slowdown ratio.
- Hosted Mac did not have ffmpeg, so all original JPEGs remain in the artifact. Locally encoded `2560-combat/actual-walltime.mp4` (2560×1440,10.20s) and `2560-traversal/actual-walltime.mp4` (10.04s) use exact frame intervals via VFR. Original capture startup/readback stalls remain in the videos; no fixed-nominal-FPS respeeding, interpolation or frame-generation. `encoding-receipt.json` retains ffprobe and first/last monotonic times. Videos start at the first captured frame (~1s after battle-start clock), not a claimed zero-time recording.
- The actual Mac binary is the hash-pinned template from prior provenance, but this run did not directly print `OS.is_debug_build()` / feature flags. That measurement is NOT claimed. The local Linux template debug-label correction above remains in force. Direct build feature flags remain an unmeasured field in this run.

### Strict visual rejection, personally checked actual frames

`2560-traversal/still-00048.png` and `frame-00040.jpg`/`frame-00053.jpg` plainly show court troops rendered over the roof and bodies clipped by incomplete lintel polygons. This is the experiment's missing/incorrect environment depth, not an actor-weight or skinning conclusion. Near bridge rail contact also does not earn a blanket pass from the support query. Thus required complete front/back occlusion and trustworthy playable surface depiction FAIL. The actual moving camera is real and does not turn this into a complete spatial solution.

The original single-plane-plus-fragment-mask route is rejected as a production mother-scene replacement. This does not establish that all 2.5D is impossible. To reconsider a limited fixed-camera hybrid would require fully authored depth/collision volumes for the entire playable gate/roof/shore space, plus suitable source resolution and a new complete traversal review. Do not spend more time merely enlarging this plate or hiding roof failures with composition. Native geometry-first mother-scene development remains separate and should not be replaced by the attractive starting still.

No new CI or source18 changes are included for this experiment. Keep this branch/artifact as a failed-but-informative internal candidate, default OFF; no merge to main/PR67.

## Stable evidence and exact recovery

`media/roof-occlusion-failure.jpg` is an unchanged original 2560×1440 JPEG from final traversal frame53. It visibly falsifies complete depth/occlusion. The two `media/*walltime.mp4` files are the same VFR encodes described above, with original start delays and no motion fabrication. Their corresponding original frames and time logs remain indexed in `archive-manifest.json`.

Restore the four archive names from their listed existing Actions artifact pages (or verified saved originals), then run `python recover.py ARCHIVE_DIRECTORY OUTPUT_DIRECTORY`. The tool verifies every member before selecting frames and encoding the same original-time sequences. It does not run Godot, upload assets, start CI, generate new images, or change any game source. Artifacts have finite retention; the committed JSON/logs, selected original failure frame, and two videos do not depend on that retention. No claim is made that every original full-resolution PNG is permanently hosted in this Git tree.
