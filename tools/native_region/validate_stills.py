"""Integrity/condition gate for real frames, explicitly not visual acceptance."""
from pathlib import Path
import argparse, hashlib, json, math
from PIL import Image

VIEWS = {
    'baseline': {'qhd-after':(2560,1440), 'uhd-after':(3840,2160), 'qhd-after-no-shadow':(2560,1440)},
    'camera-study': {'qhd-perspective-road65':(2560,1440), 'qhd-perspective-road75':(2560,1440), 'uhd-perspective-road65':(3840,2160)},
    'gate-context-study': {'qhd-perspective-road65':(2560,1440), 'qhd-perspective-context65':(2560,1440), 'uhd-perspective-context65':(3840,2160)},
}

def validate_author_context(rows):
    """Geometry projection and source identity, never an artistic quality score."""
    baseline=next(r for r in rows if r['view']=='qhd-perspective-road65')
    first=baseline['single_real_unit_author_oracle']
    hashes=('runtime_architecture_sha256','runtime_ground_sha256','runtime_woodland_sha256')
    fractions=[]
    for row in rows:
        for key in hashes:
            value=row[key]
            if len(value)!=64 or value!=baseline[key]:raise ValueError('Mixed or missing runtime asset identity')
        actor=row['single_real_unit_author_oracle']
        if actor!=first or actor.get('mesh_count')!=43 or actor.get('unit_is_real_hero') is not True:
            raise ValueError('Missing or changed complete one-unit author oracle')
        if actor.get('art_pass') is not False or actor.get('actions_accepted') is not False or actor.get('battle_state_written') is not False:
            raise ValueError('Author probe is not accepted art or mapped gameplay animation')
        if actor.get('single_actor_author_oracle_not_army_runtime') is not True or actor.get('ground_lift_m')!=0:
            raise ValueError('Unexpected actor integration or ground lift')
        if len(actor.get('metadata_sha256',''))!=64 or not actor.get('source_files'):
            raise ValueError('Missing original actor source identity')
        body=row['actual_author_body_projection']; height=body['height_px']; fraction=body['height_fraction']
        if body.get('display_backend')!='macOS' or tuple(body.get('projection_viewport',()))!=VIEWS['gate-context-study'][row['view']]:
            raise ValueError('Body measurement is not from the actual native viewport')
        if not math.isfinite(height) or height<=0 or not math.isfinite(fraction) or not 0<fraction<1:
            raise ValueError('Invalid body projection')
        if not math.isclose(body['boot_bottom_y']-body['top_y'],height,abs_tol=.01) or not math.isclose(height/row['pixels'][1],fraction,abs_tol=1e-6):
            raise ValueError('Inconsistent body projection units')
        if body.get('vertices_checked',0)<=0:raise ValueError('No actual author body points measured')
        fractions.append(fraction)
        profile=row['camera_review_profile']
        pitch=32 if row['view'].endswith('road65') else 38
        if profile.get('projection')!='perspective' or profile.get('pitch_degrees')!=pitch or profile.get('fov_degrees')!=55:
            raise ValueError('Wrong gate-context camera candidate')
        if not math.isclose(math.degrees(row['camera_yaw']),-65,abs_tol=.001):raise ValueError('Wrong context yaw')
        if not math.isclose(row['shader_clock']['fixed_seconds'],6.75,abs_tol=1e-6):raise ValueError('Wrong frozen scene time')
    if (max(fractions)-min(fractions))*1440>.2:
        raise ValueError('New camera resized the actor instead of preserving normal screen scale')

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
    if mode=='gate-context-study':validate_author_context(rows)
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
