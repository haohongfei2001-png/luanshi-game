"""Retarget the licensed complete horse and authored joint motion for River Gate.

The original Wildfire surface and its 51 skin groups stay editable. Near
geometry is one sewn subdivision of that same surface. Motion is baked from
the upstream walk and trot onto the existing saddle and real-distance phase.
"""
from collections import defaultdict
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
from figure_mesh import Surface, Library
from import_garrison_issues import read_dae, source_file
from import_remount import MESHES, fit, leg_group

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
        name=id_names.get(channel.get("target").split("/")[0])
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
        # Retain the existing rider's saddle frame and neck/rein relationship.
        # Every authored shoulder, elbow, wrist, hip, hock and hoof joint moves.
        if 1<=leg_group(name)<=4 and name in animation:
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

def fitted(points,slot):
    out=np.asarray([fit(p) for p in points])
    if slot==1:
        out[:,1]+=.17*np.clip((1.81-out[:,1])/.55,0.,1.)
        out[:,0]*=.82
    if slot==0:
        x,y,z=out.T
        saddle=(z>-.45)&(z<.25)&(y>1.08)
        out[:,1]+=.036*np.maximum(0.,1.-(x/.315)**2)*np.maximum(0.,1.-((z+.10)/.36)**2)*np.clip((y-1.08)/.25,0.,1.)*saddle
    return out

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
    body_file=source_file(cache,*MESHES[0])
    names,inverse,nodes=rig(body_file)
    initial=pose(nodes,{},0.)
    residual=max(float(np.abs(initial[name]@inverse[i]-np.eye(4)).max()) for i,name in enumerate(names))
    assert residual<.0001, ("native bind mismatch",residual)
    animation=[tracks(source_file(cache,path,sha)) for label,path,sha in ANIMATIONS]
    transforms=[]
    for clip in animation:
        samples=[]
        for key in range(KEYS+1):
            world=pose(nodes,clip,key/KEYS)
            samples.append([world[name]@inverse[i] for i,name in enumerate(names)])
        transforms.append(samples)
    transforms=np.asarray(transforms)
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
    metrics={"bind_residual":residual,"authored_joint_count":len(names),"clips":[x[0] for x in ANIMATIONS],"meshes":{}}
    for tier in ("Close","Rank"):
        surface=Surface()
        for slot,source in enumerate(sources):
            points,weights,faces,uv,uvfaces=source
            if tier=="Close" and slot==0:
                points,weights,faces,face_uv=sewn_subdivision(*source)
            else: face_uv=uv[uvfaces]
            rest=fitted(points,slot)
            homo=np.column_stack((points,np.ones(len(points))))
            native=np.einsum("ckbij,pj,pb->ckpi",transforms,homo,weights)[...,:3]
            posed=np.asarray([[fitted(frame,slot) for frame in clip] for clip in native])
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
                metrics.setdefault("hooves",{})[tier+str(group)]={"low_y":float(track[:,:,1].min()),"high_y":float(track[:,:,1].max()),"fore_aft":float(np.ptp(track[:,:,2]))}
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
    library.save(OUT/"complete_remount.glb")
    metrics["vertex_rows"]=count
    Path("reports/remount").mkdir(parents=True,exist_ok=True)
    Path("reports/remount/native.json").write_text(json.dumps(metrics,indent=2)+"\n")
    print("NATIVE_REMOUNT",json.dumps(metrics),flush=True)

if __name__=="__main__": main()
