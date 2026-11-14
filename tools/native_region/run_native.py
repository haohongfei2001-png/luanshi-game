"""Bounded real graphical execution on existing ephemeral GitHub macOS runners."""
import argparse, hashlib, json, os, pty, re, select, signal, subprocess, sys, time
from pathlib import Path

ENTRY='application/run/main_loop_type=DotNativeRegionCapture; inert bootstrap scene; no CLI override'

def window_ready(focus,row):
    return focus is not None and row.get('pid')==focus['pid'] and row.get('focused') is True and row.get('display')=='macOS'

def validate_pack_receipt(receipt):
    if receipt.get('entry')!=ENTRY or receipt.get('original_project_restored') is not True or receipt.get('original_export_config_restored') is not True or receipt.get('isolated_pack_setup_passed') is not True:
        raise ValueError('QA pack entry or original configuration restoration not verified')

def validate_engine(patch):
    receipt = json.loads((patch / "provenance.json").read_text())
    executable = patch / "godot.macos.template_release.arm64"
    if receipt["engine_source"] != "35e80b3a8822a9df9be390814b62f44c0a9c69e8":
        raise ValueError("Unexpected engine source")
    if receipt["angle_archive_sha256"] != "9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d":
        raise ValueError("Unexpected ANGLE source")
    if hashlib.sha256(executable.read_bytes()).hexdigest() != receipt["patched_binary_sha256"]:
        raise ValueError("Native engine checksum mismatch")
    return executable, receipt

def run(project, patch, output, helper, mode='baseline'):
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_OS") != "macOS" or sys.platform != "darwin":
        raise RuntimeError("Only disposable authorized GitHub macOS runner; never the owner's computer")
    executable, engine_receipt = validate_engine(patch)
    pack = executable.with_suffix('.pck')
    pack_receipt = json.loads((output/'pack-integrity.json').read_text())
    validate_pack_receipt(pack_receipt)
    if not pack.is_file() or pack.stat().st_size != pack_receipt['bytes'] or hashlib.sha256(pack.read_bytes()).hexdigest() != pack_receipt['sha256']:
        raise ValueError('Adjacent resource pack integrity mismatch')
    output.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(ARCHITECTURE_CAPTURE_OUT=str(output / "pixels"), LUANSHI_AUTHORED_LANDFORM="1",
               RIVER_SOURCE_SHA=env["GITHUB_SHA"])
    master, slave = pty.openpty()
    args = ["/usr/bin/time", "-l", "-o", str(output / "resource-time.log"), str(executable),
            "--rendering-method", "mobile", "--rendering-driver", "metal",
            "--audio-driver", "Dummy", "--disable-vsync", "--"]
    args += ['--camera-study'] if mode=='camera-study' else ['--wall-clock-action','--traversal-review','--shadow-diagnostic']
    process = subprocess.Popen(args, env=env, cwd=project, stdout=slave, stderr=slave,
                               stdin=subprocess.DEVNULL, start_new_session=True)
    os.close(slave)
    started = time.monotonic(); pending = b""; failure = None; focus = None
    startup_probes=[]; probe_times=set()
    def sample_own_child(label, request_focus=False):
        children=subprocess.run(['/usr/bin/pgrep','-P',str(process.pid)],capture_output=True,text=True)
        for child in children.stdout.split():
            if not child.isdecimal():continue
            command=subprocess.run(['/bin/ps','-p',child,'-o','comm='],capture_output=True,text=True)
            if os.path.realpath(command.stdout.strip())!=os.path.realpath(executable):continue
            sample=output/(label+'.sample.txt')
            sampled=subprocess.run(['/usr/bin/sample',child,'1','10','-file',str(sample)],capture_output=True,text=True,timeout=10)
            row={'label':label,'pid':int(child),'elapsed_seconds':time.monotonic()-started,'sample_exit':sampled.returncode}
            if request_focus:
                activated=subprocess.run([str(helper),'foreground',child],capture_output=True,text=True,timeout=8)
                row['early_focus']={'exit':activated.returncode,'stdout':activated.stdout,'stderr':activated.stderr}
            startup_probes.append(row)
            (output/'startup-probes.json').write_text(json.dumps(startup_probes,indent=2))
            return
    with (output / "actual-game.log").open("w") as log:
        def line(raw):
            nonlocal failure, focus
            value = re.sub(r"\x1b\[[0-9;]*m", "", raw.decode(errors="replace").rstrip("\r"))
            print(value, file=log, flush=True)
            if any(x in value for x in ("SCRIPT ERROR", "SHADER ERROR", "ERROR:")):
                failure = "GODOT_ERROR"
            if value.startswith("NATIVE_REGION_FOCUS ") and focus is None:
                row = json.loads(value.partition(" ")[2])
                if row.get('platform')!='macOS' or row.get('display')!='macOS' or row.get('renderer')!='mobile':
                    failure='UNEXPECTED_NATIVE_RENDERER'; return
                # Only this probe's child; no global keyboard or accessibility input.
                child = subprocess.run(["/bin/ps", "-p", str(row["pid"]), "-o", "comm="], capture_output=True, text=True, check=True)
                if os.path.realpath(child.stdout.strip()) != os.path.realpath(executable):
                    failure = "UNVERIFIED_PROCESS_FOR_FOCUS"; return
                focus = {"pid":row["pid"],"phase":"verified entry; awaiting native window event","window_ready":False}
                (output / "focus.json").write_text(json.dumps(focus, indent=2))
            if value.startswith('NATIVE_WINDOW_READY '):
                row=json.loads(value.partition(' ')[2])
                if not window_ready(focus,row):
                    failure='NATIVE_WINDOW_FOCUS_FAILED';return
                focus.update(window_ready=True,phase='native SceneTree window focus observed after event pumping',window=row)
                (output/'focus.json').write_text(json.dumps(focus,indent=2))
            if value.startswith(("NATIVE_REGION_FOCUS", "NATIVE_WINDOW_READY", "REGION_SETUP_", "ARCHITECTURE_CAPTURE_")):
                print(value, flush=True)
        try:
            while time.monotonic() - started < (120 if mode=='camera-study' else 240):
                elapsed=time.monotonic()-started
                for second in (12,45):
                    if focus is None and elapsed>=second and second not in probe_times:
                        probe_times.add(second)
                        # Read only this launched game; capture evidence before a
                        # single early-activation diagnostic, not a global UI bypass.
                        sample_own_child('before-entry-'+str(second),request_focus=second==12)
                ready, _, _ = select.select([master], [], [], .5)
                if ready:
                    try: data = os.read(master, 65536)
                    except OSError: data = b""
                    if not data: break
                    chunks = (pending + data).split(b"\n"); pending = chunks.pop()
                    for chunk in chunks: line(chunk)
                    if failure: break
                elif process.poll() is not None: break
            else: failure = "NATIVE_CAPTURE_TIMEOUT"
            if pending: line(pending)
        finally:
            os.close(master)
            if process.poll() is None and failure: os.killpg(process.pid, signal.SIGTERM)
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL); process.wait(); failure = failure or "EXIT_TIMEOUT"
    receipt = {"source":env["GITHUB_SHA"],"mode":mode,"command":args,"exit":process.returncode,"failure":failure,
               "elapsed_seconds":time.monotonic()-started,"focus":focus,"startup_probes":startup_probes,"engine":engine_receipt,"pack":pack_receipt,
               "M5":"DEVICE_NOT_RUN","art_status":"NOT_ACCEPTED",
               "scope":"Real native Metal execution, readback-instrumented, not performance acceptance"}
    (output / "process.json").write_text(json.dumps(receipt, indent=2))
    if failure or process.returncode: raise RuntimeError(json.dumps(receipt))
    if focus is None or not focus.get('window_ready'): raise RuntimeError("No verified actual native window")
    if not re.search(r'^Metal .*Forward Mobile.*Apple', (output/'actual-game.log').read_text(),re.MULTILINE):
        raise RuntimeError('No actual Metal/Apple adapter log; fallback forbidden')
    return receipt

if __name__ == "__main__":
    p=argparse.ArgumentParser()
    for name in ("project", "patch", "output", "helper"): p.add_argument(name, type=Path)
    p.add_argument('--mode',choices=['baseline','camera-study'],default='baseline')
    a=p.parse_args();print(json.dumps(run(*(getattr(a,n).resolve() for n in ("project","patch","output","helper")),mode=a.mode)))
