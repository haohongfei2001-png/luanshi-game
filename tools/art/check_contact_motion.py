"""Measure the shipped finite block/hit keys, including the supporting sole and sockets."""
from math import dist
from pathlib import Path
import json
from PIL import Image
from check_company_motion import decoded
from company_motion import (CARRY_CLIPS,CARRY_KITS,CLIPS,FRAMES,REACTIONS,arm_nodes,
                            leg_nodes,trans,LB,RB,LF,LH,RF,RH,CHEST)

bank=Image.open(Path(__file__).resolve().parents[2]/"assets/river_gate/figures/company_motion.png").convert("RGBA")
start=9*CLIPS+len(CARRY_KITS)*2*len(CARRY_CLIPS)
wrist=0.
planted=0.
minimum_catch=1.
minimum_recoil=1.
for kit in range(9):
    for index,(clip,side) in enumerate(REACTIONS):
        lane=start+kit*len(REACTIONS)+index
        def at(bone,point,frame):
            return trans(decoded(bank,bone,0,lane,frame),point)
        stationary=RB if side>0 else LB
        other=LB if side>0 else RB
        support=leg_nodes(side)[2]
        foot=leg_nodes(-side)[2]
        chest=(0.,1.39,.12)
        travel=0.
        chest_travel=0.
        for frame in range(FRAMES):
            planted=max(planted,dist(at(stationary,support,0),at(stationary,support,frame)))
            travel=max(travel,dist(at(other,foot,0),at(other,foot,frame)))
            chest_travel=max(chest_travel,dist(at(CHEST,chest,0),at(CHEST,chest,frame)))
            for sign,fore,hand in ((-1,LF,LH),(1,RF,RH)):
                socket=arm_nodes(sign)[2]
                wrist=max(wrist,dist(at(fore,socket,frame),at(hand,socket,frame)))
        minimum_catch=min(minimum_catch,travel)
        minimum_recoil=min(minimum_recoil,chest_travel)
        assert dist(at(other,foot,0),at(other,foot,FRAMES-1))<.0003
print("CONTACT_KEYS",json.dumps(dict(strips=9*len(REACTIONS),wrist_m=wrist,
      planted_m=planted,minimum_step_m=minimum_catch,minimum_body_response_m=minimum_recoil)))
assert planted<.0003 and wrist<.0022 and minimum_catch>.10 and minimum_recoil>.095
