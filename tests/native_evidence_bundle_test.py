import hashlib,json,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from native_evidence_bundle import curate, RAW
from evidence_steps import attempt
with tempfile.TemporaryDirectory() as temporary:
    root=Path(temporary);source=root/'source';frames=source/'wall-clock-qhd/wall-clock';frames.mkdir(parents=True)
    rows=[]
    for i in range(100):
        name=f'frame-{i:06d}.jpg';(frames/name).write_bytes(bytes([i])*10)
        rows.append({'kind':'frame','file':name,'monotonic_us':i*41667,'state':{'hero_impacts':int(i>=20),'vehicle':int(i==30),'hero_in_frame':True,'hero_hp':100-int(i>=40)}})
    (frames/'frames.jsonl').write_text('\n'.join(map(json.dumps,rows)))
    movie=source/'wall-clock-qhd/wall-clock.mp4';movie.write_bytes(bytes(range(256))*2)
    manifest=curate(source,root/'bundle',chunk_bytes=128)
    selected=[p for p in (root/'bundle').rglob('*.jpg') if RAW.fullmatch(p.name)]
    assert len(selected)<=10 and len(manifest['all_sampled_jpeg_sha256'])==100
    assert not manifest['complete_raw_jpeg_persisted']
    record=next(r for r in manifest['files'] if r['file'].endswith('.mp4'))
    rebuilt=b''.join((root/'bundle'/c['file']).read_bytes() for c in record['chunks'])
    assert rebuilt==movie.read_bytes() and hashlib.sha256(rebuilt).hexdigest()==record['sha256']
    with (frames/'frames.jsonl').open('a') as stream:stream.write('\n{"kind":')
    partial=curate(source,root/'partial-bundle',chunk_bytes=128)
    assert partial['journal_parse_errors'] and (root/'partial-bundle/bundle.json').exists()
    calls=[];failures=[]
    def blocked():raise RuntimeError('synthetic disk preflight failure')
    assert not attempt('capture',blocked,failures,root/'status.json')
    assert attempt('independent-old-movie',lambda:calls.append('ran'),failures,root/'status.json')
    assert calls==['ran'] and json.loads((root/'status.json').read_text())['status']=='NOT_PASSED'
print('NATIVE_EVIDENCE_BUNDLE_SYNTHETIC_PASS')
