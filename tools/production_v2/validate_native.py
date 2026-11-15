"""Exact attachment checks and honest action coverage, never manufactured success."""
import argparse,json,hashlib,struct
from pathlib import Path

def validate_material_control(out):
    report=json.loads((out/'material-control.json').read_text())
    if report.get('error') or report.get('default_enabled') is not False or report.get('original_materials_restored') is not True:raise ValueError('Material control failed or default changed')
    frames=report.get('frames',[])
    if len(frames)!=2 or [r['enabled'] for r in frames]!=[False,True]:raise ValueError('Missing OFF/ON control pair')
    if len({r['non_material_state_sha256'] for r in frames})!=1 or len({r['tick'] for r in frames})!=1:raise ValueError('Control changed pose/camera/Battle/light state')
    for row in frames:
        data=(out/row['file']).read_bytes()
        if data[:8]!=b'\x89PNG\r\n\x1a\n' or struct.unpack('>II',data[16:24])!=(2560,1440) or row['actual_pixels']!=[2560,1440] or row['internal_scale']!=1:raise ValueError('Material frame not native 2K')
    if len(report.get('adapter_receipts',[]))!=7 or any(not r.get('applied') or r.get('surfaces')!=18 for r in report['adapter_receipts']) or report.get('restored_surfaces')!=126:raise ValueError('Material scope differs from seven actual source18 actors')
    return {'scope':'material-only OFF/ON control, visual review still required','same_state':True,'original_materials_restored':True}

def validate(out):
    stills=json.loads((out/'stills.json').read_text())
    if len(stills)!=2 or {tuple(r['actual_pixels']) for r in stills}!={(2560,1440),(3840,2160)}:raise ValueError('Missing exact native2K/4K stills')
    if len({r['battle_snapshot_sha256'] for r in stills})!=1:raise ValueError('Resolution comparison changed Battle')
    for row in stills:
        data=(out/row['file']).read_bytes()
        if data[:8]!=b'\x89PNG\r\n\x1a\n' or list(struct.unpack('>II',data[16:24]))!=row['actual_pixels'] or row['internal_scale']!=1:raise ValueError('Actual PNG attachment disagrees')
    rows=[json.loads(x) for x in (out/'action/frames.jsonl').read_text().splitlines()]
    frames=[r for r in rows if r['kind']=='frame'];ends=[r for r in rows if r['kind']=='end'];results=[r for r in rows if r['kind']=='production_input_result']
    if len(frames)<2 or len(ends)!=1:raise ValueError('Incomplete actual wall recording')
    if any(r['pixels']!=[2560,1440] or r['scale']!=1 for r in frames):raise ValueError('Non-native action frame')
    if any(b['monotonic_us']<=a['monotonic_us'] for a,b in zip(frames,frames[1:])):raise ValueError('Nonmonotonic recording')
    ordinary={};hero=set()
    for frame in frames:
        hero.add(frame['hero_binding'].get('semantic',frame['hero_binding'].get('reason','unknown')))
        for unit in frame['state']['new_ordinary']:
            ordinary.setdefault(str(unit['id']),set()).add(unit['binding'].get('semantic',unit['binding'].get('reason','unknown')))
    observed=set().union(*ordinary.values(),hero)
    missing=sorted({'walk','thrust','hit_chest','death'}-observed)
    return {'native_pixels_verified':True,'frames':len(frames),'duration_seconds':(ends[0]['monotonic_us']-frames[0]['monotonic_us'])/1e6,'observed_hero':sorted(hero),'observed_ordinary':{k:sorted(v) for k,v in ordinary.items()},'missing_requested_actions':missing,'input_results':results,'art':'NOT_ACCEPTED','performance':'READBACK_INSTRUMENTED_NOT_BENCHMARK','M5':'NOT_TESTED','action_scope':'INCOMPLETE' if missing else 'RECORDED_ACTION_NAMES_NOT_VISUAL_ACCEPTANCE'}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();print(json.dumps(validate(a.out),indent=2))
