"""Archive viewable parts of an already completed hosted capture."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
from segment_whole_battle import segment_movie

def git(*args, **kwargs):
    return subprocess.run(["git", *args], check=True, **kwargs)

assert os.environ.get("GITHUB_ACTIONS") == "true"
source_sha = os.environ["CAPTURE_SOURCE_SHA"]
root = Path(sys.argv[1])
films = list(root.rglob("river-gate-bridgehead.mp4"))
assert len(films) == 1, films
film = films[0]
recording = json.loads((film.parent / "recording.json").read_bytes())
assert recording["game_source"] == source_sha
parts = Path(os.environ["RUNNER_TEMP"]) / "viewable-film"
receipt = segment_movie(film, parts)
assert receipt["source_movie_sha256"] == recording["sha256"]
receipt["game_source"] = source_sha
receipt["capture_run"] = recording["capture_run"]
receipt["archive_run"] = os.environ["GITHUB_RUN_ID"]
receipt["art_acceptance"] = "ART_REBUILD_REQUIRED"
(parts / "viewable-film.json").write_text(json.dumps(receipt, indent=2) + "\n")
branch = "codex/river-whole-native-evidence"
git("fetch", "origin", branch)
worktree = Path(os.environ["RUNNER_TEMP"]) / "film-evidence"
git("worktree", "add", "--detach", str(worktree), "FETCH_HEAD")
target = worktree / "docs/evidence/river-whole-rebuild/native" / source_sha / "movie/parts"
assert (target.parent / "recording.json").is_file()
target.mkdir(parents=True, exist_ok=True)
for path in parts.iterdir():
    shutil.copyfile(path, target / path.name)
git("-C", str(worktree), "add", str(target.relative_to(worktree)))
git("-C", str(worktree), "-c", "user.name=River Gate native review",
    "-c", "user.email=41898282+github-actions[bot]@users.noreply.github.com",
    "commit", "-m", "Archive every native QHD film frame as directly viewable stream-copy parts")
git("-C", str(worktree), "push", "origin", "HEAD:refs/heads/" + branch)
print("VIEWABLE_NATIVE_FILM", json.dumps(receipt), flush=True)
