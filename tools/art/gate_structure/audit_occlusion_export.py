"""Audit AO as a separate glTF material channel without modifying pixels."""
from pathlib import Path
import struct,json,hashlib,sys,io
from PIL import Image

def glb(path):
 data=Path(path).read_bytes();length,kind=struct.unpack_from('<II',data,12)
 if data[:4]!=b'glTF' or kind!=0x4e4f534a:raise ValueError('Not a GLB')
 meta=json.loads(data[20:20+length]);offset=20+length;size,kind=struct.unpack_from('<II',data,offset)
 if kind!=0x004e4942:raise ValueError('No GLB binary')
 return meta,data[offset+8:offset+8+size]
def image_bytes(meta,binary,texture):
 im=meta['images'][meta['textures'][texture['index']]['source']];v=meta['bufferViews'][im['bufferView']]
 return binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
def audit(before,after):
 old,ob=glb(before);new,nb=glb(after);oldm={m['name']:m for m in old['materials']};rows=[]
 for m in new['materials']:
  if m.get('name') not in ['timber','timber_cut','masonry']:continue
  name=m['name'];prior=oldm[name];pbr=m['pbrMetallicRoughness'];ppbr=prior['pbrMetallicRoughness'];occ=m.get('occlusionTexture')
  if not occ:raise ValueError('Source AO missing: '+name)
  if any(t.get('texCoord',0)!=0 for t in [occ,pbr['metallicRoughnessTexture'],pbr['baseColorTexture'],m['normalTexture']]):raise ValueError('PBR material UV is not Godot-supported primary UV')
  now=image_bytes(new,nb,pbr['baseColorTexture']);original=image_bytes(old,ob,ppbr['baseColorTexture'])
  if now!=original:raise ValueError('Albedo changed while adding separate AO: '+name)
  rough0=Image.open(io.BytesIO(image_bytes(old,ob,ppbr['metallicRoughnessTexture']))).convert('RGB').getchannel('G')
  rough1=Image.open(io.BytesIO(image_bytes(new,nb,pbr['metallicRoughnessTexture']))).convert('RGB').getchannel('G')
  if rough0.size!=rough1.size or rough0.tobytes()!=rough1.tobytes():raise ValueError('Roughness changed while adding AO: '+name)
  ao=Image.open(io.BytesIO(image_bytes(new,nb,occ))).convert('RGB').getchannel('R')
  if ao.getextrema()==(255,255):raise ValueError('Exported AO unexpectedly empty/white: '+name)
  if m['normalTexture']!=prior['normalTexture']:
   # Texture indices may move, but source normal bytes/strength/UV must not.
   if image_bytes(new,nb,m['normalTexture'])!=image_bytes(old,ob,prior['normalTexture']):raise ValueError('Normal pixels changed')
   for key in ['scale']:
    if m['normalTexture'].get(key)!=prior['normalTexture'].get(key):raise ValueError('Normal semantics changed')
  rows.append({'material':name,'occlusionTexture':occ,'ao_red_min_max':ao.getextrema(),'albedo_byte_identical':True,'albedo_sha256':hashlib.sha256(now).hexdigest(),'roughness_green_byte_identical':True,'source':'original hash-locked Poly Haven material micro-occlusion; not global contact shadow'})
 if len(rows)!=3:raise ValueError('Expected all three material variants')
 return {'result':'PASS_STANDARD_OCCLUSION_EXPORT_NOT_GAMEPLAY_ART','materials':rows}
if __name__=='__main__':
 r=audit(sys.argv[1],sys.argv[2]);Path(sys.argv[3]).write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
