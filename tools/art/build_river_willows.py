"""Author complete river willows with Blender's mature Sapling branching system.

The generator and preset are loaded at an immutable Blender Add-ons commit in
the disposable authoring runner. Output includes real connected woody branches
and individual three-dimensional lanceolate leaves, with no billboard crowns.
"""
from pathlib import Path
import ast,hashlib,importlib,json,math,sys
from urllib.request import urlopen
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/world/willows"
CACHE=Path(sys.argv[sys.argv.index("--")+1])
COMMIT="b42d68627734cb18af0e6f41537063984313a284"
FILES={"__init__.py":"e46f1945ba9aaee7b7aa9b8ca48dca771a531500","utils.py":"ea1026c10fb55de0541dd7f4a1b238ced8d4085f","presets/weeping_willow.py":"168126d5a7be5e30a76d14c44a6bd14266a64ecb","presets/small_maple.py":"08cf22dd932c1cbb5246c2071562eedd511f740f"}
def srgb(value):
    return value/12.92 if value<=.04045 else ((value+.055)/1.055)**2.4
def material(name,color):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes.get("Principled BSDF")
    n.inputs["Base Color"].default_value=tuple(srgb(v) for v in color)+(1.,)
    n.inputs["Roughness"].default_value=.94
    spec=n.inputs.get("Specular IOR Level") or n.inputs.get("Specular")
    if spec:spec.default_value=.10
    return m
def main():
    addon=CACHE/"add_curve_sapling"
    for path,signature in FILES.items():
        dest=addon/path;dest.parent.mkdir(parents=True,exist_ok=True)
        with urlopen("https://raw.githubusercontent.com/blender/blender-addons/"+COMMIT+"/add_curve_sapling/"+path,timeout=45) as response:raw=response.read()
        assert hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==signature,path
        dest.write_bytes(raw)
    sys.path.insert(0,str(CACHE))
    package=importlib.import_module("add_curve_sapling");package.register()
    preset=(addon/"presets/weeping_willow.py").read_text()
    settings=ast.literal_eval(preset[preset.index("{"):])
    OUT.mkdir(parents=True,exist_ok=True)
    report={"generator":"Blender Sapling Tree Gen","generator_commit":COMMIT,"generator_license":"GPL-2.0-or-later, generator source stays upstream","preset":"weeping_willow","variants":[]}
    for index,(seed,height) in enumerate(((2789,8.6),(2868,7.4),(3881,7.8),(3793,6.2))):
        bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
        if index<2:
            settings.update(showLeaves=True,useArm=False,armAnim=False,leafAnim=False,seed=seed,scale=height,scaleV=0.,ratio=.038,leafScale=.30,leafScaleX=.21,leafScaleV=.24,leaves=170,branches=(0,28,16,1),curveV=(80.,95.,20.,0.),bevelRes=2,curveRes=(10,14,10,1),resU=3,makeMesh=False)
        else:
            preset=(addon/"presets/small_maple.py").read_text()
            settings=ast.literal_eval(preset[preset.index("{"):])
            settings.update(showLeaves=True,useArm=False,armAnim=False,leafAnim=False,seed=seed,scale=height,scaleV=0.,ratio=.033,leafScale=.30,leafScaleX=.72,leaves=58,branches=(0,55,16,8),bevelRes=2,resU=3,makeMesh=False)
        valid=bpy.ops.curve.tree_add.get_rna_type().properties.keys()
        bpy.ops.curve.tree_add(**{k:v for k,v in settings.items() if k in valid})
        objects=list(bpy.context.scene.objects)
        for obj in objects:
            obj.select_set(True);bpy.context.view_layer.objects.active=obj
        bpy.ops.object.convert(target="MESH")
        trunk=material("Willow aged bark",(.26,.25,.195))
        leaf_tones=[material("Willow lanceolate "+str(i),color) for i,color in enumerate((((.32,.355,.17),(.40,.41,.19),(.47,.455,.22),(.26,.31,.145)) if index<2 else ((.23,.30,.12),(.28,.34,.13),(.36,.37,.16),(.18,.26,.10))))]
        for obj in bpy.context.scene.objects:
            if obj.type!="MESH":continue
            is_leaf="lea" in obj.name.lower()
            obj.name=("PendantLeaves" if is_leaf else "TrunkAndWhips")+str(index)
            obj.data.materials.clear()
            for m in leaf_tones if is_leaf else [trunk]:obj.data.materials.append(m)
            for face in obj.data.polygons:
                face.use_smooth=not is_leaf
                if is_leaf:face.material_index=(face.index*17+face.index//7)%len(leaf_tones)
        triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.context.scene.objects if o.type=="MESH")
        assert 10000<triangles<900000,triangles
        name=("river_willow_"+str(index)) if index<2 else ("river_maple_"+str(index-2))
        bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")),export_format="GLB",export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
        report["variants"].append({"file":name+".glb","seed":seed,"metres":height,"triangles":triangles,"settings":settings.copy()})
        print("WHOLE_WILLOW",name,height,triangles,flush=True)
    (OUT/"AUTHORING.json").write_text(json.dumps(report,indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Original River Gate willow scenes authored with Blender Sapling Tree Gen, using the documented immutable generator and edited weeping-willow parameters.\nGenerator by Andrew Hale, Aaron Buchler, CansecoGPC and Blender contributors, GPL-2.0-or-later.\nhttps://github.com/blender/blender-addons/tree/"+COMMIT+"/add_curve_sapling\nAUTHORING.json records the parameters and complete connected geometry.\n")
main()
