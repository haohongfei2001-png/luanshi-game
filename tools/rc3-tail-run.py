#!/usr/bin/env python3
"""Alternate versions on the same host; compare complete checkpoint bytes, not just outcomes."""
import json, math, os, pathlib, shutil, statistics, subprocess, sys
R=pathlib.Path.cwd()
D=pathlib.Path(os.environ['RUNNER_TEMP'])/'rc3-tail'
D.mkdir(exist_ok=True)
BASE='f9f6057537dc316e692ea4fedb83b809afc64386'
source='scripts/field/battle.gd'
crowd='scripts/field/crowd_grid.gd'
core=[source,crowd]
orig={p:subprocess.check_output(['git','show',BASE+':'+p]) for p in core}
new={p:(R/p).read_bytes() for p in core}
different=orig!=new
def switch(vers):
    for p,v in (orig if vers=='base' else new).items(): (R/p).write_bytes(v)
def run(tag,n,mt):
    f=D/f'{tag}-{n}.json'
    env=dict(os.environ,TAIL_N=str(n),TAIL_TICKS=str(mt),TAIL_OUT=str(f),TAIL_TAG=tag)
    subprocess.run(['godot','--headless','--path',str(R),'--script','tests/field_tail_lab.gd'],check=True,env=env,timeout=180)
    return json.loads(f.read_text())
def stats(values):
    a=sorted(values)
    if not a:return None
    return {k:round(a[math.ceil(len(a)*q)-1]/1000,3) for k,q in [('p50',.50),('p95',.95),('p99',.99),('max',1)]}|{'mean':round(statistics.mean(a)/1000,3),'n':len(a)}
def summary(r):
    return {k:r[k] for k in ('side','tag','ticks','gate_damage_tick','breach_tick','ram_near_tick','peak_active_shots','mounted_roster','charging_ticks')}|{'step_ms':stats(r['step_us']),'activity_ms':{n:stats([v for v,f in zip(r['step_us'],r['flags']) if f&m]) for n,m in [('gate_attack',1),('volleys',2),('ram_near_gate',4),('cavalry_charge',8),('after_contact',16)]},'report':{k:r['report'][k] for k in ['hits','dead','projectiles','orders_delivered','orders_lost','result']}}
res={}
switch('base')
subprocess.run([sys.executable,'tools/rc3-tail-instrument.py',source],check=True)
r=run('profile-base',512,1350)
st=r['step_us']
total=sum(st); worst=sorted(range(len(st)),key=st.__getitem__,reverse=True)[:math.ceil(len(st)*.05)]
res['profile']={name:{'all_pct':round(100*sum(a[i] for a in r['phase_us'])/total,2),'worst5_pct':round(100*sum(r['phase_us'][k][i] for k in worst)/sum(st[k] for k in worst),2),'ms':stats([a[i] for a in r['phase_us']])} for i,name in enumerate(r['phase_names'])}
print('TAIL_PROFILE',json.dumps(res['profile']),flush=True)
res['runs']=[]
count=2 if different else 1
runs={}
for n in [20,100,250,512]:
    for rep in range(count):
        for version in ((['base','core'] if rep%2==0 else ['core','base']) if different else ['base']):
            switch(version)
            r=run(f'{version}-{rep}',n,1350)
            row=summary(r)
            print('TAIL_RUN',json.dumps(row,ensure_ascii=False,separators=(',',':')),flush=True)
            res['runs'].append(row)
            runs.setdefault((n,version),[]).extend(r['step_us'])
            state={k:r[k] for k in ('ticks','state_sha256','flags','report')}
            key=f'canonical-{n}'
            if key not in res: res[key]=state
            else: assert state==res[key], f'non-identical state in {version}, {n}'
            if n==512 and version=='base': assert r['state_sha256']==json.loads((D/'profile-base-512.json').read_text())['state_sha256']
res['aggregate']={str(n):{v:stats(a) for (k,v),a in runs.items() if k==n} for n in [20,100,250,512]}
res['kind']='uncapped fixed simulation steps on one Linux VM; no rendering in this trace'
res['base']=BASE
res['lab']=os.environ.get('GITHUB_SHA')
res['host']=subprocess.check_output(['lscpu'],text=True).strip()
res['godot']=subprocess.check_output(['godot','--version'],text=True).strip()
(D/'results.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
print('TAIL_AGGREGATE',json.dumps(res['aggregate']),flush=True)
switch('core')
