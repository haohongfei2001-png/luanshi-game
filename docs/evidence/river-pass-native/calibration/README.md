# Input-driver calibration, not rendered evidence

The new hosted run completed all core gameplay regression, then correctly failed the separate input calibration: the scripted player rushed into spears and died at tick 147 with two real impacts. The game itself was not weakened. The driver now retreats using normal mapped movement after a strike or early injury, toward the friendly approach rather than the exposed former fallback. Same seed, scene, real troops and unchanged calibration predicates.

The default headless control replay now reaches the real defending victory at tick 2240, two player impacts, HP100. The real-time profile input replay reaches tick900, two player impacts, HP100. These are control simulations, not actual native Mac footage or FPS benchmarks.

The original mounted control path also failed at tick121. The corrected path sends F to mount, rides the friendly approach, sends F to dismount before the enemy front, then uses ordinary on-foot controls. Its headless replay reaches tick900 with HP81.939 but **zero player impacts**. That missing attack is not relabeled as observed. Native VFR receipts explicitly list missing sampled actions and require visual review of grips, shield raising, attacks, hits and riding poses. Mounted visibility and achieved sampling rate must still be measured in the real hosted capture.

No battle constants, HP, ordinary soldier count, damage, outcomes or acceptance predicates were changed. The fixed-step complete battle movie remains separate from wall-clock action capture and performance sampling. Current art remains rejected and actual M5 is not tested.
