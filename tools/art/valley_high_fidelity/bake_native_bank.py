"""Rasterize a licensed native scan into top-surface height and original-UV colour.
This removes its capture-floor boundary, not its genuine rock relief. No target image.
"""
import os,sys,json,hashlib
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt
src=Path(os.environ['LUANSHI_WORKSPACE_ROOT'])/'luanshi-environment-rebuild/assets/river_gate/world/masters/coast_rocks_03'
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True);j=json.loads((src/'coast_rocks_03.gltf').read_text());buffers=[(src/b['uri']).read_bytes() for b in j['buffers']]
def accessor(i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']];n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];d=np.dtype(dtype);return np.ndarray((a['count'],n),dtype=d,buffer=buffers[v['buffer']],offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',d.itemsize*n),d.itemsize)).copy()
p=j['meshes'][0]['primitives'][0];vs=accessor(p['attributes']['POSITION']);uv=accessor(p['attributes']['TEXCOORD_0']);tri=accessor(p['indices']).reshape(-1,3);image=np.asarray(Image.open(src/j['images'][0]['uri']).convert('RGB'))
x0,z0=vs[:,[0,2]].min(0);x1,z1=vs[:,[0,2]].max(0);nx,nz=512,684
heights=np.full((nz,nx),-100.,dtype=np.float32);colors=np.zeros((nz,nx,3),dtype=np.uint8);coverage=np.zeros((nz,nx),bool)
# glTF UV0 has top-left image origin. Source metre bounds are unscaled.
for ids in tri:
 a,b,c=vs[ids];ta,tb,tc=uv[ids]
 den=(b[2]-c[2])*(a[0]-c[0])+(c[0]-b[0])*(a[2]-c[2])
 if abs(den)<1e-9:continue
 ix0=max(0,int(np.floor((min(a[0],b[0],c[0])-x0)/(x1-x0)*(nx-1))));ix1=min(nx-1,int(np.ceil((max(a[0],b[0],c[0])-x0)/(x1-x0)*(nx-1))))
 iz0=max(0,int(np.floor((min(a[2],b[2],c[2])-z0)/(z1-z0)*(nz-1))));iz1=min(nz-1,int(np.ceil((max(a[2],b[2],c[2])-z0)/(z1-z0)*(nz-1))))
 xx=x0+np.arange(ix0,ix1+1)[None,:]/(nx-1)*(x1-x0);zz=z0+np.arange(iz0,iz1+1)[:,None]/(nz-1)*(z1-z0)
 u=((b[2]-c[2])*(xx-c[0])+(c[0]-b[0])*(zz-c[2]))/den;v=((c[2]-a[2])*(xx-c[0])+(a[0]-c[0])*(zz-c[2]))/den;w=1-u-v
 h=u*a[1]+v*b[1]+w*c[1];region=heights[iz0:iz1+1,ix0:ix1+1];valid=(u>=-.00001)&(v>=-.00001)&(w>=-.00001)&(h>region)
 if not valid.any():continue
 tx=u*ta[0]+v*tb[0]+w*tc[0];tz=u*ta[1]+v*tb[1]+w*tc[1];rgb=image[np.clip((tz*(image.shape[0]-1)).astype(int),0,image.shape[0]-1),np.clip((tx*(image.shape[1]-1)).astype(int),0,image.shape[1]-1)]
 region[valid]=h[valid];colors[iz0:iz1+1,ix0:ix1+1][valid]=rgb[valid];coverage[iz0:iz1+1,ix0:ix1+1][valid]=True
# Only fill tiny projected cracks; authored masks avoid the capture boundary.
inds=distance_transform_edt(~coverage,return_distances=False,return_indices=True);heights=heights[tuple(inds)];colors=colors[tuple(inds)]
np.savez_compressed(out/'native-bank-field.npz',height=heights,color=colors,bounds=np.array([x0,x1,z0,z1]),coverage=coverage)
Image.fromarray(colors[::-1]).save(out/'native-bank-top-projection.jpg',quality=95)
report={'method':'topmost native triangle barycentric original UV projection, original metre scale, no generic cliff upscaling','license':'CC0-1.0','source_bounds_godot':vs.min(0).tolist()+vs.max(0).tolist(),'resolution':[nx,nz],'coverage_fraction':float(coverage.mean()),'source_inputs':[{'name':q.name,'sha256':hashlib.sha256(q.read_bytes()).hexdigest()} for q in src.iterdir() if q.suffix in ['.gltf','.bin','.jpg','.json']],'baked_npz_sha256':hashlib.sha256((out/'native-bank-field.npz').read_bytes()).hexdigest(),'scope':'AUTHORING_COMPONENT_NOT_GAME_OR_ART_PASS'}
(out/'native-bank-provenance.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
