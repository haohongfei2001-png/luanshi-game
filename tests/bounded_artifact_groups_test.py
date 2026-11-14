"""Synthetic transport tests, never gameplay evidence."""
import json,sys,tempfile,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from bounded_artifact_groups import stage,restore
with tempfile.TemporaryDirectory() as t:
    p=Path(t);source=p/'source';source.mkdir()
    (source/'movie.mp4').write_bytes(bytes(range(256))*13)
    (source/'empty.log').write_bytes(b'')
    (source/'metadata.json').write_text('{"test":"synthetic"}')
    result=stage(source,p/'groups',chunk_size=1000,limit=1500)
    assert result['complete'] and len(result['groups'])>=3
    merged=p/'merged';merged.mkdir()
    for group in (p/'groups').iterdir():
        for f in group.iterdir():shutil.copyfile(f,merged/f.name)
    restore(merged,p/'restored')
    assert all((p/'restored'/f.name).read_bytes()==f.read_bytes() for f in source.iterdir())
    movie_record=next(r for r in result['files'] if r['path']=='movie.mp4')
    first=merged/movie_record['chunks'][1]['file'];original=first.read_bytes();first.write_bytes(b'corrupt')
    try:restore(merged,p/'bad')
    except ValueError:pass
    else:raise AssertionError('Corrupt chunks accepted')
    assert not (p/'bad/movie.mp4').exists() and not list((p/'bad').rglob('.restoring-*'))
    first.write_bytes(original)
    restore(merged,p/'bad')  # Reuses previously verified files, never partial content.
    assert (p/'bad/movie.mp4').read_bytes()==(source/'movie.mp4').read_bytes()
    (p/'bad/movie.mp4').write_bytes(b'wrong-existing')
    try:restore(merged,p/'bad')
    except ValueError:pass
    else:raise AssertionError('Existing incorrect file overwritten')
    assert (p/'bad/movie.mp4').read_bytes()==b'wrong-existing'
    try:stage(source,p/'overflow',chunk_size=1000,limit=1500,max_groups=1)
    except ValueError:pass
    else:raise AssertionError('Capacity overflow silently accepted')
    assert not json.loads((p/'overflow/group-00/recovery.json').read_text())['complete']
    manifest=json.loads((merged/'recovery.json').read_text());manifest['files'][0]['path']='../escape'
    (merged/'recovery.json').write_text(json.dumps(manifest))
    try:restore(merged,p/'unsafe')
    except ValueError:pass
    else:raise AssertionError('Unsafe path accepted')
print('BOUNDED_ARTIFACT_GROUPS_SYNTHETIC_PASS')
