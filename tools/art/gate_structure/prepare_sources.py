from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parents[3]
for name,sha in json.loads(Path(__file__).with_name('source-inputs.json').read_text()).items():
 p=root/name
 assert hashlib.sha256(p.read_bytes()).hexdigest()==sha, name
out=root/'assets/river_authored/architecture/source';out.mkdir(parents=True,exist_ok=True);(out/'.gdignore').touch()
shutil.copytree(root/'assets/river_gate/world/masters/modular_wooden_pier',out/'wooden_pier',dirs_exist_ok=True)
print('VERIFIED_EXISTING_CC0_SOURCE_HASHES; no temporary downloads or account required')
