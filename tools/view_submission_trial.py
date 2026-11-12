"""One pinned checkout and one X11/Mesa host. ABBA reverses temporal order."""
from pathlib import Path
import hashlib,json,math,os,platform,statistics,subprocess
root=Path.cwd()
out=Path(os.environ['VIEW_OUT'])
pixels=Path(os.environ['VIEW_PIXELS'])
out.mkdir(parents=True,exist_ok=True)
pixels.mkdir(parents=True,exist_ok=True)
src=Path('scripts/field/presentation.gd')
base='22d5c85abf18296c0d299075f68e287102b004e7'
old=subprocess.check_output(['git','show',base+':'+str(src)])
new=src.read_bytes()
assert old!=new
def pct(a,q):return sorted(a)[math.ceil(q*len(a))-1]
def stats(a):return {'n':len(a),'mean_ms':round(statistics.mean(a)/1000,4),'p50_ms':round(pct(a,.5)/1000,4),'p95_ms':round(pct(a,.95)/1000,4),'p99_ms':round(pct(a,.99)/1000,4)}
def command(cmd,tag):
    env=dict(os.environ,VIEW_TAG=tag)
    log=out/(tag+'.log')
    with log.open('wb') as f:
        r=subprocess.run(cmd,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=250)
    text=log.read_text()
    errors=[l for l in text.splitlines() if 'SCRIPT ERROR' in l or 'SHADER ERROR' in l or 'Parse Error' in l or l.startswith('ERROR:')]
    print('VIEW_PROCESS',tag,r.returncode,len(errors),flush=True)
    if r.returncode or errors:print(text[-8000:],flush=True);raise RuntimeError(tag)
    return json.loads((out/(tag+'.json')).read_text())
data={}
for tag in ['A0','B0','B1','A1']:
    src.write_bytes(old if tag[0]=='A' else new)
    data[tag]=command(['godot','--path','.', '--resolution','1280x800','--disable-vsync','--audio-driver','Dummy','--rendering-method','gl_compatibility','--fixed-fps','60','--script','tests/view_submission_trial.gd','--','--field-size=512'],tag)
src.write_bytes(new)
summary={'base':base,'lab':os.environ.get('GITHUB_SHA'),'host':data['A0']['host'],'hosts_by_run':{k:v['host'] for k,v in data.items()},'cpu_info':subprocess.check_output(['lscpu'],text=True),'kernel':platform.platform(),'semantic_errors':[],'pixel_comparisons':[],'cases':{}}
for case in ['close','tour']:
    aggregate={}
    order=['A0','B0','B1','A1']
    for tag in order+['baseline','candidate']:
        keys=[tag] if tag in order else (['A0','A1'] if tag=='baseline' else ['B0','B1'])
        rows=[row for k in keys for row in data[k][case]['rows']]
        agg={name:stats([v[i] for v in rows]) for i,name in [(1,'full_frame'),(2,'display_script'),(3,'sim')]}
        agg['median_visible_ordinary']=statistics.median(v[4] for v in rows)
        aggregate[tag]=agg
    for tag in order:
        ws=data[tag][case]['witnesses']
        for ref,cur in zip(data['A0'][case]['witnesses'],ws):
            mismatches=[k for k in ref if k!='rgba_sha256' and ref[k]!=cur[k]]
            if mismatches:summary['semantic_errors'].append([tag,case,cur['frame'],mismatches])
            frame=cur['frame']
            record={'case':case,'frame':frame,'tag':tag,'pixel_equal':ref['rgba_sha256']==cur['rgba_sha256']}
            if not record['pixel_equal']:
                a=(pixels/f'A0-{case}-{frame:03d}.rgba').read_bytes()
                b=(pixels/f'{tag}-{case}-{frame:03d}.rgba').read_bytes()
                dif=0;above=0;sq=0;maximum=0
                for i in range(0,len(a),4):
                    rgb=[abs(a[i+c]-b[i+c]) for c in range(3)]
                    peak=max(rgb);dif+=peak>0;above+=peak>2;maximum=max(maximum,peak);sq+=sum(v*v for v in rgb)
                record.update({'changed_pixels':dif,'total_pixels':len(a)//4,'over_2_codes':above,'max_code_delta':maximum,'rgb_rmse':round(math.sqrt(sq/(len(a)*.75)),6)})
            summary['pixel_comparisons'].append(record)
    summary['cases'][case]=aggregate
    print('VIEW_AB',case,json.dumps(aggregate,separators=(',',':')),flush=True)
print('VIEW_PARITY',json.dumps({'semantic_errors':summary['semantic_errors'],'pixel_comparisons':summary['pixel_comparisons']}),flush=True)
(out/'comparison.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
assert not summary['semantic_errors']
