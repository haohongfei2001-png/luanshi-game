#!/usr/bin/env python3
"""Bake the original river-gate actor library, atlas and reusable motion bank. Python 3 + Pillow."""
from pathlib import Path
from company_figures import costume
from company_weapons import weapon
from company_motion import bake_motion
from figure_atlas import make_atlas
from figure_mesh import Library

def main():
    dest=Path(__file__).resolve().parents[2]/"assets/river_gate/figures"
    dest.mkdir(parents=True,exist_ok=True)
    library=Library()
    for detailed,suffix in ((True,"Close"),(False,"Line")):
        for look in ("levy","archer","guard","officer","player"):
            library.insert(look.capitalize()+suffix,costume(look,detailed))
        for kit in range(9):
            library.insert("Arms"+str(kit)+suffix,weapon(kit,detailed))
    library.save(dest/"river_company.glb")
    make_atlas(dest)
    bake_motion(dest)
    for p in sorted(dest.iterdir()):
        if not p.name.endswith(".import"):
            print(p.name,p.stat().st_size)

if __name__=="__main__":
    main()
