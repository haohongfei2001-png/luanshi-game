# Natural source character: isolated, visually rejected

Default gameplay is unchanged. Full editable natural MakeHuman male, complete 163-bone skeleton, original full source body/UV and weights are retained. Author helpers are used for fit/rest, not drawn as skin. Runtime body hiding uses the garments' authored delete lists; the full body remains in the blend. Robe, trousers and boots retain complete professional source topology. This does not make the resulting outfit good art.

## Actual self-review
Blender idle and sword frames were personally inspected. The pink ankle-length robe reads as a bathrobe, not military clothing. Bald head, missing armour/hair, poor robe silhouette, trouser penetration and severe waist folds during sword motion reject the whole outfit. These are not minor finishing issues. No Godot graphical or user art acceptance has occurred. Next art work must replace/tailor coherent actual garment layers, not paint superhero skin or freeze limbs.

## Verified engineering boundaries
- Nine retargeted clips, 163 bones; target bind/rest and mesh attributes unchanged by retarget, 65 exported accessor comparisons.
- A/T-pose mismatch caused an initially crossed idle wrist; explicit reference calibration fixed that particular numerical error, not all motion/contact.
- Native headless import ran all nine durations, then 23.0167 seconds / 1381 frames. Native Godot preview is limited to eight influences and is **not full-weight rendering**.
- Source-ID UV2 maps 20159 split render vertices to 18351 source vertices with zero position/UV error, exact triangle-source membership. Existing UV0 remains intact.
- Sidecar v2 explicitly normalizes complete raw Blender groups by total. It preserves raw groups and factors. 122 vertices have raw sum deviation >1e-6. The transfer pipeline summed signed proxy coefficients before removing non-positive/tiny groups, so retained positive groups can sum above one. This is our transfer ordering issue, not a defect in the original author weights. Raw here means transferred Blender groups, not untouched author weights. GLB export also omits tiny groups on 38 vertices despite all-influence export; sidecar retains them. Actual GLB weights are recorded separately. No implicit clipping/normalization is hidden.
- Frozen static GLB SHA256 `6853fbca1b76eed03d764e32577f46e0354583a29405ae3a3a7088d69cc18539`; animated `b735dc82ca668bf2417ce4ad6bd68aa0005a9188c7cbb5eec23f15711eb20f11`. Sidecar v2 `8a580adf35abee5cc661d15a24f3f77d304c2f28ae78057edc50edc59d9093db`.

## Rebuild
`MH_SOURCE_CACHE=/tmp/mh-rebuild-source UAL_GLB='/tmp/luanshi-ubc/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb' MH_FETCH_OFFLINE=1 bash tools/art/mh_character/build_seed.sh`

Individual builder, retarget, checker, native importer and source-ID test have actually run. Aggregate shell script subsequently ran end-to-end successfully after correcting checker CLI arguments and excluding editable blend source from automatic Godot import. Original attempts failed before correction; see seed-end-to-end-verified.log. Native tests were rerun again after adding explicit missing-resource failure exits. Offline fetch verified all 40 pinned source files. Online range fetching is implemented but this aggregate fetcher's online path is not reverified. Generated binary masters are intentionally not included in the small code commit. Source licenses must travel with any generated delivery; see NOTICE.
