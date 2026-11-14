"""Freeze exact full-scene runtime assets and editable authored inputs for reuse."""
import os,sys,json,hashlib,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from bounded_artifact_groups import stage
root=Path.cwd();out=root/'artifacts/basin-recovery';out.mkdir(parents=True,exist_ok=True)
manifest={'source':os.environ.get('GITHUB_SHA'),'profile_source_sha256':hashlib.sha256((root/'scripts/field/authored_landform_profile.gd').read_bytes()).hexdigest(),'art':'NOT_ACCEPTED','assets':[],'missing':[]}
def keep(source,destination):
 if not source.is_file():manifest['missing'].append(str(source));return
 target=out/destination;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
 manifest['assets'].append({'path':str(destination),'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
for path in ['architecture/architecture.glb','ground/continuous-region.scn','woodland/region.scn','shore/region.scn','grass/region.scn']:
 relative=Path('assets/river_authored')/path;keep(root/relative,relative)
for name in ['field-oak','low-grass']:
 source=Path('/tmp')/name
 if source.exists():
  for path in source.rglob('*'):
   if path.suffix in ['.blend','.glb','.png','.json'] and not path.is_symlink():keep(path,Path('editable-sources')/name/path.relative_to(source))
for path in ['docs/evidence/river-authored-reset/sprite-source/SOURCE.json','tools/art/continuous_landform/earth_source.json','tools/art/continuous_landform/shore_source.json']:
 keep(root/path,Path('provenance')/Path(path).name)
(out/'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(stage(out,root/'artifacts/basin-groups',max_groups=5)['groups']))
