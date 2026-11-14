"""Encode timestamped native snapshots as VFR without shortening wall-clock gaps."""
import argparse, hashlib, json, re, subprocess
from pathlib import Path

def encode(directory: Path, output: Path):
    rows = [json.loads(line) for line in (directory/'frames.jsonl').read_text().splitlines() if line.strip()]
    frames = [r for r in rows if r['kind']=='frame']
    ends = [r for r in rows if r['kind']=='end']
    if len(frames)<2 or len(ends)!=1: raise ValueError('Need at least two real frames and a clean end; partial journal is preserved, not fabricated')
    stamps=[r['monotonic_us'] for r in frames]+[ends[0]['monotonic_us']]
    if any(b<=a for a,b in zip(stamps,stamps[1:])):raise ValueError('Nonmonotonic capture timestamps')
    pixels=frames[0]['pixels']
    if any(r['pixels']!=pixels or r['scale']!=1 for r in frames):raise ValueError('Mixed attachment size or scaled internal rendering')
    lines=['ffconcat version 1.0'];hashes=[]
    for i,row in enumerate(frames):
        if not re.fullmatch(r'frame-\d{6}\.jpg',row['file']):raise ValueError('Invalid frame name')
        path=directory/row['file']
        if not path.is_file() or path.stat().st_size!=row['bytes']:raise ValueError('Missing or truncated frame')
        hashes.append(hashlib.sha256(path.read_bytes()).hexdigest())
        lines.extend([f"file '{row['file']}'",'option framerate 1000',f'duration {(stamps[i+1]-stamps[i])/1e6:.6f}'])
    # Endpoint sentinel establishes the final measured hold; never interpolate gaps.
    lines.extend([f"file '{frames[-1]['file']}'",'option framerate 1000'])
    concat=directory/'wall-clock.ffconcat';concat.write_text('\n'.join(lines)+'\n')
    if output.exists():raise ValueError('Refusing to overwrite prior movie')
    # No B-frame reorder: MP4 duration must include the measured endpoint PTS.
    # Otherwise muxer DTS duration can end before its final presentation frame.
    subprocess.run(['ffmpeg','-nostdin','-v','error','-safe','0','-i',str(concat),'-an','-c:v','libx264','-preset','veryfast','-crf','20','-bf','0','-pix_fmt','yuv420p','-fps_mode','vfr','-enc_time_base','1:1000000','-video_track_timescale','1000000','-movflags','+faststart',str(output)],check=True)
    probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-select_streams','v:0','-show_frames','-show_streams','-of','json',str(output)],text=True))
    actual=[float(f['best_effort_timestamp_time']) for f in probe['frames']]
    expected=[(t-stamps[0])/1e6 for t in stamps]
    if len(actual)!=len(expected):raise ValueError('Encoder duplicated/dropped evidence frames')
    error=max(abs(a-b) for a,b in zip(actual,expected))
    duration=float(probe['streams'][0]['duration']);wall=expected[-1]
    if error>.002 or abs(duration-wall)>.01:raise ValueError(f'Wall-clock timing changed: timestamp_error={error}, duration={duration}, wall={wall}')
    coverage = {
        'mounted_hero_visible_samples': sum(bool(r.get('state',{}).get('hero_in_frame')) and r.get('state',{}).get('vehicle')==1 for r in frames),
        'player_attack_observed': any(r.get('state',{}).get('hero_impacts',0)>0 for r in frames),
        'player_damage_observed': any(r.get('state',{}).get('hero_hp',100)<frames[0].get('state',{}).get('hero_hp',0) for r in frames),
        'player_movement_observed': len({r.get('state',{}).get('hero_pos') for r in frames if r.get('state',{}).get('hero_pos') is not None})>1,
        'shield_contact_observed': any(r.get('state',{}).get('blocks',0)>0 for r in frames),
        'audio': 'NOT_CAPTURED',
    }
    coverage['missing_observations'] = [key for key in ('player_attack_observed','player_damage_observed','player_movement_observed','shield_contact_observed') if not coverage[key]]
    if not coverage['mounted_hero_visible_samples']: coverage['missing_observations'].append('mounted_hero_visible_samples')
    coverage['visual_review_required'] = ['natural weapon grip','shield raising','attack animation','hit animation','riding pose']
    receipt={'source_header':rows[0],'capture_complete':ends[0].get('reason')=='review_complete','action_acceptance':'NOT_ACCEPTED_REQUIRES_REAL_FRAME_REVIEW','sampling_target_fps':1e6/rows[0].get('sample_interval_us',250000),'coverage':coverage,'mode':'REAL_WALL_CLOCK_TIMESTAMPED_VFR','audio':'NOT_CAPTURED','pixels':pixels,'native_frames':len(frames),'terminal_hold_sentinel_frames':1,'wall_seconds':wall,'encoded_seconds':duration,'max_timestamp_error_s':error,'observed_sampling_fps':(len(frames)-1)/((stamps[-2]-stamps[0])/1e6),'end':ends[0],'frame_sha256':hashes,'movie_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'scope':'Readback-instrumented real game; low sampling holds and capture stalls remain visible. Not a performance benchmark.'}
    output.with_suffix('.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return receipt
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('directory',type=Path);parser.add_argument('output',type=Path);args=parser.parse_args()
    print(json.dumps(encode(args.directory,args.output)))
