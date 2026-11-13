"""Fit the open-licensed sculpt, head wraps and helmet to the river company's metre-scale bind."""
import json
from functools import lru_cache
from math import atan2, cos, floor, pi, sin
from pathlib import Path
from field_armour import field_helmet
from figure_atlas import uv
from figure_mesh import TAU, lerp

@lru_cache(maxsize=1)
def sculpt():
    return json.loads(Path(__file__).with_name("field_head.json").read_text())

@lru_cache(maxsize=1)
def marching_head():
    # Eight levels slice the same CC0 sculpt used for the close camera. Denser
    # angles at the forehead and nose keep a profile visible in a twelve-pixel face.
    mesh=sculpt()["close"]
    levels=(5.72,6.04,6.50,6.72,7.02,7.39,7.74,8.01)
    angles=(0,.42,1.13,2.09,pi,TAU-2.09,TAU-1.13,TAU-.42)
    points=[]
    for height in levels:
        edges=[]
        for tri in mesh["f"]:
            corners=[mesh["p"][i] for i in tri]
            cuts=[]
            for a,b in zip(corners,corners[1:]+corners[:1]):
                if min(a[1],b[1])<=height<max(a[1],b[1]):
                    t=(height-a[1])/(b[1]-a[1])
                    cuts.append((a[0]+(b[0]-a[0])*t,a[2]+(b[2]-a[2])*t-.35))
            if len(cuts)==2: edges.append(cuts)
        for angle in angles:
            dx,dz=sin(angle),cos(angle)
            radius=.06
            for (x,z),(bx,bz) in edges:
                ex,ez=bx-x,bz-z
                det=dx*ez-dz*ex
                if abs(det)<1.e-8: continue
                d=(x*ez-z*ex)/det
                u=(x*dz-z*dx)/det
                if 0<=u<=1: radius=max(radius,d)
            points.append((dx*radius,height,.35+dz*radius))
    faces=[]
    n=len(angles)
    for r in range(len(levels)-1):
        for i in range(n):
            a=r*n+i
            b=r*n+(i+1)%n
            faces.extend([(a,b,b+n),(a,b+n,a+n)])
    return {"p":points,"f":faces}

def head(s,look,bone):
    close=s.detail
    data=sculpt()
    heavy=look in ("regular","guard","officer")
    width={"levy":.105,"archer":.099,"regular":.105,"guard":.110,"officer":.109,"player":.105}[look]
    def bind(x,y,z):
        return (x*width, 1.725+(y-8.10)*.110, (z-.28)*.112+.015)
    def scalp(angle,height,extra=0):
        h=max(0,min(20.999,(height-6.33)/.081))
        u=(angle/TAU*32)%32
        col=int(u)
        row=int(h)
        def radius(n):
            a,b=data["scalp"][n][col],data["scalp"][n][(col+1)%32]
            return a+(b-a)*(u-col)
        r=radius(row)+(radius(row+1)-radius(row))*(h-row)+extra
        return bind(sin(angle)*r,height,.35+cos(angle)*r)
    def brow(a):
        return 7.00+.44*cos(a)+.07*sin(a+.4)
    source=data["close"] if close else marching_head()
    vertices={}
    for face in source["f"]:
        raw=[source["p"][i] for i in face]
        if heavy and all(y>brow(atan2(x,z-.35))+.12 for x,y,z in raw):
            continue
        x,y,z=[sum(p[k] for p in raw)/3 for k in range(3)]
        # One continuous sculpt carries both the hairline and the brow. Eye/mouth
        # recesses keep their modelled depth; painted lids never protrude as sticks.
        hairline=6.62+.86*max(0,min(1,(z+.32)/1.66))-.12*abs(x)
        mat="hair" if y>hairline else ("visage" if z>.61 else "skin")
        ids=[]
        for i in face:
            key=(i,mat)
            if key not in vertices:
                x,y,z=source["p"][i]
                st=uv(mat,max(.01,min(.99,.5+x/1.90)),max(.01,min(.99,(8.13-y)/2.63)))
                vertices[key]=s.vertex(bind(x,y,z),st,bone)
            ids.append(vertices[key])
        s.faces.append(tuple(ids))
    if close:
        for sign in (-1,1):
            # Inset eyeballs sit behind the eyelid aperture of the head sculpt.
            def eye(u,v):
                angle=TAU*(u-.5)
                latitude=(v-.5)*pi
                cx=sign*.294
                return bind(cx+.133*cos(latitude)*sin(angle),7.017+.124*sin(latitude),
                            1.212+.155*cos(latitude)*cos(angle)),bone
            s.grid(12,7,eye,"eye")
    n=24 if close else 8
    def band(row0,row1,material,thickness):
        def at(u,v):
            a=TAU*u
            y=brow(a)+row0+(row1-row0)*v
            return scalp(a,y,thickness+.022*sin(pi*v)),bone
        s.grid(n,3 if close else 1,at,material)
    if heavy:
        field_helmet(s,look,bone)
    elif look=="archer":
        # The archer's soft cloth cap follows the skull, leaving his draw shoulder clear.
        def cap(u,v):
            a=TAU*u
            h=brow(a)+.035+(8.045-brow(a))*v
            p=scalp(a,min(h,8.025),.070+.05*(1-v))
            top=bind(0,8.125,.22)
            return lerp(p,top,max(0.,(v-.80)/.20)),bone
        s.grid(n,5 if close else 3,cap,"facing")
        band(-.023,.13,"headcloth",.143)
        p=scalp(pi,7.15,.18)
        s.ribbon([p,(p[0]-.021,p[1]-.059,p[2]-.012),
                  (p[0]-.040,p[1]-.112,p[2]+.006)],.036,"headcloth",bone)
    else:
        band(-.015,.16,"leather" if look=="player" else "headcloth",.053)
        if close: band(.06,.095,"headcloth",.082)
        p=scalp(pi,7.89,.08)
        if look=="player":
            # The protagonist's folded topknot changes his outline at army scale.
            # A narrow cloth binding is visible between hairline and gathered hair.
            s.oval((-.010,1.714,-.047),(.049,.037,.052),"leather",bone,10 if close else 7,4)
            s.oval((-.016,1.755,-.054),(.059,.056,.068),"hair",bone,12 if close else 8,5)
        else:
            s.oval((p[0],p[1]+.025,p[2]),(.036,.037,.057),"hair",bone,10 if close else 6,5)
        # Cloth knot tied at the rear rather than a perfectly round bun on every crown.
        a=scalp(pi+.3,6.96,.09)
        s.ribbon([a,(a[0]-.022,a[1]-.042,a[2]-.026),(a[0]-.037,a[1]-.118,a[2]-.012)],.026,"headcloth",bone)
