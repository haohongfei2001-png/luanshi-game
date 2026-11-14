# New military gateway and structural bridge experiment

ART_NOT_ACCEPTED. This is not a complete new environment, a performance pass, or a package release.

Source: VVayToyek CC0 pavilion native roof faces/hip ridges/curved rafters, deeply reworked into a new long-ridge military canopy. No whole garden pavilion is placed on the wall. Newly authored vault/piers/walk corridor and bridge load path. Rico Cilliers / Poly Haven CC0 native deck-board topology/UV replaces the initial flat deck. No 0 A.D. gate/bridge fallback.

Frozen original professional inputs already exist in the authorized repository. `tools/art/gate_structure/source-inputs.json` verifies each SHA before Blender starts, avoiding temporary anonymous download URLs. Original publisher license pages are recorded in source LICENSE-EVIDENCE files. No new source acquisition/account/payment.

Local Blender source: assets/river_authored/architecture/source/architecture.blend, professional images packed. Runtime GLB consolidates assemblies and roof sections. Source mother files remain separately editable. Reproduce:

```
python tools/art/gate_structure/prepare_sources.py
blender -b --factory-startup --disable-autoexec --python tools/art/gate_structure/build_architecture.py -- assets/river_pass/pavilion/pavilion-source.fbx "$PWD/assets/river_authored/architecture" --no-preview
godot --headless --editor --path . --import
godot --headless --path . --script tests/authored_architecture.gd
```

Latest local import measured 9 mesh nodes,18 surfaces,313048 triangles, original UV arrays present, GateDoor origin(48,0,0). No claim this meets performance/art acceptance. Clear roadway7.4m, portal8m/4.2m, bridge top.13m. Wall-walk follows actual Ground.parapet slope from abs(z)5.5 to13.06 rather than a false constant3.25m floor. Curved roof ridges have a small ornamental envelope beyond the nominal8.2m body design, pending composition review.

Rejected first Blender render exposed roof seams and straight rafters piercing native curved roof. Replaced with source curved rafters and hip ridge covers, then removed a protruding long purlin. Masonry and remaining timber still need surface/structural refinement. These Blender renders are model review only, not gameplay evidence.

Linux workflow dot-architecture-review.yml runs actual scenes/game.tscn and real20v20 battle to tick135, hides rejected map visuals, adds new architecture and a shared gameplay-survey support surface. It preserves original characters and siege equipment. Door visibility follows actual gate_hp. New forest/complete environment not yet included. QHD normal, QHD close and UHD normal screenshots each carry actual pixel size/internal scale/source/tick/counts in receipt.json. Fixed normal camera34.2,1 /22m. Close view is separately labeled. Software runner capture is not performance evidence. No Mac run.

The new forest region is being authored separately; do not label this isolated system-link experiment as the completed whole map. Local Xorg could not establish local/unix sockets; no security settings were changed. Graphical verification belongs to actual Linux CI results, not this note.
