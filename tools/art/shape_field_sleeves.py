"""Round the original Wildfire sleeve sections and extend their elbow cloth.

Only the original cloth component is changed. Current shoulder seams, bind
joints, hands, grips and every motion sample remain authored by their owners.
"""
from math import exp, sin, pi
from collections import defaultdict
import numpy as np
from figure_mesh import Surface
from company_figures import LU,LF,RU,RF,CHEST

def unskin(value):
    packed=int(value[0]*1024)
    a,b=packed//32,packed%32
    return {a:value[1],b:1.-value[1]} if a!=b else {a:1.}

def skin(values):
    order=sorted(values,key=values.get,reverse=True)[:2]
    if len(order)==1: return (order[0],order[0],1.)
    total=sum(values[k] for k in order)
    return (order[0],order[1],values[order[0]]/total)

def sleeve_share(p,weights):
    if p[1]<1.045 or p[1]>1.43 or abs(p[0])<.175:
        return 0.
    return sum(v for k,v in weights.items() if k in (LU,LF,RU,RF))

def round_sleeves(source,role):
    original=np.asarray(source.positions)
    weights=[unskin(w) for w in source.joints]
    # Reconnect UV duplicates for one continuous normal at the cut edges.
    keys=[tuple(np.round(p,5)) for p in original]
    aliases={}
    welded=[]
    ids=[]
    for k in keys:
        if k not in aliases:
            aliases[k]=len(welded);welded.append(k)
        ids.append(aliases[k])
    vertices=np.asarray(welded,dtype=float)
    neighbors=defaultdict(set)
    edges=defaultdict(list)
    for f in source.faces:
        a,b,c=[ids[i] for i in f]
        for x,y,z in ((a,b,c),(b,c,a),(c,a,b)):
            if x==y: continue
            neighbors[x].add(y);neighbors[y].add(x)
            edges[tuple(sorted((x,y)))].append(z)
    border=set()
    for (a,b),opposite in edges.items():
        if len(opposite)==1: border.update((a,b))
    share=np.zeros(len(vertices))
    for i,p in enumerate(original):
        share[ids[i]]=max(share[ids[i]],sleeve_share(p,weights[i]))
    # The lowest cloth cross-section extends over the elbow. Shoulder has
    # room for its underlying deltoid and folds gathered by the narrow cuff.
    deformed=vertices.copy()
    for k,p in enumerate(vertices):
        influence=share[k]
        if influence<.13: continue
        hood=max(0.,min(1.,(p[1]-1.25)/.12))
        if k not in border:
            mean=vertices[sorted(neighbors[k])].mean(axis=0)
            deformed[k]+=(mean-p)*(.42 if role!="Guard" else .25)*influence*(1.-.60*hood)
        x,y,z=deformed[k]
        side=1. if x>=0 else -1.
        # The artist cuff was cut just above the elbow. Use its own turn and
        # shoulder cross-section and let it continue along the real forearm.
        down=max(0.,min(1.,(1.25-y)/.20))
        fall=(.092 if role=="Guard" else .151)*down**1.45*influence
        deformed[k,1]-=fall
        deformed[k,0]+=side*.022*down*influence
        deformed[k,2]+=.025*down*influence
        # Cloth tapers as it reaches the wrist instead of continuing as a tube.
        axis_x=side*(.225+.14*(1.405-y))
        axis_z=-.012+.10*(1.405-y)
        taper=1.-.19*down*influence
        deformed[k,0]=axis_x+(deformed[k,0]-axis_x)*taper
        deformed[k,2]=axis_z+(deformed[k,2]-axis_z)*taper
    for i,p in enumerate(original):
        moved=deformed[ids[i]]
        if share[ids[i]]>.13 and moved[1]<1.22:
            hand_side=1 if moved[0]>0 else -1
            up,fore=(RU,RF) if hand_side>0 else (LU,LF)
            arm=min(1.,max(0.,(moved[1]-1.03)/.21))
            # Move the elbow-weight gradient with the actual garment.
            mass=sum(v for k,v in weights[i].items() if k in (up,fore))
            weights[i][up]=mass*arm
            weights[i][fore]=mass*(1.-arm)
    selected={}
    for (a,b),op in edges.items():
        if min(share[a],share[b])<.38: continue
        if max(vertices[a,1],vertices[b,1])>1.425: continue
        midpoint=(deformed[a]+deformed[b])*.5
        if len(op)==2:
            midpoint=.375*(deformed[a]+deformed[b])+.125*(deformed[op[0]]+deformed[op[1]])
        selected[a,b]=midpoint
    out=Surface()
    for i,p in enumerate(original):
        out.vertex(tuple(deformed[ids[i]]),source.tex[i],skin(weights[i]))
    splits={}
    def midpoint(i,j):
        key=tuple(sorted((i,j)))
        if key in splits: return splits[key]
        p=selected[tuple(sorted((ids[i],ids[j])))]
        merged=defaultdict(float)
        for q in (i,j):
            for bone,w in weights[q].items(): merged[bone]+=.5*w
        st=.5*(np.asarray(source.tex[i])+source.tex[j])
        k=out.vertex(tuple(p),tuple(st),skin(merged))
        splits[key]=k
        return k
    for face in source.faces:
        ring=[]
        for i,j in zip(face,face[1:]+face[:1]):
            ring.append(i)
            if tuple(sorted((ids[i],ids[j]))) in selected:
                ring.append(midpoint(i,j))
        if len(ring)==3:
            out.faces.append(face)
        else:
            # Fan from a true triangle centre keeps UV seams and bone spaces
            # separate while every split edge is shared with its neighbor.
            p=np.mean([out.positions[i] for i in face],axis=0)
            st=np.mean([out.tex[i] for i in face],axis=0)
            merged=defaultdict(float)
            for q in face:
                for bone,w in weights[q].items(): merged[bone]+=w/3.
            center=out.vertex(tuple(p),tuple(st),skin(merged))
            for a,b in zip(ring,ring[1:]+ring[:1]): out.faces.append((center,a,b))
    print("DRESSED_SLEEVES",role,len(source.faces),len(out.faces),"max_shift_m",float(np.linalg.norm(deformed-vertices,axis=1).max()))
    return out
