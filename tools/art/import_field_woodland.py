"""Preserve complete author-built woodland silhouettes and matched RGBA foliage.

The source actor pairings determine bark, crown and branch meshes. Each exported
tree is assembled as a whole master at a shared root, with native UVs and masked
foliage. No leaf-card decimation is applied.
"""
from pathlib import Path
import json,shutil,sys
from PIL import Image
import numpy as np
from figure_mesh import Library
from import_garrison_issues import source_file,UPSTREAM
from import_river_gatehouse import read_frame
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/world/woodland"
MODELS={
    "tree_elm_01": "6a2f1eca2f7d5b60d7f9903b6180ed826e3aca92",
    "tree_elm_03": "70cfcc380d260c8e57ff4a9ea2ced4df18048a24",
    "oak_holly_1": "eb3d9941fb17d979e9c14261ac5b4085cd340f2c",
    "oak_holly_1_dead": "d061d89b5af8a4f6930d184d539c6335ba70aa22",
    "oak_holly_3": "a0c71565389bf869a89f353648fc519dd2f592ed",
    "oak_holly_3_dead": "ab6fe0dbf30343ae7bf6121a4704c4fb8b2ca7b0",
    "temp_bush_01": "d5a6aaff926b260450501c938f939baea7bb6af7",
    "temp_bush_03": "d257b47b409b47c0710c22e49172e008537d0171"
}
MODELS.update({
    "trees/willow_a": "88fffd3d5f319b27e03f464d70dc9f772777585c",
    "maple_a": "22856cc64d15ee028dcf0ebe6d2964f7c8299d08",
    "maple_b": "0fa90be176e27ba177e7c5661f5f5afdcbd82cd5",
    "oak_hungarian_1": "276cfcc0a449ba10230a5c220ee12471356f641c",
    "oak_hungarian_1_dead": "23ff81cadf43c9c8ebed6babbade0452c3666b08",
    "oak_hungarian_3": "c9a085decf13b11fd1cb20ef667b6df928d818f3",
    "oak_hungarian_3_dead": "4615041443aaccfb16304a85f4775d3998ba8b33",
    "grass_la_tall_a": "937ba8fdf695beb93a4f11d83fc384da92d615cb",
    "grass_la_tall_b": "cf5d048eb78733aa206bc5922a2b1dd0d29ddeec"
})
TEXTURES={
    "tree_elm_01": "76d494660eaba54f6c3926b5a1614d9c7adbfef5",
    "oak_holly_1": "1f9a2c0e53ad3a4514134fbc96dd22db2e474caa",
    "oak_holly_dead": "46d05cd34f9329fbff482c30bb2f63f30bdaa220",
    "temperate_bush_01": "9824a1cd63170fb4598d6e966cec441fc7b65f40",
    "temperate_bush_02": "159b47806423807e91d314ef6ee22109beefaa2c"
}
TEXTURES.update({
    "willow_green": "394245aef453fb83995098a182b32d654cc754ec",
    "willow_aut_b": "e35a37a4afc9af0365d73467f33c89796196f5e7",
    "maple_tree_a": "01da7cb920321b4e06e612b6c1ae8e552f62edc3",
    "maple_tree_autumn_a": "74dcfbcafaa4bc0d088c2dcbc848510cafcd36f5",
    "oak_hungarian_1": "6a231e4f674d9401fd1cd53a596033851de2299a",
    "oak_hungarian_3": "49f4d0757c524633714cdee0e5271418360ba9fc",
    "oak_hungarian_dead": "922a587e3f0fd74eb01b7293f8bd77ba02303cc7"
})
TEXTURES["grass_field"]="53f7838ab6fdaba10ff24cb6d6373f4adf2a4d1e"
GROUPS={
    "FieldElmA":[("tree_elm_01","tree_elm_01")],
    "FieldElmB":[("tree_elm_03","tree_elm_01")],
    "FieldOakA":[("oak_holly_1","oak_holly_1"),("oak_holly_1_dead","oak_holly_dead")],
    "FieldOakB":[("oak_holly_3","oak_holly_1"),("oak_holly_3_dead","oak_holly_dead")],
    "FieldBrushA":[("temp_bush_01","temperate_bush_01")],
    "FieldBrushB":[("temp_bush_03","temperate_bush_02")]
}
GROUPS.update({
    "RiverWillowGreen": [
        [
            "trees/willow_a",
            "willow_green"
        ]
    ],
    "RiverWillowGold": [
        [
            "trees/willow_a",
            "willow_aut_b"
        ]
    ],
    "FieldMapleGreen": [
        [
            "maple_a",
            "maple_tree_a"
        ]
    ],
    "FieldMapleCopper": [
        [
            "maple_b",
            "maple_tree_autumn_a"
        ]
    ],
    "FieldOakBroadA": [
        [
            "oak_hungarian_1",
            "oak_hungarian_1"
        ],
        [
            "oak_hungarian_1_dead",
            "oak_hungarian_dead"
        ]
    ],
    "FieldOakBroadB": [
        [
            "oak_hungarian_3",
            "oak_hungarian_3"
        ],
        [
            "oak_hungarian_3_dead",
            "oak_hungarian_dead"
        ]
    ],
    "VergeGrassA": [
        [
            "grass_la_tall_a",
            "grass_field"
        ]
    ],
    "VergeGrassB": [
        [
            "grass_la_tall_b",
            "grass_field"
        ]
    ]
})
def main(cache):
    cache.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    library=Library()
    library.doc.update(images=[],textures=[],materials=[])
    materials={}
    for name,sha in TEXTURES.items():
        extension=".dds" if name=="grass_field" else ".png"
        path=source_file(cache,"textures/skins/gaia/"+name+extension,sha)
        output_name=name+".png"
        if extension==".dds":
            Image.open(path).convert("RGBA").save(OUT/output_name)
        else:
            shutil.copyfile(path,OUT/output_name)
        index=len(library.doc["images"])
        library.doc["images"].append({"uri":output_name})
        library.doc["textures"].append({"source":index})
        materials[name]=len(library.doc["materials"])
        library.doc["materials"].append({"name":name,"doubleSided":True,"alphaMode":"MASK","alphaCutoff":.40,
            "pbrMetallicRoughness":{"baseColorTexture":{"index":index},"metallicFactor":0.,"roughnessFactor":.96}})
    # The willow and maple atlases reserve their right-hand panel for bark.
    # Split only material assignment; retain every authored triangle and UV.
    for texture in ("willow_green","willow_aut_b","maple_tree_a","maple_tree_autumn_a"):
        source=library.doc["materials"][materials[texture]]
        bark=json.loads(json.dumps(source))
        bark["name"]=texture+"_bark"
        bark["alphaMode"]="OPAQUE"
        materials[texture+"_bark"]=len(library.doc["materials"])
        library.doc["materials"].append(bark)
    matrix=np.array([[1.,0.,0.],[0.,0.,1.],[0.,-1.,0.]])
    records=[]
    for name,parts in GROUPS.items():
        primitives=[]
        all_points=[]
        for model,texture in parts:
            path=source_file(cache,"meshes/gaia/"+model+".dae",MODELS[model])
            points,normals,uv,faces=read_frame(path)
            points=points@matrix.T
            normals=normals@matrix.T
            normals/=np.maximum(np.linalg.norm(normals,axis=1)[:,None],1.e-9)
            all_points.extend(points)
            groups={texture:faces}
            if texture+"_bark" in materials:
                threshold=.69 if texture.startswith("willow") else .745
                bark=np.all(uv[faces[:,:,2],0]>threshold,axis=1)
                groups={texture:faces[~bark],texture+"_bark":faces[bark]}
                assert len(groups[texture])+len(groups[texture+"_bark"])==len(faces)
            for material,triangles in groups.items():
                if not len(triangles):continue
                positions=[];directions=[];tex=[];indices=[];found={}
                for face in triangles:
                    for pi,ni,ti in face:
                        key=(int(pi),int(ni),int(ti))
                        if key not in found:
                            found[key]=len(positions)
                            positions.append(points[pi]);directions.append(normals[ni])
                            tex.append((uv[ti,0],1.-uv[ti,1]))
                        indices.append((found[key],))
                attrs={"POSITION":library.accessor(positions,"f",3,True),
                       "NORMAL":library.accessor(directions,"f",3),
                       "TEXCOORD_0":library.accessor(tex,"f",2)}
                primitives.append({"attributes":attrs,"indices":library.accessor(indices,"H",1),"material":materials[material]})
        number=len(library.doc["meshes"])
        library.doc["meshes"].append({"name":name,"primitives":primitives})
        library.doc["nodes"].append({"name":name,"mesh":number})
        library.doc["scenes"][0]["nodes"].append(number)
        points=np.asarray(all_points)
        record={"name":name,"native_parts":parts,"bounds":[points.min(axis=0).tolist(),points.max(axis=0).tolist()],
                "triangles":sum(library.doc["accessors"][p["indices"]]["count"]//3 for p in primitives)}
        records.append(record);print("WOODLAND_MASTER",json.dumps(record),flush=True)
    library.save(OUT/"field_woodland.glb")
    (OUT/"SOURCE.json").write_text(json.dumps({"upstream":UPSTREAM,"license":"CC BY-SA 3.0",
        "authors":"Wildfire Games contributors","models":MODELS,"textures":TEXTURES,"groups":records,"biome_revision":2},indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete willow, elm, oak, maple, associated branch and grass masters by Wildfire Games contributors.\n"
        "https://github.com/0ad/0ad/tree/"+UPSTREAM+"/binaries/data/mods/public/art\n"
        "CC BY-SA 3.0 https://creativecommons.org/licenses/by-sa/3.0/\n"
        "Derived Y-up conversion and whole-tree library use the same license. Native leaf alpha, UVs and painted value structure are preserved.\n")
if __name__=="__main__":main(Path(sys.argv[1]))
