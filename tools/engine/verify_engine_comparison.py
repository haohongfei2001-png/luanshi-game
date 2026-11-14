import json,pathlib,re,sys
root=pathlib.Path(sys.argv[1]); summary={}
for variant in ['original','patched']:
 d=root/variant
 probe=json.loads((d/'tangent_probe/probe.json').read_text())
 colors={r['kind']:list(map(float,re.findall(r'-?\d+(?:\.\d+)?',r['center_rgb'])))[:3] for r in probe['samples']}
 errors={k:max(abs(x-y) for x,y in zip(colors['static'],colors[k])) for k in ['identity_skin','identity_skin_roundtrip']}
 pixels=json.loads((d/'gpu/parity.json').read_text())
 blend=json.loads((d/'blend_skin_probe/probe.json').read_text())
 summary[variant]={'identity_errors':errors,'pixel_reports':pixels['reports'],'blend_cases':blend['cases'],'blend_failures':blend['failures'],'renderer':probe['renderer']}
 for name in ['probe.log','gpu.log','blend-probe.log']:
  assert not re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',(d/name).read_text()),(variant,name)
(root/'comparison.json').write_text(json.dumps(summary,indent=2)+'\n')
assert all(v>.1 for v in summary['original']['identity_errors'].values()),'original source build did not reproduce; investigate rather than claiming a fix'
assert all(v<=2/255 for v in summary['patched']['identity_errors'].values()),'patched identity tangent differs'
assert all(x['pass'] for x in summary['patched']['pixel_reports']),'patched original-material pixel gate failed'
assert not all(x['pass'] for x in summary['original']['pixel_reports']),'original full material failure not reproduced'
assert summary['patched']['blend_failures']==0 and len(summary['patched']['blend_cases'])==12,'patched blend+skin direction regression failed'
print('SAME_SOURCE_NATIVE_TANGENT_COMPARISON_PASS; engine experiment only, not shipping art/performance acceptance')
