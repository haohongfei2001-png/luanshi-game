"""Synthetic parser regression only; never counts as measured game performance."""
import json, os, subprocess, tempfile
from pathlib import Path
with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    for mode, size, values in [('qhd', [2560, 1440], [10., 20., 30.]), ('uhd', [3840, 2160], [20., 40., 60.])]:
        folder = root / f'profile-{mode}-20'
        (folder / 'frame-times').mkdir(parents=True)
        rows = [{'kind': 'host', 'platform': 'SYNTHETIC'}, {'kind': 'frames', 'raw_wall_ms': values,
                 'render_target_px': size, 'internal_scale': 1, 'sim_cpu_ms': 1., 'view_script_ms': 2., 'render_gpu': None}]
        (folder/'frame-times/test.jsonl').write_text(''.join(json.dumps(row)+'\n' for row in rows))
        (folder/'input-and-camera.json').write_text(json.dumps({'ordinary':[20,20], 'wall_seconds':45.,
            'last':{'hits':[2,3]}, 'scene_composition':{'layout':'river-pass-master-v1'}, 'frames':[{'sampled_offscreen_contacts':2}]}))
        (folder/'resource-time.log').write_text('12345 maximum resident set size\n23456 peak memory footprint\n')
    env = dict(os.environ, GITHUB_SHA='SYNTHETIC', GITHUB_RUN_ID='SYNTHETIC')
    subprocess.run(['python','tools/summarize_native_profiles.py',str(root)],env=env,check=True,stdout=subprocess.DEVNULL)
    report = json.loads((root/'native-performance.json').read_text())
    assert len(report['profiles']) == 2
    a,b = report['profiles']
    assert a['render_px']==[2560,1440] and b['render_px']==[3840,2160]
    assert a['p50_ms']==20. and b['p99_ms']==60.
    assert a['maximum_rss_bytes']==12345 and b['sampled_offscreen_contacts']==2
    assert all(row['sampling_status']=='INSUFFICIENT_WINDOW' for row in report['profiles'])
    assert not report['movie_frame_cadence_used_for_fps']
print('NATIVE_PROFILE_SUMMARY_SYNTHETIC_PASS')
