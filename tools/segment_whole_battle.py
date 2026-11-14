"""Expose full native recordings as stream-copy parts without changing a frame."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys

def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout

def video_info(path):
    result = json.loads(run([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_entries", "stream=width,height,avg_frame_rate,nb_frames,duration",
        "-of", "json", str(path)
    ]))
    return result["streams"][0]

def packet_hashes(path):
    result = json.loads(run([
        "ffprobe", "-v", "error", "-select_streams", "v:0",
        "-show_packets", "-show_data_hash", "sha256",
        "-show_entries", "packet=data_hash", "-of", "json", str(path)
    ]))
    return [packet["data_hash"] for packet in result["packets"]]

def segment_movie(movie, destination):
    destination.mkdir(parents=True, exist_ok=True)
    source = video_info(movie)
    subprocess.run([
        "ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(movie),
        "-map", "0:v:0", "-map", "0:a:0", "-c", "copy",
        "-f", "segment", "-segment_time", "8", "-reset_timestamps", "1",
        "-segment_format_options", "movflags=+faststart",
        str(destination / "river-gate-part-%02d.mp4")
    ], check=True)
    parts = []
    payloads = []
    frame_offset = 0
    for part in sorted(destination.glob("river-gate-part-*.mp4")):
        info = video_info(part)
        assert [info["width"], info["height"]] == [source["width"], source["height"]]
        assert info["avg_frame_rate"] == source["avg_frame_rate"]
        assert part.stat().st_size < 95 * 1024 * 1024, part
        count = int(info["nb_frames"])
        parts.append({
            "file": part.name,
            "first_source_frame": frame_offset,
            "frame_count": count,
            "native_px": [info["width"], info["height"]],
            "fps": info["avg_frame_rate"],
            "bytes": part.stat().st_size,
            "sha256": hashlib.sha256(part.read_bytes()).hexdigest(),
        })
        frame_offset += count
        payloads.extend(packet_hashes(part))
    assert frame_offset == int(source["nb_frames"]), (frame_offset, source)
    assert payloads == packet_hashes(movie), "The original compressed video packets must match in order."
    receipt = {
        "source_movie_sha256": hashlib.sha256(movie.read_bytes()).hexdigest(),
        "source_bytes": movie.stat().st_size,
        "source_frames": frame_offset,
        "method": "FFmpeg stream copy at existing keyframes. No rescale, interpolation, speed change or re-encode.",
        "video_packets_identical": True,
        "parts": parts,
    }
    (destination / "viewable-film.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt

if __name__ == "__main__":
    receipt = segment_movie(Path(sys.argv[1]), Path(sys.argv[2]))
    print("NATIVE_FILM_PARTS", json.dumps(receipt), flush=True)
