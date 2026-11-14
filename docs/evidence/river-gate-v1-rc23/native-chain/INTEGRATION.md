# Complete ground basic-chain handoff

## Selected result

Adopt the third authored-chain candidate for ground sword and dao basic attacks. The matching ready stance, planted forward leg, pelvis, shoulder, elbow and weapon hand follow the original Wildfire Games chain. Their existing windup and recovery durations align the actual blade crossing to each simulation hit time.

The normal 22 m windows and bridge-side 6.3 m windows show the body loading the front leg and the blade finishing lower through the cut. The old body stays more upright. Original entry, contact and exit frames were inspected individually alongside the consecutive frame sheets. The close bridge-side frames expose both boots and the working wrist.

Ground sword and dao share this one source action, with their existing distinct timings and skills. The other weapon attacks, general movement transitions and multiple-player-input situations need further authored-motion work. Whole-game art remains **ART_REBUILD_REQUIRED** and real M5 validation remains **NOT_RUN**.

## Source and integration

The precise eleven-file list and Git blob identities are in `integration-manifest.json`. Source commit is `c617a1fb4383200a00df197086a338e61dfbb776`. Product diffs are `0e65f9e25a2e66e2cb9ff3cbc74b92d39838690f` and `c617a1fb4383200a00df197086a338e61dfbb776`.

The standalone distribution notice is `assets/river_gate/figures/WILDFIRE_MOTION_NOTICE.txt`. The two pinned editable COLLADA files, sampled curves and palette derivative use CC BY-SA 3.0 with Wildfire Games attribution. The source extractor uses existing `import_company_march.py` and `import_garrison_issues.py` helpers. Clean validation confirms the research-only combat importer is absent.

## Actual evidence

The fixed seed is 61112 with 512 ordinary troops on each side. Actor 584 naturally approaches at tick 16, starts the sword action at 22, hits at 27 and resumes movement at 34. Before and after contain identical simulation and actual MultiMesh instance inputs.

The 2560×1600 movies contain all twenty 50 ms simulation frames. They preserve simulation-time playback speed. Software-rendered capture runs slower in wall time, so these movies provide no real-time FPS measurement.

- [Bridge-side original before movie](https://github.com/haohongfei2001-png/luanshi-game/blob/fa58a352f73b2389268aea2a11080f718767dd1f/docs/evidence/river-gate-v1-rc23/native-chain/clear-west/before.mp4)
- [Bridge-side original after movie](https://github.com/haohongfei2001-png/luanshi-game/blob/fa58a352f73b2389268aea2a11080f718767dd1f/docs/evidence/river-gate-v1-rc23/native-chain/clear-west/after.mp4)
- [Before full contact window](https://github.com/haohongfei2001-png/luanshi-game/blob/fa58a352f73b2389268aea2a11080f718767dd1f/docs/evidence/river-gate-v1-rc23/native-chain/clear-west/before-011-native.jpg)
- [After full contact window](https://github.com/haohongfei2001-png/luanshi-game/blob/fa58a352f73b2389268aea2a11080f718767dd1f/docs/evidence/river-gate-v1-rc23/native-chain/clear-west/after-011-native.jpg)
- [After normal 22 m window](https://github.com/haohongfei2001-png/luanshi-game/blob/b1dc52d77a25eeb2bf8946175b097d7a1d6d470e/docs/evidence/river-gate-v1-rc23/native-chain/clear/after-normal-027.jpg)
- [Actual rendered ankle transitions](https://github.com/haohongfei2001-png/luanshi-game/blob/fa58a352f73b2389268aea2a11080f718767dd1f/docs/evidence/river-gate-v1-rc23/native-chain/clear-west/actual-ankles.json)

For this episode, right/left ankle displacement at march-to-windup falls from 0.550/0.496 m to 0.066/0.131 m. Recovery-to-march changes from 0.0818/0.0818 m to 0.0208/0.0108 m. These values include the actual unit transform and do not establish universal zero foot sliding across every possible incoming gait phase.

The first source cut read as a high thrust and was rejected. The second used the old opposite-foot ready stance and was rejected for its half-metre transition. The first close proof of candidate three hid the feet behind the gate roof and was rejected as foot-contact photography. All remain in the research branch.

## Verified clean checkout

[Run 43586258519](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43586258519) passed selected-source regeneration, exact parsed source-curve equality, exact decoded palette-pixel equality, `check_company_motion.py`, `check_field_carries.py`, `check_contact_motion.py`, `check_native_chain.py` and `check_native_entry.py`.

The nine-weapon baked wrist maximum is 0.168 mm. Existing carried impact poses have zero measured difference. The 36 reaction strips retain planted support and at least 0.126 m catching-foot movement. The authored cut has 0.787 mm source supporting-sole span and a continuous windup/recovery boundary.

The clean test caught the old fallen-bow assertion expecting the released string at the loose hand. Its corrected check validates the returned brace within 0.1 mm and preserves all live grasp thresholds. The initial failure is archived under `native-chain/clean-failure`.

Capture run 43585505869 completed both movies and all checks, then its evidence push conflicted with the already-completed source audit. Run 43586202454 restored the original artifact and verified movie SHA-256 values. No capture was regenerated during that recovery.
