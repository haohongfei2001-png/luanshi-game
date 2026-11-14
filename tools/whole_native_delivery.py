"""Capture and profile only the exported game in a disposable hosted macOS job."""
from pathlib import Path
import hashlib,json,os,plistlib,pty,re,select,signal,subprocess,sys,time
from rc3_native_probe import empty_game_data

def run_game(executable,output,helper,user_args,movie=None):
    output.mkdir(parents=True,exist_ok=True)
    env=os.environ.copy()
    env["RIVER_CAPTURE_OUT"]=str(output)
    env["RIVER_SOURCE_SHA"]=os.environ["GITHUB_SHA"]
    args=["/usr/bin/time","-l","-o",str(output/"resource-time.log"),str(executable),
          "--rendering-method","mobile",
          "--rendering-driver","metal","--audio-driver","Dummy","--disable-vsync"]
    if movie:
        movie.parent.mkdir(parents=True,exist_ok=True)
        args+=["--fixed-fps","24","--write-movie",str(movie)]
    args+=["--","--whole-battle-review",*user_args]
    master,slave=pty.openpty()
    process=subprocess.Popen(args,stdin=subprocess.DEVNULL,stdout=slave,stderr=slave,env=env,
                             cwd=output,start_new_session=True)
    os.close(slave)
    pending=b"";deadline=time.monotonic()+600;promoted=False
    with (output/"window.log").open("w") as log:
        def line(raw):
            nonlocal promoted
            value=raw.decode(errors="replace").rstrip("\r")
            print(value,file=log,flush=True)
            if value.startswith(("BRIDGE_MENU_","BRIDGE_NATIVE_ATTACHMENT","BRIDGE_WINDOW","BRIDGE_TICK")):
                print(value,flush=True)
            if value.startswith("BRIDGE_FOCUS_READY ") and not promoted:
                event=json.loads(value.partition(" ")[2])
                if not event["focused"]:
                    subprocess.run([str(helper),"foreground",str(event["pid"])],check=True,timeout=8)
                    promoted=True
        timed_out=False
        try:
            while time.monotonic()<deadline:
                ready,_,_=select.select([master],[],[],.5)
                if ready:
                    try:data=os.read(master,65536)
                    except OSError:data=b""
                    if not data:break
                    chunks=(pending+data).split(b"\n")
                    pending=chunks.pop()
                    for chunk in chunks:line(chunk)
                elif process.poll() is not None:break
            else:timed_out=True
            if pending:line(pending)
        finally:
            os.close(master)
            if timed_out:
                os.killpg(process.pid,signal.SIGTERM)
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid,signal.SIGKILL);process.wait()
    text=re.sub(r"\x1b\[[0-9;]*m","",(output/"window.log").read_text())
    assert not timed_out and process.returncode==0,(output.name,process.returncode,text[-2200:])
    assert not any(marker in text for marker in ("SCRIPT ERROR","SHADER ERROR","ERROR:")),text[-2200:]
    return text

def main():
    assert os.environ.get("GITHUB_ACTIONS")=="true" and os.environ.get("RUNNER_OS")=="macOS"
    workspace=Path.cwd()
    package,patch,out=map(lambda p:Path(p).resolve(),sys.argv[1:4])
    out.mkdir(parents=True,exist_ok=True)
    unpacked=out/"unpacked"
    subprocess.run(["ditto","-x","-k",str(package),str(unpacked)],check=True)
    app,=unpacked.glob("*.app")
    info=plistlib.loads((app/"Contents/Info.plist").read_bytes())
    executable=app/"Contents/MacOS"/info["CFBundleExecutable"]
    original_hash=hashlib.sha256(executable.read_bytes()).hexdigest()
    receipt=json.loads((patch/"provenance.json").read_text())
    engine=patch/"godot.macos.template_release.arm64"
    assert hashlib.sha256(engine.read_bytes()).hexdigest()==receipt["patched_binary_sha256"]
    executable.write_bytes(engine.read_bytes());executable.chmod(0o755)
    subprocess.run(["codesign","--force","--deep","--sign","-",str(app)],check=True)
    subprocess.run(["codesign","--verify","--deep","--strict",str(app)],check=True)
    for name in ("GODOT-MIT-LICENSE.txt","actual.patch","engine-version.txt"):
        (unpacked/name).write_bytes((patch/name).read_bytes())
    provenance={"game_source":os.environ["GITHUB_SHA"],"original_package_sha256":hashlib.sha256(package.read_bytes()).hexdigest(),
        "original_binary_sha256":original_hash,"engine":receipt,
        "scope":"arm64 hosted Mac review candidate, upstream shader mutex backport, actual M5 DEVICE_NOT_RUN",
        "art_status":"ART_REBUILD_REQUIRED","codesign":"ad-hoc verified, not notarized"}
    (unpacked/"ENGINE-PROVENANCE.json").write_text(json.dumps(provenance,indent=2)+"\n")
    archive=out/"Luanshi-macOS-arm64-world-review.zip"
    subprocess.run(["ditto","-c","-k","--keepParent",str(unpacked),str(archive)],check=True)
    provenance["package_sha256"]=hashlib.sha256(archive.read_bytes()).hexdigest()
    (out/"delivery.json").write_text(json.dumps(provenance,indent=2)+"\n")
    print("WHOLE_NATIVE_PACKAGE",json.dumps(provenance),flush=True)
    helper=out/"focus"
    subprocess.run(["clang","-fobjc-arc","-framework","AppKit","-o",str(helper),
                    str(workspace/"tools/macos_probe_focus.m")],check=True)
    pack,=app.glob("Contents/Resources/*.pck")
    assert pack.stat().st_size>1000000
    data=Path.home()/"Library/Application Support/Godot/app_userdata/Luanshi - Border Skirmish"
    with empty_game_data(data):
        text=run_game(executable,out/"input-smoke",helper,["--native-qhd","--menu-only","--light-study"])
        assert "BRIDGE_MENU_INPUT_PASS" in text
    with empty_game_data(data):
        text=run_game(executable,out/"profile-qhd",helper,
                      ["--native-qhd","--real-time-profile","--field-profile"])
        assert "BRIDGE_WINDOW true" in text
        profile=out/"profile-qhd/frame-times";profile.mkdir(parents=True,exist_ok=True)
        for path in (data/"frame-times").glob("*.jsonl"):
            (profile/path.name).write_bytes(path.read_bytes())
    capture=out/"take/native-window.avi"
    try:
        with empty_game_data(data):
            text=run_game(executable,out/"movie",helper,["--native-qhd"],capture)
            assert "BRIDGE_WINDOW true" in text
            subprocess.run([sys.executable,str(workspace/"tools/encode_whole_battle.py"),
                            str(capture),str(out/"movie"),os.environ["GITHUB_SHA"]],check=True)
    except BaseException:
        if capture.is_file() and capture.stat().st_size>4096:
            subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y","-i",str(capture),
                            "-c:v","libx264","-preset","veryfast","-crf","22","-c:a","aac",
                            "-movflags","+faststart",str(out/"movie/incomplete-attempt.mp4")],
                           timeout=180,check=False)
        raise
    print("WHOLE_NATIVE_INPUT_MOVIE_PROFILE_PASS",flush=True)
if __name__=="__main__":main()
