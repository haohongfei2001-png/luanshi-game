"""Authorized hosted Mac only; adjacent protected PCK, no --script bypass."""
import argparse,hashlib,json,os,pty,re,select,signal,subprocess,sys,tempfile,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'native_region'))
import importlib.util
_spec=importlib.util.spec_from_file_location("legacy_native_engine_validation",Path(__file__).resolve().parents[1]/"native_region/run_native.py")
_engine=importlib.util.module_from_spec(_spec);_spec.loader.exec_module(_engine)
validate_engine=_engine.validate_engine
from export_native_pack import ENTRY,MANIFEST

def run(project,patch,out,helper):
    if sys.platform!='darwin' or os.environ.get('GITHUB_ACTIONS')!='true' or os.environ.get('RUNNER_OS')!='macOS':raise RuntimeError('Hosted authorized Mac only, never user computer')
    executable,engine=validate_engine(patch);pack=executable.with_suffix('.pck');receipt=json.loads((out/'pack-integrity.json').read_text())
    if receipt.get('entry')!=ENTRY or not receipt.get('original_configs_restored') or not receipt.get('isolated_pack_setup_passed'):raise ValueError('Unverified exported entry')
    if pack.stat().st_size!=receipt['bytes'] or hashlib.sha256(pack.read_bytes()).hexdigest()!=receipt['sha256']:raise ValueError('Pack bytes changed')
    env=os.environ|{'LUANSHI_PRODUCTION_V2':'1','PRODUCTION_NATIVE_OUT':str(out/'pixels'),'PRODUCTION_MATERIAL_CONTROL':'1'}
    master,slave=pty.openpty();pending=b'';failure=None;host=None;window=None;completed=None
    with tempfile.TemporaryDirectory(prefix='native-empty-cwd-',dir=out) as empty, (out/'actual-game.log').open('w') as log:
        process=subprocess.Popen([str(executable),'--rendering-method','mobile','--rendering-driver','metal','--audio-driver','Dummy','--disable-vsync','--',MANIFEST],cwd=empty,env=env,stdin=subprocess.DEVNULL,stdout=slave,stderr=slave,start_new_session=True)
        os.close(slave);started=time.monotonic()
        def line(raw):
            nonlocal failure,host,window,completed
            value=re.sub(r'\x1b\[[0-9;]*m','',raw.decode(errors='replace').rstrip('\r'));print(value,file=log,flush=True)
            if any(x in value for x in ['SCRIPT ERROR','SHADER ERROR','ERROR:']):failure=failure or 'GODOT_ERROR'
            if value.startswith('PRODUCTION_NATIVE_FOCUS '):
                host=json.loads(value.split(' ',1)[1])
                if any(type(host.get(key)) is not bool for key in ['debug_build','feature_debug','feature_release','feature_editor']):failure=failure or 'MISSING_ACTUAL_TEMPLATE_MODE'
                if host['pid']!=process.pid or host['display']!='macOS' or host['renderer']!='mobile':failure=failure or 'UNEXPECTED_NATIVE_PROCESS'
                else:
                    try:
                        result=subprocess.run([str(helper),'foreground',str(process.pid)],capture_output=True,text=True,timeout=8)
                        (out/'foreground.json').write_text(json.dumps({'exit':result.returncode,'stdout':result.stdout,'stderr':result.stderr}))
                    except subprocess.TimeoutExpired:failure=failure or 'FOCUS_HELPER_TIMEOUT'
            if value.startswith('PRODUCTION_NATIVE_WINDOW '):window=json.loads(value.split(' ',1)[1])
            if value.startswith('PRODUCTION_NATIVE_COMPLETED '):completed=json.loads(value.split(' ',1)[1])
        try:
            while True:
                if time.monotonic()-started>210:failure=failure or 'BOUND_EXCEEDED';break
                ready,_,_=select.select([master],[],[],.2)
                if ready:
                    try:chunk=os.read(master,65536)
                    except OSError:chunk=b''
                    if chunk:
                        pending+=chunk
                        while b'\n' in pending:raw,pending=pending.split(b'\n',1);line(raw)
                    elif process.poll() is not None:break
                elif process.poll() is not None:break
            if pending:line(pending)
        finally:
            if process.poll() is None:
                os.killpg(process.pid,signal.SIGTERM)
                try:process.wait(timeout=5)
                except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL);process.wait()
            os.close(master)
        if process.returncode!=0:failure=failure or 'NONZERO_EXIT'
        if not window or window.get('focused') is not True:failure=failure or 'NO_ACTUAL_FOCUSED_WINDOW'
        if completed is None:failure=failure or 'NO_FINAL_RECEIPT'
        actual=(out/'actual-game.log').read_text()
        if not re.search(r'^Metal .*Forward Mobile.*Apple',actual,re.M):failure=failure or 'NATIVE_METAL_NOT_OBSERVED'
        result={'failure':failure,'exit':process.returncode,'elapsed_wall_seconds':time.monotonic()-started,'host':host,'window':window,'actual_final':completed,'engine':engine,'scope':'capture process outcome only, not art/contact/performance acceptance'}
        (out/'native-run.json').write_text(json.dumps(result,indent=2)+'\n')
        if failure:raise RuntimeError(failure)
        return result
if __name__=='__main__':
    p=argparse.ArgumentParser()
    for key in ['project','patch','out','helper']:p.add_argument(key,type=Path)
    a=p.parse_args();print(json.dumps(run(*(getattr(a,k).resolve() for k in ['project','patch','out','helper'])),indent=2))
