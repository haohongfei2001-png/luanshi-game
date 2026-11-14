"""Bounded20-per-side actual Metal: two captures, then two no-readback windows.
Existing hosted Mac only; normal adjacent-PCK entry. No engine rebuild fallback.
"""
from pathlib import Path
import os,sys,json,hashlib,subprocess,tempfile,time,pty,select,re,shutil
from entry_config import project_config
editor,project,patch,atlas,out,focus=map(lambda x:Path(x).resolve(),sys.argv[1:])
if sys.platform!='darwin' or os.environ.get('GITHUB_ACTIONS')!='true' or os.environ.get('RUNNER_OS')!='macOS':raise RuntimeError('Existing hosted Mac only')
out.mkdir(parents=True,exist_ok=True)
scale_matrix=os.environ.get('COMPARE_SCALE_MATRIX')=='1'
repeat512=os.environ.get('COMPARE_REPEAT512')=='1'
counts=[512] if repeat512 else ([100,250,512] if scale_matrix else [20])
if repeat512 and not scale_matrix:raise RuntimeError('Repeat requires identical contact-window scale configuration')
exe=patch/'godot.macos.template_release.arm64';pack=exe.with_name('godot.macos.template_release.pck')
if hashlib.sha256(exe.read_bytes()).hexdigest()!='9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3':raise RuntimeError('Unexpected reused engine')
if pack.exists():raise RuntimeError('Prior pack cannot be overwritten')
def checked(name,args,env=None,cwd=None,timeout=240):
 r=subprocess.run(list(map(str,args)),env=env,cwd=cwd,capture_output=True,text=True,timeout=timeout)
 text=r.stdout+r.stderr;(out/name).write_text(text)
 if r.returncode or re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',text):raise RuntimeError(name+' failed '+text[-1000:])
 return text
config=project/'project.godot';preset=project/'export_presets.cfg';old=config.read_bytes();old_preset=preset.read_bytes()
opaque=project/'assets/ubc_lab/ubc-source.glb.bin'
if opaque.exists():raise RuntimeError('Do not overwrite source identity proof')
shutil.copyfile(project/'assets/ubc_lab/ubc_animated.glb',opaque)
env=dict(os.environ,COMPARE_VALIDATE_PACK='1',COMPARE_ASSETS=str(atlas),COMPARE_LOD_TIER='1')
try:
 text=project_config(old.decode())
 # Keep normal startup size; GDScript resizes only after native events/focus.
 config.write_text(text)
 p=old_preset.decode().replace('exclude_filter="tests/*,tools/*,docs/*,artifacts/*,builds/*"','exclude_filter="tests/*,docs/*,artifacts/*,builds/*,.inputs/*,evidence/*"',1).replace('script_export_mode=2','script_export_mode=0',1)
 p=p.replace('include_filter="','include_filter="assets/ubc_lab/*.bin,assets/ubc_lab/NOTICE.md,assets/ubc_lab/source/*.txt,',1);preset.write_text(p)
 checked('export.log',[editor,'--headless','--path',project,'--export-pack','macOS',pack])
finally:
 config.write_bytes(old);preset.write_bytes(old_preset)
with tempfile.TemporaryDirectory(prefix='representation-empty-') as empty:
 closure=checked('empty-pack-closure.log',[editor,'--headless','--main-pack',pack],env=env,cwd=empty)
 if 'REPRESENTATION_COMPLETE_PACK_CLOSURE_PASS' not in closure:raise RuntimeError('Full intended closure not reached')
 provenance={'source':os.environ['GITHUB_SHA'],'pack_sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),'pack_bytes':pack.stat().st_size,'atlas_metadata_sha256':hashlib.sha256((atlas/'atlas.json').read_bytes()).hexdigest(),'original_project_restored':config.read_bytes()==old,'original_preset_restored':preset.read_bytes()==old_preset,'empty_cwd_closure':True,'engine':json.loads((patch/'provenance.json').read_text()),'art_pass':False,'M5':'DEVICE_NOT_RUN'}
 (out/'pack-and-source.json').write_text(json.dumps(provenance,indent=2));shutil.copyfile(atlas/'atlas.json',out/'atlas.json')
 exe.chmod(0o755)
 for count in counts:
  for capture in ([False] if repeat512 else [True,False]):
   for repeat_index,mode in enumerate(['sprite8','shared3d','shared3d','sprite8'] if repeat512 else ['shared3d','sprite8']):
    name=('capture-' if capture else 'profile-')+mode+(f'-{count}' if scale_matrix else '')+(f'-repeat{repeat_index+1}' if repeat512 else '');target=out/name;target.mkdir()
    if repeat512:
     for label,command in [('vm-before',['/usr/bin/vm_stat']),('swap-before',['/usr/sbin/sysctl','vm.swapusage']),('pressure-before',['/usr/bin/memory_pressure','-Q']),('processes-before',['/bin/ps','-A','-o','pid,%cpu,rss,comm'])]:
      snapshot=subprocess.run(command,capture_output=True,text=True,timeout=15);(target/(label+'.txt')).write_text(snapshot.stdout+snapshot.stderr)
      if snapshot.returncode:raise RuntimeError('Read-only resource snapshot failed '+label)
    env=dict(os.environ,COMPARE_MODE=mode,COMPARE_COUNT=str(count),COMPARE_CAMERA_SIZE='12',COMPARE_END_TICK=('570' if count==512 else '370') if scale_matrix else '620',COMPARE_LOD_TIER='1',COMPARE_CAPTURE='1' if capture else '0',COMPARE_OUTPUT=str(target),COMPARE_ASSETS=str(atlas),COMPARE_REQUIRE_METAL='1')
    master,slave=pty.openpty();args=['/usr/bin/time','-l','-o',str(target/'resource-time.log'),str(exe),'--rendering-method','mobile','--rendering-driver','metal','--audio-driver','Dummy','--disable-vsync']
    p=subprocess.Popen(args,cwd=empty,env=env,stdout=slave,stderr=slave,stdin=subprocess.DEVNULL,start_new_session=True);os.close(slave)
    started=time.monotonic();data=bytearray();focused=False;failure=None
    try:
     while time.monotonic()-started<180:
      ready,_,_=select.select([master],[],[],.2)
      if ready:
       try:chunk=os.read(master,65536)
       except OSError:chunk=b''
       if chunk:data.extend(chunk)
       elif p.poll() is not None:break
      if not focused:
       m=re.search(rb'REPRESENTATION_FOCUS (\d+)',data)
       if m:
        pid=m.group(1).decode();parent=subprocess.run(['/bin/ps','-p',pid,'-o','ppid='],capture_output=True,text=True)
        if parent.stdout.strip()!=str(p.pid):raise RuntimeError('Focus child identity mismatch')
        f=subprocess.run([str(focus),'foreground',pid],capture_output=True,text=True,timeout=8);(target/'focus.log').write_text(f.stdout+f.stderr)
        if f.returncode or 'game_active=1' not in f.stdout:raise RuntimeError('Own game activation not verified')
        focused=True
      if p.poll() is not None and not ready:break
     else:failure='CASE_TIMEOUT'
     if failure is None:
      try:p.wait(timeout=10)
      except subprocess.TimeoutExpired:failure='EXIT_TIMEOUT'
    except Exception as error:failure=type(error).__name__+': '+str(error)
    finally:
     os.close(master)
     # No group kill or security workaround; CI cleanup handles a stalled own child.
     log=re.sub(r'\x1b\[[0-9;]*m','',data.decode(errors='replace'));(target/'actual-metal.log').write_text(log)
     (target/'process.json').write_text(json.dumps({'exit':p.returncode,'failure':failure,'process_wall_seconds':time.monotonic()-started,'focused_own_pid':focused,'capture_readback':capture,'performance_source':'raw frame intervals, not this process time','command':args},indent=2))
    if failure or p.returncode or re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',log):raise RuntimeError(name+' failed: '+str(failure)+' '+log[-900:])
    if not re.search(r'Metal .*Forward Mobile.*Apple',log):raise RuntimeError('Actual Apple Metal startup missing')
    if repeat512:
     for label,command in [('vm-after',['/usr/bin/vm_stat']),('swap-after',['/usr/sbin/sysctl','vm.swapusage']),('pressure-after',['/usr/bin/memory_pressure','-Q']),('processes-after',['/bin/ps','-A','-o','pid,%cpu,rss,comm'])]:
      snapshot=subprocess.run(command,capture_output=True,text=True,timeout=15);(target/(label+'.txt')).write_text(snapshot.stdout+snapshot.stderr)
      if snapshot.returncode:raise RuntimeError('Read-only resource snapshot failed '+label)
    print('COMPLETE',name,flush=True)
