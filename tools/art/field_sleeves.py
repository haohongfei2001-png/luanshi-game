"""Refit the two working sleeves on a Wildfire field tunic.

All coordinates below are metres in the existing straight-arm bind. The sleeve
cut stays on the garment and shares the original artists' texture seams. Helm,
hands, forearm guard, and weapon are separate surfaces.
"""
from collections import Counter
from math import atan2, cos, exp, hypot, pi, sin, sqrt

from figure_atlas import uv
from figure_mesh import Surface

CHEST=1
LEFT_UPPER,LEFT_FORE=3,4
RIGHT_UPPER,RIGHT_FORE=6,7

def clamp(x):
    return max(0.,min(1.,x))

def transition(a,b,x):
    t=clamp((x-a)/(b-a))
    return t*t*(3.-2.*t)

def bones(encoded):
    packed=int(encoded[0]*1024)
    a,b=packed//32,packed%32
    return {a:1.} if a==b else {a:encoded[1],b:1.-encoded[1]}

def mix_bones(a,b,t):
    return {joint:a.get(joint,0.)*(1.-t)+b.get(joint,0.)*t for joint in a.keys()|b.keys()}

def compact(weights):
    ids=sorted(weights,key=weights.get,reverse=True)[:2]
    if len(ids)==1: return (ids[0],ids[0],1.)
    total=weights[ids[0]]+weights[ids[1]]
    return (ids[0],ids[1],weights[ids[0]]/total)

def section(p,weights):
    x,y,z=p
    side=1 if x>=0. else -1
    upper,fore=(RIGHT_UPPER,RIGHT_FORE) if side>0 else (LEFT_UPPER,LEFT_FORE)
    arm=weights.get(upper,0.)+weights.get(fore,0.)
    if arm<.006 or not 1.0<y<1.489: return 0.
    return transition(.13,.70,arm)*transition(.115,.19,abs(x))

def fitted(p,weights,role):
    x,y,z=p
    factor=section(p,weights)
    if factor<=0.: return p,weights
    side=1 if x>=0. else -1
    upper,fore=(RIGHT_UPPER,RIGHT_FORE) if side>0 else (LEFT_UPPER,LEFT_FORE)
    # A sloped armhole passes from the collar across the deltoid then down
    # into the armpit. At the elbow the sleeve narrows over the bracer.
    yroot=1.405
    t=clamp((yroot-y)/.260)
    cx=.225+.033*t
    cz=-.012+.026*t
    rear=1.-transition(-.055,.065,z-cz)
    dx=abs(x)-cx
    dz=z-cz
    ang=atan2(dz,dx)
    radius=hypot(dx,dz)
    relax={"Regular":1.,"Archer":1.18,"Guard":.76}[role]
    bend=exp(-((y-1.203)/.098)**2)
    folded=exp(-((y-1.193-.031*sin(ang-.49))/.032)**2)
    outside=.5+.5*cos(ang)
    # The underside is fuller on the trailing/back quarter of the arm. A
    # rolled convex fold crosses the sleeve obliquely. It never closes around
    # the whole elbow like a tube or armour hoop.
    relief=relax*(.017*folded*(.20+.80*rear)-.009*exp(-((y-1.152+.026*cos(ang))/.032)**2))
    tight=transition(1.176,1.065,y)
    # Pull the old flared top of the sleeve toward the humerus. Give the
    # hanging elbow a fuller back, then take it into a narrower wrist opening.
    rx=dx*(1.-.25*tight-.22*outside*exp(-((y-1.286)/.11)**2))
    rz=dz*(1.-.30*tight+.052*rear*bend)
    if radius>.012:
        rx+=relief*dx/radius
        rz+=relief*dz/radius
    px=side*(cx+rx)
    py=y-.010*outside*exp(-((y-1.322)/.065)**2)-.022*rear*bend+.008*(1.-rear)*folded
    pz=cz+rz-.012*rear*bend
    result=tuple(orig+(v-orig)*factor for orig,v in zip(p,(px,py,pz)))
    # The rounded top of the sleeve shares the shoulder pivot with the yoke.
    # At the elbow, swatches must agree on one continuous two-bone weight;
    # the earlier six-sided cuff had 16% to 89% forearm across one short turn.
    if y>1.228:
        sleeve=.96-.44*transition(1.285,1.447,y)
        sleeve*=.71+.29*transition(-.056,.025,dx)
        target={upper:sleeve,CHEST:1.-sleeve}
    else:
        hinge=transition(1.220,1.078,y-.011*rear+.004*outside)
        target={upper:1.-hinge,fore:hinge}
    return result,mix_bones(weights,target,.83*factor)

def refit_sleeves(source,role):
    points=source.positions
    weights=[bones(w) for w in source.joints]
    original=[key(p) for p in points]
    source_edges=Counter()
    pairs={}
    sewn=set()
    def edge(i,j):
        return tuple(sorted((original[i],original[j])))
    for face in source.faces:
        for i,j in zip(face,(face[1],face[2],face[0])):
            k=edge(i,j)
            source_edges[k]+=1
            pairs[k]=(i,j)
            if points[i][0]*points[j][0]<=0.: continue
            y0,y1=sorted((points[i][1],points[j][1]))
            if y0<1.015 or y1>1.49: continue
            if max(section(points[i],weights[i]),section(points[j],weights[j]))<.24: continue
            # A split is shared across neighbouring triangles and UV islands.
            # Long old spans were up to 17 cm across a bent shoulder.
            if length(points[i],points[j])>.061:
                sewn.add(k)
    result=Surface()
    lookup={}
    refined=[]
    seam_mids={}
    def vertex(p,st,blend):
        dest,skin=fitted(p,blend,role)
        k=(*key(dest),round(st[0],7),round(st[1],7),*(round(v,6) for v in compact(skin)))
        if k not in lookup: lookup[k]=result.vertex(dest,st,compact(skin))
        return lookup[k]
    for f in source.faces:
        corners=[]
        mid=[]
        for i,j in zip(f,(f[1],f[2],f[0])):
            a=vertex(points[i],source.tex[i],weights[i])
            corners.append(a)
            e=edge(i,j)
            if e not in sewn:
                mid.append(None)
                continue
            at=tuple((x+y)*.5 for x,y in zip(points[i],points[j]))
            # Reconstruct the curved cloth between original points. Thus a
            # newly added row describes the slope instead of duplicating a
            # flat triangle with no surface or skinning change.
            dx,dy,dz=[points[i][n]-points[j][n] for n in range(3)]
            side=1 if at[0]>=0. else -1
            t=clamp((1.405-at[1])/.260)
            nx=at[0]-side*(.225+.033*t)
            nz=at[2]-(-.012+.026*t)
            normal=max(.025,hypot(nx,nz))
            tangential=max(0.,dx*dx+dz*dz-((dx*nx+dz*nz)/normal)**2)
            amount=min(.011,tangential/.70)*min(section(points[i],weights[i]),section(points[j],weights[j]))
            raised=(at[0]+amount*nx/normal,at[1],at[2]+amount*nz/normal)
            st=tuple((x+y)*.5 for x,y in zip(source.tex[i],source.tex[j]))
            blend=mix_bones(weights[i],weights[j],.5)
            mid.append(vertex(raised,st,blend))
            if source_edges[e]==1: seam_mids[e]=fitted(raised,blend,role)
        a,b,c=corners
        ab,bc,ca=mid
        count=sum(k is not None for k in mid)
        if count==0: refined.append((a,b,c))
        elif count==3: refined.extend(((a,ab,ca),(ab,b,bc),(ca,bc,c),(ab,bc,ca)))
        elif count==1:
            i=next(n for n,m in enumerate(mid) if m is not None)
            refined.extend(((corners[i],mid[i],corners[(i+2)%3]),(mid[i],corners[(i+1)%3],corners[(i+2)%3])))
        else:
            i=next(n for n,m in enumerate(mid) if m is None)
            j,k=(i+1)%3,(i+2)%3
            refined.extend(((corners[k],mid[k],mid[j]),(corners[i],corners[j],mid[j]),(corners[i],mid[j],mid[k])))
    result.faces=refined
    # Turn the six original hem edges into a soft facing on the shortened
    # sleeve. These are actual detached cuff edges, not closed decorations
    # laid over the biceps. Reuse the seam's positions and forearm weights.
    rings={-1:[],1:[]}
    for k,num in source_edges.items():
        if num!=1: continue
        i,j=pairs[k]
        if not all(1.04<points[idx][1]<1.13 and abs(points[idx][0])>.17 for idx in (i,j)): continue
        side=1 if points[i][0]>0 else -1
        for idx in (i,j):
            if not any(original[idx]==original[prev] for prev in rings[side]): rings[side].append(idx)
    for side,ids in rings.items():
        if len(ids)!=6: raise ValueError((role,"Unrecognized sewn opening",len(ids)))
        cx=sum(points[i][0] for i in ids)/len(ids)
        cz=sum(points[i][2] for i in ids)/len(ids)
        ids.sort(key=lambda i:atan2(points[i][2]-cz,(points[i][0]-cx)*side))
        ring=[]
        for j,i in enumerate(ids):
            other=ids[(j+1)%len(ids)]
            contour=(0.,.5) if edge(i,other) in sewn else (0.,)
            for t in contour:
                q,w=seam_mids[edge(i,other)] if t else fitted(points[i],weights[i],role)
                ring.append((q,w))
        center=tuple(sum(p[j] for p,w in ring)/len(ring) for j in range(3))
        faces=[]
        for depth in (0.,.34,1.):
            row=[]
            for j,(p,w) in enumerate(ring):
                cuff=.006*sin(pi*depth)-.011*depth
                x=(p[0]-center[0])
                z=(p[2]-center[2])
                r=max(.02,hypot(x,z))
                below=.031+.015*clamp((-z+.038)/.082)
                pt=(p[0]+x*cuff/r,p[1]-depth*below,p[2]+z*cuff/r)
                colour=uv("binding" if role=="Guard" else "facing",(j+.45)/len(ring),.26+.48*depth)
                row.append(result.vertex(pt,colour,compact(w)))
            faces.append(row)
        for first,second in zip(faces,faces[1:]):
            for j in range(len(ring)):
                k=(j+1)%len(ring)
                ids=(first[j],first[k],second[k],second[j])
                if side<0: ids=ids[::-1]
                result.quad(*ids)
    print("FITTED_SLEEVE",role,"faces",len(source.faces),len(result.faces),"new edge mids",len(sewn))
    return result

def key(p):
    return tuple(round(float(v),6) for v in p)

def length(p,q):
    return sqrt(sum((a-b)**2 for a,b in zip(p,q)))
