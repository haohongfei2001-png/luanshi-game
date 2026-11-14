"""Coverage and actual PNG metrics, deliberately not automatic visual acceptance."""
import json,pathlib,sys
from PIL import Image,ImageChops
p=pathlib.Path(sys.argv[1]);r=json.loads((p/'report.json').read_text())
clips={'Idle','Walk','Jog_Fwd','Sprint','Sword_Attack','Sword_Idle','Hit_Chest','Hit_Head','Death01'}
expected={(c,round(t,2),m) for c in clips for t in [.13,.47,.83] for m in (['clear','wall','cutout'] if c in ['Walk','Death01'] else ['clear'])}
seen=set();metrics=[]
for row in r['rows']:
 key=(row['clip'],round(row['phase'],2),row['mode']);assert key in expected and key not in seen,key;seen.add(key)
 a=Image.open(p/(row['prefix']+'-full.png')).convert('RGB');b=Image.open(p/(row['prefix']+'-lod2.png')).convert('RGB');assert a.size==b.size==(2560,1440)
 assert a.getextrema()!=((0,0),(0,0),(0,0))
 delta=ImageChops.difference(a,b);bands=delta.split();d=ImageChops.lighter(ImageChops.lighter(bands[0],bands[1]),bands[2]);h=d.histogram()
 metrics.append(dict(row,changed_pixels=sum(h[1:]),over_two_levels=sum(h[3:]),mean_canvas_max_error_levels=sum(i*n for i,n in enumerate(h))/(2560*1440),difference_bbox=d.getbbox()))
assert seen==expected,(len(seen),len(expected))
assert r['source_sha256']=='64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0'
assert r['resolution']==[2560,1440] and r['internal']==1
out={'coverage_complete':True,'pairs':len(seen),'metrics':metrics,'art_pass':False,'lod_quality_pass':False,'scope':'39 static sampled pose pairs, not full animation cycles or performance. Metrics include occluder; no body-mask gate.'}
(p/'pixel-differences.json').write_text(json.dumps(out,indent=2)+'\n');print('Complete real PNG pairs:',len(seen),'quality still requires review')
