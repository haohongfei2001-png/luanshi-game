"""Exercise the already exported macOS app through its normal bridgehead menu on a hosted Mac."""
import json, math, os, plistlib, re, shutil, statistics, subprocess, sys, time
from pathlib import Path

out, package = map(Path, sys.argv[1:3])
out.mkdir(parents=True,exist_ok=True)
assert os.environ.get("GITHUB_ACTIONS")=="true" and os.environ.get("RUNNER_OS")=="macOS"
app=next(package.glob("*.app"))
executable=app/"Contents/MacOS"/plistlib.loads((app/"Contents/Info.plist").read_bytes())["CFBundleExecutable"]
def run(cmd,**kw):
    return subprocess.run(cmd,check=True,**kw)
def draw_rows(profile):
    # Ignore a half-written last record while the game is flushing a profiling interval.
    data=profile.read_text()
    return [json.loads(s) for s in data.splitlines(keepends=True) if s.endswith("\n") and s.strip()]
def wait_until(fn,seconds,desc):
    deadline=time.monotonic()+seconds
    while time.monotonic()<deadline:
        v=fn()
        if v: return v
        if proc.poll() is not None: raise RuntimeError("Game exited before "+desc)
        time.sleep(.12)
    raise TimeoutError(desc)
src=Path(os.environ["RUNNER_TEMP"])
panel=src/"bridge-window-mouse"; focus=src/"bridge-activate"
run(["clang","-fobjc-arc","-framework","AppKit","-framework","CoreGraphics","tests/hosted_bridge_input.m","-o",str(panel)])
run(["clang","-fobjc-arc","-framework","AppKit","tools/macos_probe_focus.m","-o",str(focus)])
movie_tool=src/"bridge-window-record"
movie_logs=(out/"wall-clock-capture.log").open("w", buffering=1)
compiled=subprocess.run(["swiftc","-parse-as-library","tests/hosted_bridge_movie.swift","-o",str(movie_tool)],stdout=movie_logs,stderr=movie_logs)
recorder=None
log=out/"bridgehead-native.log"
with log.open("w") as stream:
    proc=subprocess.Popen([str(executable.resolve()),"--resolution","1280x800","--disable-vsync","--","--field-profile"],stdout=stream,stderr=subprocess.STDOUT)
    pid=str(proc.pid)
    try:
        def path_written():
            row=re.search(r"FIELD_PROFILE_FILE (.+)",log.read_text())
            if row: return Path(row[1].strip())
            # A release binary can buffer stdout to a file. The game flushes the
            # per-PID JSONL itself, so discover that same session independently.
            directory=Path.home()/"Library/Application Support/Godot/app_userdata/Luanshi - Border Skirmish/frame-times"
            return next(directory.glob("*-"+pid+".jsonl"),None)
        profile=wait_until(path_written,110,"native field logger")
        wait_until(lambda:any(v["kind"]=="render_attachment" for v in draw_rows(profile)),85,"the first real rendered frame")
        run([str(focus),"foreground",pid])
        def click(x,y): run([str(panel),pid,"click",str(x),str(y)])
        def snap(name):
            attempt=subprocess.run([str(panel),pid,"capture",str((out/name).resolve()),"-"])
            if attempt.returncode: print("WINDOW_STILL_UNAVAILABLE",name,attempt.returncode,flush=True)
        click(145,264)
        time.sleep(.4)
        snap("deployment-menu.png")
        click(167,438)
        # Keep the selected deployment on screen, then compare the window
        # with the bridge and arch in the source recording. Measuring starts
        # only after the normal Deploy button and actual contacts.
        time.sleep(2.4)
        snap("bridgehead-deployment.png")
        if compiled.returncode==0:
            recorder=subprocess.Popen([str(movie_tool),pid,str((out/"hosted-bridgehead.mp4").resolve())],stdout=movie_logs,stderr=movie_logs)
            deadline=time.monotonic()+9
            while time.monotonic()<deadline and recorder.poll() is None:
                if "WINDOW_WRITER_READY" in (out/"wall-clock-capture.log").read_text(): break
                time.sleep(.12)
        click(147,444)
        def rows():
            return [v for v in draw_rows(profile) if v.get("kind")=="frames" and v["end_tick"]>v["start_tick"]]
        wait_until(lambda:rows(),100,"positive simulation ticks after the Deploy button")
        snap("bridgehead-action.png")
        # A screen grab can stall a compositor. Start at a fresh, unexposed
        # 180-frame interval after the capture and discard the intervening bin.
        if recorder is not None:
            try: status=recorder.wait(timeout=43)
            except subprocess.TimeoutExpired: recorder.terminate(); status=recorder.wait(timeout=8)
        else:
            status=compiled.returncode
        movie_logs.flush()
        (out/"window-movie-status.json").write_text(json.dumps({"exit":status,"wall_clock":True,
            "complete":status==0 and "WALL_CLOCK_MOVIE" in (out/"wall-clock-capture.log").read_text()})+"\n")
        first_clean=len(rows())+1
        def sustained():
            sample=rows()[first_clean:]
            return sample if sum(sum(x["raw_wall_ms"]) for x in sample)>=24000 else None
        evidence=wait_until(sustained,85,"24 seconds of uninterrupted live contact")
        shutil.copyfile(profile,out/"native-rows.jsonl")
        wall=[dt for group in evidence for dt in group["raw_wall_ms"]]
        def perc(p): return sorted(wall)[math.ceil(p*len(wall))-1]
        assert all(r["ordinary_rosters"]==[512,512] and r["camera_size"]==22 and r["camera_travel"]<.01 and r["internal_scale"]==1 for r in evidence)
        assert evidence[0]["visible_soldiers"]>170 and evidence[0]["camera_travel"]<.01
        assert sum(r["hits_in_window"] for r in evidence)>0
        adapter=next(v for v in draw_rows(profile) if v["kind"]=="host")
        receipt={"export_sha":adapter["revision"],"host":adapter,"render_px":evidence[0]["render_target_px"],"internal_px":evidence[0]["estimated_internal_px"],
                 "drawn_frames":len(wall),"seconds":sum(wall)/1000,"fps":1000/statistics.fmean(wall),"p50_ms":perc(.5),"p95_ms":perc(.95),"p99_ms":perc(.99),"max_ms":max(wall),
                 "peak_sampled_memory_bytes":max((r["memory_bytes"] or 0) for r in evidence),"draw_preset":evidence[0]["preset"],"hits":sum(r["hits_in_window"] for r in evidence),"losses":evidence[-1]["losses"],"visible":max(r["visible_soldiers"] for r in evidence),"last_tick":evidence[-1]["end_tick"],
                 "ordinary":[512,512],"camera":22,"armies_entered_through_normal_menu":True}
        (out/"native-bridgehead.json").write_text(json.dumps(receipt,indent=2)+"\n")
        print("NATIVE_BRIDGEHEAD",json.dumps(receipt))
    finally:
        if recorder is not None and recorder.poll() is None:
            recorder.terminate()
            try: recorder.wait(timeout=7)
            except subprocess.TimeoutExpired: recorder.kill()
        movie_logs.close()
        if 'profile' in locals() and profile.exists(): shutil.copyfile(profile,out/"native-rows.jsonl")
        if proc.poll() is None:
            proc.terminate()
            try: proc.wait(10)
            except subprocess.TimeoutExpired: proc.kill(); proc.wait()
