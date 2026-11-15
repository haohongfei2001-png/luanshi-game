"""Compare actual Godot-imported UV/material state against the exact GLB contract.
No image edits, scene render, GLB rewrite or dependence on a particular GPU driver.
"""
import sys,json,struct,pathlib,io,hashlib
from functools import lru_cache
import numpy as np
from PIL import Image
source,receipt,dest=map(pathlib.Path,sys.argv[1:]);raw=source.read_bytes();size=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+size]);binary=raw[28+size:];actual=json.loads(receipt.read_text());assert actual['glb_sha256']==hashlib.sha256(raw).hexdigest()
def accessor(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']];n={'VEC2':2,'VEC3':3,'VEC4':4,'SCALAR':1}[a['type']];offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',np.dtype(dtype).itemsize*n)
 return np.ndarray((a['count'],n),dtype=dtype,buffer=binary,offset=offset,strides=(stride,np.dtype(dtype).itemsize)).astype(float)
@lru_cache(maxsize=16)
def image(texture):
 im=g['images'][g['textures'][texture]['source']];v=g['bufferViews'][im['bufferView']];b=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];return np.asarray(Image.open(io.BytesIO(b)).convert('RGB'),dtype=float)/255.
def sample(im,uv):
 # Repeat + bilinear sampling, same convention for both coordinates.
 h,w,_=im.shape;x=(uv[0]%1)*w-.5;y=(uv[1]%1)*h-.5;ix=int(np.floor(x));iy=int(np.floor(y));fx=x-ix;fy=y-iy
 return im[iy%h,ix%w]*(1-fx)*(1-fy)+im[iy%h,(ix+1)%w]*fx*(1-fy)+im[(iy+1)%h,ix%w]*(1-fx)*fy+im[(iy+1)%h,(ix+1)%w]*fx*fy
nodes={n.get('name'):n for n in g['nodes'] if 'mesh' in n};results=[]
for row in actual['surfaces']:
 node=nodes[row['node']];mesh=g['meshes'][node['mesh']];assert len(mesh['primitives'])==1;p=mesh['primitives'][0];at=p['attributes'];mat=g['materials'][p['material']];positions=accessor(at['POSITION']);uvs={int(k[9:]):accessor(v) for k,v in at.items() if k.startswith('TEXCOORD_')};channels={}
 if 'baseColorTexture' in mat['pbrMetallicRoughness']:channels['base']=mat['pbrMetallicRoughness']['baseColorTexture']
 if 'normalTexture' in mat:channels['normal']=mat['normalTexture']
 if 'metallicRoughnessTexture' in mat['pbrMetallicRoughness']:channels['ORM']=mat['pbrMetallicRoughness']['metallicRoughnessTexture']
 samples=[]
 for s in row['samples']:
  # glTF optimizer may reorder vertices; pair by position plus untouched UV0.
  score=np.linalg.norm(positions-np.array(s['position']),axis=1)+np.linalg.norm(uvs[0]-np.array(s['uv0']),axis=1);i=int(score.argmin());assert score[i]<.0001,(row['node'],score[i])
  imported_uv2_error=float(np.linalg.norm(uvs[1][i]-s['uv1'])) if 1 in uvs else None
  observed=np.array(s['uv0'])*row['uv1_scale']+row['uv1_offset'];entry={'imported_vertex_index':s['index'],'matched_gltf_index':i,'match_error':float(score[i]),'imported_uv0':s['uv0'],'imported_uv1':s['uv1'],'uv1_vs_gltf_texcoord1_error':imported_uv2_error,'actual_all_standard_channels_uv':observed.tolist(),'channels':{}}
  for name,info in channels.items():
   tr=info.get('extensions',{}).get('KHR_texture_transform',{});coord=tr.get('texCoord',info.get('texCoord',0));assert not tr.get('rotation',0)
   expected=uvs[coord][i]*tr.get('scale',[1,1])+tr.get('offset',[0,0]);wrapped=np.abs((expected-observed+.5)%1-.5);im=image(info['index']);expected_rgb=sample(im,expected);observed_rgb=sample(im,observed)
   entry['channels'][name]={'expected_texcoord':coord,'expected_uv':expected.tolist(),'wrapped_uv_error':wrapped.tolist(),'expected_bilinear_rgb':expected_rgb.tolist(),'actual_coordinate_bilinear_rgb':observed_rgb.tolist(),'rgb_abs_error':np.abs(expected_rgb-observed_rgb).tolist()}
  samples.append(entry)
 results.append({'node':row['node'],'material':row['material'],'matched_samples':len(samples),'samples':samples})
report={'glb_sha256':actual['glb_sha256'],'engine':actual['engine'],'scope':'actual import UV arrays + material parameters, standard shader sampling proven against official4.6.3 source; CPU texture-sample diagnostic, NOT GPU pixels or cause attribution','affected_surfaces':len(results),'surfaces':results,'official_sources':['https://github.com/godotengine/godot/blob/4.6.3-stable/scene/resources/material.cpp#L1245','https://github.com/godotengine/godot/blob/4.6.3-stable/scene/resources/material.cpp#L1685','https://github.com/godotengine/godot/blob/4.6.3-stable/scene/resources/material.cpp#L1752','https://github.com/godotengine/godot/blob/4.6.3-stable/modules/gltf/gltf_document.cpp#L1531']};dest.write_text(json.dumps(report,indent=2));print('ACTUAL_UV_CONTRACT_MISMATCH_SURFACES',len(results))
