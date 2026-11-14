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

## Matched woodland-region integration, next Linux evidence

Actual game architecture run 43621560790 at a788f964c8451ab2cce4f0778bdc021eb8f5cb1d succeeded and preserved native 2560x1440 / 3840x2160 images (internal scale 1). This is NOT art acceptance: bare support ground, legacy figures, block-like gate base and roof stripe artifacts remain visible. It is not the full new battlefield. Previous run 43620505673 failed from a typed door binding error; its logs are retained.

Next experiment adds the complete Sprite Fright woodland group: five native-derived trees and five bushes, shared geometry, fixed author-origin placement. Frozen tree and bush bakers are the aa562937 source versions, not subsequently modified experimental bakers. Official archive and all recorded source member hashes are verified before extraction/use. The downloaded archive is CC-BY 4.0, attribution: Sprite Fright production environment assets, Blender Studio / Blender Foundation. No endorsement implied. Ground remains explicitly a support layer; rejected full-base edge-UV output is not used.

The four actual-frame modes are qhd-before/qhd-after/uhd-before/uhd-after. They run within one frozen battle with identical seed, 20v20 ordinary troops, tick 135, camera center (34.2,1), size 22 and unchanged lighting. The before mode shows the original master, after shows the new architectural and woodland group. The binary game snapshot must remain byte-identical across all modes, with its actual SHA256 and exact camera basis/projection, controller hash and source SHA recorded. Local headless four-mode verification passed with one snapshot hash 9b9f82789848116890585217adc377a99c516c3002437b6ef9e4b246050024c0. This verifies setup/state preservation, NOT graphical pixels.

The separately repeated gate contract passes HP260/130/0/260 -> visible true/true/false/true and y0/-.225/-.45/0 without hiding the hall, bridges or walls. It is visual binding regression, not full siege outcome coverage. No realtime traversal movie has been run for this new region; metadata explicitly reports REALTIME_INPUT_NOT_RUN. No Mac runner or official release is triggered.
