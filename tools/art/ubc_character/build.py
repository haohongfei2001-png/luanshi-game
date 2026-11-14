"""Preserve UBC mesh/binds/weights, retarget UAL world rest-relative rotations.
No Blender scripts or downloaded code are executed. numpy/scipy required.
"""
import copy, hashlib, json, pathlib, struct, sys
import numpy as np
from scipy.spatial.transform import Rotation as R, Slerp

CLIPS=['Idle_Loop','Walk_Loop','Jog_Fwd_Loop','Sprint_Loop','Hit_Chest','Hit_Head','Death01','Sword_Idle','Sword_Attack']

def read_glb(path):
 b=path.read_bytes(); n=struct.unpack_from('<I',b,12)[0]
 return json.loads(b[20:20+n]), b[28+n:]

def access(j,b,i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']]
 sizes={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
 dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
 return np.frombuffer(b,dtype=dtype,count=a['count']*sizes[a['type']],offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],sizes[a['type']]).copy()

def hierarchy(j):
 parents={c:i for i,n in enumerate(j['nodes']) for c in n.get('children',[])}
 order=[]
 def visit(i):
  order.append(i)
  for c in j['nodes'][i].get('children',[]):visit(c)
 for i in range(len(j['nodes'])):
  if i not in parents:visit(i)
 return parents,order

def rest(j):
 p,o=hierarchy(j);g={}
 for i in o:
  q=R.from_quat(j['nodes'][i].get('rotation',[0,0,0,1]))
  g[i]=g[p[i]]*q if i in p else q
 return g

def build(root,out):
 target=next(root.rglob('Superhero_Male_FullBody.gltf'))
 d=json.loads(target.read_text());raw=(target.parent/d['buffers'][0]['uri']).read_bytes();binary=bytearray(raw)
 s,sb=read_glb(next(root.rglob('UAL1_Standard.glb')))
 sp,so=hierarchy(s);tp,to=hierarchy(d);sg=rest(s);tg=rest(d)
 sn={n['name']:i for i,n in enumerate(s['nodes'])};tn={n['name']:i for i,n in enumerate(d['nodes'])}
 joints=d['skins'][0]['joints'];mapping={i:sn[d['nodes'][i]['name']] for i in joints}
 assert len(joints)==65 and all(i in mapping for i in joints)
 ratio=d['nodes'][tn['pelvis']]['translation'][2]/s['nodes'][sn['pelvis']]['translation'][2]
 def append(data,kind):
  while len(binary)%4:binary.append(0)
  a=np.asarray(data,dtype='<f4');v=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':a.nbytes});binary.extend(a.tobytes())
  ix=len(d['accessors']);spec={'bufferView':v,'componentType':5126,'count':len(a),'type':kind}
  if kind=='SCALAR':spec.update(min=[float(a.min())],max=[float(a.max())])
  d['accessors'].append(spec);return ix
 # Embed existing source images verbatim. Do not replace professional source textures.
 for im in d.get('images',[]):
  uri=im.pop('uri'); image_path=target.parent/uri
  if not image_path.exists():
   image_path=target.parent/uri.replace('_png.png','.png')
  data=image_path.read_bytes()
  while len(binary)%4:binary.append(0)
  im['bufferView']=len(d['bufferViews']);d['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(data)});binary.extend(data)
 d['animations']=[];report={'source_joints':65,'target_joints':65,'pelvis_displacement_scale':ratio,'clips':[],'visual_pass':False,'retarget':'world rest-relative rotations; fixed target limb translation and scale; scaled source root/pelvis displacement','source_mesh_binary_sha256':hashlib.sha256(raw).hexdigest()}
 for anim in s['animations']:
  if anim['name'] not in CLIPS:continue
  channels={};duration=0
  for ch in anim['channels']:
   sampler=anim['samplers'][ch['sampler']];t=access(s,sb,sampler['input']).flatten();v=access(s,sb,sampler['output']);duration=max(duration,float(t[-1]));assert sampler.get('interpolation','LINEAR')=='LINEAR'
   channels[ch['target']['node'],ch['target']['path']]=(t,v)
  times=np.linspace(0,duration,round(duration*30)+1);rot={i:[] for i in joints};pos={i:[] for i in joints if d['nodes'][i]['name'] in ('root','pelvis')}
  for time in times:
   ag={}
   for i in so:
    base=s['nodes'][i];q=R.from_quat(base.get('rotation',[0,0,0,1]))
    if (i,'rotation') in channels:
     ts,vs=channels[i,'rotation'];q=Slerp(ts,R.from_quat(vs))([np.clip(time,ts[0],ts[-1])])[0] if len(ts)>1 else R.from_quat(vs[0])
    ag[i]=ag[sp[i]]*q if i in sp else q
   targetglobal={}
   for i in to:
    parent=targetglobal.get(tp.get(i),R.identity())
    if i in mapping:
     si=mapping[i];world=ag[si]*sg[si].inv()*tg[i];local=parent.inv()*world;rot[i].append(local.as_quat());targetglobal[i]=world
     if i in pos:
      st=np.array(s['nodes'][si].get('translation',[0,0,0]));delta=np.zeros(3)
      if (si,'translation') in channels:
       ts,vs=channels[si,'translation'];delta=np.array([np.interp(time,ts,vs[:,axis]) for axis in range(3)])-st
      # Source parent local displacement -> world -> target animated parent local.
      source_parent=ag.get(sp.get(si),R.identity());delta=parent.inv().apply(source_parent.apply(delta))*ratio
      pos[i].append(np.array(d['nodes'][i].get('translation',[0,0,0]))+delta)
    else:targetglobal[i]=parent*R.from_quat(d['nodes'][i].get('rotation',[0,0,0,1]))
  a={'name':anim['name'],'channels':[],'samplers':[]};ti=append(times,'SCALAR')
  for typ,values in [('rotation',rot),('translation',pos)]:
   for i,vs in values.items():
    vs=np.array(vs)
    if typ=='rotation':
     for k in range(1,len(vs)):
      if np.dot(vs[k],vs[k-1])<0:vs[k]*=-1
    oi=append(vs,'VEC4' if typ=='rotation' else 'VEC3');a['channels'].append({'sampler':len(a['samplers']),'target':{'node':i,'path':typ}});a['samplers'].append({'input':ti,'output':oi,'interpolation':'LINEAR'})
  d['animations'].append(a);report['clips'].append({'name':a['name'],'duration':duration,'samples':len(times)})
 d['buffers']=[{'byteLength':len(binary)}];js=json.dumps(d,separators=(',',':')).encode();js+=b' '*((-len(js))%4);binary+=b'\0'*((-len(binary))%4)
 out.mkdir(parents=True,exist_ok=True);(out/'ubc_animated.glb').write_bytes(struct.pack('<III',0x46546c67,2,28+len(js)+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary)
 # Mesh accessor payload remains prefix-identical, including all original weights/bind matrices.
 assert bytes(binary[:len(raw)])==raw
 (out/'retarget-report.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report,indent=2))
if __name__=='__main__':build(pathlib.Path(sys.argv[1]),pathlib.Path(sys.argv[2]))
