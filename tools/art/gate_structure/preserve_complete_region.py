"""Separate verified runtime delivery from packed editable sources; no obsolete shore."""
import hashlib,json,os,sys,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from bounded_artifact_groups import stage
root=Path.cwd(); out=root/'artifacts/complete-runtime';out.mkdir(parents=True,exist_ok=True)
manifest={'source':os.environ.get('GITHUB_SHA'),'art':'NOT_ACCEPTED','profile_sha256':hashlib.sha256((root/'scripts/field/authored_landform_profile.gd').read_bytes()).hexdigest(),'files':[]}
for name in ['architecture/architecture.glb','ground/continuous-region.scn','woodland/region.scn','grass/region.scn']:
 relative=Path('assets/river_authored')/name; source=root/relative
 if not source.is_file():raise RuntimeError('Missing runtime: '+str(relative))
 target=out/relative;target.parent.mkdir(parents=True,exist_ok=True);os.link(source,target)
 manifest['files'].append({'path':str(relative),'bytes':source.stat().st_size,'sha256':hashlib.file_digest(source.open('rb'),'sha256').hexdigest()})
provenance=['tools/art/gate_structure/surface-sources.json','tools/art/continuous_landform/earth_source.json','tools/art/continuous_landform/road_material_sources.json','docs/evidence/river-authored-reset/sprite-source/SOURCE.json','docs/evidence/gate-structure/COMPLETE_REGION_RECOVERY.md']
for name in provenance:
 target=out/'provenance'/Path(name).name;target.parent.mkdir(exist_ok=True);shutil.copy2(root/name,target)
(out/'runtime-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(stage(out,root/'artifacts/complete-runtime-groups',max_groups=5)['groups']))
# Separate artifact: never required by Mac runtime restoration.
editable=root/'artifacts/complete-editable';editable.mkdir()
for name in ['source/architecture.blend','architecture-manifest.json','bearing-audit.json']:
 source=Path('/tmp/complete-gate')/name
 if not source.is_file():raise RuntimeError('Missing editable '+name)
 os.link(source,editable/source.name)
print(json.dumps(stage(editable,root/'artifacts/complete-editable-groups',max_groups=3)['groups']))
