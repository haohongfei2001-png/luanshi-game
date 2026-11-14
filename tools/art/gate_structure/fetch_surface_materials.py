"""Fetch only hash-locked public CC0 material files; retain atomic cache integrity."""
from pathlib import Path
import hashlib,json,sys,urllib.request,os
manifest=json.loads(Path(__file__).with_name('surface-sources.json').read_text());out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
for material in manifest['materials'].values():
 for row in material['files']:
  target=out/row['file'];assert target.resolve().is_relative_to(out.resolve())
  def valid(p):return p.is_file() and p.stat().st_size==row['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256']
  if valid(target):continue
  assert row['source_url'].startswith('https://dl.polyhaven.org/file/ph-assets/')
  target.parent.mkdir(parents=True,exist_ok=True);temporary=target.with_suffix(target.suffix+'.part')
  with urllib.request.urlopen(urllib.request.Request(row['source_url'],headers={'User-Agent':'LuanshiDotMaterialIntake/1.0 (CC0 internal production study)'}),timeout=120) as r,temporary.open('wb') as f:
   while chunk:=r.read(512*1024):f.write(chunk)
  assert valid(temporary),'Source hash mismatch: '+row['file'];os.replace(temporary,target)
(out/'source-manifest.json').write_text(json.dumps(manifest,indent=2));print('LOCKED_CC0_GATE_SURFACES_READY',','.join(manifest['materials']))
