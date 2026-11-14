# Second environment revision: actual approach terrain

## First revision rejected after actual rendering

Reviewed actual RC26 source `70cdb716` bridgehead tick 135 at native 2K and 4K,
grove and whole-war frames. Complete native willow and removal of the repeating
stone necklace improved the old forms, but did **not** meet the reference:
- the 22 m camera lost the taller trees almost entirely;
- the bridge-to-gate surface still read as a flat lawn;
- large outcrops stood up individually instead of growing out of an eroded bank;
- the wide valley remained empty, without sufficient middle/background layering.

The first render is retained by the parent; it is not accepted art.

## Real second-round changes

`Ground.bridgehead_relief()` now sculpts the shared actor/terrain surface:
0.58 m crowned roadbed, 2.15 m north shoulder and 1.72 m south terrace, broader
valley benches, and a 5.2 m northern background ridge. The bridge abutments,
gate sill, fort foundations, original blocking and bridge width are unchanged.
Legacy open-field height takes the original code path. New slopes use existing
terrain movement rules, so peripheral movement and subsequent battle results may
change; no claim of identical hit/position hashes is made.

Native elm/maple canopy groups now frame the near upper-left and lower-right
edges rather than being placed entirely outside normal-camera composition. Native
brush and ferns tie the approach shoulders into the taller stands. Added complete
native woodland stands occupy the actual new valley benches and northern ridge.
Large collision-defining source outcrops are retained but more deeply embedded;
whole scan geometry, UVs and proportions remain intact. The ground material now
places litter on the shoulder woodland and exposes soil on real slopes.

No new assets, purchases or licenses. Existing Wildfire Games CC BY-SA 3.0 and
Poly Haven CC0 provenance remains in the first-round documentation.

## Tests

First shoulder profile failed the existing new slope guard. That failure is
preserved as `rejected-steep-shoulder.log`. The transition was widened, not the
acceptance threshold. Final sampled maximum grade: 0.64733, below 0.72.

- `river_approach_relief.gd`: PASS, 7,735 legacy height samples, fixed abutments
  and foundations, shared actor height, current save restore.
- `world_terrain_compat.gd`: PASS, old/current terrain save recovery.
- `river_environment_structure.gd`: PASS after final slope-width adjustment.
  190 complete tree crowns, eight willows, 69 talus
  components and 49 riparian grass clumps.
- `field_bridgehead.gd`: PASS, 512 per side, tick 400, 297 crossed, hits501/569,
  deaths140/139. First round was 300 crossed, hits522/558, deaths135/144.
  This is a documented actual simulation consequence of shared relief, not
  replacement with fake soldiers or a reduction in roster.

- `field_bridgehead_outcome.gd`: PASS, tick2100 natural 守城成功, gate breach492,
  losses289/286, hits1191/1183, campaign audits, camp, wait, march and saved
  result all true. The first revision had losses309/329 and breach439.

Tree crowns increased from138 to190; graphics cost is **not measured** yet.
Second-round actual graphics, original-speed video, performance and M5 remain
**NOT_RUN** pending the parent's same-seed/same-camera capture. Owner art remains
**ART_REVIEW_REQUIRED / overall prior OWNER_REJECTED**. Do not mark this slice
accepted from the headless tests or the written terrain values.
