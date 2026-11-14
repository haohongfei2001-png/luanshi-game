"""Preserve complete author-built woodland silhouettes and matched RGBA foliage.

The source actor pairings determine bark, crown and branch meshes. Each exported
tree is assembled as a whole master at a shared root, with native UVs and masked
foliage. No leaf-card decimation is applied.
"""
from pathlib import Path
import json,shutil,sys
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
TEXTURES={
    "tree_elm_01": "76d494660eaba54f6c3926b5a1614d9c7adbfef5",
    "oak_holly_1": "1f9a2c0e53ad3a4514134fbc96dd22db2e474caa",
    "oak_holly_dead": "46d05cd34f9329fbff482c30bb2f63f30bdaa220",
    "temperate_bush_01": "9824a1cd63170fb4598d6e966cec441fc7b65f40",
    "temperate_bush_02": "159b47806423807e91d314ef6ee22109beefaa2c"
}
GROUPS={
    "FieldElmA":[("tree_elm_01","tree_elm_01")],
    "FieldElmB":[("tree_elm_03","tree_elm_01")],
    "FieldOakA":[("oak_holly_1","oak_holly_1"),("oak_holly_1_dead","oak_holly_dead")],
    "FieldOakB":[("oak_holly_3","oak_holly_1"),("oak_holly_3_dead","oak_holly_dead")],
    "FieldBrushA":[("temp_bush_01","temperate_bush_01")],
    "FieldBrushB":[("temp_bush_03","temperate_bush_02")]
}
def main(cache):
    cache.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
    library=Library()
    library.doc.update(images=[],textures=[],materials=[])
    materials={}
    for name,sha in TEXTURES.items():
        path=source_file(cache,"textures/skins/gaia/"+name+".png",sha)
        shutil.copyfile(path,OUT/path.name)
        index=len(library.doc["images"])
        library.doc["images"].append({"uri":path.name})
        library.doc["textures"].append({"source":index})
        materials[name]=index
        library.doc["materials"].append({"name":name,"doubleSided":True,"alphaMode":"MASK","alphaCutoff":.40,
            "pbrMetallicRoughness":{"baseColorTexture":{"index":index},"metallicFactor":0.,"roughnessFactor":.96}})
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
            positions=[];directions=[];tex=[];indices=[];found={}
            for face in faces:
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
            primitives.append({"attributes":attrs,"indices":library.accessor(indices,"H",1),"material":materials[texture]})
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
        "authors":"Wildfire Games contributors","models":MODELS,"textures":TEXTURES,"groups":records},indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete elm, oak, associated branch and undergrowth masters by Wildfire Games contributors.\n"
        "https://github.com/0ad/0ad/tree/"+UPSTREAM+"/binaries/data/mods/public/art\n"
        "CC BY-SA 3.0 https://creativecommons.org/licenses/by-sa/3.0/\n"
        "Derived Y-up conversion and whole-tree library use the same license. Native leaf alpha, UVs and painted value structure are preserved.\n")
if __name__=="__main__":main(Path(sys.argv[1]))
