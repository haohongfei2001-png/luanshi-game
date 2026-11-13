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
CLIPS=31
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
def limit_grip(p,center,radius):
    d=sub(p,center); span=sqrt(dot(d,d))
    return add(center,mul(d,radius/span)) if span>radius else p

def reachable(chest,side,rotation):
    a,b,c=arm_nodes(side)
    reach=sqrt(dot(sub(a,b),sub(a,b)))+sqrt(dot(sub(b,c),sub(b,c)))-.003
    # This is a sphere for the palm/socket, with the actual wrist offset removed.
    return sub(trans(chest,a),rot(rotation,sub(c,grip(side)))),reach

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
CHAMBER=[(.31,1.34,.054,-48,72,-22),(.31,1.40,.025,-76,41,-20),(.255,1.208,-.147,-11,65,-9),
         (.202,1.10,-.168,-4,-19,5),(.27,1.385,-.149,-58,40,-22),(.15,1.401,.39,0,-10,-9),
         (.093,1.29,.151,0,-3,0),(.251,1.17,-.067,-12,-20,-15),(.30,1.29,.055,-40,67,-16)]
CONTACT=[(-.105,1.106,.385,14,-49,12),(-.029,1.012,.424,30,-32,17),(-.117,1.097,.084,9,-56,9),
         (.066,1.23,.26,-3,-6,1),(-.093,1.068,.194,24,-40,13),(.143,1.402,.442,0,0,-9),
         (.111,1.298,.205,-3,0,0),(.115,1.167,.435,-1,-8,0),(-.084,1.078,.402,11,-51,-3)]
def mix(a,b,t): return tuple(x+(y-x)*t for x,y in zip(a,b))
def walking_foot(phase,running=False):
    # A complete cycle advances 1 / .68 metres in Battle._step. While a foot
    # bears weight its local Z recedes at exactly that rate, keeping it on the soil.
    stance=.355 if running else .51
    travel=1/(.42 if running else .68)
    half=stance*travel*.5
    if phase<stance:
        u=phase/stance
        pitch=-9*(1-smooth(min(1,u/.25)))+20*smooth(max(0,(u-.71)/.29))
        return half-phase*travel,0.,pitch
    u=(phase-stance)/(1-stance)
    arc=sin(pi*u)
    z=-half+2*half*smooth(u)-(1-stance)*travel*u*(1-u)*(1-2*u)
    return z,(.225 if running else .13)*arc**1.5,20*(1-smooth(u))-9*smooth(u)-10*arc

CARRY_KITS=(3,4,7)
# Idle, eight walking headings, four windups and four recoveries. These
# additional strips follow the original bank: original hits, player and saves
# address precisely the same rows as before.
CARRY_CLIPS=(1,0,16,17,18,19,20,21,22,2,3,4,5,6,7,8,9)

def pose(kit,clip,t,loadout=0):
    # 0 locomotion, 1 idle, 2..5 windup, 6..9 recovery, 10 guard,
    # 11 hit, 12 rout, 13 wounded, 14 falling, 15 mounted legs.
    running=clip>=23
    heading=((clip-23 if running else clip-15)*pi/4) if clip>=16 else 0.
    if clip>=16: clip=0
    swing=sin(t*2*pi)
    move=clip in (0,12)
    slot=(clip-2)%4
    attack=2<=clip<=9
    walk=swing if move else 0.
    ride=clip==15
    crouch=0.; lean=0.; turn=0.; shift=0.; pull=.03
    # At rest a long arm rides diagonally with its point above its neighbours.
    # Its authored chamber and impact still level the shaft at the original hit time.
    rests=((.198,1.07,.17,-33,-22,-8),(.238,1.09,.12,-44,21,-13),
           (.120,1.02,-.048,-30,18,-9),(.143,1.110,-.115,-45,-19,8),
           (.167,1.059,-.072,-55,17,-8),(.164,1.075,.219,-5,-18,-32),
           (.126,1.118,.084,16,-7,-5),(.206,1.117,.154,-31,-14,7),
           (.212,1.098,.142,-32,23,-12))
    rest=rests[kit]
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
    if ride: lean=17;crouch=.103;shift=.034
    if clip==11: lean=-18*(1-t);turn=-14*(1-t);crouch=.07*(1-t)
    if clip==14: crouch=.13*smooth(t)
    # The supporting hip rises while the opposite shoulder advances. A stationary
    # soldier keeps both feet loaded and breathes on their own phase.
    breath=sin(t*2*pi)
    hip_yaw=turn*.38
    shoulder_yaw=turn
    hip_roll=0.
    chest_roll=0.
    sway=0.
    if move:
        hips=cos(t*2*pi)
        sway=(.022 if running else .044)*sin(t*2*pi)
        hip_yaw=7*hips
        shoulder_yaw=-8.5*hips
        hip_roll=4.0*walk
        chest_roll=-3.3*walk
        crouch=(.088+.050*cos(t*4*pi-.22)) if running else (.089+.026*cos(t*4*pi))
        lean=12*cos(heading) if running else (9 if clip==12 else 5.8*cos(heading))
        hand=tuple(v+(.032*hips if i==0 else .035*breath if i==1 else .034*hips if i==2 else
                      (5.2 if running else 3.7)*walk if i==3 else 2.4*hips if i==4 else 0) for i,v in enumerate(hand))
    elif clip==1:
        crouch=(.059 if kit in (2,3,4,7) else .034)+.007*breath
        lean=(6.1 if kit in (2,3,4,7) else 3.8)+1.1*breath
        hip_yaw=-5.5
        shoulder_yaw=8.0+2.6*breath
        sway=.012+.005*breath
        chest_roll=-2+.7*breath
        hand=tuple(v+(.012*breath if i==1 else -.016*cos(t*2*pi) if i==2 else 0) for i,v in enumerate(hand))
    elif attack:
        load=force
        ranged=kit in (5,6)
        sway=(.026 if ranged else .064)*load
        shift+=(-.032 if ranged else -.083)*load
        crouch+=.040+.034*max(0,load)
        hip_yaw=load*(8 if ranged else 21)-4
        shoulder_yaw=load*(13 if ranged else 34)+4
        hip_roll=3.8*load
        chest_roll=-6.2*load
        lean+=3.8*(1-load)
        # In a polearm thrust the pelvis travels forward between two planted
        # feet. The spear and both wrists keep their shared reach solution.
        if kit==3 and slot<3:
            drive=(1.-load)/1.74
            crouch+=.026+.045*drive
            shift+=.078*drive-.012
            lean+=7.2*drive
            shoulder_yaw-=5.0*drive
        elif kit==7:
            crouch+=.035
            lean+=3.2
        elif kit==5:
            hip_yaw-=8.5
            shoulder_yaw-=11.5
    elif clip==10:
        sway=-.034
        hip_yaw=-12
        shoulder_yaw=14
        chest_roll=-5
    elif clip==11:
        sway=-.060*(1-t)
        hip_yaw=9*(1-t)
        shoulder_yaw=-24*(1-t)
        chest_roll=11*(1-t)
    elif clip==14:
        give=smooth(t)
        crouch=.05+.26*smooth(min(1,t/.64))
        sway=-.093*give
        shift=-.12*give
        hip_roll=12*give
        chest_roll=24*give
        shoulder_yaw=-25*give
    # Opening the torso places the drawing elbow to the side of the face.
    # Keep the head on its target while the bow shoulder reaches forward.
    bow_draw=0.
    if kit==5 and attack:
        released=smooth(max(0.,min(1.,(t-.92)/.08))) if clip<=5 else 1.
        bow_draw=smooth(min(1.,t/.72)) if clip<=5 else 1.-smooth(t)
        shoulder_yaw+=26.*bow_draw
        hip_yaw+=9.*bow_draw
    # Read the load of each kit before the motion is seen edge-on. March and
    # idle carry differ, while contact frames, metres and the hand/foot solve remain.
    if (move or clip==1) and not ride:
        if kit==3:
            shoulder_yaw-=10.; hip_yaw+=4.; chest_roll-=3.; lean+=3.; crouch+=.014
        elif kit==7:
            shoulder_yaw+=17.; hip_yaw+=5.; chest_roll-=4.; lean+=6.; crouch+=.043
        elif kit==5:
            shoulder_yaw+=14.; hip_yaw-=3.; chest_roll+=3.; lean-=4.
        elif kit==4:
            shoulder_yaw-=7.; lean+=2.; chest_roll+=4.
    # Two ways of carrying the same field equipment: a shaft seated high
    # beside the collar and a low forward carry; a shield carried across the
    # ribs or hanging at the outer hip. At release all converge on the existing
    # strike. Socket, elbow and planted foot are solved AFTER changing the load.
    carry=0.
    if loadout and kit in CARRY_KITS and not ride:
        if move or clip==1:
            carry=1.
        elif 2<=clip<=5:
            carry=1.-smooth(min(1.,t/.48))
        elif 6<=clip<=9:
            carry=smooth(max(0.,min(1.,(t-.55)/.45)))
    if carry:
        braced=loadout==2
        if kit in (3,4):
            offsets=(.027,-.078,.092,25.,14.,-9.) if braced else (.049,.105,-.054,-28.,-10.,9.)
            hand=tuple(v+carry*d for v,d in zip(hand,offsets))
        else:
            offsets=(.019,.041,.070,19.,-8.,7.) if braced else (.042,-.057,-.034,-16.,12.,-7.)
            hand=tuple(v+carry*d for v,d in zip(hand,offsets))
        shoulder_yaw+=carry*(11. if braced else -13.)
        hip_yaw+=carry*(5. if braced else -4.)
        chest_roll+=carry*(-4.0 if braced else 5.0)
        lean+=carry*(5.5 if braced else -3.)
        crouch+=carry*(.047 if braced else -.013)
        sway+=carry*(-.030 if braced else .036)
    waist=(0,.86,0)
    pelvic=placed(waist,(sway,.86-crouch,shift),euler(lean*.40,hip_yaw,hip_roll))
    chest=placed((0,1.008,0),trans(pelvic,(0,1.008,0)),euler(lean,shoulder_yaw,chest_roll))
    head_m=placed((0,1.427,.015),trans(chest,(0,1.427,.015)),euler(lean*.42,shoulder_yaw*.40,chest_roll*.28))
    ms=[(IDENT,(0.,0.,0.)) for _ in range(BONES)]
    ms[HIPS]=pelvic;ms[CHEST]=chest;ms[HEAD]=head_m
    # Hands meet a common weapon frame. Limb planes sit outward to keep elbows apart.
    anchor=add(hand[:3],(sway*.72,-crouch,shift))
    aim=euler(*hand[3:])
    offq=aim
    right,radius=reachable(chest,1,aim)
    anchor=limit_grip(anchor,right,radius)
    if kit in TWO_HAND:
        slide=0.
        if attack and slot<3 and kit in (2,3,4):
            slide=smooth(max(0,(t-.62)/.38)) if clip<=5 else 1-smooth(t)
        support=rot(aim,(0,0,FRONT_GRIP[kit]-(.18 if kit!=6 else 0)*slide))
        if not ride:
            # Intersect both wrist reach spheres. Sliding the support hand and
            # correcting the weapon as a rigid body keeps both grips on the shaft.
            left,left_radius=reachable(chest,-1,aim)
            support_center=sub(left,support)
            for _ in range(12):
                anchor=limit_grip(limit_grip(anchor,support_center,left_radius),right,radius)
        off=add(anchor,support)
    elif kit==5:
        # The bow stave is held in the right palm. In the moving/nocked carry
        # its canted upper limb passes outside the shoulder. The drawing hand
        # reaches the cheek, then clears the recoiling string after release.
        carry=add((.174,1.093,.234),(sway*.72,-crouch,shift))
        off=add(anchor,rot(aim,(0,0,-max(.18,pull))))
        if clip==1 or move or attack:
            elbow_height=(.015*walk if move else 0.)
            carry=add(carry,(.019*walk,elbow_height,.025*walk))
            anchor=lerp(carry,add((.136,1.420,.430),(sway*.72,-crouch,shift)),bow_draw)
            aim=euler(-13.+11.*bow_draw,-32.+24.*bow_draw,-60.+48.*bow_draw)
            offq=aim
            right,radius=reachable(chest,1,aim)
            anchor=limit_grip(anchor,right,radius)
            nocked=add(anchor,rot(aim,(0.,0.,-.258-.373*bow_draw)))
            if attack:
                # At release the left fingers travel back and out past the jaw.
                loose=add((-.190,1.425,-.128),(sway*.72,-crouch,shift))
                nocked=lerp(nocked,loose,released*bow_draw)
            if not attack:
                off=nocked
            else:
                carried_grip=add(anchor,rot(aim,(0.,0.,-.258)))
                off=lerp(carried_grip,nocked,bow_draw)
    elif kit==7:
        shield=1 if clip==10 else (.85 if attack and slot in (1,3) else .32)
        off=(-.215,1.105+.18*shield-crouch,.256+shield*.113+shift)
        # Let the soldier see over the upper rim during muster and the march.
        # He carries the board against the outside of the left forearm, then
        # brings it squarely forward for an actual block or the committed hit.
        carried=1.0 if move or clip==1 else 0.0
        if 2<=clip<=5: carried=1.-smooth(min(1.,t/.47))
        if 6<=clip<=9: carried=smooth(max(0.,(t-.53)/.47))
        off=add(off,mul((-.093,-.091,-.042),carried))
        if carry:
            off=add(off,mul((-.012,.052,.020) if loadout==2 else (-.033,-.058,-.018),carry))
        offq=euler(-8-shield*7+carried*7+carry*(-5. if loadout==2 else 7.),
                   -9.-carried*22.+carry*(9. if loadout==2 else -9.),-shield*14+carried*8.)
        if carried:
            anchor=limit_grip(add(anchor,mul((.066,.043,.029),carried)),right,radius)
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
    left,left_radius=reachable(chest,-1,offq)
    off=limit_grip(off,left,left_radius)
    for side,end,q in ((-1,off,offq),(1,anchor,aim)):
        upper,fore,hn=(LU,LF,LH) if side<0 else (RU,RF,RH)
        binds=arm_nodes(side)
        hand_m=placed(grip(side),end,q)
        wrist=trans(hand_m,binds[2])
        pole=(side*.65,-.52,-.83)
        if kit==5 and not ride:
            # The working elbow points outward as the fingers draw, while the
            # bow elbow remains outside the line of the string.
            pole=(side*.94,-.72+(.96*bow_draw if side<0 else .22*bow_draw),-.45)
        ms[upper],ms[fore]=two_link(binds,trans(chest,binds[0]),wrist,pole)
        ms[hn]=hand_m
    nock=add(anchor,rot(aim,(0,0,-.159))) if ride else off
    if kit==5 and attack:
        # The string returns to brace at release. A fresh nock is picked up as
        # the fingers come back to the carried bow at the end of recovery.
        freedom=released*(1.-smooth(max(0.,min(1.,(t-.56)/.44))) if clip>=6 else 1.)
        nock=lerp(off,add(anchor,rot(aim,(0,0,-.159))),freedom)
    ms[NOCK]=placed(add(grip(1),(0,0,-.159)),nock,aim)
    for side in (-1,1):
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        binds=leg_nodes(side)
        lead=-1 if kit in (2,3,4,5,6,7) else 1
        crouched=attack or clip in (10,11,13,14)
        # Long-weapon users stand across the line of attack. The shield
        # bearer stays shorter and heavier; an archer can open his shoulders.
        stance=(.290 if kit==3 else .226) if crouched and kit in (2,3,4,5,7) else (.167 if crouched else .092)
        if clip in (11,13,14): stance=.161
        if clip==1 and kit in (2,3,4,7): stance=.192 if kit==7 else .161
        if clip==1 and kit==5: stance=.151
        z=side*lead*stance
        pitch=0.
        lift=0.
        if move:
            z,lift,pitch=walking_foot((t+(.5 if side>0 else 0))%1.,running)
        if clip==14:
            z+=side*.17*smooth(t)
            lift=.12*smooth(t) if side==1 else 0.
            pitch=side*19*smooth(t)
        foot_q=euler(pitch*cos(heading),side*(5.5 if not crouched else 9.)+8*sin(heading),-pitch*sin(heading))
        # Roll about the heel or toe. Preserve the sole's actual contact height.
        lowest=min(rot(foot_q,(dx,-.117,dz))[1] for dx in (-.05,.05) for dz in (-.072,.187))
        foot=(side*(.179 if crouched else .143)+z*sin(heading),.006+lift-lowest,
              z*cos(heading)-.014-side*.129*sin(heading))
        if ride:
            foot=(side*.287,.276,.058)
            foot_q=euler(-8,side*5)
        ms[thigh],ms[shin]=two_link(binds,trans(pelvic,binds[0]),foot,(side*(1.1 if ride else .16),-.08,1))
        ms[boot]=placed(binds[2],foot,foot_q)
    if clip==14:
        k=smooth(max(0.,min(1.,(t-.14)/.80)))
        fall=placed((0,.10,0),(0,.10,0),euler(-76*k,18*k,29*k))
        ms=[chain(fall,m) for m in ms]
    return ms

def cycling(clip):
    return clip in (0,1,12,15) or clip>=16

def bake_motion(out):
    # Each bone gets a strip of adjacent keys. The four RGBA8 rows are affine
    # encodings, so GPU filtering can mix high/low bytes without a carry error.
    # The extra endpoint joins the first key of loops or holds the last action key.
    lanes=[(kit,clip,0) for kit in range(9) for clip in range(CLIPS)]
    lanes.extend((kit,clip,loadout) for kit in CARRY_KITS for loadout in (1,2) for clip in CARRY_CLIPS)
    tex=Image.new("RGBA",((FRAMES+1)*BONES,len(lanes)*4))
    px=tex.load()
    for lane,(kit,clip,loadout) in enumerate(lanes):
        previous=[None]*BONES
        y=lane*4
        for frame in range(FRAMES+1):
            t=(frame%FRAMES)/FRAMES if cycling(clip) else min(frame,FRAMES-1)/(FRAMES-1)
            for b,(q,offset) in enumerate(pose(kit,clip,t,loadout)):
                # q and -q describe the same rotation. Choose neighbours on
                # the same hemisphere before interpolation, including the wrap.
                if previous[b] and sum(a*c for a,c in zip(q,previous[b]))<0:
                    q=tuple(-v for v in q)
                previous[b]=q
                quat=[max(0,min(65535,round((n*.5+.5)*65535))) for n in q]
                xyz=[max(0,min(65535,round((n/6+.5)*65535))) for n in offset]
                x=b*(FRAMES+1)+frame
                px[x,y]=tuple(n//256 for n in quat)
                px[x,y+1]=tuple(n%256 for n in quat)
                px[x,y+2]=(*(n//256 for n in xyz),255)
                px[x,y+3]=(*(n%256 for n in xyz),255)
    tex.save(out/"company_motion.png",optimize=True)
