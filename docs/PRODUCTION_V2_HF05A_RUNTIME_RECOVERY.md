# HF05a actual mother-source integration

This replaces no default map and is not art acceptance. HF05a remains ART_FAIL.
No native GPU, imported/exported final PCK, M5, normal-speed footage or 512-unit
frame-rate claim is made by these CPU results.

## Frozen source

- GLB: `d5536b56a6846e49c99c9170e1fb654d246a2469dd131402dc5a48a093f7c230`
- Navigation JSON: `8c2e998b3eca1e8c6392a336fe4bc39eac84d8054ad281fba37a40dc424ff79d`
- Topology revision4: `cd78826cec49916b529b4dd6559dafae81daf32dbb864a6dfbee0e587f429056`
- Author identity: `dc400f55d60cae499b32ee582372f05b3241e8a69d50b1612f91e588332ef32e`

Author source closure is retained at shared `production-v2-valley-hf05a`.
HF02–04 were not executed by this runtime worker. HF05 was actually tested and
rejected at Runtime.bind because gate_dynamic.pivot was absent. Its failure is
retained. The author supplied HF05a with explicit ground-landmark [14.8,1.2,0]
and separate hinge semantics, adding pivot to the canonical topology identity.
Do not infer this landmark from GLB node origin, which is (0,0,0), or use it to
rotate gate leaves. Runtime now rejects malformed/missing gate/goal data before
binding instead of throwing a script error.

## Actual checks

- Actual raw GLTFDocument load plus exact author mother.tscn wrapper: root
  identity, one Sun with energy2.7000000477, one WorldEnvironment, and exactly
  the door-leaf semantic node all pass. Resource cache supplies the actual raw
  GLB PackedScene to the wrapper; no lighting/material modifications. This is
  NOT an editor-import/export PCK test.
- New source graph: 33719 support triangles, 59 solids, 8740 nodes, about2.25s
  instrumented configure in this cloud CPU. Not game FPS.
- Real20/512-per-side initial rosters: 43/1057 total, including officers/hero.
  West875/east594 valid candidates; actual512 placed529+528 with zero invalid
  source positions. Kits/HP/mounted/officer identity unchanged, no reductions.
- Four source-semantic continuous routes arrived via real waypoint/travel:
  west→east606 steps, east→west606, west retreat104, east retreat237. Every
  actual step checks support and obstacles. No old004 results were inherited.
- Actual Controller plus source18 Skeleton and six actual ordinary spearmen:
  100 CPU simulation ticks. Real input follows new-source waypoint rather than
  the old fixture's blindly fixed +X path; hero moves (-28.75,-11.75) to
  (-24.9513,-9.166897), 70walk/30idle, HP100, hits0. Correct logical/native
  pointer and45°/FOV50 assertions pass. This is not contact/combat or GPU proof.

The first fixed +X4m short test failed its movement assertion and remains
`hf05a-controller-short.log`; no map/obstacle/body-radius changes were made to
pass the routed version. The old004 bank connector422/110-step regression also
passes after the defensive contract change, but remains separate evidence.

Summaries: `docs/evidence/production-v2/hf05a-*.json`.
Full raw logs are shared `hf05a-{runtime-preflight,host-raw,controller-routed}`.

## Reproduce

`tests/map_runtime/source_capacity_routes.gd -- SOURCE_JSON OUTPUT_JSON`
derives bounds and every route endpoint from actual source semantics. It writes
all outcomes; exit0 means diagnostic completion, so inspect error/route fields.
`tests/map_runtime/raw_mother_host.gd -- AUTHOR_DIRECTORY OUTPUT_JSON`
checks raw GLB + exact wrapper without duplicating/importing a large asset tree.
`controller_skeleton_fixture.gd` accepts the existing five args followed by
`input-short AUTHOR_DIRECTORY` to load that actual mother instead of the empty
identity fixture. Its layout argument must derive from the same walk vertices.

Next native GPU requires this complete source closure to be recoverable on the
Mac worker, that worker's actual editor import identities and transitive texture
closure, then independent empty-cwd PCK validation. Do not launch old terrain004
or substitute previous05/06 visuals while waiting for the source artifact.
