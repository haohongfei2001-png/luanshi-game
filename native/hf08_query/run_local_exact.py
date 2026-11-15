#!/usr/bin/env python3
"""Local-only frozen-input checks. Never downloads or publishes map data/results."""
import argparse,hashlib,json,os,pathlib,platform,subprocess,time
ROOT=pathlib.Path(__file__).resolve().parents[2]
SOURCE_SHA='28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753'
TOPOLOGY_SHA='0b1d24868d11505f3e980a8eb456df7e55035203490b1d1df8384ba5622bd140'
ENGINE='4.6.3.stable.official.7d41c59c4'
FINAL_VARIANT_SHA='c92536b9e0d54d01b07779f39bfe14fcb095d0c0e69d7e8aad0b1960651e38c6'
EVENT_VARIANT_SHA='81744038da232707e0f82f197c07e481ff781ed15540a42486c875dff4fa0aa2'
# These are public parent-source file identities, not a map or state payload.
CORE_SHA={'scripts/field/battle.gd': '772665adb73e9e9eeb10f29207108aef2a03b6206c2a5c58de83b8857834e8e6', 'scripts/field/save.gd': 'b611c23985b4eb76f71c61bf9662aab32b09c812383c76447d50601a1e37c267', 'scripts/field/maps/authored_support.gd': '3e5d3a6afeff76945c5140c2e82fc17cc27e80b89c45b3dd9bb62709bb208bc0', 'scripts/field/maps/authored_obstacles.gd': '5a96d4f29b265cbb2c402a00b29c4ada7cc6f6e8af79744f32c939cc130eb0ce', 'scripts/field/maps/authored_navigation.gd': 'e501cb54265bdaa168d2df9e2908ace56b488f12374f9bd398cc584cb8549452', 'scripts/field/maps/authored_muster.gd': '0a78a924770c88fac2e4b25ab4f028c64e2c1f5bb86c76df8c7a9677324551e8'}
def sha(data):return hashlib.sha256(data).hexdigest()
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--godot',required=True,help='Official Godot 4.6.3 Linux x86_64 editor executable')
 parser.add_argument('--source',required=True,help='Separately authorized local HF08 input, outside this checkout')
 parser.add_argument('--output',required=True,help='Local evidence directory outside this checkout; never published by this tool')
 parser.add_argument('--checks',choices=['boundary','combat400','all'],default='boundary')
 args=parser.parse_args();source=pathlib.Path(args.source).expanduser().resolve(strict=True);out=pathlib.Path(args.output).expanduser().resolve()
 if source.is_relative_to(ROOT) or out.is_relative_to(ROOT):raise ValueError('Input and generated evidence must stay outside the source checkout')
 raw=source.read_bytes()
 if sha(raw)!=SOURCE_SHA:raise ValueError('Frozen source SHA256 mismatch; no substitute/relaxed input accepted')
 data=json.loads(raw)
 if data.get('topology_sha256')!=TOPOLOGY_SHA:raise ValueError('Frozen topology mismatch')
 for name,expected in CORE_SHA.items():
  if sha((ROOT/name).read_bytes())!=expected:raise ValueError('Frozen public core changed: '+name)
 if platform.system()!='Linux' or platform.machine()!='x86_64':raise ValueError('This candidate only claims tested Linux x86_64')
 godot=str(pathlib.Path(args.godot).expanduser().resolve(strict=True))
 if subprocess.check_output([godot,'--version'],text=True).strip()!=ENGINE:raise ValueError('Official engine identity mismatch')
 lib=ROOT/'native/hf08_query/bin/libhf08_query.so'
 if not lib.exists():raise ValueError('Build the optional library first with native/hf08_query/build.sh')
 out.mkdir(parents=True,exist_ok=True)
 summary={'status':'RUNNING','scope':'Local frozen-input CPU check, no GPU/FPS/real-time/Mac/M5 or Save.restore claim','source_sha256':SOURCE_SHA,'topology_sha256':TOPOLOGY_SHA,'engine':ENGINE,'checks':args.checks,'runs':[]}
 def write(): (out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
 env=os.environ.copy();env.update(HF08_CAPTURE_COMBAT_TRACE='1')
 for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[key]=str(out/'xdg'/folder)
 def run(label,script,*extra,timeout=180):
  command=[godot,'--headless','--path',str(ROOT),'--script','tests/map_runtime/'+script,'--',*map(str,extra)]
  start=time.monotonic()
  with (out/(label+'.log')).open('w') as log:
   try:result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
   except subprocess.TimeoutExpired:summary['runs'].append({'label':label,'status':'TIMEOUT','limit_seconds':timeout});write();raise
  summary['runs'].append({'label':label,'returncode':result.returncode,'wall_seconds':time.monotonic()-start});write()
  if result.returncode or 'ERROR:' in (out/(label+'.log')).read_text():raise RuntimeError(label+' failed; inspect its local log')
 write()
 try:
  if args.checks in ['boundary','all']:
   hidden=lib.with_suffix('.so.unavailable-test')
   if hidden.exists():raise RuntimeError('Refuse to overwrite a previous interrupted fallback-test library')
   lib.rename(hidden)
   try:run('fallback','native_obstacle_unavailable.gd','native-fused',timeout=30)
   finally:hidden.rename(lib)
   if 'NATIVE_BODY_UNAVAILABLE_FALLBACK_PASS' not in (out/'fallback.log').read_text():raise RuntimeError('Missing fallback pass marker')
   for label,script,extra in [('body','native_obstacle_parity.gd',[]),('fused','native_fused_parity.gd',[]),('segment','native_segment_parity.gd',['native-fused']),('support','native_support_parity.gd',[]),('routes','source_capacity_routes.gd',['native-fused'])]:run(label,script,source,out/(label+'.json'),*extra)
   reports={name:json.loads((out/(name+'.json')).read_text()) for name in ['body','fused','segment','support','routes']}
   assert reports['body']['body_dictionary_byte_checks']==417700
   assert reports['fused']['exact_early_return_counter_cases']==2652
   assert reports['segment']['point_bytes_checked']==55915 and reports['segment']['segment_decisions_checked']==2622 and reports['segment']['graph_nodes']==8882
   assert reports['support']['byte_equal_queries']==507887
   assert [r['steps'] for r in reports['routes']['routes']]==[606,606,104,237]
   assert all(r['reason']=='arrived' for r in reports['routes']['routes'])
   assert [r['actual_roster'] for r in reports['routes']['armies']]==[43,1057]
   assert all(not r['invalid_placements'] for r in reports['routes']['armies'])
   summary['boundary']='PASS'
  if args.checks in ['combat400','all']:
   vertices=[v for surface in data['surfaces'] if surface.get('walkable',False) for v in surface['vertices']]
   bounds={'bounds':{'x':[min(v[0] for v in vertices),max(v[0] for v in vertices)],'z':[min(v[2] for v in vertices),max(v[2] for v in vertices)]}}
   layout=out/'local-layout.json';layout.write_text(json.dumps(bounds))
   for name,mode in [('reference','profile'),('fused','profile-native-fused')]:run(name+'400','production_battle.gd',source,layout,512,400,out/(name+'400.json'),mode,timeout=600)
   a=json.loads((out/'reference400.json').read_text());b=json.loads((out/'fused400.json').read_text())
   for report in [a,b]:
    assert report['actual_tick']==400 and report['ordinary_per_side']==[512,512] and report['roster']==1057 and not report['active_units_invalid_support_or_obstacle']
    assert report['attacks']==492 and report['hits']==[93,139] and report['losses']==[38,22] and report['orders_delivered']==2
   assert not a['native_fused_enabled'] and b['native_fused_enabled']
   suffixes=['.events.variant-stream','.events.jsonl','.snapshot.json']+[f'.tick-{tick:04d}.{kind}.variant' for tick in [0,100,200,300,400] for kind in ['snapshot','mapped-state']]
   for suffix in suffixes:assert (out/('reference400.json'+suffix)).read_bytes()==(out/('fused400.json'+suffix)).read_bytes(),suffix+' differs'
   assert sha((out/'fused400.json.tick-0400.snapshot.variant').read_bytes())==FINAL_VARIANT_SHA
   assert sha((out/'fused400.json.events.variant-stream').read_bytes())==EVENT_VARIANT_SHA
   c=b['native_query_profile_battle_only'];native_body=b['native_obstacle_profile_battle_only']['body_calls']
   assert a['query_profile']['obstacles']['obstruction_calls']==native_body==c['fused_body_checks']==6687085
   assert b['query_profile']['obstacles'].get('obstruction_calls',0)==0
   assert a['query_profile']['obstacles']['segment_obstruction_calls']==b['query_profile']['obstacles']['segment_obstruction_calls']==16955
   assert c['fused_calls']==921833 and c['fused_planned_samples']==8920771 and c['fused_visited_samples']==6721064 and c['fused_fallbacks']==0
   summary.update(combat400='PASS',variant_snapshot_sha256=FINAL_VARIANT_SHA,variant_event_sha256=EVENT_VARIANT_SHA,control_seconds=a['phase_ms']['400_or_actual_steps_including_progress_queries']/1000,fused_seconds=b['phase_ms']['400_or_actual_steps_including_progress_queries']/1000,counters=c)
  summary['status']='PASS';write();print(json.dumps(summary,indent=2))
 except Exception as exc:
  summary.update(status='FAIL',error_type=type(exc).__name__,error=str(exc));write();raise
if __name__=='__main__':main()
