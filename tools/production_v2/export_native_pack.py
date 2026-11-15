"""Normal exported MainLoop; original project/presets always restored."""
import argparse,hashlib,json,os,subprocess,sys,tempfile
from pathlib import Path
ENTRY='application/run/main_loop_type=DotProductionV2NativeCapture; inert bootstrap; no CLI script override'
MANIFEST='res://assets/production_v2/native-manifest.json'
def project_config(data):
    old=b'run/main_scene="res://scenes/game.tscn"'
    if data.count(old)!=1 or b'run/main_loop_type=' in data:raise ValueError('Unexpected project entry')
    return data.replace(old,b'run/main_scene="res://tests/production_v2_bootstrap.tscn"\nrun/main_loop_type="DotProductionV2NativeCapture"')
def preset_config(data):
    old=b'exclude_filter="tests/*,tools/*,docs/*,artifacts/*,builds/*"'
    if data.count(old)!=2 or data.count(b'include_filter="')!=2 or data.count(b'script_export_mode=2')!=2:raise ValueError('Unexpected export preset')
    data=data.replace(b'include_filter="',b'include_filter="assets/production_v2/**/*.json,assets/production_v2/**/*.txt,assets/production_v2/**/*.md,',1)
    return data.replace(old,b'exclude_filter="tools/*,docs/*,artifacts/*,builds/*,.pipeline/*"',1).replace(b'script_export_mode=2',b'script_export_mode=0',1)
def export(editor,project,patch,out):
    out.mkdir(parents=True,exist_ok=True);pack=patch/'godot.macos.template_release.pck'
    if pack.exists():raise ValueError('Do not overwrite existing evidence PCK')
    checked=project/'tools/art/gate_structure/run_capture_checked.py';env=os.environ|{'LUANSHI_PRODUCTION_V2':'1'}
    subprocess.run([sys.executable,str(checked),str(out/'collect-import.log'),'90','--',str(editor),'--headless','--path',str(project),'--script','tools/production_v2/collect_resource_identities.gd','--','res://assets/production_v2/native-manifest-source.json',MANIFEST],check=True,env=env)
    files=[project/'project.godot',project/'export_presets.cfg'];original=[p.read_bytes() for p in files]
    try:
        files[0].write_bytes(project_config(original[0]));files[1].write_bytes(preset_config(original[1]))
        subprocess.run([sys.executable,str(checked),str(out/'pack-export.log'),'240','--',str(editor),'--headless','--path',str(project),'--export-pack','macOS',str(pack)],check=True,env=env)
    finally:
        for p,data in zip(files,original):p.write_bytes(data)
    with tempfile.TemporaryDirectory(prefix='empty-pck-',dir=out) as empty:
        subprocess.run([sys.executable,str(checked),str(out/'empty-cwd-setup.log'),'100','--',str(editor),'--headless','--main-pack',str(pack),'--',MANIFEST,'--validate-setup'],cwd=empty,env=env,check=True)
    lines=[x.split('PRODUCTION_V2_ENTRY_READY ',1)[1] for x in (out/'empty-cwd-setup.log').read_text().splitlines() if x.startswith('PRODUCTION_V2_ENTRY_READY ')]
    if len(lines)!=1:raise ValueError('Missing actual empty-cwd resource observation')
    receipt=json.loads(lines[0]);manifest=json.loads((project/'assets/production_v2/native-manifest.json').read_text())
    if not receipt['validate_only'] or len(receipt['ordinary_new_spear_ids'])!=6:raise ValueError('Wrong setup scope')
    if set(receipt['actual_resource_closure']['paths'])!=set(manifest['resource_identities']):raise ValueError('Resource closure differs')
    for path,row in manifest['resource_identities'].items():
        if receipt['runtime_packed_observations'][path]!={k:v for k,v in row.items() if k!='original_source_sha256'}:raise ValueError('Actual exported resource differs')
    result={'entry':ENTRY,'bytes':pack.stat().st_size,'sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),'original_configs_restored':all(p.read_bytes()==d for p,d in zip(files,original)),'isolated_pack_setup_passed':True,'setup':receipt,'scope':'CPU exported closure not native graphics or art acceptance'}
    (out/'pack-integrity.json').write_text(json.dumps(result,indent=2)+'\n');return result
if __name__=='__main__':
    p=argparse.ArgumentParser()
    for key in ['editor','project','patch','out']:p.add_argument(key,type=Path)
    a=p.parse_args();print(json.dumps(export(*(getattr(a,k).resolve() for k in ['editor','project','patch','out'])),indent=2))
