"""Read actual exported GLBs. Engineering checks, never a visual/contact verdict."""
import hashlib
import json
import pathlib
import struct
import sys


def read(path):
    raw = path.read_bytes()
    assert raw[:4] == b'glTF'
    n = struct.unpack_from('<I', raw, 12)[0]
    return json.loads(raw[20:20 + n]), raw[28 + n:]


def accessor(doc, binary, index):
    a = doc['accessors'][index]
    assert 'sparse' not in a, 'Sparse data requires a dedicated comparison; do not skip it'
    view = doc['bufferViews'][a['bufferView']]
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    size = {5121: 1, 5123: 2, 5125: 4, 5126: 4}[a['componentType']]
    row_bytes = width * size
    stride = view.get('byteStride', row_bytes)
    start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
    data = b''.join(binary[start + i * stride:start + i * stride + row_bytes]
                    for i in range(a['count']))
    return a, data


def floats(doc, binary, index):
    a, data = accessor(doc, binary, index)
    assert a['componentType'] == 5126
    return struct.unpack('<' + 'f' * (len(data) // 4), data)


def compare(before_path, after_path):
    report_path = after_path.parent / 'retarget-report.json'
    if report_path.exists():
        snapshot = json.loads(report_path.read_text()).get('master_runtime_glb_sha256')
        if snapshot is not None:
            assert hashlib.sha256(before_path.read_bytes()).hexdigest() == snapshot, 'Master changed after retarget; rebuild animation before comparing'
    old, ob = read(before_path)
    new, nb = read(after_path)
    assert len(new['skins']) == 1 and len(new['skins'][0]['joints']) == 163
    assert len(new['animations']) == 9
    assert not any('Body_SourceFull' in m['name'] for m in new['meshes'])
    before_mesh = {m['name']: m for m in old['meshes']}
    assert set(before_mesh) == {m['name'] for m in new['meshes']}
    checks = 0
    for mesh in new['meshes']:
        orig = before_mesh[mesh['name']]
        assert len(orig['primitives']) == len(mesh['primitives'])
        for a, b in zip(orig['primitives'], mesh['primitives']):
            assert a['attributes'].keys() == b['attributes'].keys()
            for key in a['attributes']:
                aa, av = accessor(old, ob, a['attributes'][key])
                ba, bv = accessor(new, nb, b['attributes'][key])
                assert (aa['count'], aa['type'], aa['componentType']) == (ba['count'], ba['type'], ba['componentType'])
                assert av == bv, (mesh['name'], key, 'changed during animation retarget')
                checks += 1
            assert accessor(old, ob, a['indices'])[1] == accessor(new, nb, b['indices'])[1]
            checks += 1
    old_skin, new_skin = old['skins'][0], new['skins'][0]
    assert [old['nodes'][i]['name'] for i in old_skin['joints']] == [new['nodes'][i]['name'] for i in new_skin['joints']]
    assert accessor(old, ob, old_skin['inverseBindMatrices'])[1] == accessor(new, nb, new_skin['inverseBindMatrices'])[1]
    clips = []
    moving_channels = 0
    for animation in new['animations']:
        max_time = 0.
        changes = 0
        for channel in animation['channels']:
            sampler = animation['samplers'][channel['sampler']]
            times = floats(new, nb, sampler['input'])
            values = floats(new, nb, sampler['output'])
            max_time = max(max_time, times[-1])
            width = 4 if channel['target']['path'] == 'rotation' else 3
            first = values[:width]
            if any(abs(values[i] - first[i % width]) > 1e-5 for i in range(len(values))):
                changes += 1
        assert changes > 0, animation['name']
        assert abs(max_time * 30 - round(max_time * 30)) < 5e-6
        clips.append({'name': animation['name'], 'duration': max_time, 'moving_channels': changes})
        moving_channels += changes
    assert any('WEIGHTS_2' in p['attributes'] for m in new['meshes'] for p in m['primitives'])
    return {'geometry_and_weight_accessor_comparisons': checks, 'skin_binds_exact': True,
            'joints': 163, 'full_extra_weight_set_preserved': True,
            'moving_channels_across_clips': moving_channels, 'clips': clips,
            'output_sha256': hashlib.sha256(after_path.read_bytes()).hexdigest(),
            'visual_pass': False, 'contact_pass': False, 'godot_8_weight_limit_resolved': False}


if __name__ == '__main__':
    root = pathlib.Path(sys.argv[1])
    result = compare(root / 'mh_natural_fullweights.glb', root / 'mh_natural_animated_full.glb')
    (root / 'retarget-export-check.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
