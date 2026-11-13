"""Extract MakeHuman HM08's hand topology, pose its five weighted digits in Blender,
and export a compact, shared glTF library for the Godot company's existing wrist bind.

blender -b -t 1 --python tools/art/makehuman_hands.py -- /tmp/hm08 tools/art/source/hand_grips.glb
The source directory holds base.obj, default.mhskel and default_weights.mhw.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ASSETS = {"base.obj": "d26635e9326e3cca30778fd7b9c00062b03cce09",
          "default.mhskel": "b02cbecae00143856410d7561adf006d83bf9b3e",
          "default_weights.mhw": "66185806afacf87749be8e5cf6dbf66496b2a6b0"}
STYLES = ("Haft", "BowPalm", "Nock", "Rest", "Shield")
TIERS = (("Close", .235), ("Line", .064), ("Rank", .017))


def load_source(folder):
    for name, digest in ASSETS.items():
        data = (folder/name).read_bytes()
        assert hashlib.sha1(f"blob {len(data)}\0".encode()+data).hexdigest() == digest, name
    verts, faces, group = [], [], ""
    for line in (folder/"base.obj").read_text().splitlines():
        if line.startswith("v "):
            verts.append(Vector(tuple(map(float, line.split()[1:]))))
        elif line.startswith("g "):
            group = line[2:]
        elif group == "body" and line.startswith("f "):
            faces.append(tuple(int(item.split("/")[0])-1 for item in line.split()[1:]))
    rig = json.loads((folder/"default.mhskel").read_text())
    weights = json.loads((folder/"default_weights.mhw").read_text())
    assert rig["license"] == weights["license"] == "CC0"
    return verts, faces, rig, weights["weights"]


def grip_mesh(verts, faces, rig, weight_table, style):
    def joint(bone, end):
        ids = rig["joints"][rig["bones"][bone][end]]
        return sum((verts[i] for i in ids), Vector())/len(ids)

    wrist = joint("wrist.L","head")
    fingers = [[joint(f"finger{digit}-{part}.L","head") for part in (1,2,3)]
               + [joint(f"finger{digit}-3.L","tail")] for digit in range(1,6)]
    knuckles = [line[0] for line in fingers[1:]]
    # Across the metacarpals towards the index, along the back of the hand,
    # and out of the fleshy palm. Preserve the source's thenar and knuckle volumes.
    radial = (knuckles[0]-knuckles[3]).normalized()
    distal = (sum(knuckles,Vector())/4-wrist).normalized()
    distal = (distal-radial*distal.dot(radial)).normalized()
    palmar = distal.cross(radial).normalized()

    def coords(p):
        d=p-wrist
        return Vector((d.dot(radial),d.dot(distal),d.dot(palmar)))

    def base_point(src):
        u,t,n=coords(src)
        # The root sits inside the cuff. The back sweeps clear of a 6 cm haft
        # and the knuckle ridge turns onto the working side of the handle.
        sweep=min(1,max(0,t/.63))
        sweep=sweep*sweep*(3-2*sweep)
        reach=.062*sweep+.009*math.sin(math.pi*min(1,max(0,t)))
        rise=.067*math.sin(math.pi*min(1,max(0,t)))-.011*t
        return Vector((reach-.10*n, -.024+rise-.006*u, .105*u-.021))

    def resting_vector(v):
        return Vector((-.10*v.dot(palmar),-.093*v.dot(distal),.105*v.dot(radial)))

    # Existing hand joints use +Z along a spear haft; bow palm is perpendicular.
    # The draw uses a narrow thumb lock with the index folded over the thumb,
    # and three less curled fingers that travel back with the nocking hand.
    def placed(point,t):
        x,y,z=point
        if style=="BowPalm":
            turn=max(0,min(1,(t-.02)/.45))
            return point.lerp(Vector((x,z,-y)),turn*turn*(3-2*turn))
        return Vector((x,y,z))

    targets={}
    keep=set()
    influence={}
    cutoff=(wrist-joint("lowerarm02.L","head")).normalized()
    for bone,entries in weight_table.items():
        if not bone.endswith(".L") or not bone.startswith(("wrist","metacarpal","finger","lowerarm02")):
            continue
        for i,w in entries:
            if w<=0: continue
            if bone.startswith("lowerarm") and (verts[i]-wrist).dot(cutoff)<-.32: continue
            keep.add(i)
            influence.setdefault(i,[]).append((bone,w))

    # Separate MCP/PIP/DIP positions keep the original webbing, nails and
    # soft tissue. Match the larger index and middle wraps to the game socket.
    for digit,chain in enumerate(fingers,1):
        start=base_point(chain[0])
        if digit==1:
            aim=[start, Vector((.033,.038,.035)),Vector((.012,.031,.047)),Vector((-.014,.018,.039))]
            if style=="Nock":
                aim=[start,Vector((.020,.029,.035)),Vector((.007,.013,.025)),Vector((.002,.002,.007))]
        else:
            t=(digit-2)/3
            z=start.z
            fan=.003*(1.-t)
            aim=[start, Vector((.038+.007*t,-.039+.004*t,z+fan)),
                  Vector((.008+.012*t,-.042+.002*t,z+.003)),
                  Vector((-.018+.019*t,-.025+.001*t,z+.002))]
            if style=="Nock":
                aim=[start,Vector((.030+.018*t,-.030-.009*t,z+fan)),
                     Vector((.012+.009*t,-.026-.014*t,z+.002)),
                     Vector((.001+.018*t,-.008-.023*t,z+.002))]
            if style=="BowPalm":
                # Some extension in the ring and little fingers leaves the bow
                # seated in the thumb web without closing a fist on the limb.
                aim[2].x+=.007*t
                aim[3].x+=.015*t
        if style=="Rest" and digit==1:
            aim=[start,Vector((.028,.032,.041)),Vector((.015,.008,.061)),Vector((.008,-.011,.066))]
        elif style=="Rest":
            # The free hand of the swordsman hangs at the existing wrist pose;
            # source digits curl a little more from index to little finger.
            length=sum((chain[i+1]-chain[i]).length*.10 for i in range(3))
            z=start.z
            fold=.019+.013*(digit-2)/3
            aim=[start,Vector((start.x-.013,start.y-.38*length,z)),
                 Vector((start.x-.026,start.y-.68*length,z-.002)),
                 Vector((start.x-.026-fold,start.y-.88*length,z-.004))]
        for part in range(3):
            bone=f"finger{digit}-{part+1}.L"
            at,there=chain[part],aim[part]
            axis=resting_vector(chain[part+1]-at)
            into=aim[part+1]-there
            twist=axis.rotation_difference(into)
            targets[bone]=(at,there,axis.normalized(),into.length/axis.length,twist)

    def pose(i):
        p=verts[i]
        out=Vector()
        total=0.
        for bone,w in influence[i]:
            if bone in targets:
                a,b,unit,stretch,rot=targets[bone]
                offset=resting_vector(p-a)
                value=b+rot@(offset+unit*(offset.dot(unit)*(stretch-1.)))
            else:
                value=base_point(p)
            out+=value*w
            total+=w
        t=coords(p).y
        point=out/total
        if style in ("Haft","Shield","BowPalm") and t>.31:
            # The actual haft has 27–34 mm radius. Finger pads may compress but
            # must not continue through its centre and emerge on the far side.
            # Preserve the dorsal outline and the unwarped wrist seated in its cuff.
            radial=math.hypot(point.x,point.y)
            if radial<.030:
                scale=.030/max(radial,.0004)
                angle=max(0.,min(1.,(t-.31)/.18))
                point.x*=1.+(scale-1.)*angle
                point.y*=1.+(scale-1.)*angle
        return placed(point,t)

    skin=[f for f in faces if all(i in keep for i in f)]
    used=sorted(set(i for face in skin for i in face))
    index={old:new for new,old in enumerate(used)}
    assert 1400<len(skin)<1900 and len(used)>1400
    coordinates=[]
    for i in used:
        x,y,z=pose(i)
        coordinates.append((x,-z,y))  # Blender Z up, exported glTF Y up.
    recut=[tuple(index[i] for i in face) for face in skin]
    center=sum((Vector(p) for p in coordinates),Vector())/len(coordinates)
    points=[Vector(p)-center for p in coordinates]
    volume=sum(points[f[0]].dot(points[f[i]].cross(points[f[i+1]])) for f in recut for i in range(1,len(f)-1))
    if volume<0: recut=[tuple(reversed(f)) for f in recut]
    print("HM08_SOURCE_SECTION",style,len(used),len(skin),flush=True)
    return coordinates,recut


def main():
    source,dest=map(Path,sys.argv[sys.argv.index("--")+1:])
    skin=load_source(source)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for style in STYLES:
        positions,faces=grip_mesh(*skin,style)
        for suffix,ratio in TIERS:
            name=style+suffix
            mesh=bpy.data.meshes.new(name)
            mesh.from_pydata(positions,[],faces)
            mesh.update()
            for face in mesh.polygons: face.use_smooth=True
            obj=bpy.data.objects.new(name,mesh)
            bpy.context.collection.objects.link(obj)
            bpy.context.view_layer.objects.active=obj
            # Reduce the posed topology once per tier, before it is used by a
            # single close actor or a thousand low-cost formation instances.
            dec=obj.modifiers.new("Game distance","DECIMATE")
            dec.ratio=ratio
            dec.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=dec.name)
            print("HM08_GRIP",name,len(obj.data.vertices),len(obj.data.polygons),flush=True)
    dest.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(dest.resolve()),export_format="GLB",export_yup=True,
                              export_texcoords=False,export_normals=False,export_materials="NONE")


if __name__=="__main__":
    main()
