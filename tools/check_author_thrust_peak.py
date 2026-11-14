"""Validate compact measured source evidence, not invented 0.5 contact timing."""
import json
from pathlib import Path
p = Path(__file__).resolve().parents[1] / 'tests/fixtures/author_thrust_peak.json'
x = json.loads(p.read_text())
def projection(row):
    return sum((row['center'][i] - x['baseline_center'][i]) * x['aim'][i] for i in range(3))
peak = max(x['samples'], key=projection)
assert peak['frame'] == x['peak_frame'] == 19
assert x['peak_phase'] == 19 / 36
assert all(.30 <= r['frame'] / 36 <= .70 for r in x['samples'])
assert len(x['source_sha256']) == len(x['report_sha256']) == 64
print('AUTHOR_THRUST_SOURCE_PEAK_PASS frame=19/36; NOT_CONTACT_OR_ART_PASS')
