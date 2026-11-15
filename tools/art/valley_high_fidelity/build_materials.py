"""Deterministic source texture processing, not target-image projection.
Licensed source pixels form a unique world-space terrain atlas; outputs are ordinary glTF textures.
"""
from pathlib import Path
import sys,json,hashlib,os
import numpy as np
from PIL import Image,ImageFilter
from layout import *
ROOT=Path(os.environ['LUANSHI_WORKSPACE_ROOT'])/'luanshi-environment-rebuild/assets/river_gate/world'
MAT=Path(os.environ['LUANSHI_PRODUCTION_ROOT'])/'luanshi-material-intake-20261114'
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
receipts=[]
def source(p):
 receipts.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});return Image.open(p).convert('RGB')
def sample(im,x,z,scale):
 # Area-prefilter to actual world-atlas texel density; nearest raw 2K sampling aliases soil into grain.
 target=max(32,round(scale*8192/144));im=im.resize((target,target),Image.Resampling.LANCZOS)
 a=np.asarray(im,dtype=np.float32)/255.;ix=np.floor((x/scale%1)*im.width).astype(np.int32);iz=np.floor((z/scale%1)*im.height).astype(np.int32);return a[iz,ix]
def tame(a,base,strength=.5):
 lum=a.mean(axis=-1,keepdims=True);base=np.asarray(base).reshape((1,1,3))
 # Preserve observed meso-scale soil/leaf structure; old .4*lum erased almost all relief.
 mean=np.mean(lum);relative=np.clip(lum/max(mean,.02),.18,2.1)**.55
 return np.clip(base*relative+strength*(a-lum),0,1)
# Physical feature widths match sources; contrast hierarchy is an explicit art derivative.
soil=source(ROOT/'ground/sandy_gravel_02.jpg');grass=source(ROOT/'ground/leafy_grass.jpg');mud=source(ROOT/'ground/brown_mud_dry.jpg');forest=source(ROOT/'ground/forest_ground_04.jpg')
w,h=8192,4800;x=np.linspace(-60,84,w)[None,:];allz=np.linspace(42,-42,h)
canvas=Image.new('RGB',(w,h))
for row in range(0,h,320):
 z=allz[row:row+320,None];cover=landcover(x,z)[...,None]
 s=tame(sample(soil,x,z,2.5),[.48,.445,.365],.45)
 g=tame(sample(grass,x,z,2.),[.34,.365,.245],.62)
 b=tame(sample(mud,x,z,1.3),[.43,.402,.325],.42)
 # Rich soil is local to soft road margins, not evenly stamped across every metre.
 edgewear=(1-np.abs(cover*2-1))*.24
 compaction=.24+.15*np.sin(x*.45+z*.37)*np.sin(x*.17-z*.66)
 s=s*(1-compaction[...,None])+b*compaction[...,None]
 s=s*(1-edgewear)+b*edgewear
 macro=(.012*np.sin(x*.20+z*.31)+.009*np.sin(x*.57-z*.25))[...,None]
 a=s*(1-cover)+g*cover+macro
 ruts=np.exp(-((z-road_center(x)-1.05)/.20)**2)+np.exp(-((z-road_center(x)+1.05)/.20)**2)
 ruts*=smooth(-57,-30,x)*(1-smooth(-13,-9,x));a-=ruts[...,None]*.018
 hh=np.where(x<0,base_height(x,z,'west'),base_height(x,z,'east'));damp=1-smooth(-.5,.55,hh)
 a=np.clip(a*(1-.19*damp[...,None]),0,1)
 bankmask,bankheight,bankcolor=bank_samples(x,z);a=a*(1-bankmask[...,None])+bankcolor*bankmask[...,None]
 canvas.paste(Image.fromarray((a*255).astype('uint8')),(0,row))
canvas.save(out/'valley-albedo.jpg',quality=95,subsampling=0)
# Author-generated periodic wave slopes, not random noise or photographed highlights.
size=1024;u=np.arange(size)[None,:]/size*2*np.pi;v=np.arange(size)[:,None]/size*2*np.pi
wave=np.zeros((size,size));du=wave.copy();dv=wave.copy()
for kx,kz,amp,phase in [(3,5,.025,.7),(-4,11,.018,1.2),(8,17,.009,2.8),(7,-5,.018,.1),(-11,21,.007,1.8),(13,31,.004,2.3),(17,-23,.004,.5),(-19,13,.006,3.3)]:
 phasefield=u*kx+v*kz+phase+1.7*np.sin(u*2+v*3)+.9*np.sin(u*3-v*2)
 du+=amp*kx*np.cos(phasefield);dv+=amp*kz*np.cos(phasefield)
n=np.stack((-du,-dv,np.ones_like(du)),axis=-1);n/=np.linalg.norm(n,axis=-1,keepdims=True)
Image.fromarray(((n*.5+.5)*255).astype('uint8')).save(out/'river-current-normal.png')
# Individual dressed blocks receive a real stone interior, not a repeating wall-joint image.
im=source(MAT/'medieval_blocks_03/medieval_blocks_03_diff_2k.png')
crops=[(330,30,900,360),(990,45,1550,365),(625,450,1280,780),(70,870,690,1220),(1200,875,1950,1220)]
normal=source(MAT/'medieval_blocks_03/medieval_blocks_03_nor_gl_2k.png')
for i,box in enumerate(crops):
 crop=im.crop(box).resize((1024,768),Image.Resampling.LANCZOS);a=np.asarray(crop).astype(np.float32)/255.;lum=a.mean(axis=-1,keepdims=True)
 a=np.clip(lum*.72+np.array([.17,.172,.16])+(a-lum)*.40,0,1)
 Image.fromarray((a*255).astype('uint8')).save(out/('stone-interior'+('' if i==0 else '-'+str(i))+'.jpg'),quality=95)
 normal.crop(box).resize((1024,768),Image.Resampling.LANCZOS).save(out/('stone-normal-'+str(i)+'.png'))
im=source(ROOT/'masters/modular_wooden_pier/modular_wooden_pier_planks_diff_2k.jpg');a=np.asarray(im).astype(np.float32)/255.;lum=a.mean(axis=-1,keepdims=True);a=np.clip(lum*1.10+.035+(a-lum)*.80,0,1)
Image.fromarray((a*255).astype('uint8')).save(out/'weathered-deck-atlas.jpg',quality=95)
# Neutral fired-clay mineral microstructure, derived from acquired CC0 stone interior.
# This supplies quiet grain only; every overlapping tile and cap is real new geometry.
clay=np.asarray(source(MAT/'medieval_blocks_03/medieval_blocks_03_diff_2k.png').crop((330,30,900,360)).resize((512,256),Image.Resampling.LANCZOS),dtype=np.float32)/255.
claylum=clay.mean(axis=-1,keepdims=True);claylum=(claylum-claylum.mean())*.18
for i,base in enumerate([[.355,.34,.305],[.365,.349,.315],[.345,.332,.297]]):
 Image.fromarray((np.clip(claylum+np.array(base),0,1)*255).astype('uint8')).save(out/('fired-clay-'+str(i)+'.jpg'),quality=95)
# Original atlas UV remains intact for the scans. Retone only the mineral hue range.
im=source(ROOT/'masters/rock_moss_set_01/rock_moss_set_01_diff_2k.jpg');a=np.asarray(im).astype(np.float32)/255.;lum=a.mean(axis=-1,keepdims=True);a=np.clip(lum*.83+np.array([.075,.082,.077])+(a-lum)*.55,0,1)
Image.fromarray((a*255).astype('uint8')).save(out/'rock-mineral-atlas.jpg',quality=95)
(out/'material-provenance.json').write_text(json.dumps({'license':'CC0-1.0','derivative':'world atlas and individual stone/mineral interpretation; never owner-reference projection','inputs':receipts,'ground_source_receipt':json.loads((ROOT/'ground/SOURCE.json').read_text())},indent=2))
print('MATERIALS_BUILT',out)
