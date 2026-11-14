# Native evidence reliability follow-up (not a new visual acceptance)

Source of existing measurements: `caec14c18bb063210eae0a7098fe6870a5763870`, run 43612407649. Art remains ART_REBUILD_REQUIRED, real MacBook Air M5 DEVICE_NOT_RUN.

## Original evidence preserved

QHD raw sample 60 has CPU HP 63.5577 while its pictured HUD still shows 100/100. Adjacent original-speed movie frames 61 and 70 show 64/100 and 10/100. The HUD is dynamic; sample 60 is not proof of a visibly rendered hit. The 0.13 second HUD update cadence plus rendering timing is consistent with this transient mismatch. No image, JSON, or receipt was rewritten.

Each future sample now records the actual HUD widget text, health value, refresh tick/time, and sample tick/time. This describes CPU widget state at post-draw capture, not OCR proof of the rendered text. Health refresh behavior and combat stats remain unchanged.

## Independent failures

Scope limitation: initial renderer/window probe and input smoke remain fail-fast prerequisites; this follow-up does not claim every delivery step is independent. Each scale/resolution profile after those prerequisites is attempted separately. Partial frame journals are copied in finally before temporary game data cleanup. Failed or absent profiles remain FAILED/MISSING without invented FPS. Independent successful profiles survive. Summary errors do not block wall-clock evidence. Final movie errors and fallback preservation errors enter the overall failure receipt, so partial evidence never turns the run green.

Synthetic regressions inject an initial game crash and verify its journal survives and the following profile still runs; summary tests combine measured/failed/missing entries. These tests are not performance measurements.

## Camera contract

Normal-input withdrawal target moved from (14,-1) to (18.5,-1), inside the bridge camera dead zone. The original encoder tolerance remains unchanged. Local headless full-battle and 900 tick profile calibration measured maximum center deviation 0.247416m against the existing 0.35m limit, with two protagonist impacts and HP100. Full battle ended defending victory at tick2300. This is calibration, not new Mac footage or a visual pass.

Fixed-seed scale and before/after comparisons must retain matched camera conditions. Follow-camera mounted action footage remains a separate purpose, never silently relabeled fixed-camera comparison.

## Existing package single-download reassembly

Workflow commit 59539b37fe7c66af6fd169066fa3a1258d4a0b39 only reassembles existing package artifacts. Run 43617369748 succeeded without rebuilding or running the game. Artifact14121709569 expires 2026-12-14T16:46:25Z.
Original signed inner ZIP: 364124927 bytes; SHA256 41e7b36915acbf685b4418462ef58483c1f2adaa0f55901b9aee9ce10290f956. Ad-hoc signed, not notarized; internal review only.

Non-numeric, boolean, non-finite, zero or negative frame intervals fail only their profile. Fewer than 120 frames or 10 engaged seconds retain partial metrics with INSUFFICIENT_WINDOW, but aggregate profile_coverage is NOT_ACCEPTED and summary exits red. No partial measurement is promoted to complete coverage.
