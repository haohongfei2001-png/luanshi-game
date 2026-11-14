# Action-review target: 24 real wall-clock samples/second

4fps remains explicitly DIAGNOSTIC_4FPS_NOT_ACTION_ACCEPTANCE. It cannot pass natural-motion or continuous-play acceptance. New optional `--wall-clock-action` requests 24 timestamped real frames per wall second, QHD up to 60 seconds/1440 images or UHD up to 30 seconds/720 images. Scheduling follows the original monotonic sampling grid, rather than drifting one interval after each late callback. Missing slots remain counted and visible as VFR holds, never synthesized into fluent action. A battle ending early stays a shorter recording.

Add to hosted delivery:
```
--wall-clock-video --wall-clock-uhd --wall-clock-action
```
Existing no-readback benchmark processes remain separate and unchanged. The old simulation-time movie remains unchanged. Native dimensions, scale=1 and JPEG quality .94 are unchanged. All resulting receipts say NOT_ACCEPTED_REQUIRES_REAL_FRAME_REVIEW, regardless of target or achieved sampling rate.

Disk preflight now checks the actual destination filesystem. Action profiles conservatively reserve 6MiB per QHD frame or 12MiB per UHD frame, plus 2GiB for output/working reserve: 11,207,180,288 bytes available are required for either profile. Diagnostic mode also preflights its byte ceiling plus reserve. Insufficient space writes and closes a failure journal without starting capture; no pre-existing output is removed. Actual file errors are journaled, capture stopped, and partial evidence retained. Upper limits remain hard; capture does not silently reduce resolution/quality to fit disk.

The local /tmp test genuinely rejected action mode with 4,041,678,848 bytes available; its failure record is retained. The same synthetic lifecycle tests passed on the separately checked workspace filesystem with sufficient space. Diagnostic, QHD24 and UHD24 cases validate frame/time/byte stop, callback removal and refusal to mix restarted journals. No graphical frames were produced by these tests.

Each actual frame now records image-readback, JPEG-encoding and disk-write/flush microseconds separately, as well as total readback/encode/write cost. Those stalls can substantially reduce achieved recording cadence and game responsiveness. VFR retains them; the overhead is not attributed to the separate clean performance run. JSONL flush overhead is additional, included in wall-clock gaps but not the screenshot component measurements.

Still not covered: real Mac runner readback at native2K/4K, actual sustained24 samples/s, natural movement and pose acceptance, complete horse/spear/shield/hit visibility, nine-weapon switching, audio. A successful F-key attempt is not proof of visible riding. Low-rate or missing-action footage cannot be called full action PASS. Likewise 20-per-side encounters with only one side's recorded hits are not bilateral attack/defense proof; normal inputs remain, battle rules and casualties are never forced.
