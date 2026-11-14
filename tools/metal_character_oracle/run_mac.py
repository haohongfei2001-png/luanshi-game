"""Existing disposable hosted Mac only. Normal adjacent PCK, no path overrides."""
import shutil,os,sys,pathlib,json,hashlib,subprocess,tempfile,pty,select,time,signal,re
editor,project,patch,out,focus=map(lambda s:pathlib.Path(s).resolve(),sys.argv[1:])
if sys.platform!='darwin' or os.environ.get('GITHUB_ACTIONS')!='true' or os.environ.get('RUNNER_OS')!='macOS':raise RuntimeError('Hosted Mac runner only, never user computer')
out.mkdir(parents=True,exist_ok=True)
exe=patch/'godot.macos.template_release.arm64'
assert hashlib.sha256(exe.read_bytes()).hexdigest()=='9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3'
provenance=json.loads((patch/'provenance.json').read_text());assert provenance['engine_source']=='35e80b3a8822a9df9be390814b62f44c0a9c69e8'
pack=patch/'godot.macos.template_release.pck';assert not pack.exists()
# Exporter omits imported original GLB even with include_filter. Preserve exact
# source as opaque bytes for provenance, distinct from runtime importer derivative.
shutil.copyfile(project/'assets/ubc_lab/ubc_animated.glb',project/'assets/ubc_lab/ubc-source.glb.bin')
(project/'export_presets.cfg').write_text('''[preset.0]
name="OracleMac"
platform="macOS"
runnable=true
export_filter="all_resources"
include_filter="fixture-manifest.json,assets/ubc_lab/*.bin,assets/ubc_lab/NOTICE.md,assets/ubc_lab/source/*.txt"
exclude_filter=""
script_export_mode=0
[preset.0.options]
export/distribution_type=1
binary_format/architecture="universal"
application/bundle_identifier="com.luanshi.oracle"
texture_format/s3tc_bptc=true
texture_format/etc2_astc=true
''')
def checked(name,args,env=None,cwd=None,timeout=180):
 r=subprocess.run(list(map(str,args)),cwd=cwd,env=env,capture_output=True,text=True,timeout=timeout);log=r.stdout+r.stderr;(out/name).write_text(log)
 if r.returncode or re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',log):raise RuntimeError(name+' failed: '+log[-1500:])
 return log
checked('export.log',[editor,'--headless','--path',project,'--export-pack','OracleMac',pack])
empty=pathlib.Path(tempfile.mkdtemp(prefix='oracle-empty-'));env=os.environ.copy();env['INTACT_VALIDATE_PACK']='1'
log=checked('pack-empty-cwd.log',[editor,'--headless','--main-pack',pack],env=env,cwd=empty)
assert 'METAL_ORACLE_PACK_CLOSURE_PASS' in log
receipt={'source':os.environ['GITHUB_SHA'],'pack_bytes':pack.stat().st_size,'pack_sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),'normal_entry':'MetalCharacterOracleGPU, inert Node bootstrap','empty_cwd_closure':True,'engine':provenance,'art_pass':False,'M5':'NOT_TESTED'}
(out/'pack-and-engine.json').write_text(json.dumps(receipt,indent=2))
exe.chmod(0o755);env=os.environ.copy();env.update(INTACT_REQUIRE_METAL='1',INTACT_PARITY_FULL_MESH='1',INTACT_OUTPUT=str(out/'gpu'))
master,slave=pty.openpty();p=subprocess.Popen([str(exe),'--rendering-method','mobile','--rendering-driver','metal','--audio-driver','Dummy','--disable-vsync'],cwd=empty,env=env,stdout=slave,stderr=slave,stdin=subprocess.DEVNULL,start_new_session=True);os.close(slave)
start=time.monotonic();data=bytearray();activated=False;failure=None
try:
 while time.monotonic()-start<240:
  ready,_,_=select.select([master],[],[],.2)
  if ready:
   try:chunk=os.read(master,65536)
   except OSError:chunk=b''
   if not chunk:break
   data.extend(chunk)
  if not activated and time.monotonic()-start>2 and p.poll() is None:
   # Own launched PID only, no global input or accessibility access.
   a=subprocess.run([str(focus),'foreground',str(p.pid)],capture_output=True,text=True,timeout=8);(out/'own-process-focus.log').write_text(a.stdout+a.stderr);activated=True
  if p.poll() is not None and not ready:break
 else:failure='actual Metal oracle timed out'
finally:
 os.close(master)
 if p.poll() is None:
  os.killpg(p.pid,signal.SIGTERM)
  try:p.wait(timeout=8)
  except subprocess.TimeoutExpired:os.killpg(p.pid,signal.SIGKILL);p.wait()
text=re.sub(r'\x1b\[[0-9;]*m','',data.decode(errors='replace'));(out/'actual-metal.log').write_text(text)
receipt.update(exit=p.returncode,wall_seconds=time.monotonic()-start,failure=failure,command='normal adjacent PCK; mobile/metal; no script/path/main-pack override');(out/'process.json').write_text(json.dumps(receipt,indent=2))
if failure or p.returncode or re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',text):raise RuntimeError('Actual Metal failed: '+text[-1800:])
if not re.search(r'Metal .*Forward Mobile.*Apple',text):raise RuntimeError('No actual Apple Metal startup evidence')
print('Actual Metal process completed. External strict PNG gate still required.')
