"""Fetch official CC-BY 4.0 source with exact archive and member hashes.
No archive scripts executed. Never extract links or paths outside destination.
"""
from pathlib import Path
import hashlib,json,sys,urllib.request,zipfile,stat
root=Path(__file__).resolve().parents[3]
manifest=json.loads((root/'docs/evidence/river-authored-reset/sprite-source/SOURCE.json').read_text())
cache=Path(sys.argv[1]);cache.mkdir(parents=True,exist_ok=True)
archive=cache/'sprite-source.zip'
if not archive.exists():
    # Blender's published mirror list, same immutable archive/hash, no login bypass.
    urls=[manifest['source_url'],manifest['source_url'].replace('https://download.blender.org/','https://ftp.halifax.rwth-aachen.de/blender/')]
    errors=[]
    for url in urls:
        temporary=archive.with_suffix('.partial')
        try:
            with urllib.request.urlopen(url,timeout=90) as source,temporary.open('wb') as target:
                assert source.status==200
                while chunk:=source.read(1024*1024):target.write(chunk)
            assert temporary.stat().st_size==manifest['archive_bytes']
            assert hashlib.sha256(temporary.read_bytes()).hexdigest()==manifest['archive_sha256']
            temporary.replace(archive)
            print('VERIFIED_OFFICIAL_SOURCE',url)
            break
        except Exception as error:
            errors.append(str(error))
            print('SOURCE_ATTEMPT_FAILED',url,type(error).__name__,str(error))
    if not archive.exists():raise RuntimeError('All official mirrors failed: '+repr(errors))
assert archive.stat().st_size==manifest['archive_bytes']
assert hashlib.sha256(archive.read_bytes()).hexdigest()==manifest['archive_sha256']
destination=cache/'unpacked';destination.mkdir(exist_ok=True)
with zipfile.ZipFile(archive) as z:
    for info in z.infolist():
        target=(destination/info.filename).resolve()
        assert target.is_relative_to(destination.resolve()),info.filename
        assert not stat.S_ISLNK(info.external_attr>>16),info.filename
    z.extractall(destination)
roots=list(destination.glob('**/lib/env/trees.blend'));assert len(roots)==1
source_root=roots[0].parents[2]
for member,sha in manifest['source_files'].items():
    assert hashlib.sha256((source_root/member).read_bytes()).hexdigest()==sha,member
(cache/'source-root.txt').write_text(str(source_root))
print(json.dumps({'source_root':str(source_root),'sha256':manifest['archive_sha256'],'license':manifest['license'],'attribution':manifest['attribution']}))
