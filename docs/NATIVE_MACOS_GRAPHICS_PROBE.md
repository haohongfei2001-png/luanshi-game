# Optional native macOS graphical probe

This is an **explicitly triggered, separate diagnostic** on the project's existing standard `macos-latest` GitHub-hosted runner. It does not change `verify.yml`, game source, the exported bundle, renderer configuration, account access, signing, paid services, or runner tier. A failed probe must not be reported as passed just because regular headless CI is green.

## What it checks

1. Validate a completed, successful same-repository `verify.yml` source run and download its exact named macOS artifact. Record source run/commit and probe run/commit separately. Require the expected SHA-256 of the **inner `Luanshi-macOS.zip`** to match before extracting or launching it. A mismatch stops the probe and records both hashes.
2. Record the host's macOS version, architecture, runner image identity and display/GPU metadata. Do not dump environment secrets or unrelated application windows.
3. Unpack that existing archive and run `codesign --verify --deep --strict` before launch.
4. Compile a small read-only CoreGraphics observer using the runner's installed Apple SDK. Observe active displays and only on-screen normal windows owned by the launched game's exact process ID. No screen-recording, Accessibility or Automation permission is requested.
5. Start the actual exported executable inside its unchanged `.app`, **without `--headless`**, using the default GL Compatibility renderer. Capture 90 real renderer frames with Godot's built-in MovieWriter at fixed simulation 10 FPS. Retain the final frame, validate PNG CRC/decoding/dimensions and check it is not a flat image. Keep capture process logs, renderer identification and PID window samples.
6. Separately run the existing complete battle and world-sourced campaign smokes in ordinary windowed mode. Require exit 0, the matching `SCENE_SMOKE_PASS` / `CAMPAIGN_SMOKE_PASS` marker, no engine/script error, and an observed window for each process. Use separate isolated save IDs for each run. Capture runs intentionally stop early and never count as full smoke passes.
7. Verify the unchanged bundle's strict signature again. Upload logs, PNGs and `result.json` whether the probe passes or fails. Inspect the PNG pixels before describing scene content to the user.

The first unverified stage stops later game launches. There is no automatic renderer fallback, security workaround, repeat dispatch, paid machine or local-Mac access. Each capture is bounded to 90 seconds and 90 frames; each full smoke to 150 seconds. The total job limit is 12 minutes. Python supervises process groups and terminates timed-out children; it does not depend on GNU `timeout`, which is not standard macOS software.

## Why the existing capture flag is not used

In this version, `--capture-proof` / `--capture-campaign` save to `res://artifacts`. In official 4.6.3 exported templates, `--path` is disabled (confirmed against the local exported Linux binary), and exported macOS starts in its bundle Resources directory. Creating capture directories or files there would mutate sealed bundle contents. This probe therefore uses an **absolute MovieWriter output path outside the app** and does not pass either capture flag. The game binary, resource pack and signing remain unchanged.

`--write-movie` is an officially supported exported-project flag. PNG sequence capture is offline fixed-step rendering, not desktop/compositor screen recording and not a real-time performance measurement. Temporary intermediate frames remain in the disposable runner temp directory; only the selected final image from each capture is uploaded.

## How to publish and trigger after review

The preparation itself does not publish or run anything. The probe accepts exactly two deliberate trigger routes, with identical run/artifact/checksum validation:

- **One deliberate main push:** only a change to `.github/probes/native-macos-v06.json` on `main` triggers this workflow. The source guard also checks GitHub's comparison of the push's before/after commits and refuses execution if that exact file was not added/changed. Ordinary pushes, branches, pull requests and schedules do not trigger the probe. On push the guard reads only this manifest, never manual inputs.
- **Manual dispatch:** supply all four required inputs. The guard uses only these explicit inputs, never the manifest. This route remains available wherever the GitHub interface/API supports dispatch.

After the intended v0.6 normal CI and native headless/persistence tests are green, the implementer should:

1. Review and publish the workflow, helper scripts, tests and docs **before the manifest**, or land them atomically with the manifest in a single reviewed commit. If the connector writes one file per commit, write the manifest last. Do not publish the trigger before its dependencies exist. No user desktop/API action is required.
2. Publish the checked-in manifest exactly once to `main` to deliberately trigger the v0.6 probe. It contains:

   ```json
   {
     "source_run_id": "42425639702",
     "source_sha": "e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b",
     "artifact_sha": "0b6dd7037ec40bc8fea5b2002fcd3a8c82a08fe4",
     "expected_archive_sha256": "278daea3d44ccbbd6a98f36e2895f48df57121959b9bbf18352a28c3ea82956d"
   }
   ```

   `source_sha` is the successful run's `head_sha`; `artifact_sha` is the suffix from its exact `Luanshi-macOS-<SHA>` artifact name. For pull-request runs this is the test-merge checkout SHA and can differ from the branch head. All four values must be strings; unknown or missing fields are rejected. Leaving the manifest unchanged causes no future runs. Another manifest edit is an explicit new probe request, not recurring monitoring.
3. Alternatively, dispatch after the workflow exists on the default branch:

   ```sh
   gh workflow run macos-graphical-probe.yml --repo haohongfei2001-png/luanshi-game \
     --ref main -f source_run_id=42425639702 \
     -f source_sha=e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b \
     -f artifact_sha=0b6dd7037ec40bc8fea5b2002fcd3a8c82a08fe4 \
     -f expected_archive_sha256=278daea3d44ccbbd6a98f36e2895f48df57121959b9bbf18352a28c3ea82956d
   ```

   Source: https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42425639702. The macOS artifact ID is `13595636136`. GitHub's artifact-wrapper digest is `sha256:1a9ee676571c095cd780815f842207123b073351140777f4c693560b6148544b`; that is **not** the inner application ZIP checksum above, independently verified when the v0.6 package was downloaded. Recheck artifact availability before triggering because artifacts expire.
4. Inspect the exact trigger commit/run result, `source.json`, `archive.json`, `result.json`, all capture/smoke logs and actual PNGs. Neither an accepted push nor an accepted dispatch is completion. If it fails, report the exact stage/classification and logs, not a blanket claim that macOS cannot render. The normal `verify.yml` may also run on this code/manifest commit under its existing triggers; this probe does not change those rules or its required checks.

The workflow has only `contents: read` and `actions: read` permissions. Validated guard outputs, rather than raw event inputs, choose the artifact and run ID and supply the expected ZIP checksum to the probe. A missing/malformed checksum is a setup failure; a mismatched archive cannot be extracted or executed.

## Result meanings and limits

- `PASS_NATIVE_CI_GRAPHICS`: both real viewport captures and complete ordinary windowed smokes passed, their PID-owned windows were observed, and strict signing stayed valid.
- `RUNNER_RENDERER_UNAVAILABLE`: a known renderer/context/device initialization error occurred. Preserve the exact message; do not automatically infer every native Mac would fail.
- `RUNNER_DISPLAY_UNAVAILABLE`: successful display queries consistently reported no active display and no window/capture was observed.
- `GAME_FAILED` / `GAME_OR_ENGINE_FAILED`: script errors or unclassified runtime/engine errors. They are not silently blamed on the hosted environment.
- `CAPTURE_FAILED`, `WINDOW_UNOBSERVED`, `SMOKE_INCOMPLETE`, `LAUNCH_FAILED`, `INCONCLUSIVE_TIMEOUT`, `PROBE_SETUP_FAILED`: the corresponding evidence is missing or failed. A timeout alone is not evidence of a missing GPU. Native observer compilation is part of setup and is not pre-claimed to work before its first macOS run.

An observed window plus a viewport image is evidence of **native hosted-VM window/render operation**. It does not prove presentation through the desktop compositor, Finder/double-click or Gatekeeper behavior, notarization, working audio, human keyboard/mouse input, sustained real-time FPS, thermal behavior, battery use, M5 hardware compatibility/performance, or user acceptance. The capture uses fixed simulation timing; never report its rate as gameplay FPS.

Current official GitHub documentation lists the standard Apple Silicon runner as a virtual machine with 3 M1 CPU cores and 7 GB memory. `macos-latest` is a moving image label. Record each actual host instead of treating that label as a particular OS version, hardware GPU or performance guarantee. Standard runners are free for this public repository; larger/GPU runners are not part of this probe.

## Sources

- GitHub runner specifications and public-repository standard-runner policy: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- Manual workflow dispatch requires a default-branch workflow: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- Godot MovieWriter, exported-project support, PNG sequence and non-real-time limitations: https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html
- Godot 4.6 exported path setup / bundle resource directory: https://github.com/godotengine/godot/blob/4.6-stable/main/main.cpp
- Godot 4.6 resource pack and resource path setup: https://github.com/godotengine/godot/blob/4.6-stable/core/config/project_settings.cpp

## Preparation verification

Portable harness tests cover PNG decoding (all five filters, RGB/RGBA), blank/corrupt images, missing window/smoke marker, error classification, timeouts/process termination, launch failures and the non-macOS guard. Source-guard tests cover both explicit routes, exact manifest-change checking, PR head/merge identity, checksums, failed/expired/wrong-origin artifacts and refusal of other events. YAML structure is checked for only the two explicit triggers, the standard runner, read-only permissions and timeout. These checks are **not a native macOS execution result**. The first reviewed dispatch must compile the CoreGraphics helper and establish actual native graphical capability.

```sh
python3 -m unittest discover -s tests -p test_macos_graphics_probe.py -v
python3 -m py_compile tools/probe_macos_graphics.py
node --test tests/test_macos_probe_source.cjs
```
