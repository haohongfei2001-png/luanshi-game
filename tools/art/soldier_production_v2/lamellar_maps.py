"""Authored regular lamellar construction maps; no random dirt/noise/painted light.
Tile physical extent 28x66mm. Basecolor and tangent relief are independent.
"""
import numpy as np
from PIL import Image
import pathlib,sys
p=pathlib.Path(sys.argv[1]);p.mkdir(parents=True,exist_ok=True);n=512
y,x=np.mgrid[0:n,0:n]/n
edge=np.minimum(x,1-x);row=np.minimum(y,1-y)
plate=np.clip((edge-.035)/.035,0,1)*np.clip((row-.04)/.04,0,1)
height=plate*.0008
color=np.zeros((n,n,3))+[.28,.31,.33];color*=.70+.30*plate[:,:,None]
# Narrow dark physical split and two warm binding cords cross each top edge.
cord=np.zeros_like(x)
for cx in [.19,.81]:
 dx=np.minimum(abs(x-cx),1-abs(x-cx));dy=np.minimum(abs(y-.12),1-abs(y-.12));c=np.clip(1-((dx/.027)**2+(dy/.10)**2),0,1);cord=np.maximum(cord,c)
height+=cord*.0012;color=color*(1-cord[:,:,None])+np.array([.30,.16,.08])*cord[:,:,None]
dy,dx=np.gradient(height,.066/n,.028/n);normal=np.stack([-dx,dy,np.ones_like(x)],axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
Image.fromarray(np.uint8(np.clip(color,0,1)*255),'RGB').save(p/'lamellar-basecolor.png')
Image.fromarray(np.uint8((normal*.5+.5)*255),'RGB').save(p/'lamellar-normal.png')
rough=np.zeros_like(x)+.68;rough=np.maximum(rough,cord*.86);metal=.42*(1-cord)
Image.fromarray(np.uint8(np.stack([np.ones_like(x),rough,metal],axis=-1)*255),'RGB').save(p/'lamellar-orm.png')
