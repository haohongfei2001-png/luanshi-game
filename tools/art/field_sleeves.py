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
    t=clamp((1.405-y)/.260)
    cx=.225+.033*t
    cz=-.012+.026*t
    dx,dz=abs(x)-cx,z-cz
    radius=max(.021,hypot(dx,dz))
    a=atan2(dz,dx)
    rear=clamp((1.-sin(a))*.5)
    # The dress has a high shoulder head and a low underarm seam. The
    # outside and behind the elbow receive the spare cloth. A shorter
    # inside edge keeps the bent arm and bracer clear. The two sleeves
    # use different ease on the weapon and support sides.
    cloth={"Regular":1.,"Guard":.83,"Archer":1.19}[role]
    cloth*=1.06 if side<0 and role!="Guard" else .98
    belly=exp(-((y-1.224)/.082)**2)
    cap=exp(-((y-1.335)/.090)**2)
    cuff=transition(1.164,1.077,y)
    fold=exp(-((y-1.187-.046*sin(a-.65))/.025)**2)
    trough=exp(-((y-1.144-.022*sin(a-.65))/.025)**2)
    dr=cloth*(.040*belly*(.16+.84*rear)+.016*fold-.010*trough)
    scale_x=1.-.245*cap-.185*cuff
    scale_z=1.-.235*cuff+.081*rear*belly
    px=side*(cx+dx*scale_x+dr*dx/radius)
    pz=cz+dz*scale_z+dr*dz/radius-.029*cloth*rear*belly
    py=y-.038*cloth*belly*rear-.017*cap*max(0.,cos(a))+.010*fold*(1.-rear)
    result=tuple(orig+(v-orig)*factor for orig,v in zip(p,(px,py,pz)))
    if y>1.228:
        sleeve=(.98-.38*transition(1.286,1.442,y))*(.67+.33*transition(-.058,.033,dx))
        target={upper:sleeve,CHEST:1.-sleeve}
    else:
        # Inner cloth shortens while the outside rests on the elbow. The
        # weights turn through a full strip, not across a broken diagonal.
        hinge=transition(1.221,1.075,y-.016*rear+.007*(1.-rear))
        target={upper:1.-hinge,fore:hinge}
    return result,mix_bones(weights,target,.89*factor)

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
            if length(points[i],points[j])>.095:
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
        bottom=[p for p,_ in ring]
        root_skin=[w for _,w in ring]
        # The older shirt ended at the top of the bracer in a straight cut. Hang the
        # sewn outlines well below the elbow, translating with the forearm,
        # then roll the bottom seam back into the wrist. This new fabric
        # occupies real space and has a deliberately open inside face.
        reach={"Regular":.152,"Archer":.177,"Guard":.128}[role]
        stages=((0.,1.,0.),(.34,1.08,.75),(.63,1.0,1.),
                (.79,.81,.59),(1.,.58,.10))
        for k,(t,spread,pouch) in enumerate(stages):
            row=[]
            for j,(px,py,pz) in enumerate(bottom):
                dx,dz=px-center[0],pz-center[2]
                radius=max(.02,hypot(dx,dz))
                angle=atan2(dz,side*dx)
                rear=.5-.5*sin(angle)
                hang=reach*(.84+.25*rear+.079*cos(angle))
                sweep=reach*.36*t
                x=center[0]+side*sweep*.43+dx*spread
                z=center[2]+sweep+dz*spread
                # The narrowing sleeve retains two large, diagonal folds as
                # it turns under the arm. No geometry lies on the palm.
                fullness=(.014+.024*rear)*pouch
                x+=dx/radius*fullness
                z+=dz/radius*fullness-.013*pouch*rear
                yy=py-hang*t-pouch*(.010+.017*rear)+.007*sin(2*angle+.41)*pouch
                if k==len(stages)-1:
                    yy+=.007*cos(angle)
                at=(x,yy,z)
                cuff_weights=mix_bones(root_skin[j],{RIGHT_FORE if side>0 else LEFT_FORE:1.},transition(0.,.53,t))
                # The upper three stations are a single darkened length of
                # the team-dyed bolt. No painted highlights cross its seam.
                row.append((at,compact(cuff_weights)))
            faces.append(row)
        for k,(upper,lower) in enumerate(zip(faces,faces[1:])):
            material="coat" if k<2 else "facing" if k==2 else "binding"
            if role=="Guard" and k==2: material="quilt"
            two=[]
            for level,section_row in enumerate((upper,lower)):
                row=[]
                for j,(at,skin) in enumerate(section_row):
                    colour=uv(material,.20+.55*(j+.3)/len(section_row),.29+.40*level)
                    row.append(result.vertex(at,colour,skin))
                two.append(row)
            for j in range(len(ring)):
                z=(j+1)%len(ring)
                corners=(two[0][j],two[0][z],two[1][z],two[1][j])
                if side<0: corners=corners[::-1]
                result.quad(*corners)
    print("FITTED_SLEEVE",role,"faces",len(source.faces),len(result.faces),"new edge mids",len(sewn))
    return result

def key(p):
    return tuple(round(float(v),6) for v in p)

def length(p,q):
    return sqrt(sum((a-b)**2 for a,b in zip(p,q)))
