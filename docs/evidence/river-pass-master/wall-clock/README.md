# Optional real-wall-clock capture, not a benchmark

The old fixed-step simulation-time film is retained unchanged. New capture is opt-in and runs in its own exported-game process after clean no-readback performance profiles.

`wall_clock_capture.gd` connects to frame_post_draw in a normally running game. It never steps ticks, sets fixed FPS, enables Movie Maker, changes render scale or creates replacement combat frames. It rejects fixed-fps/write-movie arguments. At most four native JPEG snapshots per wall second are saved, each with monotonic microsecond timestamp, actual dimensions/scale, source SHA, drawn frame number, readback/encode/file-write cost and actual battle/hero/camera state. This intentionally low sampling rate is NOT gameplay FPS or a claim of smoothness. Slow rendering and readback stalls stay in the film as real timestamp gaps.

Bounds: 480 saved frames, 1.5GB and 120 wall seconds. The existing review normally stops after 45 wall seconds. Every JSONL record is flushed. Exit disconnects the callback and closes the journal. Existing output journals are refused on restart rather than overwritten or mixed. Interrupted journals stay on disk; the encoder refuses missing end records, nonmonotonic times, truncated frames or mixed dimensions/scale. No fabricated terminal duration is added to incomplete evidence.

The independent encoder uses ffconcat durations from the exact monotonic deltas and VFR H.264. It verifies decoded timestamps within 2ms, total measured duration within 10ms and exact source frame count plus one declared final hold sentinel. No optical-flow frames, speed-up, frame interpolation or resize is used. It hashes each JPEG and the output. Audio is explicitly NOT_CAPTURED. Capture receipts include source header, readback overhead and skipped sampling opportunities. Screenshot cost excludes the later JSONL journal flush; all overhead remains included in wall-clock timestamp gaps.

Optional input coverage uses ordinary mapped keys only. Early movement attempts to approach the parked horse and press F, then dismount and return to normal combat. Mount rejection is respected. Receipt records actual mounted-and-visible samples, hero impacts and HP changes; an attempted key is never evidence of successful riding. Existing spear input/ordinary shields remain, but weapon switching is still NOT_EXERCISED. Character readability, actual directional animation, attack/block, visible injury and mounted coverage require the resulting real frames, not just receipt counters.

Hosted invocation:
```
python tools/whole_native_delivery.py "$PACKAGE" "$PATCH" "$OUT" --require-river-pass-master --profile-uhd --wall-clock-video --wall-clock-uhd
```
This adds separate QHD/UHD real-time sampled videos and retains the old complete simulation-time movie. The wrapper does not pass --field-profile to readback runs and never uses their timings for benchmark FPS.

Standalone capture entry, on the existing focused cloud display:
```
RIVER_CAPTURE_OUT="$OUT" RIVER_SOURCE_SHA="$SHA" GAME --rendering-method mobile --rendering-driver metal --audio-driver Dummy --disable-vsync -- --whole-battle-review --native-qhd --wall-clock-capture --field-size=512 --require-river-pass-master
python tools/encode_wall_clock_capture.py "$OUT/wall-clock" "$OUT/wall-clock.mp4"
```
Change native-qhd to native-uhd for 3840x2160. Output names must be fresh. No user computer, OS recording permission, new account, service or paid capture dependency is used.

Local validation: GDScript parser; synthetic lifecycle tests for normal close, frame/byte/time caps, callback cleanup and restart collision; synthetic JPEG/VFR test with irregular 275/935/260/730ms intervals, timestamp/duration verification, rejection of incomplete and reversed-time journals. These tests do NOT represent actual gameplay footage. Real Mac runner native frame capture, video coverage and graphical performance remain NOT_RUN pending deployment.
