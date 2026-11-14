# Full basin actual Godot review (2026-11-14)

Source 67700146a7af81832276a47b0dad782d1f399485, run 43632863687, artifact 14129117119.
Actual 2560×1440 (yaw −65/−75) and 3840×2160 (yaw −65), internal scale 1.0, tick 135; all three original frames share actual battle-snapshot.bin SHA256 `1d5ec50f80084389cd20700086bcf8e49f96bc36996587833b9d050fbee6708d`. These are candidate perspective cameras, not fixed official MOBA parameters. Old actors remain. These three images are not a controlled before/after against earlier scene versions.

Engineering: the frozen 018372 basin, native shore, new field-oak woodland and low grass run together in the actual game. All downloaded logs independently scanned without SCRIPT ERROR / SHADER ERROR / ERROR. Real display grass layout verifies 598 transforms with zero origin mismatch. Water TIME is transiently frozen at 6.75, original and substituted shader hashes recorded. Linux Mesa llvmpipe is not a Mac performance result. No new original-speed traversal in this run. M5 NOT_TESTED.

ART_FAIL: both original QHD views personally reviewed. Extended terrain removes former gray missing region, but large bare uniform earth remains, two cliff sections look attached rather than a continuous bank, water reads as a smooth green sheet with broad gloss, narrow fragmented tree crowns lack a convincing connected grove, masonry is a large untextured block and upper timber hall looks structurally detached. The normal view crops most of the roof. Existing actors/vehicles are below the approved concept. This is internal failure evidence, not an accepted candidate or user-facing successful delivery.

Known geometry limitation retained from frozen source: reachable off-road main river bank interpolation difference can reach 0.10844 m, while tested main route maximum is 0.01694 m. Later adaptive source 98ef111 is NOT included in these images. Do not claim exact support everywhere.

Recovery: download run artifacts basin-recovery-00 (14129062156), -01 (14129062161), -02 (14128862788), -03 (14128643295), merge their archive roots and run `python tools/bounded_artifact_groups.py restore GROUPS DEST`. Verify source-manifest.json and every original SHA before reusing. It contains five runtime assets and editable authored tree/grass sources. Do not rebake identical assets just for a new camera test.

Separate release capture safety: f06d1dcac1c41085f068864c1cbd7676d042d6d7 moves capture side effects out of debug assertions and adds source regression. Actual packed runtime closure is still being independently repaired; editor success here does not prove it.
