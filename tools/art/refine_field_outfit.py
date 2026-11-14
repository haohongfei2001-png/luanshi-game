"""Continuous surfaces and dye for the complete licensed field outfits.

Loop subdivision follows the original garment topology. UV seams stay split,
but positions, smooth normals and skin weights meet across those seams.
"""
from collections import defaultdict
import hashlib
import numpy as np
from PIL import Image
from figure_mesh import Surface
from import_garrison_issues import source_file, cloth, ISSUES

class FieldSurface(Surface):
    def __init__(self, detail=True):
        super().__init__(detail)
        self.reference_normals = {}

    def normals(self):
        values = super().normals()
        for index, value in self.reference_normals.items():
            values[index] = value
        return values

def decoded(encoded):
    pair = int(encoded[0]*1024)
    weights = np.zeros(16)
    weights[pair//32] += encoded[1]
    weights[pair%32] += 1.-encoded[1]
    return weights

def skin(weights):
    order = np.argsort(weights)[-2:][::-1]
    total = weights[order].sum()
    return int(order[0]), int(order[1]), float(weights[order[0]]/total)

def subdivide(source):
    """One smooth step on a sewn garment, with a common skin at every seam."""
    unique, index, points, weights = {}, [], [], []
    for p, bones in zip(source.positions, source.joints):
        key = tuple(round(v,6) for v in p)
        if key not in unique:
            unique[key] = len(points)
            points.append(p)
            weights.append(decoded(bones))
        index.append(unique[key])
    points, weights = np.asarray(points), np.asarray(weights)
    faces = [face for face in source.faces if len({index[i] for i in face})==3]
    neighbors = defaultdict(set)
    edges = defaultdict(list)
    for face in faces:
        tri = [index[i] for i in face]
        for a,b,c in (tri, tri[1:]+tri[:1], tri[2:]+tri[:2]):
            neighbors[a].add(b)
            neighbors[b].add(a)
            edges[tuple(sorted((a,b)))].append(c)
    edge_nodes = {}
    new_points, new_weights = [], []
    for i, p in enumerate(points):
        boundary = [j for j in neighbors[i] if len(edges[tuple(sorted((i,j)))])==1]
        if not neighbors[i]:
            new_points.append(p)
            new_weights.append(weights[i])
        elif len(boundary)==2:
            new_points.append(.75*p+.125*points[boundary].sum(axis=0))
            new_weights.append(.75*weights[i]+.125*weights[boundary].sum(axis=0))
        else:
            adjacent = sorted(neighbors[i])
            beta = 3./16. if len(adjacent)==3 else 3./(8.*len(adjacent))
            new_points.append((1.-len(adjacent)*beta)*p+beta*points[adjacent].sum(axis=0))
            new_weights.append((1.-len(adjacent)*beta)*weights[i]+beta*weights[adjacent].sum(axis=0))
    for edge, opposing in edges.items():
        a,b = edge
        edge_nodes[edge] = len(new_points)
        if len(opposing)==2:
            new_points.append(.375*(points[a]+points[b])+.125*points[opposing].sum(axis=0))
            new_weights.append(.375*(weights[a]+weights[b])+.125*weights[opposing].sum(axis=0))
        else:
            new_points.append(.5*(points[a]+points[b]))
            new_weights.append(.5*(weights[a]+weights[b]))
    out = FieldSurface()
    seen = {}
    def add(i, coord):
        key = (i, *[round(v,8) for v in coord])
        if key not in seen:
            seen[key] = out.vertex(tuple(new_points[i]),tuple(coord),skin(new_weights[i]))
        return seen[key]
    for a,b,c in faces:
        tri = [index[i] for i in (a,b,c)]
        uv = np.asarray([source.tex[i] for i in (a,b,c)])
        ab,bc,ca = [edge_nodes[tuple(sorted(edge))] for edge in
                    ((tri[0],tri[1]),(tri[1],tri[2]),(tri[2],tri[0]))]
        pa,pb,pc = [add(i,coord) for i,coord in zip(tri,uv)]
        pab = add(ab,(uv[0]+uv[1])*.5)
        pbc = add(bc,(uv[1]+uv[2])*.5)
        pca = add(ca,(uv[2]+uv[0])*.5)
        out.faces.extend([(pa,pab,pca),(pab,pb,pbc),(pca,pbc,pc),(pab,pbc,pca)])
    assert np.isfinite(out.positions).all()
    return out

def align_neckline(source):
    """Align Wildfire's actual collar with the HM08 throat and nape.

    The native opening was centred behind the game's throat and nape.
    Move the existing upper garment continuously, with ease around the throat.
    Shoulder, elbow, wrist, belt and weapon anchors remain at their original bind.
    """
    def transition(a,b,value):
        t = max(0., min(1., (value-a)/(b-a)))
        return t*t*(3.-2.*t)
    points = []
    for x,y,z in source.positions:
        follow = transition(1.36,1.485,y)*(1.-transition(.078,.18,abs(x)))
        side = float(np.tanh(x/.02))
        points.append((x+.020*side*follow,y,z+(.066+.20*(z+.053))*follow))
    source.positions = points
    return source

def collar_boundary(source):
    """Recover the actual sewn neck opening from the licensed garment surface."""
    points, lookup, mapping = [], {}, []
    for point in source.positions:
        key = tuple(round(float(v),6) for v in point)
        if key not in lookup:
            lookup[key] = len(points)
            points.append(np.asarray(point,dtype=float))
        mapping.append(lookup[key])
    edges = defaultdict(int)
    for face in source.faces:
        # The original issued surface carries the neck opening. Separate
        # project collar facings have open ends across the chest.
        if not all(2.<=source.tex[i][0]<3. for i in face): continue
        ids = [mapping[i] for i in face]
        for a,b in zip(ids,ids[1:]+ids[:1]):
            if a!=b: edges[tuple(sorted((a,b)))] += 1
    candidates = set()
    for (a,b), count in edges.items():
        if count==1 and all(points[i][1]>1.435 and abs(points[i][0])<.16 for i in (a,b)):
            candidates.update((a,b))
    assert len(candidates)>=6, ("missing native neck boundary",len(candidates))
    # An opening is convex in the transverse section. The original eight-sided
    # contour survives UV splits and the one sewn subdivision step.
    section = sorted(set((float(points[i][0]),float(points[i][2])) for i in candidates))
    def cross(o,a,b):
        return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lower,upper = [],[]
    for point in section:
        while len(lower)>=2 and cross(lower[-2],lower[-1],point)<=0.: lower.pop()
        lower.append(point)
    for point in reversed(section):
        while len(upper)>=2 and cross(upper[-2],upper[-1],point)<=0.: upper.pop()
        upper.append(point)
    polygon = np.asarray(lower[:-1]+upper[:-1])
    assert len(polygon)>=6
    return polygon, max(points[i][1] for i in candidates)

def fit_under_collar(points, boundary):
    """Tailor the original lower neck inside the shirt's actual opening.

    The HM08 selection includes the roots of the trapezius. Hide that covered
    continuation inside the sewn collar, leaving the face and upper throat at
    their source shape. Both surfaces follow CHEST at the seam.
    """
    polygon,top = boundary
    center = polygon.mean(axis=0)
    out = []
    for original in points:
        p = np.asarray(original,dtype=float).copy()
        t = float(np.clip((p[1]-top)/.030,0.,1.))
        follow = 1.-t*t*(3.-2.*t)
        if follow>0.:
            direction = p[[0,2]]-center
            distance = float(np.linalg.norm(direction))
            if distance>1.e-8:
                direction /= distance
                radius = float("inf")
                for a,b in zip(polygon,np.roll(polygon,-1,axis=0)):
                    edge = b-a
                    denominator = direction[0]*edge[1]-direction[1]*edge[0]
                    if abs(denominator)<1.e-10: continue
                    relative = a-center
                    ray = (relative[0]*edge[1]-relative[1]*edge[0])/denominator
                    segment = (relative[0]*direction[1]-relative[1]*direction[0])/denominator
                    if ray>0. and -.00001<=segment<=1.00001: radius=min(radius,ray)
                assert np.isfinite(radius), ("open neckline",p.tolist())
                inset = max(.01,radius-.006)
                if distance>inset:
                    p[[0,2]] -= direction*(distance-inset)*follow
        out.append(tuple(p))
    return out

def palette(cache, destination):
    """Retain native cloth/lacing regions and the untouched fourth shield tile."""
    atlas = Image.open(destination).convert("RGBA")
    shield = atlas.crop((264,264,528,528)).tobytes()
    for slot,(role,model,blob,paint,signature) in enumerate(ISSUES):
        source = source_file(cache,"textures/skins/skeletal/han/"+paint+".png",signature)
        tile = np.asarray(cloth(source,role)).copy()
        rgb = tile[:,:,:3].astype(float)
        dye = tile[:,:,3].astype(float)/255.
        if role=="Archer":
            # The whole long-sleeve tunic is dyed linen. Its girdle and wrist
            # bindings are separate geometry, with their own material.
            dye[:] = 1.
        else:
            dye = np.clip((dye-.12)/.25,0.,1.)
        luminance = np.dot(rgb,[.25,.56,.19])
        fabric = np.clip(153.+(luminance-140.)*.20,133.,175.)
        rgb = rgb*(1.-dye[:,:,None])+fabric[:,:,None]*dye[:,:,None]
        tile[:,:,:3] = np.rint(np.clip(rgb,0.,255.)).astype(np.uint8)
        tile[:,:,3] = np.rint(dye*255.).astype(np.uint8)
        atlas.paste(Image.fromarray(tile,"RGBA"),(264*(slot%2),264*(slot//2)))
    assert atlas.crop((264,264,528,528)).tobytes()==shield
    atlas.save(destination)
    return {"shield_rgba_sha256":hashlib.sha256(shield).hexdigest(),
            "shield_pixels_unchanged":True,"cloth_tiles":[0,1,2]}
