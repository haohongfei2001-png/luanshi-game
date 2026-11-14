# Fallen equipment and cloth contact

## Adopted scope

Production source is e10b336005497a26de914ac0f0ddc5630bb758d3. Evidence source f1c93719503968f90d8475b68f70e152d806a4c2 contains the same runtime blobs.

- `assets/river_gate/figures/company_motion.png`, blob b76d90a539ad923391cbcb1c2835b82ca3036e40
- `scripts/field/company_skin.gdshader`, blob e292ea185bf65280b122711332f2bb6d0e0e448e
- `tools/art/company_motion.py`, blob 2f00e77e66e52535dbb06722be1c1841ccb70e00

The fallen palm used an eighty-degree pitch while each held blade or shaft runs along local +Z. It consequently pointed almost vertically above the body. The nine final fall poses now rest their actual weapon planes near the ground, with wrists and forearms still joined.

After skinning, the back hem of the complete clothing master previously reached 0.1953 m below the ground. A continuous rational contact curve now settles deformed cloth above it. The lowest imported body point is the existing boot edge at -0.00308 m. Bones, feet and hands keep their authored transforms.

No new external assets or license changes are involved.

## Reproduction and measurements

Ubuntu 24.04 hosted GitHub runner, Godot 4.6.3, X11/Xvfb, Mesa software OpenGL. Runtime image is 2560 by 1600 at internal scale 1.0.

Bake run 43576068018 passed. `palette-check.json` confirms 408 original live strips are byte-identical. Only the nine clip14 strips differ. Dimensions remain 528 by 1668 and there are no added runtime texture samples.

`tests/field_rest_equipment.gd` checked all nine equipment meshes and ordinary, officer and player body meshes. `rest-mesh-bounds.json` contains the full bounds and source vertices.

Movie run 43576987264 passed. Its original-speed baseline was reused from the identical baseline recording in run 43575555706, artifact 14106546372. Final clean artifact 14107570794 contains raw frames, logs, two MP4 files and receipts.

`movie/before-normal.mp4` and `movie/after-normal.mp4` each contain 32 consecutive actual game steps at 20 frames per second. The same ordinary sword actor #80 is alive at tick44, dies through actual combat at tick48, finishes the existing 0.70-second fall at tick62 and stays down through tick75. Camera is fixed at the bridge view, size22, yaw-33 degrees. Counts remain 512 ordinary troops per side. Recorded physics sequences are equal.

These files reconstruct the original simulation speed. They are not realtime performance measurements. The screenshot projection diagnostic stored as `floor_pixel` is uncalibrated and must not be used as a pixel annotation. Actor ID, world coordinates, camera and simulation ticks identify the subject.

## Visual review

Inspected the complete before/after normal windows at tick75, close side windows, reverse windows and the six-frame fall sequence. Upright corpse weapons visibly disappear from the settled front. Cloth retains a rounded contact silhouette. Reverse subject visibility is partly obstructed by the unchanged tree.

The evidence contains a natural mounted ordinary dao attack at tick112. This roster has zero mounted officers, so it does not verify mounted-officer gameplay. All live strips remain byte-identical, including existing mounted attacks.

The limited corpse defect repair is retained. Whole character and environment art remain ART_REBUILD_REQUIRED. No actual M5 measurement was made.

## Separate rejected research and next work

The former horizontal-cut research and full-horse experiment are excluded. The former constrained the source wrist to an old procedural world-space grip and lost the full body force chain. Its T-pose upper-arm and forearm axes also differ from the game bind by 82.90 and 86.15 degrees.

The next independent work continues on `codex/river-rc23-native-chain`. Its verified CC0 Quaternius source bind and original joint curves are saved at fef42da590b314eab882d3b7597a281b07993669. Retarget the complete pelvis, legs, shoulder and wrist chain, preserve relative weapon-hand geometry and simulation hit timing, then compare actual original-speed gameplay. The source itself contains a recovery foot drag and needs explicit support-foot review. No attack candidate is accepted by this report.
