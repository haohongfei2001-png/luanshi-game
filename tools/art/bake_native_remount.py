"""Bake the complete licensed horse, its original skinning and real saddle motion.

The whole source body, mane and tail share the original authored joint hierarchy.
A single similarity transform fits the original proportions to the riding seat.
"""
from collections import defaultdict
import json
import hashlib
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
from figure_mesh import Surface, Library
from import_garrison_issues import read_dae, source_file
from import_remount import MESHES, leg_group
import struct

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/third_party/wildfire_remounts"
ANIMATIONS=[
    ("walk","animation/quadraped/horse_walk.dae","f5f3c10fde8cea8be4632a2930e0f3ddb5b794fa"),
    ("trot","animation/quadraped/horse_trot.dae","3029b971df52c2b3bb67dd2ca6e44971bf894bc4"),
]
KEYS=32

def document(path):
    root=ET.parse(path).getroot()
    for node in root.iter(): node.tag=node.tag.split("}")[-1]
    return root

def rig(path):
    root=document(path)
    skin=root.find(".//controller/skin")
    channels={n.get("semantic"):n.get("source")[1:] for n in skin.find("joints").findall("input")}
    names=skin.find("source[@id='"+channels["JOINT"]+"']/Name_array").text.split()
    inverse=np.fromstring(skin.find("source[@id='"+channels["INV_BIND_MATRIX"]+"']/float_array").text,sep=" ").reshape((-1,4,4))
    nodes={}
    def walk(node,parent):
        name=node.get("name")
        matrix=node.find("matrix")
        if matrix is None: return
        nodes[name]=(parent,np.fromstring(matrix.text,sep=" ").reshape((4,4)))
        for child in node.findall("node"): walk(child,name)
    walk(root.find(".//visual_scene/node"),None)
    return names,inverse,nodes

def tracks(path):
    root=document(path)
    id_names={n.get("id"):n.get("name") for n in root.findall(".//visual_scene//node")}
    result={}
    for animation in root.findall(".//animation"):
        channel=animation.find("channel")
        if channel is None: continue
        target = channel.get("target", "").split("/", 1)
        # Blender also exports scalar B-bone ease controls. The authored
        # evaluated transform already contains their effect.
        if len(target) != 2 or target[1] != "transform": continue
        name = id_names.get(target[0])
        if not name: continue
        sampler=animation.find("sampler")
        sources={n.get("semantic"):n.get("source")[1:] for n in sampler.findall("input")}
        time=np.fromstring(animation.find("source[@id='"+sources["INPUT"]+"']/float_array").text,sep=" ")
        transforms=np.fromstring(animation.find("source[@id='"+sources["OUTPUT"]+"']/float_array").text,sep=" ").reshape((-1,4,4))
        result[name]=(time,transforms)
    assert result
    return result

def pose(nodes,animation,phase):
    duration=max((float(time[-1]) for time,values in animation.values()),default=1.)
    world={}
    for name,(parent,bind) in nodes.items():
        local=bind
        # The original leg keys include compensation for their animated spine
        # and belly parents. Evaluate the whole hierarchy before registering
        # its saddle frame; freezing parents changes the authored hoof paths.
        if name in animation:
            time,values=animation[name]
            moment=phase*duration
            i=min(len(time)-2,max(0,int(np.searchsorted(time,moment)-1)))
            blend=(moment-time[i])/max(1.e-9,time[i+1]-time[i])
            local=values[i]*(1.-blend)+values[i+1]*blend
        world[name]=local if parent is None else world[parent]@local
    return world

def sewn_subdivision(points,weights,faces,uv,uvfaces):
    neighbors=defaultdict(set)
    edges=defaultdict(list)
    for face in faces:
        for a,b,c in (face,np.roll(face,-1),np.roll(face,-2)):
            neighbors[int(a)].add(int(b))
            neighbors[int(b)].add(int(a))
            edges[tuple(sorted((int(a),int(b))))].append(int(c))
    new_points,new_weights=[],[]
    for i,p in enumerate(points):
        boundary=[j for j in neighbors[i] if len(edges[tuple(sorted((i,j)))])==1]
        if len(boundary)==2:
            new_points.append(.75*p+.125*points[boundary].sum(axis=0))
            new_weights.append(.75*weights[i]+.125*weights[boundary].sum(axis=0))
        elif neighbors[i]:
            adjacent=sorted(neighbors[i])
            beta=3./16. if len(adjacent)==3 else 3./(8.*len(adjacent))
            new_points.append((1.-len(adjacent)*beta)*p+beta*points[adjacent].sum(axis=0))
            new_weights.append((1.-len(adjacent)*beta)*weights[i]+beta*weights[adjacent].sum(axis=0))
        else:
            new_points.append(p);new_weights.append(weights[i])
    midpoint={}
    for edge,opposite in edges.items():
        a,b=edge
        midpoint[edge]=len(new_points)
        if len(opposite)==2:
            new_points.append(.375*(points[a]+points[b])+.125*points[opposite].sum(axis=0))
            new_weights.append(.375*(weights[a]+weights[b])+.125*weights[opposite].sum(axis=0))
        else:
            new_points.append(.5*(points[a]+points[b]))
            new_weights.append(.5*(weights[a]+weights[b]))
    out_faces,out_uv=[],[]
    for face,seam in zip(faces,uvfaces):
        a,b,c=[int(i) for i in face]
        ab,bc,ca=[midpoint[tuple(sorted(e))] for e in ((a,b),(b,c),(c,a))]
        ta,tb,tc=uv[seam]
        tab,tbc,tca=(ta+tb)*.5,(tb+tc)*.5,(tc+ta)*.5
        out_faces.extend(((a,ab,ca),(ab,b,bc),(ca,bc,c),(ab,bc,ca)))
        out_uv.extend(((ta,tab,tca),(tab,tb,tbc),(tca,tbc,tc),(tab,tbc,tca)))
    return np.asarray(new_points),np.asarray(new_weights),np.asarray(out_faces),np.asarray(out_uv)

def apply_fit(points, transform):
    homogeneous = np.column_stack((points, np.ones(len(points))))
    return (homogeneous @ transform.T)[:, :3]

def fit_transform(points, initial):
    floor = float(points[:, 2].min())
    saddle = initial["prop_saddle"][:3, 3]
    scale = (1.44 - .012) / (saddle[2] - floor)
    transform = np.eye(4)
    transform[:3, :3] = np.asarray(((scale, 0., 0.), (0., 0., scale), (0., -scale, 0.)))
    transform[:3, 3] = (-saddle[0] * scale, .012 - floor * scale, saddle[1] * scale - .04)
    return transform

def head_fit(point, transform):
    # Invert the previous fitted head coordinates to recover their source space.
    x, y, z = point
    source_height = np.interp(y, [.012, .915, 1.369, 1.628, 1.993], [-.01, 2.6, 4.01, 4.55, 5.554])
    source_forward = np.interp(z, [-1.082, -.573, -.048, .480, .785, 1.187], [2.99, 1.57, -.05, -1.66, -3.03, -3.992])
    return apply_fit(np.asarray([(x / .418, source_forward, source_height)]), transform)[0]

def fit_tack(transform):
    doc = json.loads((ROOT / "assets/art/mounts/mounts.gltf").read_text())
    raw = (ROOT / "assets/art/mounts/mounts.bin").read_bytes()
    library = Library()
    def values(index):
        accessor = doc["accessors"][index]
        view = doc["bufferViews"][accessor["bufferView"]]
        width = {"VEC3": 3, "VEC2": 2, "SCALAR": 1}[accessor["type"]]
        kind = {5126: "f", 5123: "H"}[accessor["componentType"]]
        start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        rows = list(struct.iter_unpack("<" + kind * width, raw[start:start + accessor["count"] * width * struct.calcsize(kind)]))
        return [tuple(v / 65535. for v in row) for row in rows] if accessor.get("normalized") else rows
    for mesh in doc["meshes"]:
        primitive = mesh["primitives"][0]
        xyz, uv, joint = (values(primitive["attributes"][key]) for key in ("POSITION", "TEXCOORD_0", "TEXCOORD_1"))
        indices = [value[0] for value in values(primitive["indices"])]
        surface = Surface()
        remap = {}
        draught = mesh["name"].startswith("Draught")
        for start in range(0, len(indices), 3):
            triangle = indices[start:start + 3]
            tiles = {int(uv[i][0] * 4) + 4 * int(uv[i][1] * 4) for i in triangle}
            assert len(tiles) == 1
            if not 6 <= tiles.pop() <= 13:
                continue
            for index in triangle:
                if index in remap:
                    continue
                point = np.asarray(xyz[index])
                bone, weight = int(joint[index][0] * 32), joint[index][1]
                if bone == 11:
                    point += (head_fit(point, transform) - point) * weight
                    if draught and weight < .999:
                        bone = 17  # The far rein endpoint belongs to the cart driver.
                elif draught and bone == 0:
                    bone = 16
                    t = float(np.clip((point[2] + 1.2) / .52, 0., 1.))
                    weight = t * t * (3. - 2. * t)
                remap[index] = surface.vertex(tuple(point), uv[index], 0)
                surface.joints[-1] = ((bone + .5) / 32., weight)
            surface.faces.append(tuple(remap[index] for index in triangle))
        library.insert(mesh["name"], surface, check_tiles=False)
    library.save(OUT / "native_tack.glb")

def normals(points,faces):
    result=np.zeros_like(points)
    for tri in faces:
        a,b,c=points[tri]
        n=np.cross(b-a,c-a)
        for i in tri: result[i]+=n
    lengths=np.linalg.norm(result,axis=1)
    assert np.all(lengths>1.e-10)
    return result/lengths[:,None]

def main():
    cache=Path(sys.argv[1]);cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    body_file=source_file(cache,*MESHES[0])
    names,inverse,nodes=rig(body_file)
    initial=pose(nodes,{},0.)
    residual=max(float(np.abs(initial[name]@inverse[i]-np.eye(4)).max()) for i,name in enumerate(names))
    assert residual<.0001, ("native bind mismatch",residual)
    body_points = read_dae(body_file, need_bind_positions=False)[0]
    fit_matrix = fit_transform(body_points, initial)
    fit_inverse = np.linalg.inv(fit_matrix)
    transforms = []
    socket_frames = []
    bind_changes = {}
    for label, path, signature in ANIMATIONS:
        source = source_file(cache, path, signature)
        _, _, source_nodes = rig(source)
        clip = tracks(source)
        # Retarget the ears/tail bind differences of the original walk clip.
        # Trot already uses exactly the body mesh's bind hierarchy.
        changed = {}
        for name, (time, values) in list(clip.items()):
            if name not in nodes or name not in source_nodes:
                continue
            target_bind = nodes[name][1]
            source_bind = source_nodes[name][1]
            difference = float(np.abs(target_bind - source_bind).max())
            if difference > .0001:
                clip[name] = (time, np.einsum("ij,kjl->kil", target_bind @ np.linalg.inv(source_bind), values))
                changed[name] = difference
        bind_changes[label] = changed
        samples = []
        sockets = []
        for key in range(KEYS + 1):
            world = pose(nodes, clip, key / KEYS)
            samples.append([world[name] @ inverse[i] for i, name in enumerate(names)])
            frame = {}
            for title, bone in (("saddle", "prop_saddle"), ("head", "Horse_Head")):
                delta = fit_matrix @ world[bone] @ np.linalg.inv(initial[bone]) @ fit_inverse
                frame[title] = delta[:3, :].tolist()
            sockets.append(frame)
        transforms.append(samples)
        socket_frames.append(sockets)
    transforms = np.asarray(transforms)
    sources=[]
    for slot,(path,sha) in enumerate(MESHES):
        points,uv,faces,uvfaces,influences,_=read_dae(source_file(cache,path,sha),need_bind_positions=False)
        weights=np.zeros((len(points),len(names)))
        for i,skin in enumerate(influences):
            for bone,value in skin: weights[i,names.index(bone)]+=value
        weights/=np.maximum(weights.sum(axis=1)[:,None],1.e-10)
        assert np.allclose(weights.sum(axis=1),1.)
        sources.append((points,weights,faces,uv,uvfaces))
    library=Library()
    all_positions,all_normals,all_groups,all_strength=[],[],[],[]
    metrics={"bind_residual":residual,"authored_joint_count":len(names),"saddle_registration":"original root with rider and tack following authored prop_saddle", "uniform_scale":float(fit_matrix[0,0]), "retargeted_bind_nodes":bind_changes,"clips":[x[0] for x in ANIMATIONS],"meshes":{}}
    for tier in ("Close","Rank"):
        surface=Surface()
        for slot,source in enumerate(sources):
            points,weights,faces,uv,uvfaces=source
            if tier=="Close" and slot==0:
                points,weights,faces,face_uv=sewn_subdivision(*source)
            else: face_uv=uv[uvfaces]
            rest=apply_fit(points,fit_matrix)
            homo=np.column_stack((points,np.ones(len(points))))
            native=np.einsum("ckbij,pj,pb->ckpi",transforms,homo,weights)[...,:3]
            posed=np.asarray([[apply_fit(frame,fit_matrix) for frame in clip] for clip in native])
            grouped=np.zeros((len(points),16))
            for i,name in enumerate(names): grouped[:,leg_group(name)]+=weights[:,i]
            groups=np.argmax(grouped[:,1:],axis=1)+1
            strength=np.take_along_axis(grouped,groups[:,None],axis=1).ravel()
            groups=np.where(strength>.001,groups,0)
            for group in range(1,5):
                hoof=(groups==group)&(rest[:,1]<.10)
                if not np.any(hoof): continue
                # First record the untouched author's support path. Surface
                # contact and foot travel are reviewed before accepting a clip.
                track=posed[:,:,hoof].mean(axis=2)
                details={"low_y":float(track[:,:,1].min()),"high_y":float(track[:,:,1].max()),"fore_aft":float(np.ptp(track[:,:,2]))}
                for clip_index,(label,_,_) in enumerate(ANIMATIONS):
                    path=track[clip_index]
                    support=path[:,1] <= float(path[:,1].min())+.030
                    supported=support[:-1]&support[1:]
                    velocity=np.diff(path[:,2])*KEYS
                    supported &= velocity<0.
                    steps=velocity[supported]
                    details[label]={"supported_samples":int(supported.sum()),
                                    "local_support_metres_per_cycle":float(-np.median(steps)) if len(steps) else None,
                                    "world_drift_at_four_metres_per_second":float(np.sqrt(np.mean((steps+1./.68)**2))*4.*.68) if len(steps) else None,
                                    "lowest_surface_y":float(posed[clip_index,:,hoof,1].min())}
                metrics.setdefault("hooves",{})[tier+str(group)]=details
            norm=np.asarray([[normals(frame,faces) for frame in clip] for clip in posed])
            base=len(all_groups)
            all_positions.extend(posed.transpose(2,0,1,3))
            all_normals.extend(norm.transpose(2,0,1,3))
            for i,group in enumerate(groups):
                if group==12: strength[i]*=float(np.clip((1.38-rest[i,1])/.72,0.,1.))
                elif group==11: strength[i]*=float(np.clip((rest[i,2]-.27)*1.05+(rest[i,1]-1.14)*.90,0.,1.))
            all_groups.extend(groups.tolist());all_strength.extend(strength.tolist())
            used={}
            for face,coords in zip(faces,face_uv):
                indices=[]
                for i,coord in zip(face,coords):
                    key=(int(i),round(float(coord[0]),6),round(float(coord[1]),6))
                    if key not in used:
                        index=base+int(i)
                        u,v=np.clip(coord,.0005,.9995)
                        used[key]=surface.vertex(tuple(rest[i]),(float(u)+(2 if slot==0 else 3),float(v)),0)
                        surface.joints[-1]=(((index%256)+.5)/256.,((index//256)+.5)/32.)
                    indices.append(used[key])
                surface.faces.append(tuple(indices))
        library.insert("Remount"+tier,surface,check_tiles=False)
        metrics["meshes"][tier]={"triangles":len(surface.faces),"vertices":len(surface.positions)}
    count=len(all_groups)
    assert count<8192, count
    positions=np.asarray(all_positions).reshape((count,2*(KEYS+1),3))
    normal=np.asarray(all_normals).reshape((count,2*(KEYS+1),3))
    assert np.isfinite(positions).all() and np.isfinite(normal).all()
    assert positions.min()>-3. and positions.max()<3.,(positions.min(),positions.max())
    value=np.rint((positions/6.+.5)*65535.).astype(np.uint16)
    high=np.empty((count,66,4),dtype=np.uint8);low=high.copy();normal_image=high.copy()
    high[:,:,:3]=value>>8;low[:,:,:3]=value&255
    high[:,:,3]=np.asarray(all_groups,dtype=np.uint8)[:,None]
    low[:,:,3]=np.rint(np.asarray(all_strength)*255).astype(np.uint8)[:,None]
    normal_image[:,:,:3]=np.rint((normal*.5+.5)*255).astype(np.uint8)
    normal_image[:,:,3]=255
    for name,data in (("native_pose_hi",high),("native_pose_lo",low),("native_pose_normal",normal_image)):
        Image.fromarray(data,"RGBA").save(OUT/(name+".png"),optimize=True)
        resource="res://"+str((OUT/(name+".png")).relative_to(ROOT))
        imported="res://.godot/imported/"+name+".png-"+hashlib.md5(resource.encode()).hexdigest()+".ctex"
        (OUT/(name+".png.import")).write_text(
            '[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="'+imported+'"\n\n'
            '[deps]\nsource_file="'+resource+'"\ndest_files=["'+imported+'"]\n\n'
            '[params]\ncompress/mode=0\nmipmaps/generate=false\nmipmaps/limit=-1\n'
            'process/fix_alpha_border=false\nprocess/premult_alpha=false\n'
            'process/normal_map_invert_y=false\ndetect_3d/compress_to=0\n')
    library.save(OUT/"complete_remount.glb")
    fit_tack(fit_matrix)
    (OUT/"native_sockets.json").write_text(json.dumps({"keys":KEYS,"clips":[x[0] for x in ANIMATIONS],"frames":socket_frames},separators=(",",":"))+"\n")
    metrics["vertex_rows"]=count
    Path("reports/remount").mkdir(parents=True,exist_ok=True)
    Path("reports/remount/native.json").write_text(json.dumps(metrics,indent=2)+"\n")
    print("NATIVE_REMOUNT",json.dumps(metrics),flush=True)

if __name__=="__main__": main()
