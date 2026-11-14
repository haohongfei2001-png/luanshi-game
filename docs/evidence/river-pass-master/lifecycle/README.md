# Lifecycle correction

Original failure logs remain untouched in the parent evidence directory. The original 229 resources / 584 renderer instances were real errors, not harmless warnings.

Cause: offline authoring reassigned all imported children to the master owner but retained their imported root scene_file_path. PackedScene consequently instantiated a source subtree and then replaced its children with explicitly authored children, orphaning the first set. The compiler now clears scene_file_path on the authored subtree. It does not globally delete orphan nodes or suppress errors.

Proof: three consecutive map open/close cycles each load 1157 nodes and return to exactly one SceneTree root with zero orphan nodes. Structural and actual game-entry tests exit with zero ERROR and zero WARNING. New serialized scene has the same 1155 authored nodes and all 1906 authored node property lines (transforms, meshes, materials) unchanged; only PackedScene instancing headers differ. The current visual source therefore has no intended art/layout change, but still needs actual renderer review.

Actual game entry additionally exposed mixer-held WAV playback on immediate process exit. Sound cleanup now stops each active voice, detaches its stream and releases the bank on exit. The entry test gives the asynchronous mixer 150 milliseconds after node teardown before terminating the process; it does not shorten or disable battle sound. The captured test still runs the full 135 ticks at 512 vs 512 and records the identical 185/231 hits.

Recovery: run tests/river_pass_lifecycle.gd, tests/river_pass_entry.gd, tests/river_pass_master.gd with Godot headless. Apply the lifecycle regression to the normal test suite; any ERROR remains a failure. Real graphical-backend shutdown and M5 remain untested here.
