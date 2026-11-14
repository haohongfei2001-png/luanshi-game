"""Encode the native Godot AVI without changing frame cadence, size, or audio timing."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys
from PIL import Image

capture = Path(sys.argv[1])
directory = Path(sys.argv[2])
game_sha = sys.argv[3]
facts = json.loads((directory / "input-and-camera.json").read_bytes())
fps = 24

def run(command, **kwargs):
    return subprocess.run(command, check=True, **kwargs)

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def probe(path):
    result = run([
        "ffprobe", "-v", "error", "-show_entries",
        "stream=codec_name,width,height,avg_frame_rate,channels,duration,nb_frames",
        "-of", "json", str(path)
    ], capture_output=True, text=True)
    return json.loads(result.stdout)["streams"]

source = probe(capture)
video = next(stream for stream in source if "width" in stream)
assert video["avg_frame_rate"] == "24/1", video
frame_count = int(video["nb_frames"])
duration = frame_count / fps
battle_seconds = (facts["last"]["tick"] - facts["frames"][0]["tick"]) / 20.
assert abs(battle_seconds - (frame_count - facts["first_game_frame"]) / fps) < .4, (
    battle_seconds, duration, facts["first_game_frame"])
assert all(row["both_landmarks"] and abs(row["zoom"] - 22.) < .001 for row in facts["frames"])
assert all(abs(row["center"][0] - 34.2) < .35 and abs(row["center"][1] - 1.) < .35 for row in facts["frames"])

movie = directory / "river-gate-bridgehead.mp4"
run([
    "ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(capture),
    "-map", "0:v:0", "-map", "0:a:0", "-c:v", "libx264", "-preset", "fast",
    "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "128k",
    "-movflags", "+faststart", str(movie)
])
streams = probe(movie)
rendered = next(stream for stream in streams if "width" in stream)
sound = next(stream for stream in streams if "channels" in stream)
assert rendered["codec_name"] == "h264" and rendered["avg_frame_rate"] == "24/1"
assert int(rendered["nb_frames"]) == frame_count
with Image.open(next(directory.glob("view-*.jpg"))) as still:
    pixels = list(still.size)
assert [rendered["width"], rendered["height"]] == pixels == [2560, 1440]
assert facts["internal"] == 1 and facts["native_render_px"] == pixels
assert sound["channels"] == 2 and abs(float(sound["duration"]) - duration) < .12
volume = run([
    "ffmpeg", "-hide_banner", "-i", str(movie), "-vn", "-af", "volumedetect",
    "-f", "null", "-"
], capture_output=True, text=True).stderr
peak = float(re.search(r"max_volume: ([-.0-9]+) dB", volume)[1])
assert -60 < peak <= 0, volume[-500:]

first_contact = facts["first_game_frame"] + round(max(0, facts["first_player_strike"]) * fps / 20)
shots = {"approach": int(fps * 2), "gate": int(fps * 12), "first-contact": first_contact}
indices = sorted(set([
    *[min(frame_count - 1, value) for value in shots.values()],
    *[min(frame_count - 1, int(frame_count * fraction)) for fraction in (.08, .17, .24, .34, .62, .89)]
]))
selected = "+".join("eq(n\\," + str(index) + ")" for index in indices)
temporary = directory / "selected-source-frames"
temporary.mkdir(exist_ok=True)
run([
    "ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(capture),
    "-vf", "select=" + selected, "-fps_mode", "vfr", str(temporary / "%03d.png")
])
images = dict(zip(indices, sorted(temporary.glob("*.png")), strict=True))
for name, index in shots.items():
    with Image.open(images[min(frame_count - 1, index)]) as image:
        image.convert("RGB").save(directory / (name + ".jpg"), quality=96, subsampling=0)
        preview = image.copy()
        preview.thumbnail((1440, 810))
        preview.convert("RGB").save(directory / (name + "-preview.jpg"), quality=93, subsampling=0)
sequence = Image.new("RGB", (960, 370), (29, 35, 31))
for slot, fraction in enumerate((.08, .17, .24, .34, .62, .89)):
    index = min(frame_count - 1, int(frame_count * fraction))
    with Image.open(images[index]) as image:
        sequence.paste(image.convert("RGB").resize((320, 180), Image.Resampling.LANCZOS),
                       (320 * (slot % 3), 190 * (slot // 3)))
sequence.save(directory / "sequence.jpg", quality=93, subsampling=0)
receipt = {
    "game_source": game_sha,
    "capture_run": os.environ.get("GITHUB_RUN_ID"),
    "mode": "Godot Movie Maker, 24 successive frames per simulated second, normal mapped inputs",
    "capture_container": "MJPEG AVI with stereo PCM, native dimensions and every frame retained",
    "capture_sha256": sha(capture),
    "fps": fps,
    "native_capture_px": pixels,
    "physical_window_px": facts.get("physical_window_px"),
    "logical_root": facts["resolution"],
    "art_acceptance": "ART_REBUILD_REQUIRED",
    "seconds": duration,
    "simulated_battle_seconds": battle_seconds,
    "source_frame_count": frame_count,
    "streams": streams,
    "max_signal_db": peak,
    "sha256": sha(movie),
    "bytes": movie.stat().st_size,
    "summary": {key: value for key, value in facts.items() if key != "frames"},
    "device_framerate_measurement": False,
    "input_replay_pass": bool(
        facts["sampled_ticks"] > 150 and facts["last"]["hero_impacts"] > 0
        and facts["last"]["soldier_shield_contacts"] > 0
        and (duration >= 30 or facts["last"]["result"] != ""))
}
(directory / "recording.json").write_text(json.dumps(receipt, indent=2, ensure_ascii=False) + "\n")
print("BRIDGE_FILM", json.dumps({key: value for key, value in receipt.items() if key != "summary"}))
assert receipt["input_replay_pass"], "Actual combat acceptance failed, the complete captured attempt is retained."
