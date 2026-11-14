"""Import unaltered 2K CC0 soil, grass and forest-floor diffuse masters."""
from pathlib import Path
import hashlib,json,sys
from PIL import Image
from bake_gate_apron import scan
ROOT=Path(__file__).resolve().parents[2]
def main(cache):
    cache.mkdir(parents=True,exist_ok=True)
    out=ROOT/"assets/river_gate/world/ground"
    out.mkdir(parents=True,exist_ok=True)
    receipt={}
    for name,author in [("brown_mud_dry","Rob Tuytel"),("leafy_grass","Charlotte Baglioni"),("forest_ground_04","Rob Tuytel and Rico Cilliers")]:
        pixels=scan(name,cache,receipt)
        Image.fromarray(pixels).save(out/(name+".jpg"),quality=94,subsampling=0)
        texture="res://"+(out/(name+".jpg")).relative_to(ROOT).as_posix()
        imported="res://.godot/imported/"+name+".jpg-"+hashlib.md5(texture.encode()).hexdigest()+".ctex"
        (out/(name+".jpg.import")).write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="'+imported+'"\nmetadata={"vram_texture": false}\n[deps]\nsource_file="'+texture+'"\ndest_files=["'+imported+'"]\n[params]\ncompress/mode=0\nmipmaps/generate=true\ndetect_3d/compress_to=0\n')
        receipt[name]["author"]=author
    (out/"SOURCE.json").write_text(json.dumps(receipt,indent=2)+"\n")
    (out/"NOTICE.txt").write_text("Poly Haven CC0 1.0 diffuse scan masters. Original sources and authors are recorded in SOURCE.json. No normal-map or roughness-map dependency.\n")
if __name__=="__main__":main(Path(sys.argv[1]))
