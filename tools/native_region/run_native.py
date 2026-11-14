"""Bounded real graphical execution on existing ephemeral GitHub macOS runners."""
import argparse, hashlib, json, os, pty, re, select, signal, subprocess, sys, time
from pathlib import Path
from capture_mode import MODES, arguments, capture_budget

ENTRY='application/run/main_loop_type=DotNativeRegionCapture; inert bootstrap scene; no CLI override'

def window_ready(focus,row):
    return focus is not None and row.get('pid')==focus['pid'] and row.get('focused') is True and row.get('display')=='macOS'

def validate_pack_receipt(receipt, mode=None):
    if receipt.get('entry')!=ENTRY or receipt.get('original_project_restored') is not True or receipt.get('original_export_config_restored') is not True or receipt.get('isolated_pack_setup_passed') is not True:
        raise ValueError('QA pack entry or original configuration restoration not verified')
    if mode is not None and receipt.get('validated_capture_mode')!=mode:
        raise ValueError('Pack never validated the requested runtime closure')

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

def diagnostic_command(args, timeout):
    """Optional own-child diagnostics cannot abort capture; never retry or elevate."""
    def text(value):return value.decode(errors='replace') if isinstance(value,bytes) else value or ''
    try:
        r=subprocess.run(args,capture_output=True,text=True,timeout=timeout)
        return {'status':'EXITED','exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr}
    except subprocess.TimeoutExpired as error:
        return {'status':'TIMEOUT','exit':None,'timeout_seconds':timeout,'stdout':text(error.stdout),'stderr':text(error.stderr)}
    except OSError as error:
        return {'status':'OS_ERROR','exit':None,'error':str(error),'stdout':'','stderr':''}

def capture_failure(failure, exit_code, focus, log_text):
    """Capture truth is independent of optional diagnostics; retain first failure."""
    if failure:return failure
    if exit_code != 0:return 'PROCESS_EXIT_NOT_ZERO'
    if focus is None or not focus.get('window_ready'):return 'NATIVE_WINDOW_NOT_VERIFIED'
    if not re.search(r'^Metal .*Forward Mobile.*Apple',log_text,re.MULTILINE):
        return 'NATIVE_METAL_NOT_VERIFIED'
    return None

def run(project, patch, output, helper, mode='baseline'):
    mode_arguments=arguments(mode)
    if os.environ.get("GITHUB_ACTIONS") != "true" or os.environ.get("RUNNER_OS") != "macOS" or sys.platform != "darwin":
        raise RuntimeError("Only disposable authorized GitHub macOS runner; never the owner's computer")
    executable, engine_receipt = validate_engine(patch)
    pack = executable.with_suffix('.pck')
    pack_receipt = json.loads((output/'pack-integrity.json').read_text())
    validate_pack_receipt(pack_receipt,mode)
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
    args += mode_arguments
    process = subprocess.Popen(args, env=env, cwd=project, stdout=slave, stderr=slave,
                               stdin=subprocess.DEVNULL, start_new_session=True)
    os.close(slave)
    started = time.monotonic(); pending = b""; failure = None; focus = None
    startup_probes=[]; probe_times=set(); wrapper_exception=None; cleanup_error=None
    def sample_own_child(label, request_focus=False):
        row={'label':label,'elapsed_seconds':time.monotonic()-started,'optional_diagnostic':True}
        try:
            children=diagnostic_command(['/usr/bin/pgrep','-P',str(process.pid)],5)
            row['child_lookup']=children
            if children['status']!='EXITED' or children['exit']!=0:return
            for child in children['stdout'].split():
                if not child.isdecimal():continue
                command=diagnostic_command(['/bin/ps','-p',child,'-o','comm='],5)
                if command['status']!='EXITED' or command['exit']!=0:row['identity_lookup']=command;continue
                if os.path.realpath(command['stdout'].strip())!=os.path.realpath(executable):continue
                row['pid']=int(child)
                sample=output/(label+'.sample.txt')
                sampled=diagnostic_command(['/usr/bin/sample',child,'1','10','-file',str(sample)],10)
                row['sample']=sampled;row['sample_exit']=sampled['exit']
                if request_focus:row['early_focus']=diagnostic_command([str(helper),'foreground',child],8)
                return
            row['status']='NO_VERIFIED_OWN_GAME_CHILD'
        finally:
            startup_probes.append(row)
            (output/'startup-probes.json').write_text(json.dumps(startup_probes,indent=2))
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
                child = subprocess.run(["/bin/ps", "-p", str(row["pid"]), "-o", "comm="], capture_output=True, text=True, check=True, timeout=5)
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
            while time.monotonic() - started < capture_budget(mode):
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
        except Exception as error:
            wrapper_exception={'type':type(error).__name__,'message':str(error)}
            failure=failure or 'WRAPPER_EXCEPTION'
        finally:
            os.close(master)
            if process.poll() is None and failure:
                try:os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:pass
                except OSError as error:cleanup_error=str(error)
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                failure=failure or "EXIT_TIMEOUT"
                # No retry/alternate signal after an explicit cleanup denial.
                if cleanup_error is None:
                    try:os.killpg(process.pid,signal.SIGKILL)
                    except ProcessLookupError:pass
                    except OSError as error:cleanup_error=str(error)
                if cleanup_error is None:
                    try:process.wait(timeout=5)
                    except subprocess.TimeoutExpired:cleanup_error='Own process did not exit after bounded cleanup'

    failure=capture_failure(failure,process.returncode,focus,(output/"actual-game.log").read_text())
    receipt = {"source":env["GITHUB_SHA"],"mode":mode,"command":args,"exit":process.returncode,"failure":failure,
               "wrapper_exception":wrapper_exception,"cleanup_error":cleanup_error,"elapsed_seconds":time.monotonic()-started,"capture_budget_seconds":capture_budget(mode),"focus":focus,"startup_probes":startup_probes,"engine":engine_receipt,"pack":pack_receipt,
               "M5":"DEVICE_NOT_RUN","art_status":"NOT_ACCEPTED",
               "scope":"Real native Metal execution, readback-instrumented, not performance acceptance"}
    (output / "process.json").write_text(json.dumps(receipt, indent=2))
    if failure: raise RuntimeError(json.dumps(receipt))
    return receipt

if __name__ == "__main__":
    p=argparse.ArgumentParser()
    for name in ("project", "patch", "output", "helper"): p.add_argument(name, type=Path)
    p.add_argument('--mode',choices=MODES,default='baseline')
    a=p.parse_args();print(json.dumps(run(*(getattr(a,n).resolve() for n in ("project","patch","output","helper")),mode=a.mode)))
