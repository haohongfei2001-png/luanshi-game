# Full sewn forearm sleeve derivative: partial structural result, not art acceptance

crosscollar_recut.py makes guarded modifications to the retained recut_front.py:
new diagonal crossing front pieces share original side seam vertices; visible
ivory facing belongs to those sewn polygons, not an overlay. Full original sculpted
shoulder/elbow/back remains. Source cage is retained and an independent expanded
clothing cage is rebound, with original rig weights intact.

Whole assembly2 removal of old leather gauntlets revealed a genuine source gap:
the author supplied no visible forearm mesh between original short sleeve and
hand. This was preserved as failure, never hidden with alpha or detached hands.

Assembly3 extends the ORIGINAL closed cuff boundary with connected sewn rows to
the original wrist, with taper and a physical folded cuff, then binds the whole
new garment to the source cage. Actual full-body raised-arm Blender image was
reviewed: no detached-hand gap remains; soft pale sleeve now reaches the wrist.
The .blend, UVs and complete rig remain editable. This is an actual garment
structure change, not relabeling the old gauntlet as fabric.

Still rejected as complete art: collar silhouette is too restrained/vertical,
shoulder plates remain arched, skirt/boots do not match the approved soldier.
Sleeve bending/contact through the full walk/thrust cycle is not validated.
No new cache generated; stable945b oracle unchanged. Current sleeve render is
Blender only, not Godot or owner acceptance.

Reproduce:
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/crosscollar_recut.py -- ORIGINAL_GUARDIAN.blend OUTPUT_RECUT
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/whole_garment_assembly.py -- WHOLE_LAYER_SYSTEM1.blend OUTPUT_RECUT/recut-editable.blend OUTPUT_ASSEMBLY
Local actual images: character-diagnostics/sintel-guardian/whole-garment-assembly2
and whole-garment-assembly3/whole-BLENDER-NOT-GODOT.png.
