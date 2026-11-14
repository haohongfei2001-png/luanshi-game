"""Bake the licensed HM08 anatomical surface onto the existing field joints.

Run in Blender after fetch_hand_source.py. The output stores the original
surface, smooth reference normals and two-bone bind. No gameplay or hand socket changes.
"""
import hashlib
import json
from pathlib import Path
import sys
from urllib.request import urlopen
import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree
sys.path.insert(0,str(Path(__file__).resolve().parent))
from company_figures import arm_nodes, leg_nodes
from fetch_hand_source import FILES, BASE

TARGETS=[
    ("targets/macrodetails/asian-male-young.target","8cd3ef3e9ddb06ee2d166f75f9ac10871251f938",1.0),
    ("targets/macrodetails/proportions/male-young-averagemuscle-averageweight-idealproportions.target","c0a95b13bd0d2a78b025da7502f7b5653f917904",.60),
    ("targets/macrodetails/universal-male-young-maxmuscle-averageweight.target","b7c039c7f463fe1f1721b9ab269c7248d9c4f2f7",.22),
]
def checked(folder,path,digest):
    file=folder/Path(path).name
    if not file.exists(): file.write_bytes(urlopen(BASE+path,timeout=45).read())
    raw=file.read_bytes()
    assert hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==digest
    return raw.decode()
def frame(axis):
    axis=axis/np.linalg.norm(axis)
    reference=np.array([0.,1.,0.]) if abs(axis[2])>.95 else np.array([0.,0.,1.])
    lateral=np.cross(axis,reference)
    lateral/=np.linalg.norm(lateral)
    return np.stack([lateral,np.cross(axis,lateral),axis],axis=1)
def fit(point,first,last,start,end):
    delta=frame(last-first).T @ (point-first)
    delta[:2]*=.105
    delta[2]*=np.linalg.norm(end-start)/np.linalg.norm(last-first)
    return start+frame(end-start)@delta

def main():
    folder=Path(sys.argv[sys.argv.index("--")+1])
    for path,digest in FILES: checked(folder,path,digest)
    points,faces,group=[],[],""
    for line in (folder/"base.obj").read_text().splitlines():
        if line.startswith("v "): points.append(list(map(float,line.split()[1:])))
        elif line.startswith("g "): group=line[2:]
        elif group=="body" and line.startswith("f "): faces.append([int(v.split("/")[0])-1 for v in line.split()[1:]])
    original=np.array(points)
    p=original.copy()
    for name,digest,weight in TARGETS:
        for line in checked(folder,name,digest).splitlines():
            if line and line[0].isdigit():
                i,*delta=line.split()
                p[int(i)]+=np.array(delta,dtype=float)*weight
    # The old face atlas is registered to the asian young facial landmarks.
    chart=original.copy()
    for line in checked(folder,*TARGETS[0][:2]).splitlines():
        if line and line[0].isdigit():
            i,*delta=line.split()
            chart[int(i)]+=np.array(delta,dtype=float)
    rig=json.loads((folder/"default.mhskel").read_text())
    influence=json.loads((folder/"default_weights.mhw").read_text())["weights"]
    def at(bone): return p[rig["joints"][rig["bones"][bone]["head"]]].mean(axis=0)*[-1,1,1]
    reflected=p*np.array([-1,1,1])
    fitted=reflected.copy()
    crown=max(p[i,1] for face in faces for i in face)
    # Top of scalp and existing rig stay fixed. The source ideal-proportions
    # morph and 96 mm/source-unit head fit expose an adult neck above the collar.
    def headpoint(v):
        return np.array([v[0]*.096,1.725+(v[1]-crown)*.096,(v[2]-.28)*.104+.015])
    bone_weights=[{} for _ in points]
    sections={}
    for label,side,arm,fore,thigh,shin in (("L",-1,3,4,9,10),("R",1,6,7,12,13)):
        shoulder,elbow,wrist=map(np.array,arm_nodes(side))
        hip,knee,ankle=map(np.array,leg_nodes(side))
        sections[fore]=(at("lowerarm01."+label),at("wrist."+label),elbow,wrist)
        sections[thigh]=(at("upperleg01."+label),at("lowerleg01."+label),hip,knee)
        sections[shin]=(at("lowerleg01."+label),at("foot."+label),knee,ankle)
        sections[shin+1]=(at("foot."+label),at("foot."+label)+np.array([0.,0.,1.]),ankle,ankle+np.array([0.,0.,.105]))
        for name,entries in influence.items():
            if not name.endswith("."+label): continue
            prefix=name.split(".")[0]
            bone=fore if prefix.startswith(("lowerarm","wrist")) else thigh if prefix.startswith("upperleg") else shin if prefix.startswith("lowerleg") else shin+1 if prefix.startswith(("foot","toe")) else -1
            if bone<0: continue
            for i,w in entries:
                if w>0: bone_weights[i][bone]=bone_weights[i].get(bone,0)+w
    data={"source":{"revision":"a8bc2d54ff0ac92e78ff71431b1023eda42bf482","targets":TARGETS,"mesh_points":p.round(6).tolist(),"body_faces":faces,"rig":rig,"weights":influence}}
    for name in ("head","forearms","legs","feet"):
        def wanted(i):
            x,y,z=chart[i]
            if name=="head": return y>5.04 and abs(x)<1.4
            weights=bone_weights[i]
            if name=="forearms": return sum(weights.get(k,0) for k in (4,7))>.15
            if name=="feet": return sum(weights.get(k,0) for k in (11,14))>.15 or y<-7.35
            return y<.35 and sum(weights.get(k,0) for k in (9,10,12,13))>.15
        selected=[face for face in faces if all(wanted(i) for i in face)]
        used=sorted({i for face in selected for i in face})
        lookup={old:new for new,old in enumerate(used)}
        source_pos=[]
        compact_weights=[]
        for i in used:
            if name=="head":
                position=headpoint(reflected[i])
                weight=max(0.,min(1.,(position[1]-1.415)/.10))
                weights=(2,1,weight)
            else:
                w=bone_weights[i]
                weights=sorted(w,key=w.get,reverse=True)[:2]
                if len(weights)==1: weights.append(weights[0])
                amount=w[weights[0]]/sum(w[k] for k in set(weights))
                position=sum((fit(reflected[i],*sections[k])*w[k] for k in w),np.zeros(3))/sum(w.values())
                if name=="feet":
                    foot=11 if reflected[i][0]<0 else 14
                    delta=reflected[i]-sections[foot][0]
                    position=sections[foot][2]+delta*np.array([.108,.171,.112])
                    weights=[foot,foot];amount=1.
                first=weights[0]
                start,end=sections[first][2:]
                axis=end-start
                t=np.clip(np.dot(position-start,axis)/np.dot(axis,axis),0,1)
                center=start+axis*t
                ease=(1.15 if name=="legs" else 1. if name=="feet" else 1.02)
                position=center+(position-center)*ease
                weights=(*weights,amount)
            source_pos.append(position)
            compact_weights.append(weights)
        assert np.isfinite(source_pos).all(), (name,"non-finite fitted anatomy")
        kd=KDTree(len(used))
        for i,v in enumerate(source_pos): kd.insert(Vector(v),i)
        kd.balance()
        for tier,ratio in (("Close",1.0),("Line",.58),("Rank",.20)):
            bpy.ops.wm.read_factory_settings(use_empty=True)
            mesh=bpy.data.meshes.new(name+tier)
            # Reflection in X changes the source polygon orientation.
            mesh.from_pydata(source_pos,[],[tuple(lookup[i] for i in reversed(face)) for face in selected])
            mesh.update()
            if name=="head":
                bm=bmesh.new();bm.from_mesh(mesh)
                bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
                bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
                bm.to_mesh(mesh);bm.free();mesh.update()
            if name=="head":
                chart_xy=mesh.uv_layers.new(name="Original face XY")
                chart_z=mesh.uv_layers.new(name="Original face Z")
                for loop in mesh.loops:
                    x,y,z=chart[used[loop.vertex_index]]
                    chart_xy.data[loop.index].uv=(x,y)
                    chart_z.data[loop.index].uv=(z,0.)
            obj=bpy.data.objects.new(name+tier,mesh);bpy.context.collection.objects.link(obj)
            bpy.context.view_layer.objects.active=obj
            if name=="feet":
                # A leather shoe encloses the original anatomical last. Build
                # each foot's outer hull independently so the separated toe
                # islands and open ankle cannot become a voxel wire lattice.
                hp,hf=[],[]
                for side in (-1,1):
                    bm=bmesh.new()
                    for point in source_pos:
                        if point[0]*side>0: bm.verts.new(tuple(point))
                    bm.verts.ensure_lookup_table()
                    result=bmesh.ops.convex_hull(bm,input=list(bm.verts),use_existing_faces=False)
                    unused=[v for v in bm.verts if not v.link_faces]
                    if unused: bmesh.ops.delete(bm,geom=unused,context="VERTS")
                    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
                    bm.verts.index_update()
                    offset=len(hp)
                    hp.extend(tuple(v.co) for v in bm.verts)
                    hf.extend(tuple(v.index+offset for v in f.verts) for f in bm.faces)
                    bm.free()
                replacement=bpy.data.meshes.new("Closed anatomical shoe")
                replacement.from_pydata(hp,[],hf);replacement.update()
                obj.data=replacement
            dec=obj.modifiers.new("Field surface reduction","DECIMATE")
            budget={"head":(6800,3200,900),"forearms":(1400,700,180),"legs":(2600,1200,400),"feet":(800,400,140)}[name][("Close","Line","Rank").index(tier)]
            dec.ratio=min(ratio,budget/max(1,sum(len(p.vertices)-2 for p in obj.data.polygons)));dec.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=dec.name)
            final=obj.data
            final.update()
            final.calc_loop_triangles()
            verts=[list(v.co) for v in final.vertices]
            assert np.isfinite(verts).all(), (name,tier,"non-finite reduced anatomy")
            assert len(final.loop_triangles)<=budget*1.1, (name,tier,len(final.loop_triangles),budget)
            nearest=[kd.find(v.co)[1] for v in final.vertices]
            result={"p":[],"f":[],"w":[],"chart":[],"n":[]}
            remapped={}
            for triangle in final.loop_triangles:
                face=[]
                for i,loop in zip(triangle.vertices,triangle.loops):
                    sample=chart[used[nearest[i]]].round(5).tolist()
                    if name=="head":
                        a=final.uv_layers["Original face XY"].data[loop].uv
                        z=final.uv_layers["Original face Z"].data[loop].uv[0]
                        sample=[round(a[0],5),round(a[1],5),round(z,5)]
                    key=(i,*sample)
                    if key not in remapped:
                        remapped[key]=len(result["p"])
                        result["p"].append([round(a,6) for a in verts[i]])
                        result["n"].append([round(a,7) for a in final.vertices[i].normal])
                        result["chart"].append(sample)
                        result["w"].append(compact_weights[nearest[i]])
                    face.append(remapped[key])
                result["f"].append(face)
            data[name+tier]=result
            print("MATURE_FIELD_SURFACE",name,tier,len(result["p"]),len(result["f"]),flush=True)
    out=Path(__file__).with_name("source")/"field_anatomy.json"
    out.write_text(json.dumps(data,separators=(",",":"))+"\n")
    Path("reports/hm08").mkdir(parents=True,exist_ok=True)
    Path("reports/hm08/anatomy.json").write_text(json.dumps({"source":TARGETS,"crown":crown,"surface_counts":{k:len(v["f"]) for k,v in data.items() if k!="source"}},indent=2)+"\n")
if __name__=="__main__": main()
