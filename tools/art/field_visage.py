"""Fit the open-licensed sculpt, head wraps and helmet to the river company's metre-scale bind."""
import json
from functools import lru_cache
from math import atan2, cos, floor, pi, sin
from pathlib import Path
from figure_atlas import uv
from figure_mesh import TAU, lerp

@lru_cache(maxsize=1)
def sculpt():
    return json.loads(Path(__file__).with_name("field_head.json").read_text())

@lru_cache(maxsize=2)
def field_skin(close):
    """Fit a single outward surface to sections of the HM08 master.

    The source has real eyelid apertures and an inner mouth. Voxel reduction
    can merge their opposite sides. With a two-sided costume shader those
    little return faces and the old eyeballs blink through at combat scale.
    Preserve the brow, nose tip, jaw and ear profile on the outside only.
    """
    mesh = sculpt()["close"]
    if close:
        levels = (5.60,5.74,5.85,5.93,6.02,6.13,6.23,6.31,6.41,6.51,6.61,
                  6.69,6.79,6.89,7.00,7.13,7.24,7.38,7.55,7.73,7.90,8.02,8.077)
        half = (0,.105,.218,.322,.444,.604,.805,1.04,1.29,1.55,1.83,2.18,2.63,pi)
    else:
        levels = (5.69,5.91,6.12,6.33,6.53,6.68,6.88,7.04,7.22,7.54,7.83,8.03)
        half = (0,.235,.49,.83,1.29,1.75,2.31,pi)
    angles = (*half, *(TAU-a for a in reversed(half[1:-1])))
    points = []
    for height in levels:
        edges = []
        for face in mesh["f"]:
            corners = [mesh["p"][i] for i in face]
            cuts = []
            for p,q in zip(corners,corners[1:]+corners[:1]):
                if min(p[1],q[1]) <= height < max(p[1],q[1]):
                    t = (height-p[1])/(q[1]-p[1])
                    cuts.append((p[0]+(q[0]-p[0])*t,p[2]+(q[2]-p[2])*t-.35))
            if len(cuts)==2:
                edges.append(cuts)
        for angle in angles:
            dx,dz = sin(angle),cos(angle)
            radius = .045
            for (x,z),(bx,bz) in edges:
                ex,ez = bx-x,bz-z
                det = dx*ez-dz*ex
                if abs(det)<1.e-8:
                    continue
                d = (x*ez-z*ex)/det
                u = (x*dz-z*dx)/det
                if 0<=u<=1:
                    radius = max(radius,d)
            points.append((dx*radius,height,.35+dz*radius))
    # Bridge the sockets between the measured top of the cheek and the brow.
    # Bound the recess relative to those two real profiles, at each own angle.
    base,top = ((6.89,7.13) if close else (6.88,7.22))
    lo,hi = levels.index(base),levels.index(top)
    for k,a in enumerate(angles):
        angle = min(a,TAU-a)
        if not .10 < angle < .64:
            continue
        dx,dz = sin(a),cos(a)
        def at(i):
            x,_,z = points[i*len(angles)+k]
            return x*dx+(z-.35)*dz
        for row in range(lo+1,hi):
            t = (levels[row]-base)/(top-base)
            floor_radius = at(lo)+(at(hi)-at(lo))*t-.037*sin(pi*t)
            radius = max(at(row),floor_radius)
            points[row*len(angles)+k] = (radius*dx,levels[row],.35+radius*dz)
    # The broad forehead turns back above the lid. Keep the profile single
    # sided and trade the eye socket hole for one deliberate orbital plane.
    for index,(x,y,z) in enumerate(points):
        if z<.89 or not 6.85<=y<=7.34:
            continue
        eye=max(0.,1.-abs(abs(x)-.313)/.218)
        lid=max(0.,1.-abs(y-7.006)/.145)
        brow=max(0.,1.-abs(y-7.205)/.175)
        points[index]=(x,y,z+eye*(.041*brow-.064*lid))
    count = len(angles)
    faces = []
    for row in range(len(levels)-1):
        for col in range(count):
            i = row*count+col
            j = row*count+(col+1)%count
            faces.extend(((i,j,j+count),(i,j+count,i+count)))
    return {"p":points,"f":faces}


def archer_brow(a):
    # Farther above the eyes than the nape and tied just behind the left ear.
    return 1.612 + .037*cos(a) + .006*sin(a+.4)


def head(s,look,bone):
    close=s.detail
    data=sculpt()
    heavy=look in ("regular","guard","officer")
    width={"levy":.105,"archer":.099,"regular":.105,"guard":.110,"officer":.109,"player":.105}[look]
    def bind(x,y,z):
        # The armour issue and haircut carry at distance. Underneath, keep
        # distinct jaw taper, cheek breadth and chin without changing head pivot.
        jaw=max(0.,min(1.,(7.1-y)/1.37))
        if look=="levy":
            x*=1.-.17*jaw
            z+=.12*jaw*max(0.,min(1.,z))
        elif look in ("guard","officer"):
            x*=1.+.16*jaw
        # The protagonist has a longer chin. The officer keeps a fuller,
        # blunter jaw below his helmet; both keep their original headgear bind.
        if look=="player":
            y-=.071*jaw
            x*=1.-.065*jaw
            z+=.075*jaw*max(0.,min(1.,z))
        elif look=="officer":
            y+=.045*jaw
            z-=.045*jaw*max(0.,min(1.,z))
        return (x*width,1.725+(y-8.10)*.110,(z-.28)*.112+.015)
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
    source=field_skin(close)
    vertices={}
    for face in source["f"]:
        raw=[source["p"][i] for i in face]
        if heavy and all(y>brow(atan2(x,z-.35))+.12 for x,y,z in raw):
            continue
        if look=="archer" and all(bind(x,y,z)[1]>archer_brow(atan2(x*width,(z-.35)*.112))+.014 for x,y,z in raw):
            continue
        x,y,z=[sum(p[k] for p in raw)/3 for k in range(3)]
        # The single surface carries the hairline and registered features.
        # Restrict the painted strip to the front; the rest of the cheek is skin.
        hairline=6.62+.86*max(0,min(1,(z+.32)/1.66))-.12*abs(x)
        mat="hair" if y>hairline else ("visage" if z>.60 and abs(x)<.745 else "skin")
        ids=[]
        for i in face:
            key=(i,mat)
            if key not in vertices:
                x,y,z=source["p"][i]
                if mat=="visage":
                    # The artist's chart sets the brow, upper lid and lip on rows
                    # 23, 27 and 45, spanning the full 64-unit atlas cell.
                    # UV padding is already present in the painted outer margin.
                    st=(max(.012,min(.988,.5+x/1.90))/8.,
                        (2.+max(.012,min(.988,(8.13-y)/2.63)))/4.)
                else:
                    st=uv(mat,max(.01,min(.99,.5+x/1.90)),max(.01,min(.99,(8.13-y)/2.63)))
                vertices[key]=s.vertex(bind(x,y,z),st,bone)
            ids.append(vertices[key])
        s.faces.append(tuple(ids))
    n=24 if close else 8
    def band(row0,row1,material,thickness):
        def at(u,v):
            a=TAU*u
            y=brow(a)+row0+(row1-row0)*v
            return scalp(a,y,thickness+.022*sin(pi*v)),bone
        s.grid(n,3 if close else 1,at,material)
    # Issued headwear is separately authored, licensed and fitted to this scalp.
    if not heavy and look!="archer":
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
