"""Sample the actual field shield, its inner grip, head and shared bank rows."""
import json
import sys
from math import acos, degrees, dist, sqrt
from PIL import Image
from check_company_motion import decoded
from company_motion import (CLIPS,CARRY_CLIPS,CARRY_KITS,FRAMES,REACTIONS,arm_nodes,
                            leg_nodes,trans,grip,HEAD,CHEST,HIPS,LF,LH,RF,RH,LB,RB)
from company_weapons import field_shield
from figure_mesh import Surface,sub,dot
before,after=[Image.open(f).convert("RGBA") for f in sys.argv[1:3]]
start=9*CLIPS+len(CARRY_KITS)*2*len(CARRY_CLIPS)
lanes=(7*CLIPS+10,start+7*len(REACTIONS),start+7*len(REACTIONS)+1)
changed=[i for i in range(before.height//4) if before.crop((0,4*i,before.width,4*i+4)).tobytes()!=after.crop((0,4*i,before.width,4*i+4)).tobytes()]
assert sorted(changed)==sorted(lanes)
surface=Surface();field_shield(surface,True)
# All 7 levels, 9 cross-section samples on the shields actual front face.
planks=surface.positions[:7*9]
rim=planks[-9:]
chest_samples=[(x,y,z) for x in (-.12,0.,.12) for y in (1.145,1.264,1.36) for z in (.029,.095)]
head_samples=[(x,y,z) for x in (-.058,0.,.058) for y in (1.482,1.540,1.608) for z in (.041,.091)]
centre=planks[4+9*3]
side_rails=[planks[3*9+i] for i in (0,8)]
def norm(p): return sqrt(dot(p,p))
def audit(bank,lane):
    moments=[];gaps=[];support=[];saved=[]
    for frame in range(FRAMES):
        def at(b,p): return trans(decoded(bank,b,0,lane,frame),p)
        shield=lambda p:at(LH,p)
        face=[shield(p) for p in planks]
        reach=[shield(p) for p in rim]
        face_points=[at(HEAD,p) for p in head_samples]
        chest_points=[at(CHEST,p) for p in chest_samples]
        hp=at(HEAD,(0.,1.548,.087));cp=at(CHEST,(0.,1.265,.095))
        c=shield(centre)
        left,right=[shield(p) for p in side_rails]
        board_to_cheek=min(dist(p,v) for p in reach for v in face_points)
        board_to_chest=min(dist(p,v) for p in face for v in chest_points)
        hand=shield(grip(-1))
        for side,fore,palm in ((-1,LF,LH),(1,RF,RH)):
            joint=arm_nodes(side)[2]
            gaps.append(dist(at(fore,joint),at(palm,joint)))
        if lane!=lanes[0]:
            side=-1 if lane==lanes[1] else 1
            foot=leg_nodes(side)[2]
            support.append(at(LB if side==-1 else RB,foot))
        middle_front=min(face,key=lambda p:dist(p,cp))
        moments.append({"key":frame,"rim_cheek_m":board_to_cheek,"plank_chest_m":board_to_chest,
                        "board_y":c[1],"board_z":c[2],"head_z":hp[2],"belt_z":at(HIPS,(0,.86,0))[2],
                        "sternum_x":cp[0],"elbow_y":at(LF,arm_nodes(-1)[1])[1],"left_palm":hand,
                        "shaft_clearance_x_m":max(p[0] for p in face)-cp[0],
                        "front_at_nearest_chest":middle_front[2]-cp[2],"head_top":hp[1]})
        saved.append([c[0],c[1],c[2]])
    a=moments
    return {"min_rim_cheek_samples_m":min(v["rim_cheek_m"] for v in a),
            "min_plank_chest_samples_m":min(v["plank_chest_m"] for v in a),
            "max_wrist_m":max(gaps),"support_drift_m":max((dist(support[0],v) for v in support),default=0.),
            "shield_depth_range_m":max(v["board_z"] for v in a)-min(v["board_z"] for v in a),
            "forward_return_m":max(v["board_z"] for v in a[16:])-min(v["board_z"] for v in a[:17]),
            "stance_width":dist(saved[0],saved[-1]),
            "moments":[a[i] for i in (0,6,14,21,26,31)]}
out={name:{"before":audit(before,lane),"after":audit(after,lane)} for name,lane in zip(("guard","left","right"),lanes)}
print(json.dumps({"clean_bank_rows":before.height//4-len(changed),"changed":changed,"checks":out},indent=2))
for s in ("left","right"):
    assert out[s]["after"]["support_drift_m"]<.0003
    assert out[s]["after"]["max_wrist_m"]<.0022
