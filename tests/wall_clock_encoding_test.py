"""Synthetic timestamps test encoding only, not gameplay evidence."""
import json, sys, tempfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from encode_wall_clock_capture import encode
with tempfile.TemporaryDirectory() as temp:
    p=Path(temp);rows=[{'kind':'header','synthetic':True}]
    for i,t in enumerate([1000000,1275000,2210000,2470000]):
        name=f'frame-{i:06d}.jpg';Image.new('RGB',(320,180),(i*70,20,30)).save(p/name)
        rows.append({'kind':'frame','file':name,'monotonic_us':t,'pixels':[320,180],'scale':1,'bytes':(p/name).stat().st_size})
    rows.append({'kind':'end','monotonic_us':3200000,'frames':4})
    (p/'frames.jsonl').write_text('\n'.join(map(json.dumps,rows)))
    r=encode(p,p/'result.mp4');assert abs(r['wall_seconds']-2.2)<1e-9
    assert r['native_frames']==4 and r['max_timestamp_error_s']<=.002
    for bad in [rows[:-1],rows[:2]+[dict(rows[2],monotonic_us=999999)]+rows[3:]]:
        (p/'frames.jsonl').write_text('\n'.join(map(json.dumps,bad)))
        try:encode(p,p/'bad.mp4')
        except ValueError:pass
        else:raise AssertionError('Invalid/incomplete timing accepted')
print('WALL_CLOCK_ENCODING_SYNTHETIC_PASS')

# Reproduce a real irregular cadence with SYNTHETIC pixels. Default B-frame
# reorder previously made stream duration 11.366ms shorter than final PTS.
stamps=json.loads((Path(__file__).parent/'fixtures/wall_clock_reorder_timestamps.json').read_text())['relative_us']
with tempfile.TemporaryDirectory() as temp:
    p=Path(temp);rows=[{'kind':'header','synthetic':True}]
    for i,t in enumerate(stamps[:-1]):
        name=f'frame-{i:06d}.jpg';Image.new('RGB',(320,180),(20,30,40)).save(p/name)
        rows.append({'kind':'frame','file':name,'monotonic_us':t,'pixels':[320,180],'scale':1,'bytes':(p/name).stat().st_size})
    rows.append({'kind':'end','monotonic_us':stamps[-1],'frames':len(stamps)-1})
    (p/'frames.jsonl').write_text('\n'.join(map(json.dumps,rows)))
    result=encode(p,p/'result.mp4')
    assert result['native_frames']==255 and abs(result['encoded_seconds']-result['wall_seconds'])<=.01
    assert result['max_timestamp_error_s']<=.002
print('WALL_CLOCK_REORDER_REGRESSION_SYNTHETIC_PASS')
