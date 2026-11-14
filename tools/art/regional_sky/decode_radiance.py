"""Exact original RGBE -> float32; avoid Godot HDR RGBE9995 saturation at65408.
No exposure/color edit. Keeps raw source HDR and serializes verified linear data.
"""
import hashlib,json,pathlib,sys,io,numpy as np

def decode(path):
 f=io.BytesIO(path.read_bytes());header=[]
 while True:
  line=f.readline()
  if not line:raise ValueError('Truncated HDR header')
  header.append(line.decode('ascii').strip())
  if not line.strip():break
 fields=f.readline().decode('ascii').split()
 if len(fields)!=4 or fields[0]!='-Y' or fields[2]!='+X':raise ValueError('Unsupported orientation')
 h,w=int(fields[1]),int(fields[3])
 if (w,h)!=(2048,1024):raise ValueError('Unexpected frozen sky dimensions')
 data=np.empty((h,w,4),np.uint8)
 for y in range(h):
  marker=f.read(4)
  if len(marker)!=4 or marker[:2]!=b'\x02\x02' or int.from_bytes(marker[2:],'big')!=w:raise ValueError('Invalid scanline')
  for c in range(4):
   x=0
   while x<w:
    code=f.read(1)
    if not code or code[0]==0:raise ValueError('Invalid/truncated HDR run')
    repeat=code[0]>128;n=code[0]-128 if repeat else code[0]
    if x+n>w:raise ValueError('HDR run crosses row')
    payload=f.read(1 if repeat else n)
    if len(payload)!=(1 if repeat else n):raise ValueError('Truncated HDR run')
    data[y,x:x+n,c]=payload[0] if repeat else np.frombuffer(payload,np.uint8);x+=n
 rgb=np.ldexp(data[:,:,:3].astype(np.float32),data[:,:,3:4].astype(np.int16)-136);rgb[data[:,:,3]==0]=0
 if not np.isfinite(rgb).all() or rgb.min()<0:raise ValueError('Invalid HDR radiance')
 return rgb

if __name__=='__main__':
 p=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);source=json.loads(pathlib.Path(__file__).with_name('source.json').read_text())
 assert hashlib.sha256(p.read_bytes()).hexdigest()==source['sha256']
 rgb=decode(p);data=rgb.astype('<f4').tobytes();out.write_bytes(data);lum=rgb@np.array([.2126,.7152,.0722],np.float32);iy,ix=np.unravel_index(lum.argmax(),lum.shape)
 result={'source_sha256':source['sha256'],'linear_float_sha256':hashlib.sha256(data).hexdigest(),'dimensions':[2048,1024,3],'bytes':len(data),'max_channel':float(rgb.max()),'max_luminance':float(lum.max()),'sun_peak_xy':[int(ix),int(iy)],'transform':'exact original RGBE radiance decode; no exposure or color edits','rejected_builtin_hdr_loader':'Image FORMAT_RGBE9995 saturated this source at65408; original max73216'}
 pathlib.Path(str(out)+'.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
