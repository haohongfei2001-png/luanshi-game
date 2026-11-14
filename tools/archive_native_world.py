"""Publish reviewable native receipts from the disposable hosted Mac."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
from PIL import Image

def git(*args,**options):
    return subprocess.run(["git",*args],check=True,**options)

def main():
    assert os.environ.get("GITHUB_ACTIONS")=="true" and os.environ.get("RUNNER_OS")=="macOS"
    source=Path(sys.argv[1]).resolve()
    branch="codex/river-whole-native-evidence"
    source_sha=os.environ["GITHUB_SHA"]
    workspace=Path(os.environ["RUNNER_TEMP"])/("native-evidence-"+os.environ["GITHUB_RUN_ID"])
    remote=subprocess.run(["git","ls-remote","--exit-code","origin","refs/heads/"+branch],capture_output=True,text=True)
    assert remote.returncode in (0,2),remote.stderr
    if remote.returncode==0:
        git("fetch","origin",branch)
        parent="FETCH_HEAD"
    else:
        parent=source_sha
    git("worktree","add","--detach",str(workspace),parent)
    target=workspace/"docs/evidence/river-whole-rebuild/native"/source_sha
    target.mkdir(parents=True,exist_ok=True)
    files=[]
    for path in sorted(source.rglob("*")):
        if not path.is_file():continue
        relative=path.relative_to(source)
        if relative.parts[0] in ("take","unpacked"):continue
        if path.suffix.lower() not in (".jpg",".json",".jsonl",".txt",".log",".mp4"):continue
        if path.stat().st_size>95*1024*1024:continue
        destination=target/relative
        destination.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(path,destination)
        files.append({"file":relative.as_posix(),"bytes":path.stat().st_size,
            "sha256":hashlib.sha256(path.read_bytes()).hexdigest()})
        if path.suffix.lower()==".jpg" and not path.stem.endswith("-preview"):
            with Image.open(path) as frame:
                frame.thumbnail((1440,810))
                frame.convert("RGB").save(destination.with_name(path.stem+"-preview.jpg"),quality=93,subsampling=0)
    (target/"archive.json").write_text(json.dumps({"source":source_sha,
        "run":os.environ["GITHUB_RUN_ID"],"files":files,"art_status":"ART_REBUILD_REQUIRED",
        "device":"Hosted macOS, actual M5 DEVICE_NOT_RUN"},indent=2)+"\n")
    git("-C",str(workspace),"add","docs/evidence/river-whole-rebuild/native")
    git("-C",str(workspace),"-c","user.name=River Gate native review",
        "-c","user.email=41898282+github-actions[bot]@users.noreply.github.com",
        "commit","-m","Preserve native whole-world review at "+source_sha[:12])
    git("-C",str(workspace),"push","origin","HEAD:refs/heads/"+branch)
    print("NATIVE_WORLD_EVIDENCE",source_sha,branch,flush=True)

if __name__=="__main__":main()
