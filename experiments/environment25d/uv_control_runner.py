"""One pending-review, native Metal UV control. No upload or CI-dispatch code.

Preparation uses only the already public 1cbdc20 project and 01fb175 resources.
No geometry generation, new texture, resampling, battle stepping or camera move.
"""
import argparse, hashlib, json, os, struct, subprocess, tempfile, time
from pathlib import Path

ENGINE_SHA = '9cb81197d4402a2b5b57719ba7f89616b90ebbb33e88dbb6dbab7c588fc036d3'
ENGINE_SOURCE = '35e80b3a8822a9df9be390814b62f44c0a9c69e8'
ANGLE_SHA = '9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d'

def require(value, message):
    if not value:
        raise RuntimeError(message)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def preflight(project):
    contract = json.loads((project / 'uv_control_sources.json').read_text())
    receipts = []
    for item in contract['files']:
        path = project / item['path']
        require(path.is_file(), 'Missing unchanged public source: ' + item['path'])
        actual = sha(path)
        require(actual == item['sha256'], 'Public source changed: ' + item['path'])
        receipts.append({'path': item['path'], 'sha256': actual})
    return {'public_baseline': contract['public_baseline'], 'public_adapter': contract['public_adapter'],
            'verified': receipts, 'not_an_art_or_renderer_acceptance': True}

def run_logged(command, logfile, env, cwd, seconds=120):
    start = time.monotonic()
    record = {'command': command, 'cwd': str(cwd), 'timeout_seconds': seconds}
    try:
        with logfile.open('w') as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                                    env=env, cwd=cwd, timeout=seconds)
        record['returncode'] = result.returncode
    except subprocess.TimeoutExpired:
        record['timed_out'] = True
        raise
    finally:
        record['monotonic_wall_seconds'] = time.monotonic() - start
        logfile.with_suffix('.process.json').write_text(json.dumps(record, indent=2))
    require(result.returncode == 0, 'Process failed; all original log/frames retained: ' + logfile.name)
    return record

def validate(result, cpu=False):
    require(result['cpu_only'] is cpu, 'Unexpected CPU/GPU mode')
    require(not result['failures'], 'Runtime gates failed')
    require(result['all_actor_count'] == 11 and result['other_kit_proxy_count'] == 8, 'Original scene population changed')
    require(result['battle_tick'] == 0, 'Not original tick0')
    require(len(result['selected_ids']) == 11 and result['projected_clear_candidates'] >= 7, 'Insufficient projected existing actors')
    require(len(result['application_receipts']) == 11, 'Not all original actors processed')
    require(all(x['result']['surfaces'] == 18 and x['result']['applied'] for x in result['application_receipts']), 'Affected surface mismatch')
    require(result['restored_surfaces'] == 198, 'Restore incomplete')
    require([s['stage'] for s in result['stages']] == ['OFF', 'ON', 'RESTORED_OFF'], 'Incomplete control')
    require(len({s['snapshot']['signature'] for s in result['stages']}) == 1, 'Scene/pose/state mismatch')
    require(result['stages'][0]['material_signature'] == result['stages'][2]['material_signature'] == result['initial_material_signature'], 'Original material identities not restored')
    require(result['camera']['projection_name'] == 'ORTHOGONAL' and result['camera']['size'] == 22.0, 'Camera changed')
    require(abs(result['camera']['distance_to_existing_focus'] - 56.5685424949) < .0001, 'Not the original actual camera distance')
    if not cpu:
        require(result['engine']['renderer'] == 'mobile' and result['engine']['features']['macos'], 'Not native Mac Mobile')
        require(bool(result['engine']['device']), 'GPU device not recorded')
        require(result['render']['internal_3d_scale'] == 1.0, 'Internal resolution scale changed')
        require(all(s['pixels'] == [2560, 1440] and s['save_error'] == 0 for s in result['stages']), 'Not three original native 2K frames')
        require(result['stages'][0]['raw_pixel_sha256'] == result['stages'][2]['raw_pixel_sha256'], 'Restored OFF pixel mismatch')
        require(result['stages'][0]['raw_pixel_sha256'] != result['stages'][1]['raw_pixel_sha256'], 'No visible OFF/ON change: inconclusive, never repair by moving camera')
        require(all(s['background_tile_control']['tiles_changed'] == 0 for s in result['stages'][1:]), 'Background/temporal instability: UV-only attribution fails, keep all originals')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).parent)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--preflight-only', action='store_true')
    parser.add_argument('--editor', type=Path)
    parser.add_argument('--engine-dir', type=Path)
    args = parser.parse_args()
    project, out = args.project.resolve(), args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    require(not (out / 'source-preflight.json').exists(), 'Refuse to overwrite an earlier control output')
    receipt = preflight(project)
    (out / 'source-preflight.json').write_text(json.dumps(receipt, indent=2))
    if args.preflight_only:
        print('SOURCE_PREFLIGHT_PASS; no renderer started')
        return
    require(args.editor and args.engine_dir, 'Editor and existing pinned engine directory required')
    editor, patch = args.editor.resolve(), args.engine_dir.resolve()
    exe = patch / 'godot.macos.template_release.arm64'
    provenance = json.loads((patch / 'provenance.json').read_text())
    require(provenance['engine_source'] == ENGINE_SOURCE and provenance['angle_archive_sha256'] == ANGLE_SHA, 'Existing engine provenance mismatch')
    require(provenance['patched_binary_sha256'] == sha(exe) == ENGINE_SHA, 'Not pinned existing Metal engine')
    pack = exe.with_suffix('.pck')
    require(not pack.exists(), 'Refuse to replace an existing PCK')
    env = os.environ | {'LUANSHI_25D_EXPERIMENT': '1', 'LUANSHI_SOURCE18_UV_CONTROL': '1',
                        'LUANSHI_25D_RENDER_SIZE': '2560x1440', 'LUANSHI_25D_OUT': str(out / 'gpu')}
    config, presets = project / 'project.godot', project / 'export_presets.cfg'
    original_config, original_presets = config.read_bytes(), presets.read_bytes()
    try:
        require(b'run/main_loop_type="LuanshiEnvironment25DExperiment"' in original_config, 'Base main loop changed')
        # Ephemeral build selection only; exact original files restored in finally.
        config.write_bytes(original_config.replace(b'run/main_loop_type="LuanshiEnvironment25DExperiment"', b'run/main_loop_type="LuanshiSource18UVControl"'))
        presets.write_bytes(original_presets.replace(b'assets/*.json,', b'scripts/field/experimental/production_v2/uv_spatial/source18_contract.json,uv_control_sources.json,assets/*.json,'))
        run_logged([str(editor), '--headless', '--editor', '--path', str(project), '--import'], out / 'import.log', env, project)
        run_logged([str(editor), '--headless', '--path', str(project), '--export-pack', 'macOS', str(pack)], out / 'export.log', env, project)
        (out / 'engine-pack.json').write_text(json.dumps({'provenance': provenance, 'pack_sha256': sha(pack), 'pack_bytes': pack.stat().st_size,
            'main_loop': 'LuanshiSource18UVControl', 'build_kind': 'Measure actual runtime flags; filename alone is not evidence'}, indent=2))
        with tempfile.TemporaryDirectory(prefix='empty-uv-cwd-', dir=out) as empty:
            # Actual PCK sidecar and class registration, but explicitly CPU/editor, not release or GPU acceptance.
            cpu_env = env | {'LUANSHI_25D_OUT': str(out / 'packed-cpu')}
            run_logged([str(editor), '--headless', '--main-pack', str(pack), '--', '--pose-control', '--uv-cpu-only'], out / 'packed-cpu.log', cpu_env, empty)
            validate(json.loads((out / 'packed-cpu/uv-control.json').read_text()), cpu=True)
            exe.chmod(0o755)
            command = [str(exe), '--resolution', '2560x1440', '--rendering-method', 'mobile', '--rendering-driver', 'metal', '--audio-driver', 'Dummy', '--', '--pose-control']
            run_logged(command, out / 'native-metal.log', env, empty)
        result = json.loads((out / 'gpu/uv-control.json').read_text())
        validate(result)
        native_log = (out / 'native-metal.log').read_text()
        require('Metal' in native_log, 'Metal startup not observed in actual engine log')
        require(not any(x in native_log for x in ['ERROR:', 'SCRIPT ERROR', 'Shader compilation failed', 'Failed loading']), 'Native errors retained; do not accept fallback rendering')
        for stage in result['stages']:
            file = out / 'gpu' / stage['file']
            require(struct.unpack('>II', file.read_bytes()[16:24]) == (2560, 1440), 'Actual PNG IHDR mismatch')
            require(sha(file) == stage['file_sha256'], 'Original frame bytes changed')
        (out / 'technical-validation.json').write_text(json.dumps({'status': 'PROTOCOL_PASS_VISUAL_REVIEW_REQUIRED',
            'no_whole_scene_art_acceptance': True, 'no_revival_of_rejected_environment_route': True,
            'actual_build_kind': result['engine'], 'actual_camera': result['camera']}, indent=2))
    finally:
        config.write_bytes(original_config)
        presets.write_bytes(original_presets)
        (out / 'build-config-restored.json').write_text(json.dumps({'project_godot_exact': config.read_bytes() == original_config,
            'export_presets_exact': presets.read_bytes() == original_presets}, indent=2))

if __name__ == '__main__':
    main()
