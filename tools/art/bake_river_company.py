#!/usr/bin/env python3
"""Bake the original river-gate actor library, atlas and reusable motion bank. Python 3 + Pillow."""
import argparse
from pathlib import Path
from company_figures import costume
from company_weapons import weapon
from company_motion import bake_motion
from figure_atlas import make_atlas
from figure_mesh import Library
import company_line

def bake_geometry(dest):
    library=Library()
    for detailed,suffix in ((True,"Close"),(False,"Line")):
        for look in ("levy","archer","regular","guard","officer","player"):
            surface=costume(look,True) if detailed else company_line.costume(look)
            library.insert(look.capitalize()+suffix,surface)
            print(look,suffix,len(surface.faces),"triangles")
        for kit in range(9):
            surface=weapon(kit,True) if detailed else company_line.arms(kit)
            library.insert("Arms"+str(kit)+suffix,surface)
    for look in ("levy","archer","regular","guard","officer","player"):
        surface=company_line.costume(look,rank=True)
        library.insert(look.capitalize()+"Rank",surface)
    library.save(dest/"river_company.glb")

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--geometry-only",action="store_true",help="only rebuild the shared body and weapon meshes")
    args=parser.parse_args()
    dest=Path(__file__).resolve().parents[2]/"assets/river_gate/figures"
    dest.mkdir(parents=True,exist_ok=True)
    bake_geometry(dest)
    if not args.geometry_only:
        make_atlas(dest)
        bake_motion(dest)
    for p in sorted(dest.iterdir()):
        if not p.name.endswith(".import"):
            print(p.name,p.stat().st_size)

if __name__=="__main__":
    main()
