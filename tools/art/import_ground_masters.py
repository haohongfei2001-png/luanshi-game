"""Import matched CC0 terrain colour and normal masters for the whole battlefield."""
from pathlib import Path
import hashlib
import json
import sys
from urllib.request import Request, urlopen
from PIL import Image
from bake_gate_apron import scan

ROOT = Path(__file__).resolve().parents[2]
ASSETS = [
    ("brown_mud_dry", "Rob Tuytel", 1.3),
    ("leafy_grass", "Charlotte Baglioni", 2.0),
    ("forest_ground_04", "Rob Tuytel and Rico Cilliers", None),
    ("sandy_gravel_02", "Dario Barresi", 2.5),
]
HEADERS = {"User-Agent": "Luanshi-River-Art/1.0 (github.com/haohongfei2001-png/luanshi-game)"}

def read(url):
    with urlopen(Request(url, headers=HEADERS), timeout=75) as response:
        return response.read()

def import_hint(path, normal=False):
    texture = "res://" + path.relative_to(ROOT).as_posix()
    imported = "res://.godot/imported/" + path.name + "-" + hashlib.md5(texture.encode()).hexdigest() + ".ctex"
    (path.parent / (path.name + ".import")).write_text(
        '[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="' + imported +
        '"\nmetadata={"vram_texture": false}\n[deps]\nsource_file="' + texture +
        '"\ndest_files=["' + imported + '"]\n[params]\ncompress/mode=0\n' +
        'mipmaps/generate=true\ndetect_3d/compress_to=0\n' +
        ('compress/normal_map=1\n' if normal else ''))

def main(cache):
    cache.mkdir(parents=True, exist_ok=True)
    out = ROOT / "assets/river_gate/world/ground"
    out.mkdir(parents=True, exist_ok=True)
    receipt = {}
    for name, author, metres in ASSETS:
        pixels = scan(name, cache, receipt)
        path = out / (name + ".jpg")
        Image.fromarray(pixels).save(path, quality=94, subsampling=0)
        import_hint(path)
        receipt[name]["author"] = author
        receipt[name]["source_width_metres"] = metres
        if name == "forest_ground_04":
            continue
        manifest = json.loads(read("https://api.polyhaven.com/files/" + name))
        entry = manifest["nor_gl"]["2k"]["jpg"]
        cached = cache / (name + "_nor_gl.jpg")
        if not cached.is_file() or hashlib.md5(cached.read_bytes()).hexdigest() != entry["md5"]:
            data = read(entry["url"])
            assert hashlib.md5(data).hexdigest() == entry["md5"], entry["url"]
            cached.write_bytes(data)
        path = out / cached.name
        path.write_bytes(cached.read_bytes())
        with Image.open(path) as image:
            assert min(image.size) >= 2048, image.size
        import_hint(path, normal=True)
        receipt[name]["normal"] = {"source": entry["url"], "md5": entry["md5"], "convention": "OpenGL"}
    (out / "SOURCE.json").write_text(json.dumps(receipt, indent=2) + "\n")
    (out / "NOTICE.txt").write_text(
        "Poly Haven CC0 1.0 colour and matched OpenGL normal masters.\n"
        "Original source URLs, authors and checksums are recorded in SOURCE.json.\n"
        "https://polyhaven.com/license\n")

if __name__ == "__main__":
    main(Path(sys.argv[1]))
