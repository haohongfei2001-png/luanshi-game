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
    with urllib.request.urlopen(manifest['source_url'],timeout=60) as probe:
        assert probe.status==200
        assert probe.read(4)==b'PK\x03\x04','Not a source ZIP'
    temporary=archive.with_suffix('.partial')
    with urllib.request.urlopen(manifest['source_url'],timeout=90) as source,temporary.open('wb') as target:
        while chunk:=source.read(1024*1024):target.write(chunk)
    assert temporary.stat().st_size==manifest['archive_bytes']
    assert hashlib.sha256(temporary.read_bytes()).hexdigest()==manifest['archive_sha256']
    temporary.replace(archive)
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
