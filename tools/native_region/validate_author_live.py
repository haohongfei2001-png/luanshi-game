"""Truthful live-input/camera diagnostic gate, never full action or art approval."""
import argparse,json,math
from pathlib import Path

def validate_rows(rows):
    contracts=[r for r in rows if r.get('kind')=='author_dynamic_contract']
    results=[r for r in rows if r.get('kind')=='author_dynamic_result']
    frames=[r for r in rows if r.get('kind')=='frame']
    camera=[r for r in rows if r.get('kind')=='author_after_draw_camera']
    inputs=[r for r in rows if r.get('kind')=='author_actual_input']
    observations=[r for r in rows if r.get('kind')=='author_render_observation']
    problems=[]
    if len(contracts)!=1 or len(results)!=1:problems.append('MISSING_UNIQUE_BEGIN_OR_END')
    result=results[0] if len(results)==1 else {}
    if result.get('reason')!='review_complete' or result.get('inputs_released') is not True:problems.append('INCOMPLETE_OR_INPUT_NOT_RELEASED')
    if result.get('actual_attack_keydown_events',0)<1:problems.append('NO_ACTUAL_ATTACK_INPUT')
    if len(frames)<2 or any(r.get('pixels')!=[2560,1440] or r.get('scale')!=1 for r in frames):problems.append('MISSING_NATIVE_REAL_FRAMES')
    if not camera:problems.append('NO_POST_DRAW_CAMERA')
    for r in camera:
        p=r.get('review_profile',{})
        if r.get('projection')!=0 or not math.isclose(r.get('fov',0),65,abs_tol=.001) or p.get('pitch_degrees')!=26 or p.get('look_height')!=1.5 or p.get('follow_lead_world')!=[3,0]:problems.append('DESTINATION26_CAMERA_CHANGED');break
        if not math.isclose(r.get('yaw_radians',0),math.radians(-65),abs_tol=.001) or not math.isclose(r.get('pitch_radians',0),math.radians(26),abs_tol=.001):problems.append('DESTINATION26_ANGLE_CHANGED');break
        if len(r.get('camera_center',[]))!=2 or len(r.get('hero_pos',[]))!=2:problems.append('MISSING_FOLLOW_OBSERVATION');break
        if not r.get('transform') or not r.get('projection_matrix'):problems.append('MISSING_ACTUAL_CAMERA_MATRIX');break
    ticks=[r.get('tick',-1) for r in observations]
    positions={tuple(r.get('pos',[])) for r in observations}
    if len(ticks)<2 or max(ticks)<=min(ticks):problems.append('REAL_SIMULATION_DID_NOT_ADVANCE')
    if len(positions)<2:problems.append('NO_ACTUAL_MOVEMENT')
    if not any(r.get('type')=='InputEventAction' and r.get('action')=='move_right' and r.get('pressed') is True for r in inputs):problems.append('NO_REAL_MOVE_INPUT')
    # Native attachment comes from the actual readback, NOT texture metadata.
    by_draw={f.get('engine_drawn'):f for f in frames if isinstance(f.get('engine_drawn'),int)}
    body_pixels=[]
    for sample in camera:
        body=sample.get('body',{})
        if body.get('valid') is not True:continue
        frame=by_draw.get(sample.get('engine_drawn'))
        fraction=body.get('height_fraction',float('nan'))
        if frame is None or not math.isfinite(fraction) or not 0<fraction<1:
            problems.append('BODY_WITHOUT_MATCHED_ACTUAL_ATTACHMENT');continue
        body_pixels.append({'engine_drawn':sample['engine_drawn'],'pixels':frame['pixels'],
                            'height_fraction':fraction,'native_height_px':fraction*frame['pixels'][1],
                            'scope':'same engine_drawn actual JPEG attachment; projected geometry NOT visible silhouette'})
    return {'joined_actual_body_pixels':body_pixels,'input_camera_integrity':'PASS' if not problems else 'FAIL','problems':problems,'frames':len(frames),'post_draw_samples':len(camera),'actual_input_events':len(inputs),'actual_attack_keydowns':result.get('actual_attack_keydown_events',0),'release_transitions_observed':result.get('observed_release_transitions',0),'hero_impacts_delta':result.get('hero_impacts_delta',0),'hit_status':result.get('hit_status','NOT_OBSERVED'),'scope':'ONE_HERO_MIXED_FALLBACK_DIAGNOSTIC; no shield/riding/full army action claim; geometry projection not visible pixel mask','art':'NOT_ACCEPTED','performance':'NOT_MEASURED','M5':'DEVICE_NOT_RUN'}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('journal',type=Path);a=p.parse_args()
    result=validate_rows([json.loads(line) for line in a.journal.read_text().splitlines() if line.strip()]);print(json.dumps(result,indent=2));raise SystemExit(0 if result['input_camera_integrity']=='PASS' else 1)
