"""Preserve verified reproducible inputs even when subsequent GUI evidence fails."""
from pathlib import Path
import json,shutil,sys,hashlib
from bake_recipe_cache import validate
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from bounded_artifact_groups import stage
root=Path.cwd();out=root/'artifacts/derived-recovery';out.mkdir(parents=True,exist_ok=True)
receipt={'source_sha':__import__('os').environ.get('GITHUB_SHA'),'assets':[],'missing':[],'art_status':'NOT_ACCEPTED'}
for kind in ['tree','bush']:
 recipe=Path('/tmp/sprite-recipes')/(kind+'.json');source=Path('/tmp/sprite-'+kind)
 try:
  proof=validate(recipe,source)
  shutil.copytree(source,out/kind)
  receipt['assets'].append(proof)
 except Exception as e:receipt['missing'].append({'asset':kind,'reason':str(e)})
for relative in ['assets/river_authored/ground/continuous-region.scn','assets/river_authored/woodland/region.scn','tools/art/continuous_landform/earth_source.json','docs/evidence/river-authored-reset/sprite-source/SOURCE.json']:
 p=root/relative
 if p.is_file():
  target=out/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target)
  receipt['assets'].append({'path':relative,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'runtime_art_acceptance':False})
 else:receipt['missing'].append({'path':relative})
(out/'recovery-source.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(stage(out,root/'artifacts/derived-groups',max_groups=4)['groups']))
