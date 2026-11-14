"""Explicitly stage only the generated intact source character, never imports or caches."""
import hashlib,json,pathlib,subprocess
root=pathlib.Path.cwd();base=root/'assets/ubc_lab'
files=[base/'ubc_animated.glb',base/'retarget-report.json']+list((base/'source').iterdir())
files=[p for p in files if p.is_file() and p.suffix!='.import' and not p.name.endswith('.blend1')]
rows=[{'file':str(p.relative_to(root)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in sorted(files)]
out=root/'docs/evidence/intact-character-adapter/hosted-source.json'
out.write_text(json.dumps({'seed_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'files':rows,'scope':'Native intact-rig technology lab only. Modern source clothes, not accepted historical game art. Not shipping. M5 DEVICE_NOT_RUN.'},indent=2)+'\n')
subprocess.run(['git','add','--',*[str(p.relative_to(root)) for p in files],str(out.relative_to(root))],check=True)
