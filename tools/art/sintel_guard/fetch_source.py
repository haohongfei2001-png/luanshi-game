"""Recover the exact CC-BY 3.0 r854 master, never run embedded source scripts."""
import argparse,hashlib,json,pathlib,urllib.request,zipfile,os
HERE=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--archive',type=pathlib.Path);p.add_argument('--output',type=pathlib.Path,required=True);p.add_argument('--verify-only',action='store_true');a=p.parse_args()
meta=json.loads((HERE/'license-evidence.json').read_text())['original_package'];members=json.loads((HERE/'source-members.json').read_text())
a.output.mkdir(parents=True,exist_ok=True);archive=a.archive or a.output/'guardians_r854.zip'
if not archive.exists():
 if a.archive:raise FileNotFoundError(archive)
 tmp=archive.with_suffix('.part')
 with urllib.request.urlopen(meta['url'],timeout=120) as response, tmp.open('wb') as f:
  while chunk:=response.read(1024*1024):f.write(chunk)
 os.replace(tmp,archive)
def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  while chunk:=f.read(1024*1024):h.update(chunk)
 return h.hexdigest()
assert archive.stat().st_size==meta['bytes'],'package byte length changed'
assert digest(archive)==meta['sha256'],'package SHA changed: refuse new contents'
with zipfile.ZipFile(archive) as z:
 expected={m['file']:m for m in members};files={i.filename:i for i in z.infolist() if not i.is_dir()}
 assert set(files)==set(expected),'archive file set changed'
 for name,m in expected.items():
  rel=pathlib.PurePosixPath(name);assert not rel.is_absolute() and '..' not in rel.parts
  info=files[name];assert info.file_size==m['bytes'] and f'{info.CRC:08x}'==m['crc32']
  data=z.read(name);assert hashlib.sha256(data).hexdigest()==m['sha256'],name
  if not a.verify_only:
   dest=a.output/'guardians_r854'/name;dest.parent.mkdir(parents=True,exist_ok=True)
   if dest.exists():assert digest(dest)==m['sha256'],'refuse overwriting edited master: '+name
   else:dest.write_bytes(data)
 print(json.dumps({'verified_members':len(expected),'package_sha256':meta['sha256'],'extracted':not a.verify_only,'embedded_scripts_executed':False}))
