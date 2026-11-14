"""Fit the licensed five-lobed 0 A.D. board and rear handle to the field shield hand."""
from pathlib import Path
import math
import sys

import numpy as np
from PIL import Image, ImageFilter

from company_figures import LH, grip
from figure_mesh import Library, Surface
from import_garrison_issues import source_file
from import_river_gatehouse import read_frame

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/third_party/wildfire_shields"
MODEL = ("meshes/props/shield/han_02.dae", "b9ae14e9dcb24beb9cbd1bf87502463445220e09")
PAINT = ("textures/skins/props/shield/han_04.dds", "51d070ec82e3b5bf0dd7b19d159155b16d73039c")
HANDLE = np.array([.0007, .066, -.0505])
# Columns are the source X, Y, Z axes. Its front looks down -Y and its handle
# runs up Z. Hold the top just outside the head without shifting the palm.
TILT = math.radians(7)
FIT = np.array([[.515*math.cos(TILT), 0., -.548*math.sin(TILT)],
                [.515*math.sin(TILT), 0.,  .548*math.cos(TILT)],
                [0., -1.08, 0.]])

def board_mesh(cache):
    pos, normals, uv, triangles = read_frame(source_file(cache, *MODEL))
    points = (pos-HANDLE) @ FIT.T + np.asarray(grip(-1))
    directions = normals @ np.linalg.inv(FIT)
    directions /= np.linalg.norm(directions, axis=1, keepdims=True)
    mesh = Surface()
    lookup = {}
    authored_normals = []
    for tri in triangles:
        face = []
        for vertex, normal, texel in tri:
            key = (vertex, normal, texel)
            if key not in lookup:
                u,v = np.clip(uv[texel], 0., 1.)
                # The fourth quadrant of the existing 528px garment sheet is
                # empty. Keep the replicated gutter and sample its texel centres.
                st = (3.+(268.5+255.*u)/528., (268.5+255.*(1.-v))/528.)
                lookup[key] = mesh.vertex(tuple(points[vertex]), st, LH)
                authored_normals.append(directions[normal].tolist())
            face.append(lookup[key])
        mesh.faces.append(tuple(face))
    # Retain distinct front, edge and grip normals across the author's UV seams.
    mesh.normals = lambda: authored_normals
    # Two end brackets and the through-grip occupy the back of the shell.
    # Their tips project behind the socket; the face must clear the fingers.
    z = points[:,2] - grip(-1)[2]
    if len(mesh.faces) != 129 or not (-.025 < z.min() < -.012 and .17 < z.max() < .22):
        raise ValueError("Unexpected board topology or grip clearance")
    return mesh

def lacquer_tile(cache):
    original = Image.open(source_file(cache, *PAINT)).convert("RGB")
    if original.size != (256,256):
        raise ValueError("Unexpected shield sheet size")
    original = original.filter(ImageFilter.GaussianBlur(.48))
    rgb = np.asarray(original, dtype=float)
    red, green, blue = rgb.transpose(2,0,1)
    value = .29*red + .55*green + .16*blue
    # Original broad lacquer figures on the face remain visible when mipmapped.
    # Dye only these islands; inward-facing wood and the crossbar stay warm.
    front = np.indices(value.shape)[1] < 128
    pigment = np.clip((red-np.maximum(green,blue)-15.)/58., 0., 1.)*front
    wood = np.stack([36.+.89*value, 32.+.77*value, 27.+.63*value], axis=-1)
    lacquer = np.stack([57.+.77*value, 57.+.73*value, 53.+.65*value], axis=-1)
    result = np.where(front[:,:,None], lacquer, wood)
    rgba = np.dstack([result, pigment*236.]).clip(0,255).round().astype(np.uint8)
    return Image.fromarray(np.pad(rgba,((4,4),(4,4),(0,0)),mode="edge"),"RGBA")

def write_board(cache):
    OUT.mkdir(parents=True,exist_ok=True)
    board = board_mesh(cache)
    library = Library()
    library.insert("GarrisonShield",board,check_tiles=False)
    library.save(OUT / "garrison_shield.glb")
    print("ISSUED_SHIELD",len(board.faces),"triangles at all three distances")

if __name__ == "__main__":
    cache = Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    write_board(cache)
    path = ROOT / "assets/third_party/wildfire_garments/field_colours.png"
    with Image.open(path) as src:
        atlas = src.convert("RGBA")
    if atlas.size != (528,528):
        raise ValueError("Unexpected issue sheet dimensions")
    atlas.paste(lacquer_tile(cache),(264,264))
    atlas.save(path)
