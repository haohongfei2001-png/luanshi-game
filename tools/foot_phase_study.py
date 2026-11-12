from math import cos,dist,pi,sin
from pathlib import Path
import sys
from PIL import Image
sys.path.insert(0,"tools/art")
from check_company_motion import decoded
from company_motion import FRAMES, LB, leg_nodes, trans
from figure_mesh import add
bank=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
legacy=bank.width==384
paths=[]
for i in range(16):
    running=i>=8
    clip=23+i%8 if running else (0 if i==0 else 15+i)
    heading=i%8*pi/4
    stance=.355 if running else .51
    metres=1/(.42 if running else .68)
    planted=[]
    for subkey in range(FRAMES*16):
        phase=subkey/(FRAMES*16)
        if not .25*stance<=phase<=.70*stance: continue
        address=min(31,int(phase*31+.5)) if legacy else phase*32
        foot=trans(decoded(bank,LB,3,clip,address),leg_nodes(-1)[2])
        planted.append(add(foot,(sin(heading)*phase*metres,0.,cos(heading)*phase*metres)))
    paths.append(max(dist(a,b) for a in planted for b in planted))
print("SUBFRAME_FOOT_RANGE_METRES", "nearest" if legacy else "filtered", round(max(paths),6), [round(n,5) for n in paths])
