"""External strict gate: release-template asserts are not trusted.
Requires Pillow, actual PNGs and original numerical thresholds. No engine build.
"""
import argparse,json,pathlib,re
from PIL import Image,ImageChops
p=argparse.ArgumentParser();p.add_argument('folder',type=pathlib.Path);p.add_argument('--log',type=pathlib.Path,required=True);p.add_argument('--fixture-manifest',type=pathlib.Path,required=True);p.add_argument('--cpu-json',type=pathlib.Path);a=p.parse_args()
log=a.log.read_text(errors='replace');assert log.strip() and not re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',log),'actual runtime error or empty log'
r=json.loads((a.folder/'parity.json').read_text());assert r['rendering_driver']=='metal' and r['rendering_method']=='mobile'
assert r['diagnostic_only'] is False and r['diagnostic']=='' and r['lod_threshold']==0
assert r['native_size']==[512,512] and r['internal']==1 and r['engine']['hash']
assert r['source_glb_sha256']=='64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0'
manifest=json.loads(a.fixture_manifest.read_text());hashes={x['path']:x['sha256'] for x in manifest['files']}
for path,digest in {'native_rig_palette.gd':'7f359343afd1b291e139b49aef48b971b382251dd886e958b4481f72f3cb75c0','native_rig_material.gd':'d6a52f9e32804dde3dbd8eaeeb294ef863076abacb7120e956b73e4bd3259da9','textured_native_rig.gdshader':'62e199d8c1e88709e29f99c630d1567359123e178454ec3c125709c14a82289f'}.items():assert hashes['scripts/field/experimental/'+path]==digest,'adapter source changed'
expected={'Idle':0.,'Walk':.45,'Sword_Attack':.5,'Death01':.75};seen=set();rows=[]
def maximum(channels):
 result=channels[0]
 for c in channels[1:]:result=ImageChops.lighter(result,c)
 return result
for row in r['reports']:
 name=row['clip'];assert name in expected and name not in seen and row['phase']==expected[name];seen.add(name);assert row['pass'] is True
 native=Image.open(a.folder/(name+'-native.png')).convert('RGBA');batch=Image.open(a.folder/(name+'-batch.png')).convert('RGBA');assert native.size==batch.size==(512,512)
 bg=Image.new('RGBA',native.size,native.getpixel((0,0)))
 mask=maximum(ImageChops.difference(native,bg).split()+ImageChops.difference(batch,bg).split());visible=512*512-mask.histogram()[0]
 diff=maximum(ImageChops.difference(native.convert('RGB'),batch.convert('RGB')).split());hist=diff.histogram();different=sum(hist[3:]);mae=sum(i*n for i,n in enumerate(hist))/(255*512*512)
 assert visible>1000 and mae<.001 and different<visible*.02,(name,visible,mae,different)
 rows.append({'clip':name,'visible_pixels':visible,'mae':mae,'pixels_over_two_levels':different})
assert seen==set(expected)
if a.cpu_json:
 cpu=json.loads(a.cpu_json.read_text());assert cpu['checks']==68047 and cpu['failures']==0 and cpu['native_bones']==65 and cpu['source_lods_preserved']==18
out={'actual_mobile_metal_pixel_gate':True,'external_png_recalculation':rows,'original_thresholds_unchanged':True,'fixture_adapter_hashes_checked':True,'cpu_checked':bool(a.cpu_json),'art_pass':False,'M5':'NOT_TESTED'}
(a.folder/'external-strict-result.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out))
