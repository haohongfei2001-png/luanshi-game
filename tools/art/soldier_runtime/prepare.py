import pathlib,sys,shutil,json,hashlib
repo=pathlib.Path(__file__).resolve().parents[3];fixture,out=map(pathlib.Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
receipts=[]
files=[('scripts/review/complete_head/oracle.gd',repo/'scripts/review/complete_head/oracle.gd')]
files += [('scripts/field/experimental/'+x,repo/'scripts/field/experimental'/x) for x in ['native_rig_palette.gd','native_rig_material.gd','textured_native_rig.gdshader']]
files += [('assets/head/'+p.name,p) for p in fixture.iterdir() if p.suffix in ['.json','.png']]
for name,src in files:
 dst=out/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst);receipts.append({'path':name,'bytes':dst.stat().st_size,'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()})
(out/'project.godot').write_text('''config_version=5
[application]
config/name="Complete source head oracle only"
run/main_scene="res://bootstrap.tscn"
run/main_loop_type="CompleteHeadOracle"
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.macos="mobile"
rendering_device/driver.macos="metal"
''')
(out/'bootstrap.tscn').write_text('[gd_scene format=3]\n[node name="Bootstrap" type="Node"]\n')
(out/'fixture-manifest.json').write_text(json.dumps({'files':receipts,'source_sha256':json.loads((fixture/'head-source.json').read_text())['source_sha256'],'art_pass':False},indent=2)+'\n')
print('Minimal complete-head project',sum(x['bytes'] for x in receipts),'bytes')
