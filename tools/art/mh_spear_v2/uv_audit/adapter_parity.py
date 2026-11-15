"""Independent CPU expected glTF vs actual-import UV/adapter mapping and PBR samples.
No GPU proof: base-level raw-image bilinear samples only, no mip/compression claim.
"""
import json,sys,struct,pathlib,io,hashlib
from functools import lru_cache
import numpy as np
from PIL import Image
source,expected_path,import_path,adapter_path,output=map(pathlib.Path,sys.argv[1:]);raw=source.read_bytes();n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);binary=raw[28+n:];expected=json.loads(expected_path.read_text());imported=json.loads(import_path.read_text());adapter=json.loads(adapter_path.read_text());sha=hashlib.sha256(raw).hexdigest();assert sha==adapter['source_sha256']==expected['glb_sha256']==imported['glb_sha256']
@lru_cache(None)
def image(index,linearize=False):
 im=g['images'][g['textures'][index]['source']];v=g['bufferViews'][im['bufferView']];b=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];a=np.asarray(Image.open(io.BytesIO(b)).convert('RGB'),dtype=float)/255
 return np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4) if linearize else a
def sample(im,uv):
 h,w,_=im.shape;x=(uv[0]%1)*w-.5;y=(uv[1]%1)*h-.5;ix=int(np.floor(x));iy=int(np.floor(y));fx=x-ix;fy=y-iy
 return im[iy%h,ix%w]*(1-fx)*(1-fy)+im[iy%h,(ix+1)%w]*fx*(1-fy)+im[(iy+1)%h,ix%w]*(1-fx)*fy+im[(iy+1)%h,(ix+1)%w]*fx*fy
lookup={(s['node'],r['imported_vertex_index']):(s,r) for s in expected['surfaces'] for r in s['samples']};nodes={x['name']:x for x in g['nodes'] if 'mesh' in x};im_lookup={(s['node'],r['index']):r for s in imported['surfaces'] for r in s['samples']}
max_uv=0.;max_rgb=0.;details=[];max_custom=0.
for row in adapter['parity_samples']:
 s,e=lookup[(row['node'],row['index'])];actual_import=im_lookup[(row['node'],row['index'])];primitive=g['meshes'][nodes[row['node']]['mesh']]['primitives'][0];mat=g['materials'][primitive['material']];p=mat['pbrMetallicRoughness'];infos={'normal':mat['normalTexture'],'base':p.get('baseColorTexture'),'ORM':p.get('metallicRoughnessTexture')}
 for channel,uv in row['corrected_uv'].items():
  exp=e['channels'][channel]['expected_uv'];error=float(np.max(np.abs(np.array(uv)-exp)));max_uv=max(max_uv,error)
  tex=image(infos[channel]['index'],channel=='base');a=sample(tex,exp);b=sample(tex,uv)
  if channel=='base':a*=p.get('baseColorFactor',[1,1,1,1])[:3];b*=p.get('baseColorFactor',[1,1,1,1])[:3]
  if channel=='ORM':a*=np.array([1,p.get('roughnessFactor',1),p.get('metallicFactor',1)]);b*=np.array([1,p.get('roughnessFactor',1),p.get('metallicFactor',1)])
  delta=float(np.max(np.abs(a-b)));max_rgb=max(max_rgb,delta);details.append({'node':row['node'],'vertex':row['index'],'channel':channel,'uv_error':error,'channel_sample_error':delta})
  if infos[channel].get('texCoord',0)==2:max_custom=max(max_custom,float(np.max(np.abs(np.array(actual_import['custom0_xy'])-exp))))
assert max_uv<1e-5 and max_rgb<.0001 and max_custom<1e-5
for actual in adapter['shader_materials']:
 name=actual['name'].split(' / exact')[0];m=next(m for m in g['materials'] if m['name']==name);p=m['pbrMetallicRoughness']
 assert np.max(np.abs(np.array(actual['base_factor_linear'])-p.get('baseColorFactor',[1,1,1,1])))<1e-6
 for key in ['metallic','roughness']:assert abs(actual[key+'_factor']-p.get(key+'Factor',1))<1e-6
 assert abs(actual['normal_scale']-m['normalTexture'].get('scale',1))<1e-6
report={'source_sha256':sha,'sampled_channel_coordinates':len(details),'max_uv_error':max_uv,'max_baselevel_channel_error':max_rgb,'actual_CUSTOM0_xy_vs_glTF_TEXCOORD2_max_error':max_custom,'shader_frontend_uniforms':adapter['shader_uniforms_in_headless'],'real_unit_bindings':adapter['actors'],'scope':'Actual imported UV0/UV2/CUSTOM0 and bound material factors; independent CPU baselevel glTF sampling parity; GPU/backend/mips NOT_TESTED','samples':details};output.write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k!='samples'}))
