"""Fit the bound timber bridge edge from 0 A.D. to the River Gate's plank deck."""
from hashlib import md5
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageFilter

from figure_mesh import Library
from import_garrison_issues import source_file
from import_river_gatehouse import read_frame

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/third_party/wildfire_bridge"
FRAME = ("meshes/props/special/bridge_edge_wooden.dae", "d2280ae0d344699c0ba198aa0f5d0fd0433ccc60")
SKIN = ("textures/skins/props/bridge_edge_wooden.png", "430fab99a5507dcb810f231deddcddfd3ad54341")

def timber(cache):
    pos, norm, uv, faces = read_frame(source_file(cache, *FRAME))
    # Source X runs along the bridge's bound trusses, Y across the rails,
    # and Z up. Fit the lower transoms under the deck, not across its surface.
    axis = np.array([[.132,0.,0.],[0.,0.,.226],[0.,-.145,0.]])
    vertices = pos @ axis.T + np.array([.06,.66,-1.13])
    normals = norm @ np.linalg.inv(axis)
    normals /= np.maximum(np.linalg.norm(normals, axis=1)[:, None], 1.e-9)
    coords, directions, tex, indices, used = [], [], [], [], {}
    for face in faces:
        for pi, ni, ti in face:
            key = (int(pi), int(ni), int(ti))
            if key not in used:
                used[key] = len(coords)
                coords.append(vertices[pi])
                directions.append(normals[ni])
                tex.append((uv[ti,0], 1.-uv[ti,1]))
            indices.append((used[key],))
    lib = Library()
    features = {"POSITION":lib.accessor(coords,"f",3,True),
                "NORMAL":lib.accessor(directions,"f",3),
                "TEXCOORD_0":lib.accessor(tex,"f",2)}
    lib.doc["meshes"].append({"name":"BoundTimber","primitives":[{"attributes":features,"indices":lib.accessor(indices,"H",1)}]})
    lib.doc["nodes"].append({"name":"BoundTimber","mesh":0})
    lib.doc["scenes"][0]["nodes"].append(0)
    lib.save(DEST/"bridge_edge.glb")
    assert len(faces)==4916 and 11.3<np.ptp(vertices[:,0])<11.7
    print("BRIDGE_EDGE", len(faces), vertices.min(axis=0), vertices.max(axis=0))

def atlas(cache):
    src = Image.open(source_file(cache,*SKIN)).convert("RGB")
    src.thumbnail((768,768), Image.Resampling.LANCZOS)
    paint = np.asarray(src.filter(ImageFilter.GaussianBlur(.68)), dtype=float)/255.
    light = paint @ np.array([.25,.57,.18])
    value = np.interp(light,[0.,.20,.39,.65,.86,1.],[.15,.235,.37,.52,.65,.73])
    warm = np.stack([value*1.15, value*.946, value*.729], axis=-1)
    pixels = np.clip(.23*paint+.77*warm,0.,1.)
    out = DEST/"bound_timber.png"
    Image.fromarray(np.rint(pixels*255).astype(np.uint8)).save(out,optimize=True)
    path = "res://"+out.relative_to(ROOT).as_posix()
    imp = "res://.godot/imported/bound_timber.png-"+md5(path.encode()).hexdigest()+".ctex"
    out.with_suffix(".png.import").write_text(f'''[remap]
importer="texture"
type="CompressedTexture2D"
path="{imp}"
metadata={{"vram_texture": false}}
[deps]
source_file="{path}"
dest_files=["{imp}"]
[params]
compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
''')

if __name__=="__main__":
    cache = Path(sys.argv[1])
    cache.mkdir(parents=True, exist_ok=True)
    DEST.mkdir(parents=True, exist_ok=True)
    timber(cache)
    atlas(cache)
