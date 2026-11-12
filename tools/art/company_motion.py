"""Bake authored poses and analytic two-link limbs into an instanced GPU palette.

Both hand sockets and the bow nock live in the clip, so rotating a long shaft moves its
support hand. No per-soldier Godot Skeleton3D or runtime inverse kinematics is required.
"""
from math import sin,cos,pi,acos,sqrt
from PIL import Image
from figure_mesh import add,sub,mul,dot,cross,unit,lerp,smooth
from company_figures import *
from company_weapons import TWO_HAND, FRONT_GRIP

BONES=16
FRAMES=32
CLIPS=16
IDENT=(0.,0.,0.,1.)
def qm(q,r):
    a,b=q[:3],r[:3]
    return (*add(add(mul(b,q[3]),mul(a,r[3])),cross(a,b)), q[3]*r[3]-dot(a,b))
def rot(q,v):
    t=mul(cross(q[:3],v),2.)
    return add(v,add(mul(t,q[3]),cross(q[:3],t)))
def aa(axis,angle):
    return (*mul(axis,sin(angle*.5)),cos(angle*.5))
def euler(pitch,yaw,roll=0):
    k=pi/180
    return qm(aa((0,1,0),yaw*k),qm(aa((1,0,0),pitch*k),aa((0,0,1),roll*k)))
def towards(v,w):
    a,b=unit(v),unit(w)
    if dot(a,b)<-.999: return aa(unit(cross(a,(1,0,0) if abs(a[0])<.9 else (0,0,1))),pi)
    return unit((*cross(a,b),1+dot(a,b)))
def placed(rest,target,q):
    return q,sub(target,rot(q,rest))
def trans(m,p): return add(rot(m[0],p),m[1])
def chain(m,n): return qm(m[0],n[0]),add(rot(m[0],n[1]),m[1])
def two_link(binds,root,end,pole):
    a,b,c=binds
    upper,lower=sqrt(dot(sub(b,a),sub(b,a))),sqrt(dot(sub(c,b),sub(c,b)))
    line=sub(end,root); length=max(.004,sqrt(dot(line,line))); fwd=mul(line,1/length)
    normal=unit(sub(pole,mul(fwd,dot(pole,fwd))))
    dist=max(.005,min(upper+lower-.001,length))
    reach=(upper*upper-lower*lower+dist*dist)/(2*dist)
    hinge=add(root,add(mul(fwd,reach),mul(normal,sqrt(max(0,upper*upper-reach*reach)))))
    return placed(a,root,towards(sub(b,a),sub(hinge,root))),placed(b,hinge,towards(sub(c,b),sub(end,hinge)))

# Grip and blade orientation at chamber, impact (on release), and guard.
# Values are measured around the torso, in metres and degrees, not percentage
# damage/reach. A sweep, short thrust, shield shove and bow draw use different arcs.
READY=(.205,1.102,.212,-16,-14,0)
CHAMBER=[(.31,1.34,.054,-48,72,-22),(.31,1.40,.025,-76,41,-20),(.255,1.208,-.147,-11,65,-9),
         (.202,1.10,-.168,-4,-19,5),(.27,1.385,-.149,-58,40,-22),(.15,1.401,.39,0,-10,-9),
         (.093,1.29,.151,0,-3,0),(.251,1.17,-.067,-12,-20,-15),(.30,1.29,.055,-40,67,-16)]
CONTACT=[(-.105,1.106,.385,14,-49,12),(-.029,1.012,.424,30,-32,17),(-.117,1.097,.084,9,-56,9),
         (.066,1.23,.26,-3,-6,1),(-.093,1.068,.194,24,-40,13),(.143,1.402,.442,0,0,-9),
         (.111,1.298,.205,-3,0,0),(.115,1.167,.435,-1,-8,0),(-.084,1.078,.402,11,-51,-3)]
def mix(a,b,t): return tuple(x+(y-x)*t for x,y in zip(a,b))
def pose(kit,clip,t):
    # 0 locomotion, 1 idle, 2..5 windup, 6..9 recovery, 10 guard,
    # 11 hit, 12 rout, 13 wounded, 14 falling, 15 mounted legs.
    swing=sin(t*2*pi)
    move=clip in (0,12)
    slot=(clip-2)%4
    attack=2<=clip<=9
    walk=swing if move else 0.
    ride=clip==15
    crouch=0.; lean=0.; turn=0.; shift=0.; pull=.03
    rest=READY
    if kit in TWO_HAND: rest=(.16,1.075,-.04,-10,-17,0)
    if kit==5: rest=(.177,1.19,.264,-8,-14,-18)
    if kit==6: rest=(.143,1.155,.093,-3,-8,0)
    hand=rest
    if clip==1 or move or ride:
        hand=tuple(rest[i]+(walk*.064 if i==2 and kit not in TWO_HAND else 0) for i in range(6))
        turn=walk*(4 if kit in TWO_HAND else 7);lean=6 if clip==12 else 2
        crouch=.027*abs(walk)
    if attack:
        chamber,contact=CHAMBER[kit],CONTACT[kit]
        if slot==2 and kit==0: chamber,contact=CHAMBER[3],(.10,1.21,.45,-5,-4,5)
        if slot==1 and kit in (0,1,4): chamber=mix(chamber,(.31,1.26,-.07,-12,96,-16),.74);contact=mix(contact,(-.14,1.23,.32,2,-78,4),.76)
        if slot in (1,2) and kit==2: chamber,contact=CHAMBER[3],(.035,1.18,.21,-5,-8,0)
        if slot==3:
            chamber=rest
            contact=(.138,1.36,.253,-59,-38,-13) if kit not in TWO_HAND else (.107,1.244,.029,-29,-28,6)
        if clip<=5:
            if t<=.72: hand=mix(rest,chamber,smooth(t/.72))
            else: hand=mix(chamber,contact,smooth((t-.72)/.28))
            force=smooth(t/.72) if t<=.72 else 1-1.74*smooth((t-.72)/.28)
        else:
            amount=smooth(t)
            hand=mix(contact,rest,amount)
            force=-.74*(1-amount)
            if (kit==8 and slot in (0,1)) or (kit==3 and slot==1):
                counter=mix(contact,chamber,.83)
                if t<.28: hand=mix(contact,counter,smooth(t/.28))
                elif t<.45: hand=mix(counter,contact,smooth((t-.28)/.17))
                else: hand=mix(contact,rest,smooth((t-.45)/.55))
        turn=force*(20 if kit not in (5,6) else 6)
        lean=4-force*8;shift=-force*.054;crouch=.026+.028*abs(force)
        if slot==3 and kit in (1,5,8): crouch+=.13*(1-abs(t-.55));shift-=.075
        if kit==5: pull=(.15+.37*smooth(min(1,t/.88))) if clip<=5 else (.15+.14*sin(t*pi))
    if clip in (10,13):
        hand=(.122,1.326,.245,-60,-32,8) if kit not in TWO_HAND else (.104,1.232,.013,-31,-23,6)
        lean=9;crouch=.092 if clip==10 else .212
    if clip==11: lean=-18*(1-t);turn=-14*(1-t);crouch=.07*(1-t)
    if clip==14: crouch=.13*smooth(t)
    waist=(0,.86,0)
    pelvic=placed(waist,(0,.86-crouch,shift),euler(lean*.34,turn*.33,walk*1.6))
    chest=placed((0,1.008,0),trans(pelvic,(0,1.008,0)),euler(lean,turn,walk*2))
    head_m=placed((0,1.427,.015),trans(chest,(0,1.427,.015)),euler(lean*.49,turn*.42,walk*1.1))
    ms=[(IDENT,(0.,0.,0.)) for _ in range(BONES)]
    ms[HIPS]=pelvic;ms[CHEST]=chest;ms[HEAD]=head_m
    # Hands meet a common weapon frame. Limb planes sit outward to keep elbows apart.
    anchor=add(hand[:3],(0,-crouch,shift))
    aim=euler(*hand[3:])
    offq=aim
    if kit in TWO_HAND:
        off=add(anchor,rot(aim,(0,0,FRONT_GRIP[kit])))
    elif kit==5:
        off=add(anchor,rot(aim,(0,0,-pull)))
    elif kit==7:
        shield=1 if clip==10 else (.85 if attack and slot in (1,3) else .32)
        off=(-.215,1.105+.18*shield-crouch,.256+shield*.113+shift)
        offq=euler(-8-shield*7,-9,-shield*14)
    elif kit==8:
        off=(-hand[0],1.14+(1.24-hand[1])*.7-crouch,.225-(hand[2]-.21)*.52+shift)
        offq=euler(-11-hand[3]*.49,-hand[4]*.81,8)
    else:
        off=(-.263,1.023+.072*walk-crouch,.153-.127*walk+shift)
        offq=euler(-19,-19,-24)
    if ride:
        # Reins hang into the off hand above the saddle. The two-handed support
        # socket returns to the weapon on its actual windup/release clip.
        off=(-.167,.845,.233)
        offq=euler(-24,-9,-18)
    if kit==6 and 6<=clip<=9:
        load=sin(pi*t)**2
        off=lerp(off,add(anchor,rot(aim,(0,.073,-.066))),load)
    for side,end,q in ((-1,off,offq),(1,anchor,aim)):
        upper,fore,hn=(LU,LF,LH) if side<0 else (RU,RF,RH)
        binds=arm_nodes(side)
        hand_m=placed(grip(side),end,q)
        wrist=trans(hand_m,binds[2])
        ms[upper],ms[fore]=two_link(binds,trans(chest,binds[0]),wrist,(side*.65,-.52,-.83))
        ms[hn]=hand_m
    ms[NOCK]=placed(add(grip(1),(0,0,-.159)),off,aim)
    for side in (-1,1):
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        binds=leg_nodes(side)
        foot=(side*(.155 if attack else .14),.123+max(0,side*cos(t*2*pi))**2*.105*(1 if move else 0),
              -.014+side*(.22*walk if move else .091 if attack else .022))
        if ride: foot=(side*.287,.276,.058)
        ms[thigh],ms[shin]=two_link(binds,trans(pelvic,binds[0]),foot,(side*(1.1 if ride else .16),-.08,1))
        ms[boot]=placed(binds[2],foot,euler(-walk*12*side if move else -8 if ride else 0,side*5))
    if clip==14:
        k=smooth(min(1.,t/.91))
        fall=placed((0,.10,0),(0,.10,0),euler(-82*k,14*k,12*k))
        ms=[chain(fall,m) for m in ms]
    return ms

def bake_motion(out):
    tex=Image.new("RGBA",(8*BONES*3,9*CLIPS*4))
    px=tex.load()
    for kit in range(9):
        for clip in range(CLIPS):
            for frame in range(FRAMES):
                t=frame/(FRAMES if clip in (0,1,12,15) else FRAMES-1)
                for b,(q,offset) in enumerate(pose(kit,clip,t)):
                    x=frame%8*BONES*3+b*3; y=(kit*CLIPS+clip)*4+frame//8
                    px[x,y]=tuple(max(0,min(255,round((n*.5+.5)*255))) for n in q)
                    v=[max(0,min(65535,round((n/6+.5)*65535))) for n in offset]
                    px[x+1,y]=(*(n//256 for n in v),255)
                    px[x+2,y]=(*(n%256 for n in v),255)
    tex.save(out/"company_motion.png",optimize=True)
