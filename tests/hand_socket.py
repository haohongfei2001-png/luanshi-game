from pathlib import Path
import json, sys
sys.path.insert(0,"tools/art")
from hand_grips import library
import company_motion
from figure_mesh import add
from math import hypot,dist
meshes=library()
for name,(points,faces) in meshes.items():
    assert all(abs(c)<.17 for p in points for c in p),name
    assert min(p[0] for p in points)<0<max(p[0] for p in points)
    if name.startswith("Haft"): radius=lambda p:hypot(p[0],p[1])
    elif name.startswith("BowPalm"): radius=lambda p:hypot(p[0],p[2])
    else: radius=lambda p:hypot(p[0]-.009,p[1])
    seat=.033 if not name.startswith('Nock') else .009
    contact=[p for p in points if abs(radius(p)-seat)<.008 and abs(p[2] if not name.startswith("BowPalm") else p[1])<.075]
    print('HM08_SOCKET',name,len(faces),'hand surface near weapon',len(contact),'deepest surface',round(min(radius(p) for p in points),4),'extent',[(round(min(p[i] for p in points),4),round(max(p[i] for p in points),4)) for i in range(3)])
    assert contact,name
for key in ("Haft","BowPalm","Nock"):
    assert len(meshes[key+'Rank'][1])<len(meshes[key+'Line'][1])<len(meshes[key+'Close'][1])
