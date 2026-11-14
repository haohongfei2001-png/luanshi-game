"""Orient only explicitly authored closed solids; do not touch professional surfaces.
Connected components are checked independently, with translation-stable volume.
"""
from collections import defaultdict

def orient_closed(verts,faces):
    faces=[tuple(f) for f in faces];edges=defaultdict(list)
    for i,face in enumerate(faces):
        for a,b in zip(face,face[1:]+face[:1]):edges[tuple(sorted((a,b)))].append(i)
    neighbors=defaultdict(set)
    for fs in edges.values():
        for f in fs:neighbors[f].update(fs)
    seen=set();report=[]
    for seed in range(len(faces)):
        if seed in seen:continue
        pending=[seed];component=set()
        while pending:
            i=pending.pop()
            if i in component:continue
            component.add(i);pending.extend(neighbors[i]-component)
        seen.update(component)
        component_edges={tuple(sorted((a,b))) for i in component for a,b in zip(faces[i],faces[i][1:]+faces[i][:1])}
        if any(len(edges[e])!=2 for e in component_edges):
            raise ValueError('Authored solid is open/nonmanifold; must be deliberately modeled, not silently repaired')
        ids={v for i in component for v in faces[i]};center=[sum(verts[v][k] for v in ids)/len(ids) for k in range(3)]
        def at(v):return tuple(verts[v][k]-center[k] for k in range(3))
        volume=0.
        for i in component:
            f=faces[i];a=at(f[0])
            for j in range(1,len(f)-1):
                b,c=at(f[j]),at(f[j+1]);volume+=(a[0]*(b[1]*c[2]-b[2]*c[1])+a[1]*(b[2]*c[0]-b[0]*c[2])+a[2]*(b[0]*c[1]-b[1]*c[0]))/6
        if abs(volume)<1e-10:raise ValueError('Degenerate closed authored volume')
        if volume<0:
            for i in component:faces[i]=tuple(reversed(faces[i]))
        # Closed incidence alone is insufficient: each edge must be traversed
        # once in each direction, rejecting inconsistent mixed-winding shells.
        directed=defaultdict(int)
        for i in component:
            f=faces[i]
            for a,b in zip(f,f[1:]+f[:1]):directed[(a,b)]+=1
        if any(directed[(a,b)]!=directed[(b,a)] for a,b in directed):raise ValueError('Mixed solid orientation, not a global inversion')
        report.append({'faces':len(component),'signed_volume_before_m3':volume,'signed_volume_after_m3':abs(volume),'flipped':volume<0})
    return faces,report
