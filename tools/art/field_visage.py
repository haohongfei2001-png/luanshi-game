"""Fit the open-licensed sculpt, head wraps and helmet to the river company's metre-scale bind."""
import json
from functools import lru_cache
from math import atan2, cos, floor, pi, sin
from pathlib import Path
from figure_atlas import uv
from figure_mesh import TAU

@lru_cache(maxsize=1)
def sculpt():
    return json.loads(Path(__file__).with_name("field_head.json").read_text())

def head(s,look,bone):
    close=s.detail
    data=sculpt()
    heavy=look in ("guard","officer","player")
    width={"levy":.105,"archer":.099,"guard":.110,"officer":.109,"player":.105}[look]
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
    source=data["close" if close else "line"]
    vertices={}
    for face in source["f"]:
        raw=[source["p"][i] for i in face]
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
    n=24 if close else 10
    def brow(a):
        return 7.00+.44*cos(a)+.07*sin(a+.4)
    def band(row0,row1,material,thickness):
        def at(u,v):
            a=TAU*u
            y=brow(a)+row0+(row1-row0)*v
            return scalp(a,y,thickness+.022*sin(pi*v)),bone
        s.grid(n,3 if close else 1,at,material)
    if heavy:
        def helmet(u,v):
            a=TAU*u
            y=brow(a)+(8.12-brow(a))*v
            return scalp(a,min(8.03,y),.052+.079*(1-v)),bone
        s.grid(n,6 if close else 3,helmet,"iron")
        band(-.025,.075,"leather",.155)
        band(.055,.092,"brass" if look in ("player","officer") else "edge",.163)
        # A short guard at the nape leaves the silhouette of the nose and chin free.
        def nape(u,v):
            a=1.05+(TAU-2.10)*u
            y=brow(a)-(.58+.09*cos(3*a))*(1-v)
            return scalp(a,y,.16+.12*(1-v)),bone
        s.grid(n//2,3 if close else 1,nape,"lamellar")
        if look in ("player","officer"):
            # Bound horsehair follows the crown, with a tapered return down the back.
            crest=[(0,1.732,.048),(.006,1.778,-.016),(.011,1.770,-.105),
                   (.019,1.715,-.165),(.031,1.59,-.184)]
            s.tube(crest,[.012,.031,.033,.023,.003],"sash",bone,9 if close else 5,1.35)
    else:
        band(-.015,.16,"dyed" if look=="archer" else "headcloth",.053)
        if close: band(.06,.095,"headcloth",.082)
        p=scalp(pi,7.89,.08)
        s.oval((p[0],p[1]+.025,p[2]),(.036,.037,.057),"hair",bone,10 if close else 6,5)
        # Cloth knot tied at the rear rather than a perfectly round bun on every crown.
        a=scalp(pi+.3,6.96,.09)
        s.ribbon([a,(a[0]-.022,a[1]-.042,a[2]-.026),(a[0]-.037,a[1]-.118,a[2]-.012)],.026,"headcloth",bone)
