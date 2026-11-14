"""Build a normal adjacent resource pack; never relax template path restrictions."""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, sys, tempfile
from capture_mode import MODES, arguments
from resource_identity import collect, verify_runtime_observation
from restore_complete import RUNTIME_FILES
from restore_inputs import FILES

def transform_project(data):
    old=b'run/main_scene="res://scenes/game.tscn"'
    if data.count(old)!=1 or b'run/main_loop_type=' in data:
        raise ValueError('Unexpected project entry configuration')
    # A protected template silently ignores CLI --script. Select the exported
    # global MainLoop through normal project settings, not a path override.
    return data.replace(old,b'run/main_scene="res://tests/native_region_bootstrap.tscn"\nrun/main_loop_type="DotNativeRegionCapture"',1)

def transform_preset(data):
    old = b'exclude_filter="tests/*,tools/*,docs/*,artifacts/*,builds/*"'
    if data.count(old) != 2:
        raise ValueError("Unexpected source export filters")
    # This internal QA pack needs its explicitly invoked test entry and dependencies.
    if data.count(b'script_export_mode=2') != 2:
        raise ValueError('Unexpected script export configuration')
    # Evidence hashes the exact public .gd source, not an engine-version token stream.
    if data.count(b'include_filter="')!=2:raise ValueError('Unexpected include filter layout')
    data=data.replace(b'include_filter="',b'include_filter="tests/fixtures/author_thrust_peak.json,',1)
    return data.replace(old, b'exclude_filter="docs/*,artifacts/*,builds/*"', 1).replace(b'script_export_mode=2', b'script_export_mode=0', 1)

def export(editor, project, patch, output, mode='baseline'):
    mode_arguments=arguments(mode)
    resource_identities=collect(project,RUNTIME_FILES if mode in ('gate-context-study','destination-study','destination-action') else FILES)
    config = project/'export_presets.cfg'
    original = config.read_bytes()
    temporary = transform_preset(original)
    project_config=project/'project.godot'
    original_project=project_config.read_bytes()
    internal_project=transform_project(original_project)
    pack = patch/'godot.macos.template_release.pck'
    if pack.exists(): raise ValueError("Refuse to overwrite an earlier review pack")
    output.mkdir(parents=True, exist_ok=True)
    try:
        config.write_bytes(temporary)
        project_config.write_bytes(internal_project)
        subprocess.run([sys.executable, str(project/'tools/art/gate_structure/run_capture_checked.py'),
                        str(output/'pack-export.log'), '180', '--', str(editor), '--headless', '--path', str(project),
                        '--export-pack', 'macOS', str(pack)], check=True, cwd=project)
    finally:
        config.write_bytes(original)
        project_config.write_bytes(original_project)
    if not pack.is_file() or pack.stat().st_size < 1000000:
        raise ValueError("Review pack absent or implausibly small")
    # Never test a pack with the source checkout as cwd: FileAccess may silently
    # fall back to a file excluded by .gdignore, hiding a broken exported closure.
    env=os.environ.copy()
    env.update(LUANSHI_NATIVE_WOODLAND='1',LUANSHI_AUTHORED_LANDFORM='1',ARCHITECTURE_CAPTURE_OUT=str(output/'isolated-pack-setup'))
    with tempfile.TemporaryDirectory(prefix='isolated-pck-',dir=output) as isolated:
        subprocess.run([sys.executable,str(project/'tools/art/gate_structure/run_capture_checked.py'),
                        str(output/'isolated-pack-setup.log'),'75','--',str(editor),'--headless',
                        '--main-pack',str(pack),'--','--validate-setup',*mode_arguments],
                       check=True,cwd=isolated,env=env)
    setup_log=(output/'isolated-pack-setup.log').read_text()
    resource_lines=[line.split('RUNTIME_RESOURCE_IDENTITY ',1)[1] for line in setup_log.splitlines() if line.startswith('RUNTIME_RESOURCE_IDENTITY ')]
    if len(resource_lines)!=1:raise ValueError('Missing isolated packed-resource observation')
    verify_runtime_observation(json.loads(resource_lines[0]),resource_identities)
    if collect(project,RUNTIME_FILES if mode in ('gate-context-study','destination-study','destination-action') else FILES)!=resource_identities:
        raise ValueError('Source/imported resources changed during pack export')
    if 'NATIVE_REGION_FOCUS ' not in setup_log or 'ARCHITECTURE_GAME_SETUP_PASS tick=135 ordinary=[20, 20]' not in setup_log:
        raise ValueError('Isolated exported pack did not reach real intended setup')
    if mode in ('gate-context-study','destination-study','destination-action') and 'REGION_SETUP_LOADING_ONE_REAL_UNIT_AUTHOR_ORACLE' not in setup_log:
        raise ValueError('Isolated pack did not load the requested real-unit author oracle')
    if mode=='destination-action':
        fixture_sha=hashlib.sha256((project/'tests/fixtures/author_thrust_peak.json').read_bytes()).hexdigest()
        if 'AUTHOR_DYNAMIC_FIXTURE_VALIDATED '+fixture_sha not in setup_log:raise ValueError('Exported exact live phase fixture was not verified in isolated pack')
    result={'resource_identities':resource_identities,'packed_resource_identity_verified_in_isolated_process':True,'pack':pack.name,'bytes':pack.stat().st_size,'sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),
            'original_export_config_sha256':hashlib.sha256(original).hexdigest(),
            'internal_review_export_config_sha256':hashlib.sha256(temporary).hexdigest(),
            'original_export_config_restored':config.read_bytes()==original,
            'original_project_sha256':hashlib.sha256(original_project).hexdigest(),
            'internal_project_sha256':hashlib.sha256(internal_project).hexdigest(),
            'original_project_restored':project_config.read_bytes()==original_project,
            'entry':'application/run/main_loop_type=DotNativeRegionCapture; inert bootstrap scene; no CLI override',
            'isolated_pack_setup':'PASS: empty temporary cwd; no source checkout fallback; official editor headless, NOT native graphics',
            'isolated_pack_setup_passed':True,
            'validated_capture_mode':mode,
            'scope':'Internal QA pack includes test/tool resources; not release or default configuration'}
    (output/'pack-integrity.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser()
    for name in ('editor','project','patch','output'):p.add_argument(name,type=Path)
    p.add_argument('--mode',choices=MODES,default='baseline')
    a=p.parse_args();print(json.dumps(export(*(getattr(a,n).resolve() for n in ('editor','project','patch','output')),mode=a.mode)))
