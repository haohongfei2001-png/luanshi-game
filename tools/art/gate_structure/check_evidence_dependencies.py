"""Fail early on missing evidence/bootstrap sources in the actual checkout.
Generated resources are an explicit allowlist, not an exemption for missing scripts.
"""
from pathlib import Path
import argparse,json,re,hashlib
GENERATED={'assets/fonts/NotoSansSC-Regular.otf','assets/river_authored/architecture/architecture.glb','assets/river_authored/woodland/region.scn','assets/river_authored/ground/continuous-region.scn','assets/river_authored/shore/region.scn','assets/river_authored/grass/region.scn'}
OUTPUT_OR_OPTIONAL={'artifacts/battle-proof.png','artifacts/campaign-battle-proof.png','assets/build-revision.txt'}
TEXT={'.gd','.gdshader','.gdshaderinc','.tscn','.tres'}
def scan(root,require_generated=False,workflow_name=".github/workflows/dot-architecture-review.yml",scene_mode="all"):
 if scene_mode not in ("all","road-section"):raise ValueError("Unknown scene mode")
 root=Path(root).resolve();workflow=root/workflow_name
 queue=['tools/evidence_steps.py','scenes/game.tscn','tests/authored_architecture_capture.gd','tools/native_evidence_bundle.py','tools/bounded_artifact_groups.py','tools/encode_wall_clock_capture.py','tools/prepare-font.sh']
 queue+=re.findall(r'(?:python(?:3)?|--python|--script)\s+([\w/.-]+\.(?:py|gd))',workflow.read_text())
 seen=set();missing=[];generated=[];hashes={};directories=[]
 while queue:
  path=queue.pop()
  if path in seen:continue
  seen.add(path);file=root/path
  if not file.resolve().is_relative_to(root):raise ValueError('Resource outside checkout')
  if path in OUTPUT_OR_OPTIONAL:continue
  if path in GENERATED:
   # road03 deliberately retired the isolated shore-strip resource. It is
   # loaded only by the older basin branch, not --road-section-study.
   required=not(scene_mode=='road-section' and path=='assets/river_authored/shore/region.scn')
   generated.append({'path':path,'present':file.is_file(),'required_in_selected_scene':required})
   if require_generated and required and not file.is_file():missing.append(path)
   continue
  if file.is_dir():directories.append(path);continue
  if not file.is_file():missing.append(path);continue
  data=file.read_bytes();hashes[path]=hashlib.sha256(data).hexdigest()
  if file.suffix in TEXT:
   for target in re.findall(r'res://([^\"\'\s)]+)',data.decode()):
    if '%' not in target and '{' not in target:queue.append(target)
 return {'selected_scene_mode':scene_mode,'checked_files':len(hashes),'missing':sorted(missing),'generated_resources':generated,'directory_references_require_runtime_setup':directories,'source_file_sha256':hashes,'scope':'static source closure plus explicit generated resources; real clean import/setup still required'}
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--require-generated',action='store_true');p.add_argument('--workflow',default='.github/workflows/dot-architecture-review.yml');p.add_argument('--scene-mode',choices=['all','road-section'],default='all');p.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[3]);a=p.parse_args();result=scan(a.root,a.require_generated,a.workflow,a.scene_mode);print(json.dumps(result,indent=2));raise SystemExit(bool(result['missing']))
