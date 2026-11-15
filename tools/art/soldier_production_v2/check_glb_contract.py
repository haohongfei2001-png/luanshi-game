"""Check actual serialized rig/action/material contracts, not Blender UI state."""
import json,struct,sys,pathlib
p=pathlib.Path(sys.argv[1]);f=p.open('rb');assert f.read(4)==b'glTF';version,length=struct.unpack('<II',f.read(8));n,t=struct.unpack('<II',f.read(8));j=json.loads(f.read(n));assert version==2
assert len(j.get('skins',[]))==1 and len(j['skins'][0]['joints'])==163
expected={'Idle_Loop':2.5,'Walk_Loop':4/3,'Sprint_Loop':2/3,'Death01':2.4,'Hit_Chest':1/3,'Hit_Head':13/30,'Jog_Fwd_Loop':14/15}
actual={a['name']:max(j['accessors'][s['input']]['max'][0] for s in a['samplers']) for a in j['animations']}
for name,duration in expected.items():assert abs(actual[name]-duration)<.025,(name,actual[name],duration)
if '--ai-material' in sys.argv:
 m=next(m for m in j['materials'] if m['name']=='V2 continuous lamellar cuirass');tx=m['pbrMetallicRoughness']['baseColorTexture'];assert tx.get('extensions',{}).get('KHR_texture_transform',{}).get('scale')==[.125,.25],tx
 for key in ['normalTexture']:assert key in m
print(json.dumps({'status':'SERIALIZED_CONTRACT_PASS_NOT_VISUAL','rig_bones':163,'durations_s':actual,'ai_texture_scale_verified':'--ai-material' in sys.argv,'gpu':'NOT_RUN'},indent=2))
