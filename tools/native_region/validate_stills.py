"""Integrity/condition gate for real frames, explicitly not visual acceptance."""
from pathlib import Path
import argparse, hashlib, json, math
from PIL import Image

VIEWS = {
    'baseline': {'qhd-after':(2560,1440), 'uhd-after':(3840,2160), 'qhd-after-no-shadow':(2560,1440)},
    'camera-study': {'qhd-perspective-road65':(2560,1440), 'qhd-perspective-road75':(2560,1440), 'uhd-perspective-road65':(3840,2160)},
}

def validate_records(rows, source, mode):
    views=VIEWS[mode]
    if len(rows)!=len(views) or {r['view'] for r in rows}!=set(views):
        raise ValueError('Missing, duplicate or unexpected actual frame')
    snapshot=rows[0]['battle_snapshot_sha256']
    if len(snapshot)!=64:raise ValueError('Missing frozen Battle hash')
    for row in rows:
        expected=views[row['view']]
        if row['source']!=source or row['battle_snapshot_sha256']!=snapshot:
            raise ValueError('Mixed source or Battle state')
        if row['internal_scale']!=1 or any(tuple(row[key])!=expected for key in ('pixels','internal_pixels','attachment_size','viewport')):
            raise ValueError('Not native requested pixels')
        if str(row['seed'])!='61112' or row['tick']!=135 or row['ordinary']!=[20,20]:
            raise ValueError('Unexpected fixture; do not imply a different army benchmark')
        if mode=='camera-study':
            p=row['camera_review_profile']
            if p != {'projection':'perspective','nominal_body_fraction':.10,'pitch_degrees':32.,'fov_degrees':55.}:
                raise ValueError('Wrong experimental camera profile')
            yaw=-75 if row['view'].endswith('road75') else -65
            if not math.isclose(math.degrees(row['camera_yaw']),yaw,abs_tol=.001):
                raise ValueError('Wrong actual camera yaw')
    return snapshot

def validate(directory, source, mode):
    rows=json.loads((directory/'receipt.json').read_text())
    snapshot=validate_records(rows,source,mode)
    if hashlib.sha256((directory/'battle-snapshot.bin').read_bytes()).hexdigest()!=snapshot:
        raise ValueError('Frozen Battle file hash mismatch')
    files=[]
    for row in rows:
        p=directory/(row['view']+'.png')
        with Image.open(p) as im:
            if im.format!='PNG' or im.size!=VIEWS[mode][row['view']]:raise ValueError('Actual PNG mismatch')
            im.verify()
        files.append({'view':row['view'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
    return {'source':source,'mode':mode,'frame_integrity':'PASS','files':files,'battle_snapshot_sha256':snapshot,
            'art':'NOT_ACCEPTED_REQUIRES_PIXEL_REVIEW','performance':'NOT_MEASURED','M5':'DEVICE_NOT_RUN',
            'scope':'Native actual-frame integrity only; nominal adult box is not measured character readability'}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('directory',type=Path);p.add_argument('source');p.add_argument('--mode',choices=VIEWS,default='baseline');a=p.parse_args()
    print(json.dumps(validate(a.directory,a.source,a.mode),indent=2))
