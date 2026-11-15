"""One authored metre-space landform field, shared by material, mesh and semantics."""
import numpy as np
import os
SEED=20261115
BOUNDS=(-60.,84.,-42.,42.)
WATER_Y=-.65
PAVING=[('west_landing',-8.2,-5.,-3.1,3.1,1.,1.),('east_landing',5.,9.7,-3.1,3.1,1.,1.2),('gate_tunnel',9.7,15.5,-3.1,3.1,1.2,1.2)]
def smooth(a,b,x):
 t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def gauss(x,z,cx,cz,rx,rz):return np.exp(-((x-cx)/rx)**2-((z-cz)/rz)**2)
def edge(z,side):
 zs=[-42,-31,-22,-14,-8,0,7,15,23,32,42]
 xs=[-14,-11,-15,-12,-10,-5,-8,-12,-16,-14,-18] if side=='west' else [15,13,11.5,10.5,9.3,5,9.2,10.1,11.5,13,17]
 # C1 shoreline curve prevents angular spline-knot cuts in long river views.
 z=np.asarray(z);zs=np.asarray(zs,dtype=float);xs=np.asarray(xs,dtype=float)
 slope=np.gradient(xs,zs);i=np.clip(np.searchsorted(zs,z,side='right')-1,0,len(zs)-2)
 span=zs[i+1]-zs[i];t=np.clip((z-zs[i])/span,0,1)
 return (2*t**3-3*t**2+1)*xs[i]+(t**3-2*t**2+t)*span*slope[i]+(-2*t**3+3*t**2)*xs[i+1]+(t**3-t**2)*span*slope[i+1]
def road_center(x):return -.0039*np.minimum(x+5,0)**2

def road_weight(x,z):
 center=np.where(x<-5,road_center(x),0.)
 width=np.where(x<-5,3.5+.022*np.maximum(-x-5,0),3.1)
 d=np.abs(z-center)
 irregular=.25*np.sin(x*.48+z*.7)+.17*np.sin(x*1.13-z*.82)
 return 1-smooth(width-.45,width+2.4+irregular,d)
def base_height(x,z,side=None):
 x=np.asarray(x);z=np.asarray(z)
 if side is None:side='west' if float(np.mean(x))<0 else 'east'
 e=edge(z,side);d=e-x if side=='west' else x-e
 terrace=1.15+.22*np.sin(x*.083+z*.12)+.12*np.sin(z*.31-x*.17)
 if side=='west':
  terrace+=2.0*gauss(x,z,-19,12,11,9)+1.55*gauss(x,z,-17,-15,10,8)+1.8*gauss(x,z,-43,33,18,10)
  terrace-=.40*gauss(x,z,-28,-10,10,3)
 else:
  terrace+=1.4*gauss(x,z,14,18,9,12)+1.8*gauss(x,z,20,-26,15,12)
  terrace=np.where((x>15.5)&(np.abs(z)<22),1.2+.08*np.sin(x*.16)*np.sin(z*.13),terrace)
 bank=-2.0+smooth(-2.8,5.2,d)*(terrace+2.0)
 h=np.where(d>5.2,terrace,bank)
 rw=road_weight(x,z)
 # Packed military road has gentle longitudinal drainage, not a noisy hill.
 rh=np.where(x<-5,1.+np.maximum(-x-22,0)*.006,np.where(x<9.7,1.+np.clip((x-5)/4.7,0,1)*.2,1.2))
 if side=='west':rw*=1-smooth(-5.,-4.7,x)
 else:rw*=smooth(4.7,5.,x)
 h=h*(1-rw)+rh*rw
 # Broad dry staging areas hold the real armies, outside the primary composition.
 if side=='west':
  mask=smooth(-57,-52,x)*(1-smooth(-29,-25,x))*(1-smooth(19,23,np.abs(z)))
  h=h*(1-mask)+(1.15+.04*np.sin(z*.18))*mask
 return h

def landcover(x,z):
 rw=road_weight(x,z)
 macro=.5+.20*np.sin(x*.24+z*.17)+.13*np.sin(x*.67-z*.36)+.10*np.sin(z*.98+x*.17)
 shoulder=np.clip((1-rw)*(.48+.62*macro),0,1)
 woodland=smooth(10,18,np.abs(z))*.5
 return np.clip(shoulder+woodland*(1-rw),0,1)

# Real native scan relief and original-UV colour are both sampled in the same metre transform.
_BANK=None
BANK_PATCHES=[(-15.2,-25.,5.8,7.0,.7,.4),(-11.5,12.3,6.8,8.3,0.,.75),(-12.8,-13.2,6.,7.4,1.45,.65),(10.6,-14.8,5.6,8.3,3.14,.70)]
def bank_samples(x,z):
 global _BANK
 xx,zz=np.broadcast_arrays(np.asarray(x),np.asarray(z));mask=np.zeros(xx.shape);hh=np.zeros(xx.shape);color=np.zeros(xx.shape+(3,))
 path=os.environ.get('LUANSHI_BANK_FIELD')
 if not path:return mask,hh,color
 if _BANK is None:
  data=np.load(path);_BANK={key:data[key] for key in data.files};data.close()
 heights=_BANK['height'];colors=_BANK['color'];x0,x1,z0,z1=_BANK['bounds'];nz,nx=heights.shape
 for cx,cz,rx,rz,angle,dy in BANK_PATCHES:
  dx=xx-cx;dz=zz-cz;rr=(dx/rx)**2+(dz/rz)**2;weight=np.clip(1-rr,0,1)**1.35
  weight*=1-road_weight(xx,zz);active=(weight>mask)&(weight>0)
  if not np.any(active):continue
  ax=xx[active];az=zz[active];dx=ax-cx;dz=az-cz;u=dx*np.cos(angle)+dz*np.sin(angle);v=-dx*np.sin(angle)+dz*np.cos(angle)
  wf=weight[active]*smooth(-.1,.2,base_height(ax,az,'west' if cx<0 else 'east')+.65)
  ix=np.clip((u-x0)/(x1-x0)*(nx-1),0,nx-1.001);iz=np.clip((v-z0)/(z1-z0)*(nz-1),0,nz-1.001);xi=ix.astype(int);zi=iz.astype(int);tx=ix-xi;tz=iz-zi
  h=heights[zi,xi]*(1-tx)*(1-tz)+heights[zi,xi+1]*tx*(1-tz)+heights[zi+1,xi]*(1-tx)*tz+heights[zi+1,xi+1]*tx*tz
  rgb=colors[zi,xi].astype(float)/255.;lum=rgb.mean(axis=-1,keepdims=True);rgb=np.clip(lum*.83+np.array([.115,.12,.115])+(rgb-lum)*.52,0,1)
  indices=np.flatnonzero(active);choose=wf>mask.ravel()[indices];indices=indices[choose]
  hh.ravel()[indices]=h[choose]+dy;color.reshape(-1,3)[indices]=rgb[choose];mask.ravel()[indices]=wf[choose]
 return mask,hh,color

def height(x,z,side=None):
 base=base_height(x,z,side);mask,scan,_=bank_samples(x,z);return base*(1-mask)+scan*mask
