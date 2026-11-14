#!/usr/bin/env python3
"""Audit licensed author curves separately from retarget/render acceptance."""
import argparse
import hashlib
import json
from math import dist
from pathlib import Path


def audit(path):
    raw = Path(path).read_bytes()
    data = json.loads(raw)
    c = data['curves']['pike_02']
    frames = c['frames']
    if len(frames) < 2 or not c['source_blob']:
        raise ValueError('Incomplete author curve')
    names = ('hips', 'foot.L', 'foot.R', 'hand.L', 'hand.R')
    travel = {}
    for name in names:
        points = [frame['p'][name] for frame in frames]
        travel[name] = {'extent_xyz_m': [max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)],
                        'start_end_gap_m': dist(points[0], points[-1]),
                        'path_length_m': sum(dist(a,b) for a,b in zip(points,points[1:]))}
    return {'source_sha256': hashlib.sha256(raw).hexdigest(), 'authors': data['authors'],
            'license': data['license'], 'source_blob': c['source_blob'], 'source_path': c['source_path'],
            'source_duration_s': c['duration'], 'sample_count': len(frames),
            'bind_matrix_error': c['bind_matrix_error'], 'motion': travel,
            'source_curves_modified': False, 'source_motion_is_not_world_contact': True,
            'godot_visual_pass': False}


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source_curves'); p.add_argument('--output', required=True)
    a=p.parse_args()
    result=audit(a.source_curves)
    Path(a.output).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))
