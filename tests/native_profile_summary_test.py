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
    initial=subprocess.run(['python','tools/summarize_native_profiles.py',str(root)],env=env,stdout=subprocess.DEVNULL)
    assert initial.returncode==1  # short samples retain metrics but never complete coverage
    report = json.loads((root/'native-performance.json').read_text())
    assert len(report['profiles']) == 2
    a,b = report['profiles']
    assert a['render_px']==[2560,1440] and b['render_px']==[3840,2160]
    assert a['p50_ms']==20. and b['p99_ms']==60.
    assert a['maximum_rss_bytes']==12345 and b['sampled_offscreen_contacts']==2
    assert all(row['sampling_status']=='INSUFFICIENT_WINDOW' for row in report['profiles'])
    assert not report['movie_frame_cadence_used_for_fps']
    assert report['profile_coverage']=='NOT_ACCEPTED'
    qhd=root/'profile-qhd-20/frame-times/test.jsonl'
    original=qhd.read_text()
    for invalid in [0.,float('nan'),float('inf'),-1.,True]:
        rows=[json.loads(line) for line in original.splitlines()]
        rows[1]['raw_wall_ms']=[invalid]
        qhd.write_text(''.join(json.dumps(row)+'\n' for row in rows))
        result=subprocess.run(['python','tools/summarize_native_profiles.py',str(root)],env=env,stdout=subprocess.DEVNULL)
        assert result.returncode==1
        result_rows=json.loads((root/'native-performance.json').read_text())['profiles']
        assert result_rows[0]['status']=='FAILED' and 'average_fps' not in result_rows[0]
        assert result_rows[1]['status']=='MEASURED_HOSTED_ONLY'
    qhd.write_text(original)
    originals={folder: (folder/'frame-times/test.jsonl').read_text() for folder in root.glob('profile-*')}
    for folder,text in originals.items():
        rows=[json.loads(line) for line in text.splitlines()]
        rows[1]['raw_wall_ms']=[100.]*120
        (folder/'frame-times/test.jsonl').write_text(''.join(json.dumps(row)+'\n' for row in rows))
    full=subprocess.run(['python','tools/summarize_native_profiles.py',str(root)],env=env,stdout=subprocess.DEVNULL)
    assert full.returncode==0
    assert json.loads((root/'native-performance.json').read_text())['profile_coverage']=='COMPLETE'
    for folder,text in originals.items(): (folder/'frame-times/test.jsonl').write_text(text)
    # Missing/failed attempts must not erase independent successful measurements.
    (root/'expected-profiles.json').write_text(json.dumps(['profile-qhd-20','profile-uhd-20','profile-qhd-512']))
    (root/'profile-uhd-20'/'attempt.json').write_text(json.dumps({'status':'FAILED'}))
    result=subprocess.run(['python','tools/summarize_native_profiles.py',str(root)],env=env,stdout=subprocess.DEVNULL)
    assert result.returncode == 1
    profiles={r['scenario']:r for r in json.loads((root/'native-performance.json').read_text())['profiles']}
    assert profiles['profile-qhd-20']['status']=='MEASURED_HOSTED_ONLY'
    assert profiles['profile-uhd-20']['status']=='FAILED'
    assert profiles['profile-qhd-512']['status']=='MISSING'
    assert 'average_fps' not in profiles['profile-qhd-512']
print('NATIVE_PROFILE_SUMMARY_SYNTHETIC_PASS')
