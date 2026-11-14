"""Bake authored poses and analytic two-link limbs into an instanced GPU palette.

Both hand sockets and the bow nock live in the clip, so rotating a long shaft moves its
support hand. No per-soldier Godot Skeleton3D or runtime inverse kinematics is required.
"""
from math import sin,cos,pi,acos,sqrt
from PIL import Image
from pathlib import Path
import json
from figure_mesh import add,sub,mul,dot,cross,unit,lerp,smooth
from company_figures import *
from company_weapons import TWO_HAND, FRONT_GRIP

BONES=16
FRAMES=32
CLIPS=31
MOUNTED_ATTACKS=((0,2),(0,6),(1,2),(1,6),(7,2),(7,6))
IDENT=(0.,0.,0.,1.)
MARCH_BANK=json.loads((Path(__file__).parent/'source'/'march_curves.json').read_text())['curves']
SWORD_SOURCE=json.loads((Path(__file__).parent/'source'/'combat_curves.json').read_text())['curves']['Sword_Attack']
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

# Four finite reaction strips per kit follow the original and carry banks.
# Negative/positive side is mesh-local X, measured at the actual contact.
REACTIONS=((10,-1),(10,1),(11,-1),(11,1))

def ramp(t,start,end):
    return smooth(max(0.,min(1.,(t-start)/(end-start))))

def blend_rigid(origin, target, amount):
    q,p=origin
    n,end=target
    if dot(q,n)<0.:
        n=tuple(-v for v in n)
    return unit(lerp(q,n,amount)),lerp(p,end,amount)


def grounded_rest(kit):
    """Rest on the back or rear shoulder with the heavy parts on the earth.

    Locations are body-joint pivots, never scaled. Forward +Z runs towards
    the boots once prone. The unchanged 2-bone solver maintains bone lengths.
    """
    side=-1 if kit in (1,3,6,8) else 1
    curl=kit in (2,4,7)
    root=(side*.033,.164,-.018)
    pelvis=placed((0,.86,0),root,euler(-82.,side*(6. if curl else 3.),side*4.))
    chest_root=trans(pelvis,(0,1.008,0))
    chest=placed((0,1.008,0),chest_root,euler(-91.,side*(14. if curl else 8.),side*5.))
    neck=trans(chest,(0,1.427,.015))
    head=placed((0,1.427,.015),neck,euler(-101.,side*23.,side*6.))
    ms=[(IDENT,(0.,0.,0.)) for _ in range(BONES)]
    ms[HIPS],ms[CHEST],ms[HEAD]=pelvis,chest,head
    for direction in (-1,1):
        thigh,shin,boot=(LT,LS,LB) if direction<0 else (RT,RS,RB)
        binds=leg_nodes(direction)
        hip=trans(pelvis,binds[0])
        bent=direction==side
        ankle=(direction*(.254 if bent else .168),.087 if bent else .080,
               .655 if bent and curl else .675 if bent else .710)
        # The bent knee falls out towards the soil. It does not hinge up in
        # the air as in the standing IK pose.
        ms[thigh],ms[shin]=two_link(binds,hip,ankle,(direction*.98,.12,-.10))
        ms[boot]=placed(binds[2],ankle,euler(-70. if bent else -78.,
                              direction*(31. if bent else 15.),direction*17.))
        upper,fore,hand=(LU,LF,LH) if direction<0 else (RU,RF,RH)
        arms=arm_nodes(direction)
        shoulder=trans(chest,arms[0])
        across = direction==-side and curl
        elbow=(direction*(.248 if across else .402),.121,
               -.267 if across else -.277)
        # A long blade/shaft runs along the hand's +Z axis. A falling palm
        # pitched eighty degrees left that axis vertical above a prone body.
        # Rest blades on their broad face, the bow in its stave plane and the
        # crossbow across its prod. The hand remains joined at the same wrist.
        hand_q=euler(0.,direction*20.,direction*90.)
        height=.070
        if direction==1 and kit==5:
            hand_q=euler(-90.,20.)
            height=.150
        elif direction==1 and kit==6:
            hand_q=euler(0.,20.)
            height=.120
        elif direction==-1 and kit==7:
            hand_q=euler(-90.,-20.)
            height=.035
        wrist=(direction*(.123 if across else .461),height,
               -.095 if across else -.068)
        pole=unit(sub(elbow,shoulder))
        ms[upper],ms[fore]=two_link(arms,shoulder,wrist,pole)
        ms[hand]=placed(arms[2],wrist,hand_q)
    ms[NOCK]=ms[RH]
    return ms


def procedural_pose(kit,clip,t,loadout=0,side_hit=0):
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
    if clip==11 and not side_hit: lean=-18*(1-t);turn=-14*(1-t);crouch=.07*(1-t)
    if clip==14: crouch=.13*smooth(t)
    # The supporting hip rises while the opposite shoulder advances. A stationary
    # soldier keeps both feet loaded and breathes on their own phase.
    breath=sin(t*2*pi)
    hip_yaw=turn*.38
    shoulder_yaw=turn
    hip_roll=0.
    chest_roll=0.
    sway=0.
    recoil=0.
    settle=0.
    thrust=kit==3 and attack and slot<3
    if move:
        hips=cos(t*2*pi)
        # Imported gait first, then the two-hand grips and ground-locked soles.
        # A rank bearing a shaft braces its shoulders more than a light footman.
        mode="Jog_Fwd_Loop" if running or clip==12 else ("Walk_Formal_Loop" if kit in (3,4,7) else "Walk_Loop")
        step=MARCH_BANK[mode][round(t*FRAMES)%FRAMES]
        sway,rise,hip_yaw,shoulder_yaw,hip_roll,chest_roll=step
        if mode=="Jog_Fwd_Loop":
            # The unarmed source twists 80 degrees and bobs 25 cm peak to peak.
            # Keep the planted phase and the asymmetric stride of the animator.
            # A braced shaft or a shield limits the movement at the shoulder.
            braced = kit in TWO_HAND or kit == 7
            rise *= .43 if braced else .52
            shoulder_yaw *= .36 if braced else .46
            chest_roll *= .48 if braced else .64
        lateral=abs(sin(heading))
        sway*=1.-.34*lateral
        hip_yaw*=1.-.42*lateral
        shoulder_yaw*=(.83 if kit in TWO_HAND else 1.)*(1.-.40*lateral)
        chest_roll*=.90
        crouch=(.088 if running else .084)-rise
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
            # The rear knee gathers ahead of the wrists. It extends through
            # release, then catches the belt after the shaft stops. The exact
            # hit and the first recovery key use the same pose and sockets.
            coil=sin(pi*min(t/.72,1.))**2 if clip<=5 else 0.
            follow=sin(pi*min(t/.68,1.))**2 if clip>=6 else 0.
            shift-=.094*coil
            sway+=.040*coil-.046*follow
            crouch+=.042*coil+.028*follow
            hip_yaw+=11.*coil-8.*follow
            shoulder_yaw-=13.*coil+8.*follow
            hand=tuple(v+(d*coil+e*follow) for v,d,e in zip(hand,
                       (.048,.050,-.060,-8.,5.,-8.),(-.030,-.041,.028,6.,-6.,2.)))
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
    if side_hit:
        # The board and shoulder compress first. Hips and the replant follow
        # later, while the eyes stay aimed over the guard.
        recoil=ramp(t,0.,.23)*(1.-ramp(t,.30,.90))
        settle=ramp(t,.13,.49)*(1.-ramp(t,.56,1.))
        if clip==10:
            lean=9.-15.*recoil+5.*settle
            sway=-.034-side_hit*(.052*recoil+.031*settle)
            hip_yaw=-12.+side_hit*12.*settle
            shoulder_yaw=14.+side_hit*24.*recoil
            chest_roll=-5.+side_hit*11.*recoil
            crouch=.092+.098*settle
            shift=-.097*settle
            hand=tuple(v+d*recoil for v,d in zip(hand,(-side_hit*.057,-.041,-.076,12.,side_hit*14.,4.)))
        else:
            sway=-side_hit*(.109*recoil+.046*settle)
            shift=-.135*settle
            lean=2.-24.*recoil+6.*settle
            hip_yaw=side_hit*14.*settle
            shoulder_yaw=side_hit*32.*recoil
            hip_roll=side_hit*9.*settle
            chest_roll=-side_hit*17.*recoil
            crouch=.040+.107*settle
            hand=tuple(v+d*recoil for v,d in zip(hand,(side_hit*.074,.102,-.095,-20.,side_hit*18.,9.)))
    # The timber shield is carried in the left palm. At rest set it across the
    # ribs, with the left boot in front. A real contact gives at the elbow,
    # passes through the shoulder and then loads the hip. At both endpoints
    # the two directional reactions meet the exact same waiting guard.
    board_give=0.
    board_drive=0.
    if kit==7 and clip==10:
        sway=-.060; shift=.034; crouch=.139
        lean=14.; hip_yaw=-9.; shoulder_yaw=-16.; hip_roll=1.4; chest_roll=-3.8
        hand=(.300,1.258,.192,-49.,-9.,11.)
        if side_hit:
            board_give=ramp(t,0.,.19)*(1.-ramp(t,.34,.79))
            board_drive=ramp(t,.38,.66)*(1.-ramp(t,.70,1.))
            sway-=side_hit*(.044*board_give+.039*settle)
            shift-=.083*settle
            crouch+=.090*settle
            lean-=15.*board_give-6.2*board_drive
            hip_yaw+=side_hit*9.8*settle
            shoulder_yaw+=side_hit*17.5*board_give
            hip_roll-=side_hit*4.4*settle
            chest_roll-=side_hit*8.*board_give
            hand=tuple(v+d*board_give for v,d in zip(hand,
                       (.035,-.020,-.080,9.,side_hit*10.,5.)))
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
    # The old alternate carries changed the poles' starting angles, then all
    # carriers traced almost the same path. Resolve the load against a real
    # support step. A forward levelled shaft is steadied on the leading arm;
    # a shouldered one tips back as the free elbow passes the ribcage.
    load_beat=0.
    if loadout and kit in (3,7) and (move or clip==1):
        load_beat=-.42*cos(2*pi*t-.10) if move else .16*sin(2*pi*t-.32)
        counter=.55*sin(2*pi*t) if move else .21*sin(2*pi*t-.85)
        if kit==3:
            high=loadout==1
            bias=.075 if high else -.057
            shoulder_yaw+=(12. if high else -6.)*load_beat
            chest_roll+=(-6. if high else 4.)*load_beat
            sway+=bias*(.63 if move else .80)*load_beat
            offsets=(.023,.065,-.086,19.,-12.,6.) if high else (-.045,-.037,.093,-10.,9.,-4.)
        else:
            high=loadout==2
            shoulder_yaw+=(-13. if high else 9.)*load_beat
            chest_roll+=(6.8 if high else -4.)*load_beat
            sway+=(-.054 if high else .044)*load_beat
            offsets=(.016,-.034,-.055,-4.,8.,4.) if high else (.049,.055,.063,13.,-11.,-5.)
        lean+=(3.0 if high else -2.2)*counter
        shift+=(.048 if high else -.037)*counter
        crouch+=.012*(1.-load_beat)
        hand=tuple(v+d*load_beat for v,d in zip(hand,offsets))
    # The source formal march was taken from an upright parade. Its feet
    # have useful contact timing; its level shoulders and pelvis turn in the
    # same direction. Let the loaded hip lead, and let the chest overtake it
    # over the opposite planted leg. Feet are solved against the ground below.
    pelvic_pitch=lean*.40
    if clip==0:
        a=2.*pi*t
        support=sin(a)                 # left support in the first half
        strike=cos(a-.10)              # left heel arrives, right shoulder leads
        absorb=cos(2.*a-.55)           # compress just after each foot arrives
        forward=cos(heading)
        across=sin(heading)
        front=.48+.52*abs(forward)
        heavy=kit in (4,7)
        bow=kit in (5,6)
        root_turn=6.5 if running else 7.2
        upper_turn=(4.0 if heavy else 4.2 if bow else 6.4) * (.72 if running else 1.)
        # Swing the girdle into the leading thigh while seating the belt on the
        # current support. Reverse and oblique steps keep their true footpath.
        hip_yaw+=(root_turn*strike*forward)
        hip_roll-=(4.3 if running else 5.)*support*front
        sway-=(.041 if heavy else .034)*support*front
        shift+=(.030 if running else .024)*(.24+.76*abs(forward))*sin(2.*a-.36)*forward
        crouch+=(.016 if running else .009)*absorb+(.019 if heavy else .006)
        pelvic_pitch+=(4.5 if running else 3.3)*absorb*forward
        # The shoulders turn about a different centre than the belt. A shield
        # keeps the loaded left side forward; an archer controls the bow with
        # a quieter outside shoulder. Let the free side complete the stride.
        shoulder_yaw-=upper_turn*(cos(a+.19)*forward+.32*support*across)
        chest_roll+=((1.2 if heavy else 1.8) if running else (5.1 if heavy else 6.0))*sin(a-.26)*front
        lean+=(7.2 if running else 5.7)*cos(2.*a-.80)*forward
        lean+=(4.0 if heavy else 2.2 if kit==3 else 0.)*forward
        # This offset falls away on a backstep: a loaded forward advance
        # puts the sternum ahead of the pelvis, while the rear file can step
        # away without pitching its head across the rear heel.
        advancing=max(0.,forward)
        if kit==7:
            sway-=.041; shoulder_yaw+=10.; chest_roll-=7.
            lean+=7.*advancing; shift+=.045*advancing; crouch+=.034
        elif kit==3:
            shoulder_yaw-=9.; chest_roll+=2.3
            lean+=6.2*advancing; shift+=.040*advancing; crouch+=.024
        elif kit==4:
            shoulder_yaw-=5.; chest_roll+=3.6
            lean+=5.5*advancing; shift+=.030*advancing; crouch+=.020
        elif kit==6:
            shoulder_yaw-=15.; chest_roll+=3.6; crouch+=.033
            lean+=4.6*advancing; shift+=.030*advancing
        elif kit==5:
            sway+=.018; shoulder_yaw+=2.7; lean-=2.1*advancing
        else:
            lean+=4.6*advancing; shift+=.041*advancing; crouch+=.010
        if kit in (2,3,4,6):
            # Both palms still lie on the rigid weapon axis. The support
            # forearm rides the carried mass instead of following the sternum.
            reach=(.011,.022,-.029,-3.5,2.1,1.4) if heavy else (.020,.028,-.043,-5.8,3.2,2.4)
            hand=tuple(v+d*strike*front for v,d in zip(hand,reach))
        elif kit not in (5,7):
            hand=tuple(v+d*strike*front for v,d in zip(hand,(.013,.027,-.066,-7.,3.,4.)))
    elif clip==1:
        # Split stance when the file checks its advance. Put the belt over
        # the front or rear leg and keep the face looking down the weapon.
        # This is the existing idle row, including when a target checks a file.
        if kit in (2,3,4,6,7):
            forward_leg=kit in (3,6,7)
            sway+=-.046 if forward_leg else .037
            crouch+=.049 if kit==7 else .036
            shift+=.039 if forward_leg else -.023
            hip_yaw+=7. if kit in (3,4) else -7.
            shoulder_yaw+=-9.5 if kit in (3,6) else 8.5
            chest_roll+=-4.8 if forward_leg else 4.
            lean+=5.2 if forward_leg else 2.5
            pelvic_pitch+=2.
        elif kit==5:
            sway+=.034; hip_yaw-=8.; shoulder_yaw+=9.; chest_roll+=3.
        else:
            sway+=.023; hip_yaw+=5.; shoulder_yaw-=5.
    waist=(0,.86,0)
    pelvic=placed(waist,(sway,.86-crouch,shift),euler(pelvic_pitch,hip_yaw,hip_roll))
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
            pitch,yaw,roll=-13.+11.*bow_draw,-32.+24.*bow_draw,-60.+48.*bow_draw
            if move:
                # The old walking bow had exactly the same rotation in all 32
                # poses. Let the support arm absorb the alternating footfall,
                # while both hands and the nock travel as one loaded bow.
                stride=2.*pi*t
                support=cos(stride-.29)
                swing=sin(stride-.24)
                balance=(1.16 if running else 1.)*(1.-.30*abs(sin(heading)))
                pitch+=balance*(7.4*support+1.35*sin(2.*stride-.49))
                yaw+=balance*5.6*swing
                roll-=balance*(8.1*support+1.2*sin(2.*stride+.60))
                anchor=add(anchor,(.013*swing,.014*support,-.018*swing))
            aim=euler(pitch,yaw,roll)
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
            off=add(off,mul((.020,.091,.032) if loadout==2 else (-.033,-.058,-.018),carry))
        offq=euler(-8-shield*7+carried*7+carry*(-13. if loadout==2 else 9.),
                   -9.-carried*22.+carry*(24. if loadout==2 else -10.),-shield*14+carried*8.)
        if loadout and (move or clip==1):
            # The upper edge of a braced board rolls out of the helmet as the
            # loaded forearm takes the stride. A low side carry swings behind.
            braced=loadout==2
            off=add(off,mul((-.050,.083,.081) if braced else (.050,-.088,-.112),load_beat))
            offq=qm(euler((-12. if braced else 15.)*load_beat,
                          (11. if braced else -14.)*load_beat,
                          (8. if braced else -7.)*load_beat),offq)
        if clip==10:
            # The old top edge was tilted backwards into the head while the
            # board retreats. Carry the top slightly outward on impact and
            # keep its working face towards the side of actual contact.
            # The elbow yields behind the grip; the rear leg then helps push
            # the board back out. No shaft or shield corner moves on its own.
            off=(-.083+sway*.50,1.355-crouch,.344+shift)
            off=add(off,(side_hit*.055*board_give,.032*board_give-.026*settle,
                         -.083*board_give+.095*board_drive))
            offq=euler(4.+11.*board_give-5.*board_drive,
                       6.+side_hit*26.*board_give,-7.-side_hit*8.*board_give)
        if clip in (0,1):
            # Let the strapped board travel with the loaded shoulder. The
            # old low carry used the identical vertical board at both heel
            # strikes while the shield shoulder moved visibly around it.
            step=sin(2.*pi*t-.28)*front if clip==0 else .15*sin(2.*pi*t)
            heel=cos(2.*pi*t-.32)*front if clip==0 else .10*cos(2.*pi*t)
            off=add(off,(-.012-.027*step,.022-.032*step,.048+.049*heel))
            offq=qm(euler(-4.+5.4*heel,5.5-5.1*heel,2.2+4.*step),offq)
        if carried:
            # The sword rests outside the leading edge of the shield. Its weight
            # sits in a lowered elbow; both wrist and crossguard continue to be
            # solved at the same palm, and release keeps the authored contact.
            anchor=limit_grip(add(anchor,mul((.148,-.008,.206),carried)),right,radius)
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
        if loadout and kit in (3,7) and (move or clip==1):
            # The leading forearm seats the load; the trailing elbow has room
            # to open. The two-link solve below still terminates at the palm.
            lead=side<0
            open_arm=(loadout==1 and not lead) or (loadout==2 and lead)
            pole=(side*(.91 if open_arm else .49),
                  (-.22 if open_arm else -.69)+(.14 if lead else -.12)*load_beat,
                  -.64 if open_arm else -.95)
        if clip in (0,1) and kit in (3,4,6):
            # The front elbow supports a shaft from underneath, the other
            # hangs back beside the ribs. A crossbow tucks both closer to
            # the torso so the stock lies on the line of the shoulder.
            pulse=sin(2.*pi*t-.31) if clip==0 else .14*sin(2.*pi*t)
            if kit==6:
                pole=(side*(.43+.07*pulse),-.86+.08*pulse,-.58)
            elif side<0:
                pole=(-.51-.08*pulse,-.70+.12*pulse,-.75)
            else:
                pole=(.80+.12*pulse,-.43-.09*pulse,-.80)
        if kit==7 and clip==10:
            # A bent, strapped shield arm stays on the outer side of the
            # board. The weapon elbow folds by the ribs, clear of the face.
            if side<0:
                pole=(-.91,-.34-.35*board_give,-.74+.22*board_drive)
            else:
                pole=(.83,-.54+.12*settle,-.78)
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
        lateral=0.
        if thrust and side!=lead:
            push=ramp(t,.73,1.) if clip<=5 else 1.-ramp(t,0.,.55)
            pitch+=23.*push
        if side_hit and side==-side_hit:
            # One sole stays down while the catching boot shifts support.
            # Two small swing arcs let the moving foot replant and recover.
            landing=ramp(t,.14,.56)*(1.-ramp(t,.71,1.))
            swing_out=sin(pi*max(0.,min(1.,(t-.14)/.42)))**2
            swing_home=sin(pi*max(0.,min(1.,(t-.71)/.29)))**2
            lateral=side*(.052 if clip==10 else .101)*landing
            z-=(.115 if clip==10 else .204)*landing
            lift=(.049 if clip==10 else .076)*swing_out+.034*swing_home
            pitch+=11.*swing_out-7.*swing_home
        if clip==14:
            z+=side*.17*smooth(t)
            lift=.12*smooth(t) if side==1 else 0.
            pitch=side*19*smooth(t)
        foot_q=euler(pitch*cos(heading),side*(5.5 if not crouched else 9.)+8*sin(heading),-pitch*sin(heading))
        # Roll about the heel or toe. Preserve the sole's actual contact height.
        lowest=min(rot(foot_q,(dx,-.117,dz))[1] for dx in (-.05,.05) for dz in (-.072,.187))
        foot=(side*(.179 if crouched else .143)+lateral+z*sin(heading),.006+lift-lowest,
              z*cos(heading)-.014-side*.129*sin(heading))
        if ride:
            foot=(side*.287,.276,.058)
            foot_q=euler(-8,side*5)
        ms[thigh],ms[shin]=two_link(binds,trans(pelvic,binds[0]),foot,(side*(1.1 if ride else .16),-.08,1))
        ms[boot]=placed(binds[2],foot,foot_q)
    if clip==14:
        k=ramp(t,.14,.75)
        fall=placed((0,.10,0),(0,.10,0),euler(-76*k,18*k,29*k))
        ms=[chain(fall,m) for m in ms]
        if t>.28:
            # When the pelvis reaches the floor, the inert body uncoils off
            # the kneeling pose. Give the final ankles, torso and head their
            # own support heights; turning a crouched upright rig around its
            # feet left both boot shafts pointing into the air indefinitely.
            weight=ramp(t,.28,.97)
            rest=grounded_rest(kit)
            ms=[blend_rigid(from_pose,to_pose,weight) for from_pose,to_pose in zip(ms,rest)]
            # Keep each joint shared in the transitional frames. Blending
            # translations around the world origin makes the forearm pull
            # away from the palm when its quaternion turns ninety degrees.
            # Rebuild the chain about the existing bind points instead.
            ms[CHEST]=placed((0,1.008,0),trans(ms[HIPS],(0,1.008,0)),ms[CHEST][0])
            ms[HEAD]=placed((0,1.427,.015),trans(ms[CHEST],(0,1.427,.015)),ms[HEAD][0])
            for direction in (-1,1):
                upper,fore,hand=(LU,LF,LH) if direction<0 else (RU,RF,RH)
                thigh,shin,boot=(LT,LS,LB) if direction<0 else (RT,RS,RB)
                for parent,chain_ids,pivots in ((CHEST,(upper,fore,hand),arm_nodes(direction)),
                                                 (HIPS,(thigh,shin,boot),leg_nodes(direction))):
                    for child,pivot in zip(chain_ids,pivots):
                        ms[child]=placed(pivot,trans(ms[parent],pivot),ms[child][0])
                        parent=child
            if kit==5:
                ms[NOCK]=ms[RH]
    return ms


def source_sword(phase):
    frames=SWORD_SOURCE["frames"]
    location=max(0.,min(1.,phase))*(len(frames)-1)
    index=min(int(location),len(frames)-2)
    amount=location-index
    first,last=frames[index],frames[index+1]
    positions={name:lerp(value,last["p"][name],amount) for name,value in first["p"].items()}
    rotations={name:blend_rigid((value,(0.,0.,0.)),(last["q"][name],(0.,0.,0.)),amount)[0]
               for name,value in first["q"].items()}
    return positions,rotations

def inverse_rotation(q):
    return (-q[0],-q[1],-q[2],q[3])

def rotation_mix(a,b,amount):
    return blend_rigid((a,(0.,0.,0.)),(b,(0.,0.,0.)),amount)[0]

def pose(kit,clip,t,loadout=0,side_hit=0):
    base=procedural_pose(kit,clip,t,loadout,side_hit)
    if kit not in (0,1,7) or clip not in (2,6) or side_hit:
        return base
    # The published Sword_Attack is a large step-through cut. Transfer its
    # complete joint timing into the existing attack window, with the foot
    # travel shortened for close formation fighting. The original release
    # socket is an exact constraint, shared by the last windup/first recovery.
    contact=SWORD_SOURCE["forward_hand_phase"]
    phase=t*contact if clip==2 else contact+(1.-contact)*t
    points,rotations=source_sword(phase)
    start_points,start_rotations=source_sword(0.)
    hit_points,hit_rotations=source_sword(contact)
    end_points,end_rotations=source_sword(1.)
    ready=procedural_pose(kit,1,0.,loadout)
    if loadout:
        standard=procedural_pose(kit,1,0.)
        carry=1.-ramp(t,0.,.48) if clip==2 else ramp(t,.55,1.)
        ready=[blend_rigid(a,b,carry) for a,b in zip(standard,ready)]
    impact=procedural_pose(kit,2,1.,loadout)
    origin=ready if clip==2 else impact
    finish=impact if clip==2 else ready
    native_start=start_points if clip==2 else hit_points
    native_finish=hit_points if clip==2 else end_points
    native_start_q=start_rotations if clip==2 else hit_rotations
    native_finish_q=hit_rotations if clip==2 else end_rotations
    settling=1.-ramp(t,.78,1.) if clip==6 else 1.
    result=list(base)
    loaded=ramp(t,0.,.60) if clip==2 else 1.-ramp(t,.48,1.)
    joined=ramp(t,0.,.22) if clip==2 else 1.-ramp(t,.75,1.)
    # The animator's hip/shoulder counter-turn remains continuous across
    # release. Register all joint pivots on the game's existing sewn skeleton.
    body_names=((HIPS,"hips",.64),(CHEST,"spine.003",.50),(HEAD,"head",.60))
    for bone,name,strength in body_names:
        delta=qm(rotations[name],inverse_rotation(start_rotations[name]))
        result[bone]=(qm(rotation_mix(IDENT,delta,strength*settling),ready[bone][0]),(0.,0.,0.))
    result[CHEST]=(qm(euler(8.*loaded,0.),result[CHEST][0]),(0.,0.,0.))
    waist=(0.,.86,0.)
    hip_shift=add(mul(sub(points["hips"],start_points["hips"]),.60*settling),(0.,-.075*loaded,0.))
    result[HIPS]=placed(waist,add(trans(ready[HIPS],waist),hip_shift),result[HIPS][0])
    feet={}
    lower_hips=0.
    for side in (-1,1):
        boot=LB if side<0 else RB
        suffix="L" if side<0 else "R"
        name="foot."+suffix
        binds=leg_nodes(side)
        delta=qm(rotations[name],inverse_rotation(start_rotations[name]))
        rotation=qm(rotation_mix(IDENT,delta,.50*settling),ready[boot][0])
        offset=mul(sub(points[name],start_points[name]),.40*settling)
        foot=add(trans(ready[boot],binds[2]),offset)
        lowest=min(rot(rotation,(x,-.117,z))[1] for x in (-.05,.05) for z in (-.072,.187))
        foot=(foot[0],max(foot[1],.006-lowest),foot[2])
        hip=trans(result[HIPS],binds[0])
        reach=sum(sqrt(dot(sub(b,a),sub(b,a))) for a,b in zip(binds,binds[1:]))-.003
        horizontal=(hip[0]-foot[0])**2+(hip[2]-foot[2])**2
        lower_hips=min(lower_hips,foot[1]+sqrt(max(0.,reach*reach-horizontal))-hip[1])
        feet[side]=(foot,rotation)
    # Register the authored stepping feet before solving the torso. A straight
    # support leg lowers the pelvis instead of opening the ankle/knee seams.
    hip_q,hip_translation=result[HIPS]
    result[HIPS]=(hip_q,add(hip_translation,(0.,lower_hips,0.)))
    result[CHEST]=placed((0.,1.008,0.),trans(result[HIPS],(0.,1.008,0.)),result[CHEST][0])
    result[HEAD]=placed((0.,1.427,.015),trans(result[CHEST],(0.,1.427,.015)),result[HEAD][0])
    # Motion warping preserves the exact grip at both endpoints while keeping
    # the authored chamber, accelerating cut and follow-through between them.
    first=trans(origin[RH],grip(1))
    last=trans(finish[RH],grip(1))
    residual=sub(points["hand.R"],lerp(native_start["hand.R"],native_finish["hand.R"],t))
    anchor=add(lerp(first,last,t),mul(residual,.56))
    source_line=rotation_mix(native_start_q["hand.R"],native_finish_q["hand.R"],t)
    extra=qm(inverse_rotation(source_line),rotations["hand.R"])
    aim=qm(rotation_mix(origin[RH][0],finish[RH][0],t),rotation_mix(IDENT,extra,.72))
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        suffix="L" if side<0 else "R"
        binds=arm_nodes(side)
        if side>0:
            palm,rotation=anchor,aim
        elif kit==7:
            palm=lerp(trans(ready[LH],grip(-1)),trans(base[LH],grip(-1)),joined)
            rotation=rotation_mix(ready[LH][0],base[LH][0],joined)
        else:
            travel=mul(sub(points["hand.L"],start_points["hand.L"]),.56*settling)
            palm=add(trans(ready[LH],grip(-1)),travel)
            delta=qm(rotations["hand.L"],inverse_rotation(start_rotations["hand.L"]))
            rotation=qm(rotation_mix(IDENT,delta,.65*settling),ready[LH][0])
        center,radius=reachable(result[CHEST],side,rotation)
        palm=limit_grip(palm,center,radius)
        arm_lengths=[sqrt(dot(sub(b,a),sub(b,a))) for a,b in zip(binds,binds[1:])]
        folded_reach=abs(arm_lengths[0]-arm_lengths[1])+.003
        toward_palm=sub(palm,center)
        palm=add(center,mul(unit(toward_palm),max(folded_reach,sqrt(dot(toward_palm,toward_palm)))))
        hand_pose=placed(grip(side),palm,rotation)
        native_elbow=unit(sub(points["forearm."+suffix],points["upper_arm."+suffix]))
        ready_elbow=unit(sub(trans(ready[upper],binds[1]),trans(ready[CHEST],binds[0])))
        elbow=unit(lerp(ready_elbow,native_elbow,joined))
        result[upper],result[fore]=two_link(binds,trans(result[CHEST],binds[0]),trans(hand_pose,binds[2]),elbow)
        result[hand]=hand_pose
    for side in (-1,1):
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        suffix="L" if side<0 else "R"
        binds=leg_nodes(side)
        foot,rotation=feet[side]
        native_knee=unit(sub(points["shin."+suffix],points["thigh."+suffix]))
        ready_knee=unit(sub(trans(ready[thigh],binds[1]),trans(ready[HIPS],binds[0])))
        knee=unit(lerp(ready_knee,native_knee,joined))
        result[thigh],result[shin]=two_link(binds,trans(result[HIPS],binds[0]),foot,knee)
        result[boot]=placed(binds[2],foot,rotation)
    return result

def cycling(clip):
    return clip in (0,1,12,15) or clip>=16

def bake_motion(out):
    # Each bone gets a strip of adjacent keys. The four RGBA8 rows are affine
    # encodings, so GPU filtering can mix high/low bytes without a carry error.
    # The extra endpoint joins the first key of loops or holds the last action key.
    lanes=[(kit,clip,0,0) for kit in range(9) for clip in range(CLIPS)]
    lanes.extend((kit,clip,loadout,0) for kit in CARRY_KITS for loadout in (1,2) for clip in CARRY_CLIPS)
    lanes.extend((kit,clip,0,side) for kit in range(9) for clip,side in REACTIONS)
    # Preserve the seated torso for native ground cuts. The shader selects
    # these six existing poses only for a mounted basic sword/dao/shield action.
    mounted_start=len(lanes)
    lanes.extend((kit,clip,0,0) for kit,clip in MOUNTED_ATTACKS)
    tex=Image.new("RGBA",((FRAMES+1)*BONES,len(lanes)*4))
    px=tex.load()
    for lane,(kit,clip,loadout,side) in enumerate(lanes):
        previous=[None]*BONES
        y=lane*4
        sample_pose=procedural_pose if lane>=mounted_start else pose
        for frame in range(FRAMES+1):
            t=(frame%FRAMES)/FRAMES if cycling(clip) else min(frame,FRAMES-1)/(FRAMES-1)
            for b,(q,offset) in enumerate(sample_pose(kit,clip,t,loadout,side)):
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
