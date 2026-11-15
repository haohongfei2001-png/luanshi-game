# HF08 independent functional check

Actual author source: `cb89ed9ca8d045c28c684bc69d62b996bdad3d5e1a61bf47e5d14aa20d982755` GLB.
Navigation file: `28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`.
Topology revision6: `0b1d24868d11505f3e980a8eb456df7e55035203490b1d1df8384ba5622bd140`.
Author identity: `494c71705211b4d956f05a22483a93ddf7fbf0b54beb17dc95062e8f9a10a2f4`.

HF05a results were not inherited: actual HF08 raw GLB and exact author wrapper
were loaded and tested again with Godot4.6.3. The author wrapper correctly
sets shadow_enabled=true, directional_shadow_mode=2, max_distance=80,
shadow_bias≈0.1, normal_bias≈0.6 on the existing sole Sun (energy≈2.7),
with exactly one WorldEnvironment. Runtime did not add lighting or change it.
This fixes the author contract gap found in HF05a (shadow_enabled=false), but
CPU property verification is not proof of the rendered shadow's quality.

The new source graph has8882 nodes,33862 tagged support triangles and62 solids.
Both20 and512-per-side actual rosters deploy successfully: the latter1057 total
(529+528),875/594 source candidates, zero invalid placements. Four real continuous
source-derived travel routes arrive in606/606/104/237 steps. No soldiers, kits,
HP or obstacles were removed to pass.

The actual HF08 mother + source18 Skeleton + six actual ordinary spearmen were
then loaded into the real Controller.100 CPU ticks of real routed input produce
70walk/30idle; hero HP100 and hits0. Original45°/FOV50/yaw−65 camera remains the
candidate, not the author's alternative yaw−40 study or an approved final camera.

Evidence: `docs/evidence/production-v2/hf08-*.json`. Full logs and input trace are
shared `hf08-{shadow-readonly,runtime-preflight,controller-routed}`. Commands and
scope follow `PRODUCTION_V2_HF05A_RUNTIME_RECOVERY.md`, substituting the exactHF08
source and bounds derived from its tagged walk vertices.

NOT_RUN: GPU rendering, final imported/exported PCK, native movie, large-battle
FPS, M5. Art remains NOT_ACCEPTED. These are functional CPU results, not evidence
that the entire game now meets the visual target. No CI was started for this check.
