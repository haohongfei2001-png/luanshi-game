"""Preserve the entire one-actor oracle, not a production army format."""
import gzip,hashlib,json,os,pathlib,sys,tarfile
root,out=map(pathlib.Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()
meta=json.loads((root/'character.json').read_text())
archive=out/'cache.tar.gz'
with archive.open('wb') as raw,gzip.GzipFile(fileobj=raw,mode='wb',mtime=0) as gz,tarfile.open(fileobj=gz,mode='w|') as tar:
 for p in sorted(root.rglob('*')):
  if p.is_file():
   info=tar.gettarinfo(str(p),arcname='cache/'+str(p.relative_to(root)));info.mtime=0;info.uid=info.gid=0;info.uname=info.gname=''
   with p.open('rb') as f:tar.addfile(info,f)
parts=[]
with archive.open('rb') as f:
 for i in range(int(os.getenv('CACHE_PART_LIMIT','10'))):
  b=f.read(24*1024*1024)
  if not b:break
  p=out/f'cache.part{i:02d}';p.write_bytes(b);parts.append({'file':p.name,'bytes':len(b),'sha256':sha(p)})
 if f.read(1):raise RuntimeError('Cache exceeds configured independently downloadable parts; no incomplete manifest')
manifest={'source_commit':os.getenv('GITHUB_SHA','local'),'kind':'single actor oracle, NOT army runtime','art_pass':False,'archive_sha256':sha(archive),'archive_bytes':archive.stat().st_size,'parts':parts,'source_files':meta['source_files'],'character_json_sha256':sha(root/'character.json'),'files':[{'path':str(p.relative_to(root)),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(root.rglob('*')) if p.is_file()],'restore':'Verify each listed part SHA, concatenate in manifest order as cache.tar.gz, verify archive SHA, then tar -xzf cache.tar.gz. Validate every extracted member SHA before use.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(out/'ATTRIBUTION.md').write_text('''# Experimental derived soldier oracle
Guardian r854 original by Blender Foundation / Sintel Durian contributors, CC BY 3.0: https://durian.blender.org/sharing/ and https://durian.blender.org/news/guardians-community-help/ . Attribution and exact source members: tools/art/sintel_guard/license-evidence.json and source-members.json at source_commit. This is an extensively modified early source, NOT the film final or an approved Chinese soldier.
MakeHuman official body/face/eyes textures and skeleton: CC0; pinned source recovery tools/art/mh_character at b778bc0f016a7d339fcd8459e6b622387ad3a755. UAL donor animation: Quaternius, exact CC0 June 2026 Standard package in assets/ubc_lab/source/package-license-manifest.json and ual-standard-current-LICENSE.txt.
Modifications include complete recut clothing, added armor/helmet/spear, young head module, original-rig authored walk/thrust, evaluated pose cache, derived LOD and approximate real-time materials. Original complete editable sources remain separately recoverable. Foot contact, grip, animation and visual quality have NOT passed. Not a production crowd format.
''')
archive.unlink() # all complete chunks and full verification receipt retained
print(json.dumps({'parts':len(parts),'archive_bytes':manifest['archive_bytes'],'archive_sha256':manifest['archive_sha256']}))
