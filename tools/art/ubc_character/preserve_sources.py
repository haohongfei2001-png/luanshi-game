"""Copy exact licensed selected upstream files, retaining byte hashes and notices."""
import hashlib,json,pathlib,shutil,sys
root,out=map(pathlib.Path,sys.argv[1:3]);out.mkdir(parents=True,exist_ok=True)
model=next(root.rglob('Superhero_Male_FullBody.gltf'))
data=json.loads(model.read_text())
paths=[model,model.parent/data['buffers'][0]['uri']]
for row in data['images']:
 p=model.parent/row['uri']
 if not p.exists():p=model.parent/row['uri'].replace('_png.png','.png')
 paths.append(p)
paths.append(next(root.rglob('UAL1_Standard.glb')))
paths.append(next(root.rglob('UAL1_Standard_RM.glb')))
rows=[]
for p in dict.fromkeys(paths):
 target=out/p.name;shutil.copyfile(p,target)
 rows.append({'member':str(p.relative_to(root)),'file':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for original,target in [('Universal Base Characters[Standard]/License_Standard.txt','universal-base-characters-standard-LICENSE.txt'),('Universal Animation Library[Standard]/License.txt','ual-standard-current-LICENSE.txt')]:
 assert (root/original).read_bytes()==(out/target).read_bytes(),'License text drift'
(out/'selected-source-manifest.json').write_text(json.dumps({'packages':json.loads((root/'verified-sources.json').read_text()),'files':rows},indent=2)+'\n')
