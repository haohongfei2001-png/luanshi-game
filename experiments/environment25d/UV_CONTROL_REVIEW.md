# Pending-review source18 UV control, not an environment restart

LOCAL PREPARATION ONLY. No GitHub write, workflow dispatch, GPU capture, new asset,
new geometry or source18 revision was performed for this candidate.

## Immutable inputs

- Public scene: `1cbdc20aaa63786b1f2fc6181bd7a62c77a84eeb`, tree
  `7a00714dde185b9ca8fbc75ae59fe9da2634118a`. The local baseline commit `50a4479`
  has exactly this tree. The candidate is based on it, NOT on `69527e7`.
- Three unchanged public adapter resources from
  `01fb175a8ee64ed65c67e16f76bf06ea37f2b6b5`:
  `adapter.gd`, `source18.gdshader`, `source18_contract.json` under the existing
  `scripts/field/experimental/production_v2/uv_spatial/` path.
- Original public gzip, GLB `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`,
  timing, image and full license packet unchanged. `uv_control_sources.json`
  freezes 55 input hashes; 51 original baseline files were additionally compared
  against their local Git blobs, not merely their current filesystem bytes.
- Original static environment has only 1672x941 source pixels and is rejected as
  a complete playable/art solution. No full-depth or HF08 inputs are included.

## Exactly one future GPU comparison

`uv_control.gd` subclasses the unchanged public entry. Its `--pose-control`
branch never starts the Battle. All original 19 Units, 11 source18 actors, eight
explicit other-kit capsules, geometry, skeletons, actions, camera and lighting
remain. At tick0 the adapter changes only 18 surface overrides per source18 actor,
198 total, and restores their exact original identities afterward.

One native Metal process saves only `OFF.png`, `ON.png`, `RESTORED_OFF.png` at
2560x1440. There is no combat/traversal replay, 4K pass, video or performance matrix.
Two identical process/draw waits occur at each stage. Manual animations and all
Battle/binding updates remain frozen. Scene/Unit/bone/rest/skin/mesh/base-material/
camera/light/viewport signatures must match at all stages. Matched snapshots use
in-process resource identities, so these signatures are not compared across
different engine processes.

The actual camera is ORTHOGONAL, size22, position determined by the unchanged
public scene, with focus offset `(0,40,40)`: distance56.56854m. Size22 is NOT a
22m camera distance. Only the old HUD's misleading distance label is clarified;
the text is identical in all three new frames.

The process records actual debug/release/editor/template features, renderer,
GPU name/vendor, full camera/projection, requested and observed viewport sizes,
3D scale/mode, TAA, MSAA2D/3D, screen-space AA and FSR sharpness. Quality settings
are not changed to force pixel equality. OFF/restored full raw pixels and image
metrics plus conservative non-actor background tiles must be stable. Instability
is an attribution failure, not evidence of a UV improvement. All three original
frames and failed logs survive. A visible OFF/ON change is required but does not
establish correct visual appearance or artistic acceptance.

## Local checks actually completed

- CPU protocol, exact source18 imports: 11 actors, 198 overrides and 198 restores,
  tick0, three identical signatures, no error in final CPU log.
- All 11 projected skeleton bounds are uncropped, height80.43–82.67px at the
  declared target. This is NOT proof of unoccluded armor; actual GPU originals
  need direct inspection. No unit or camera was moved to improve coverage.
- Runtime opt-in absent: exit21. Frozen pose mode absent: exit22.
- Python validator positive receipt and four altered receipt negatives
  (restoration count, tick, camera scale, signature) behave correctly.
- Python syntax and workflow YAML parse pass. No actual Mac/PCK/GPU claim yet.
- CPU-only dummy renderer uses a clearly synthetic signal to release the old
  draw wait; it does not create images or masquerade as a GPU draw.

## Trigger and budget for parent review

Only a push to **`dot/source18-metal-uv-control-run`** AND a matching code path
from `.github/workflows/dot-source18-uv-control.yml` triggers the new job. Current
local branch is `dot/source18-metal-uv-control-local`; it does not match. There
is no dispatch trigger. One `macos-latest` job, timeout10minutes, no matrix or
automatic rerun. Existing native-experiment concurrency group is shared and
cancel-in-progress is false. Existing engine cache/artifact43580708251 is reused;
binary hash `9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3`
is checked. No build, account, purchase or service is added.

The runner makes a temporary MainLoop/export-filter selection only for this PCK,
restores both source configs in `finally`, and runs the PCK from an empty cwd.
An editor/headless packed CPU check precedes the single Metal process and is
labelled as such. Original source config files are not changed in this commit.
Artifact upload uses `if: always()` for failures too (subject to runner loss or
hard job timeout). An ordinary PR would also trigger existing `verify.yml`, so
do not create a PR for this bounded run. The old full experiment workflow only
matches its old branch and will not run on this new branch.

## Added files only

1. `.github/workflows/dot-source18-uv-control.yml`
2. `experiments/environment25d/uv_control.gd`
3. `experiments/environment25d/uv_control_runner.py`
4. `experiments/environment25d/uv_control_sources.json`
5. `experiments/environment25d/UV_CONTROL_REVIEW.md`
6–8. The three public `uv_spatial` resources listed above.

Untracked local imported cache and read-only hardlinked existing asset bytes are
not a new asset payload and must not be staged. No denied geometry is present in
the change set. Publication and the single future runner remain the parent's
decision after review; whole-scene ART_FAIL is unchanged whatever this test finds.
