"""Existing pinned hosted Mac Metal template. Not the GLES tangent patch."""
import hashlib,json,subprocess,sys,os,tempfile
from pathlib import Path
editor,project,patch,out=map(lambda s:Path(s).resolve(),sys.argv[1:])
out.mkdir(parents=True,exist_ok=True)
exe=patch/'godot.macos.template_release.arm64';pack=exe.with_suffix('.pck')
provenance=json.loads((patch/'provenance.json').read_text())
assert provenance['engine_source']=='35e80b3a8822a9df9be390814b62f44c0a9c69e8'
assert provenance['angle_archive_sha256']=='9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d'
assert provenance['patched_binary_sha256']==hashlib.sha256(exe.read_bytes()).hexdigest()=='9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3'
assert not pack.exists(),'Refuse to replace old pack'
exe.chmod(0o755)
with (out/'pack-export.log').open('w') as log:subprocess.run([str(editor),'--headless','--path',str(project),'--export-pack','macOS',str(pack)],stdout=log,stderr=subprocess.STDOUT,check=True,timeout=120)
with tempfile.TemporaryDirectory(prefix='empty-pack-',dir=out) as cwd, (out/'packed-setup.log').open('w') as log:
 subprocess.run([str(editor),'--headless','--main-pack',str(pack),'--','--validate-packed'],cwd=cwd,env=os.environ|{'LUANSHI_25D_EXPERIMENT':'1','LUANSHI_25D_OUT':str(out/'packed-setup')},stdout=log,stderr=subprocess.STDOUT,check=True,timeout=90)
text=(out/'packed-setup.log').read_text();assert '25D_PACKED_SETUP ' in text and not any(x in text for x in ['ERROR:','SCRIPT ERROR','Failed loading'])
(out/'engine-pack-receipt.json').write_text(json.dumps({'engine':provenance,'pack_sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),'pack_bytes':pack.stat().st_size,'normal_main_loop':'LuanshiEnvironment25DExperiment','empty_cwd_real_actor_setup':True,'comparison':'official GLES versus existing custom Mobile Metal, renderer+engine difference NOT one-patch GLES isolation','same_assets_materials_camera_topology':True},indent=2))
