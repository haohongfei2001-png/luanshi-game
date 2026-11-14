"""Copy a small explicit source-only oracle project, not the whole battlefield.
No compiled engine, no code execution from source assets, no source rewriting.
"""
import pathlib,sys,shutil,json,hashlib,struct
repo=pathlib.Path(__file__).resolve().parents[2];out=pathlib.Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
files=['assets/ubc_lab/ubc_animated.glb','assets/ubc_lab/NOTICE.md','assets/ubc_lab/source/universal-base-characters-standard-LICENSE.txt','assets/ubc_lab/source/ual-standard-current-LICENSE.txt']
files += ['scripts/field/experimental/'+name for name in ['native_rig_palette.gd','native_rig_material.gd','textured_native_rig.gdshader','full_weight_reference.gd']]
files += ['tools/metal_character_oracle/'+name for name in ['gpu.gd','cpu.gd','weights.gd']]
receipts=[]
for name in files:
 source=repo/name;dest=out/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest)
 receipts.append({'path':name,'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
# Fresh checkouts need no pre-existing editor-generated PNG/import sidecars.
raw=(repo/'assets/ubc_lab/ubc_animated.glb').read_bytes()
length,kind=struct.unpack_from('<II',raw,12);assert kind==0x4E4F534A
scene=json.loads(raw[20:20+length]);binary_length,binary_kind=struct.unpack_from('<II',raw,20+length);assert binary_kind==0x004E4942
binary=raw[28+length:28+length+binary_length]
for image in scene['images']:
 view=scene['bufferViews'][image['bufferView']];start=view.get('byteOffset',0);png=binary[start:start+view['byteLength']];assert png.startswith(b'\x89PNG')
 name='assets/ubc_lab/ubc_animated_'+pathlib.Path(image['name']).stem+'.png';dest=out/name;dest.write_bytes(png)
 receipts.append({'path':name,'bytes':len(png),'sha256':hashlib.sha256(png).hexdigest(),'origin':'exact embedded GLB bufferView, no recompression'})
for template in sorted((repo/'tools/metal_character_oracle/import_settings').glob('*.txt')):
 name='assets/ubc_lab/'+template.name.removesuffix('.txt');dest=out/name;shutil.copyfile(template,dest)
 receipts.append({'path':name,'bytes':dest.stat().st_size,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'origin':'explicit matched importer settings'})
assert next(r['sha256'] for r in receipts if r['path'].endswith('/ubc_animated.glb'))=='64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0'
(out/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Isolated native Metal character oracle"\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\n[rendering]\nrenderer/rendering_method="mobile"\nrenderer/rendering_method.macos="mobile"\nrendering_device/driver.macos="metal"\n')
(out/'fixture-manifest.json').write_text(json.dumps({'source_glb':'bf520c13aa393c2fdc4b5c2596cfe5cbdb0bd7d9','files':receipts,'total_source_bytes':sum(x['bytes'] for x in receipts),'Mac_run':'NOT_YET_RUN','engine_patch':'GLES3 tangent patch deliberately NOT required or applied to Metal'},indent=2)+'\n')
print(out, sum(x['bytes'] for x in receipts),'source bytes')
