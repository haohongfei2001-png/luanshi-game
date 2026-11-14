"""Strict source-evaluated normals/UV/RGBA gate, not an eight-weight reference."""
import pathlib,json,sys,re
from PIL import Image,ImageChops
p=pathlib.Path(sys.argv[1]);r=json.loads((p/'report.json').read_text());log=pathlib.Path(sys.argv[2]).read_text(errors='replace')
assert log.strip() and not re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',log)
assert r['driver']=='metal' and r['method']=='mobile'
expected={'walk-0','walk-13','walk-47','walk-83','walk-50','walk-100','tail-stress'};seen=set();rows=[];failures=[]
if r.get('walk_cycle',False):expected.remove('tail-stress');expected.update('cycle-%02d'%i for i in range(24))
assert len(r['inventory'])==4 and all(m['bones']==163 for m in r['inventory'])
face=next(m for m in r['inventory'] if m['name']=='Young complete author face module');assert face['slots']==9 and face['original_over8_vertices']==14
for row in r['rows']:
 name=row['name'];assert name in expected and name not in seen;seen.add(name)
 suffix='-isolated' if r.get('walk_cycle',False) else ''
 if suffix:assert r.get('actor_isolation_mask',False),'Ground cannot dilute actor-visible denominator'
 a=Image.open(p/(name+'-author'+suffix+'.png')).convert('RGBA');b=Image.open(p/(name+'-shared'+suffix+'.png')).convert('RGBA');assert a.size==b.size==(512,512)
 def maximum(parts):
  out=parts[0]
  for c in parts[1:]:out=ImageChops.lighter(out,c)
  return out
 bg=Image.new('RGBA',a.size,a.getpixel((0,0)));mask=maximum(ImageChops.difference(a,bg).split()+ImageChops.difference(b,bg).split());visible=512*512-mask.histogram()[0]
 d=maximum(ImageChops.difference(a.convert('RGB'),b.convert('RGB')).split());h=d.histogram();over=sum(h[3:]);mae=sum(i*n for i,n in enumerate(h))/(255*512*512)
 scene_over=0;shadow_pixels=None
 if suffix:
  sa=Image.open(p/(name+'-author.png')).convert('RGB');sb=Image.open(p/(name+'-shared.png')).convert('RGB');assert sa.size==sb.size==(512,512)
  scene_over=sum(maximum(ImageChops.difference(sa,sb).split()).histogram()[3:])
  if name in r.get('shadow_on_off_checks',[]):
   off=Image.open(p/(name+'-author-shadow-off.png')).convert('RGB');assert off.size==(512,512)
   shadow_change=maximum(ImageChops.difference(sa,off).split()).point(lambda x:255 if x>2 else 0)
   actor=mask.point(lambda x:255 if x>0 else 0)
   shadow_pixels=512*512-ImageChops.subtract(shadow_change,actor).histogram()[0]
   if shadow_pixels<100:failures.append(name+': no measurable ground shadow')
 passed=scene_over<512*512*.02 and visible>1000 and mae<.001 and over<visible*.02
 rows.append(dict(row,actor_only_denominator=bool(suffix),shadow_scene_pixels_over_two_levels=scene_over,shadow_on_off_ground_pixels=shadow_pixels,visible=visible,mean_canvas_max_rgb_error=mae,pixels_over_two_levels=over,fraction_over_two_levels=over/max(visible,1),strict_pass=passed))
 if not passed:failures.append(name)
assert seen==expected
result={'normal_mode':r.get('normal_mode','weighted_bind_normal'),'normal_bank_bytes':r.get('normal_bank_bytes',0),'rows':rows,'failures':failures,'original_two_levels_two_percent_gate':True,'reference':'Blender complete source 9 influences and evaluated corner normals, not native8','art_pass':False,'M5':'NOT_TESTED'}
(p/'external-pixel-gate.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));sys.exit(1 if failures else 0)
