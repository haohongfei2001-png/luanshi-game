"""Fit the editable Wildfire Games infantry head and its own UV-matched faces to helmeted troops."""
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageFilter

from company_figures import HEAD
from figure_mesh import Surface, Library
from import_garrison_issues import ROOT, source_file
from import_river_gatehouse import read_frame

OUT = ROOT / "assets/third_party/wildfire_faces"
MASTER = ("meshes/props/new/dude_head.dae", "61391ecdf88a8d51ea2e77f4efc5edaa724d8c81")
FACES = (
    ("han_a","6e5cff731cbdce540b153ed3b2d4999a0d820fd5",False),
    ("han_c","d05c5c697c97e2ad03d8b28300e2686ff6893792",False),
    ("han_b","d5b5e65970c6b6666873da8fa0b2192409170eb3",True),
)

def field_head(source, role, width):
    """Place the jaw, nose, eyes and crown under the existing cap in its real bind."""
    points, normals, uvs, faces = source
    # The source faces down -Y. X remains the helmet width, Z is the crown.
    # The neck is already part of the garment, and the base of this head seats
    # inside it. Normals and original UV seams survive the anisotropic fit.
    transform = np.array([[width,0.,0.],[0.,0.,.47],[0.,-.442,0.]])
    bound = points @ transform.T + np.array([0.,1.494,.014])
    transformed = normals @ np.linalg.inv(transform)
    transformed /= np.linalg.norm(transformed,axis=1,keepdims=True)
    result = Surface()
    lookup, outline_normals = {}, []
    for tri in faces:
        indices = []
        for p,n,t in tri:
            key = (p,n,t)
            if key not in lookup:
                u,v=np.clip(uvs[t],0.,1.)
                # Mark this mesh; the skin shader selects one persistent face
                # from three 128px issues before interpolation, with 4px gutters.
                coords=(4.+min(float(u),.99999), (4.5+127.*(1.-v))/136.)
                lookup[key]=result.vertex(tuple(bound[p]),coords,HEAD)
                outline_normals.append(transformed[n].tolist())
            indices.append(lookup[key])
        result.faces.append(tuple(indices))
    result.normals=lambda: outline_normals
    print("INFANTRY_HEAD",role,len(result.faces),"triangles",bound.min(axis=0),bound.max(axis=0))
    return result

def painted_face(cache,name,signature,moustache):
    pic=Image.open(source_file(cache,"textures/skins/props/head/"+name+".png",signature)).convert("RGB")
    if pic.size != (128,128):
        raise ValueError((name,pic.size))
    # A narrow median removes the photographic grain on the old atlas. Broad
    # eyelids, brows, hair and lip shapes still come from the source painter.
    before=np.asarray(pic.filter(ImageFilter.MedianFilter(3)),dtype=float)/255.
    mid=np.asarray(pic.filter(ImageFilter.GaussianBlur(1.45)),dtype=float)/255.
    pigment=.67*mid+.33*before
    value=pigment @ np.array([.27,.59,.14])
    keys=[.0,.16,.27,.43,.62,.82,1.]
    hues=np.asarray([[37,34,31],[52,44,38],[84,59,49],[137,92,73],
                     [176,124,94],[202,153,116],[215,173,139]])
    # Preserve the dark brow and beard as shapes. Limit bright temple, nose
    # and cheek to warm matte skin tones instead of importing photographic shine.
    shade=np.stack([np.interp(value,keys,hues[:,i]) for i in range(3)],axis=-1)
    if moustache:
        shade[:,:,0]*=.975
    raw=shade.round().astype(np.uint8)
    return Image.fromarray(np.pad(raw,((4,4),(4,4),(0,0)),mode="edge"))

def main(cache):
    cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    source=read_frame(source_file(cache,*MASTER))
    bank=Library()
    for role,width in (("Regular",.489),("Guard",.513),("Archer",.469)):
        bank.insert(role+"Face",field_head(source,role,width),check_tiles=False)
    bank.save(OUT/"field_heads.glb")
    atlas=Image.new("RGB",(408,136))
    for slot,face in enumerate(FACES):
        atlas.paste(painted_face(cache,*face),(slot*136,0))
    atlas.save(OUT/"field_visages.png")

if __name__=="__main__":
    main(Path(sys.argv[1]))
