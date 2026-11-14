"""Content-addressed, source-verified derivative reuse. Cache is never art acceptance."""
import argparse,hashlib,json,time
from pathlib import Path
BLENDER={'version':'4.3.2','platform':'linux-x86_64','official_archive_sha256':'4da1c956673c0485e63054e563ee69198cc8f80d8157dd7592dffc8a6a5592e6'}
def sha(path):
 h=hashlib.sha256()
 with Path(path).open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()
def canonical(obj):return json.dumps(obj,sort_keys=True,separators=(',',':')).encode()
def recipes(source_root,survey,destination,project=None):
 project=Path(project or Path(__file__).resolve().parents[3]);source_root=Path(source_root);destination=Path(destination);destination.mkdir(parents=True,exist_ok=True)
 license_file=project/'docs/evidence/river-authored-reset/sprite-source/SOURCE.json';license=json.loads(license_file.read_text())
 rows={
  'tree':('lib/env/trees.blend','bake_reusable_collection.py',['EN-tree.1'],'derived.glb'),
  'bush':('lib/env/bushes.blend','bake_native_collection.py',['EN-bush.01'],'derived-EN-bush.01.glb'),
  'ground':('lib/sets/mushroom_grove/mushroom_grove.blend','bake_ground_base.py',['--road-wear','--safe-core'],'ground-approach.glb')}
 result={}
 for kind,(member,script,args,glb) in rows.items():
  recipe={'schema':1,'asset':kind,'official_archive_sha256':license['archive_sha256'],'source_member':member,'source_blend_sha256':sha(source_root/member),'bake_script':script,'bake_script_sha256':sha(project/'tools/art/sprite_source'/script),'blender':BLENDER,'flags':args,'settings_in_hashed_script':True,'source_manifest_sha256':sha(license_file),'license':license['license'],'attribution':license['attribution'],'required_outputs':[glb]+(['source-diffuse-atlas.png','source-normal-atlas.png','source-roughness-atlas.png'] if kind=='bush' else ['diffuse.png','normal.png','roughness.png'])}
  if kind=='ground':recipe['survey_sha256']=sha(survey)
  recipe['cache_key']='luanshi-sprite-derivative-v1-'+kind+'-'+hashlib.sha256(canonical(recipe)).hexdigest()
  (destination/(kind+'.json')).write_text(json.dumps(recipe,indent=2)+'\n');result[kind+'_key']=recipe['cache_key']
 return result
def validate(recipe_file,output,require_stamp=True):
 recipe=json.loads(Path(recipe_file).read_text());output=Path(output)
 if require_stamp and json.loads((output/'verified-recipe.json').read_text())!=recipe:raise ValueError('Recipe/source/Blender/settings changed')
 report=json.loads((output/'complete.json').read_text())
 if report['source_blend_sha256']!=recipe['source_blend_sha256']:raise ValueError('Source blend hash mismatch')
 if recipe['asset']=='ground' and report.get('survey_sha256')!=recipe['survey_sha256']:raise ValueError('Ground survey mismatch')
 outputs=report['outputs_sha256']
 if not set(recipe['required_outputs'])<=set(outputs):raise ValueError('Incomplete GLB/PBR report')
 for name,expected in outputs.items():
  path=output/name
  if Path(name).name!=name or path.is_symlink() or not path.is_file():raise ValueError('Unsafe/missing output: '+name)
  if sha(path)!=expected:raise ValueError('Output hash mismatch: '+name)
 return {'asset':recipe['asset'],'cache_key':recipe['cache_key'],'verified_output_count':len(outputs),'source_blend_sha256':report['source_blend_sha256'],'license':recipe['license'],'attribution':recipe['attribution'],'art_status':'NOT_ACCEPTED'}
def stamp(recipe,output):
 result=validate(recipe,output,False)
 (Path(output)/'verified-recipe.json').write_bytes(Path(recipe).read_bytes())
 return result
def quarantine(output):
 output=Path(output)
 if output.exists():
  saved=output.with_name(output.name+'.invalid-'+str(time.time_ns()));output.rename(saved);print('RETAINED_INVALID_CACHE',saved)
 output.mkdir(parents=True,exist_ok=True)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('mode',choices=['keys','verify','stamp','quarantine']);p.add_argument('paths',nargs='+');a=p.parse_args()
 if a.mode=='keys':
  for key,value in recipes(*a.paths).items():print(key+'='+value)
 elif a.mode=='quarantine':quarantine(*a.paths)
 else:
  try:print(json.dumps((validate if a.mode=='verify' else stamp)(*a.paths)))
  except (ValueError,KeyError,FileNotFoundError,json.JSONDecodeError) as e:print('CACHE_NOT_VERIFIED',str(e));raise SystemExit(1)
