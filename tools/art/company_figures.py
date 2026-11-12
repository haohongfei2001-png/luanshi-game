"""Patterns for the river levy, bowman, guard, officer and mounted player's company.
The yoke has real armholes: the first sleeve row is the edge of the torso mesh.
"""
from math import atan2, cos, exp, hypot, pi, sin
from field_armour import skirts
from field_visage import head
from figure_atlas import uv
from figure_mesh import Surface, TAU, add, lerp

HIPS, CHEST, HEAD, LU, LF, LH, RU, RF, RH, LT, LS, LB, RT, RS, RB, NOCK = range(16)
def arm_nodes(s):
    return ((s*.225,1.405,-.012),(s*.258,1.145,.014),(s*.273,.915,.055))
def grip(s): return (s*.273,.943,.075)
def leg_nodes(s):
    return ((s*.12,.858,-.012),(s*.134,.477,.021),(s*.141,.123,-.016))
def clamp(x): return max(0,min(1,x))
def smoothstep_cloth(x):
    x=clamp(x)
    return x*x*(3-2*x)

def coat(s,look):
    close=s.detail
    n=24 if close else 12
    start={"levy":.575,"archer":.667,"regular":.565,"guard":.601,"officer":.494,"player":.528}[look]
    hem=[(start,.254,.183),(.75,.241,.170),(.86,.211,.15),(.96,.177,.135),
         (1.075,.19,.141),(1.185,.219,.151),(1.255,.233,.153),(1.327,.245,.142),
         (1.408,.199,.100),(1.456,.077,.074)]
    lo,hi=6,8
    def cloth(p):
        x,y,z=p
        if y<.86:
            # The middle of a hanging coat hangs from the belt. Only the side
            # beside a moving thigh is carried forward by that leg.
            side_weight=.25+.75*smoothstep_cloth(abs(x)/.20)
            return (LT if x<0 else RT,HIPS,clamp((.88-y)*1.37)*side_weight)
        if y>1.245 and abs(x)>.147:
            return ((LU if x<0 else RU),CHEST,.46*clamp((abs(x)-.147)/.078))
        return (CHEST,HIPS,clamp((y-.88)*3.8))
    def point(c,r):
        a=TAU*(c%n)/n
        y,rx,rz=hem[r]
        hanging=clamp((.93-y)/(.93-start))
        biased=cos(a+.63)**8 if cos(a+.63)>0 else 0
        y+=hanging*(.088*biased+.018*sin(3*a+.9)-.018*cos(a))
        # A handful of long folds open from the girdle and continue to the hem.
        pleat=cos(7*a+.52*cos(2*a)-.48*hanging)
        radius=hanging*(.018*pleat-.006*cos(3*a+.2))
        # Cloth bunches above the cinch and opens back out across the shoulder blades.
        radius+=.009*exp(-((y-1.045)/.092)**2)*cos(5*a+.8)+.006*exp(-((y-1.25)/.11)**2)*cos(3*a-.65)
        return ((rx+radius)*sin(a),y,(rz+radius)*cos(a)-.009*(1-cos(a))-.006)
    heavy=look in ("regular","guard","officer","player")
    vertices={}
    def body_vertex(c,r,material,panel):
        split=r<2 and c%n in (n//4,3*n//4)
        key=(c,r,material,panel if split else 0)
        if key not in vertices:
            p=point(c,r)
            if split:
                # Front and back skirts meet at the hip and open at the side seam
                # during a stride. Their converging edges do not bridge the thighs.
                freedom=clamp((.86-p[1])/(.86-start))
                p=(p[0]*(1.-.024*freedom),p[1]+.035*freedom,p[2]+panel*.050*freedom)
            v=1-clamp((p[1]-.966)/.43) if material=="lames" else clamp((1.46-p[1])/(1.46-start))
            vertices[key]=s.vertex(p,uv(material,c/n,v),cloth(p))
        return vertices[key]
    span=3 if close else 2
    slots=(n//4,3*n//4)
    for r in range(len(hem)-1):
        for c in range(n):
            if lo<=r<hi and any(center-span<=c<center+span for center in slots): continue
            material="coat"
            if heavy and 3<=r<=7:
                material="lames"
            elif look=="archer" and 3<=r<=7:
                material="quilt"
            elif look=="levy" and r==8:
                material="facing"
            elif r<=1 and (c>=3*n//4 or c<n//8):
                material="overskirt"
            panel=1 if cos(TAU*(c+.5)/n)>0 else -1
            s.quad(body_vertex(c,r,material,panel),body_vertex(c+1,r,material,panel),
                   body_vertex(c+1,r+1,material,panel),body_vertex(c,r+1,material,panel))
    for side,center in ((1,slots[0]),(-1,slots[1])):
        left,right=center-span,center+span
        rim=([(c,lo) for c in range(left,right)]+[(right,r) for r in range(lo,hi)]
             +[(c,hi) for c in range(right,left,-1)]+[(left,r) for r in range(hi,lo,-1)])
        # Both sides of an armhole use the garment's exact bind positions and skin weights.
        rows=[[(point(c,r),cloth(point(c,r))) for c,r in rim]]
        circle=[]
        for c,r in rim:
            x,y,z=point(c,r)
            lateral=(y-1.333)/.077
            front=(z+.014)/.125
            length=max(.001,hypot(lateral,front))
            circle.append((lateral/length,front/length))
        upper,fore=(LU,LF) if side<0 else (RU,RF)
        sleeve=[(.231,1.357,.069,.089,-.003),(.246,1.299,.083,.086,0),
                (.251,1.227,.074,.078,.007),(.257,1.155,.065,.071,.017),
                (.260,1.110,.067,.069,.023),(.264,1.075,.058,.054,.032)]
        if not close: sleeve=[sleeve[i] for i in (0,2,3,5)]
        for j,(cx,y,rx,rz,cz) in enumerate(sleeve):
            ring=[]
            for out,front in circle:
                bulge=.004*cos(atan2(front,out)*3+j*.74)
                p=(side*(cx+(rx+bulge)*out),y-.009*front,(rz+bulge)*front+cz)
                weight=(upper,CHEST,.76) if j==0 else (upper,fore,clamp((y-1.105)/.109))
                ring.append((p,weight))
            rows.append(ring)
        # A trim boundary duplicates UVs only. A triangle joining two atlas tiles
        # would pick up iron or skin halfway across the sleeve when the arm turns.
        edge=len(rows)-1
        if heavy:
            # Use the fitted sleeve itself under the shoulder suspension. A second
            # shell following a different arm weight can open holes during a thrust.
            cap_end=(3 if look=="regular" else 4) if close else (2 if look=="regular" else 3)
            panels=[(0,cap_end,"lames")]
            if cap_end<edge-1: panels.append((cap_end,edge-1,"dyed"))
        else:
            panels=[(0,edge-1,"dyed")]
        panels.append((edge-1,edge,"headcloth"))
        for first,last,material in panels:
            def sleeve_point(u,v):
                row=first+round(v*(last-first))
                return rows[row][round(u*len(rim))%len(rim)]
            s.grid(len(rim),last-first,sleeve_point,material)
    def body_at(a,y,offset=.010):
        # Sample the garment itself so a strap cannot cross through a rotating back.
        j=next((i for i in range(len(hem)-1) if hem[i][0]<=y<hem[i+1][0]),len(hem)-2)
        t=clamp((y-hem[j][0])/(hem[j+1][0]-hem[j][0]))
        rx=hem[j][1]*(1-t)+hem[j+1][1]*t+offset
        rz=hem[j][2]*(1-t)+hem[j+1][2]*t+offset
        return (rx*sin(a),y,rz*cos(a)-.009*(1-cos(a))-.006)
    def collar(u,v):
        # The neckband starts exactly at the last tunic row; it stands up at the
        # nape and falls under the crossed front. No detached strip can clip an arm.
        a=TAU*u
        base=point(round(u*n),len(hem)-1)
        rise=.012+.027*(1-cos(a))*.5
        p=(base[0]+.0025*v*sin(a),base[1]+rise*v,base[2]+.0025*v*cos(a))
        return p,cloth(base)
    s.grid(n,1,collar,"facing")
    def belt(u,v):
        a=TAU*u
        p=body_at(a,.921+.065*v+.009*cos(a+.3),.014+.003*sin(pi*v))
        return p,cloth(p)
    s.grid(20 if close else 10,2,belt,"girdle" if heavy else "leather")
    if look in ("levy","archer","player","officer"):
        for front in (True,False):
            def baldric(u,v):
                # Back strap is visible from the normal follow camera.
                a=((-.74+1.58*(1-v)) if front else (3.89-1.59*(1-v)))+(u-.5)*.32
                if look=="levy": a=-a
                p=body_at(a,.94+.465*v,.017)
                return p,cloth(p)
            s.grid(2,7 if close else 3,baldric,"leather" if look=="levy" else ("quiver" if look=="archer" else "sash"))
    if close or look in ("player","officer"):
        p=body_at(.68,.958,.026)
        s.oval(p,(.030,.023,.016),"brass",HIPS,8 if close else 6,4)
    if look in ("levy","archer"):
        # A soft bag gives the visible diagonal strap a real attachment at the belt.
        s.rings([(.792,.032,.040,-.184,.057),(.812,.055,.063,-.191,.057),
                 (.874,.060,.068,-.196,.055),(.920,.053,.052,-.188,.060),
                 (.937,.034,.034,-.180,.059)],"quiver",HIPS,10 if close else 6)

def equipment(s,look):
    close=s.detail
    heavy=look in ("regular","guard","officer","player")
    if heavy:
        skirts(s,look,HIPS,(LT,RT))
        # Two shoulder fastenings suspend the front and back without filling the neckline.
        for side in (-1,1):
            path=[(side*.130,1.318,.129),(side*.143,1.382,.103),
                  (side*.138,1.431,.049),(side*.134,1.442,-.026),
                  (side*.144,1.398,-.107),(side*.150,1.314,-.150)]
            s.ribbon(path,.031,"leather",CHEST)
    if look in ("player","officer"):
        # Asymmetric half-mantle with a split over the left hip; a readable back
        # silhouette even with a spear lifted or the front arm hidden by the shield.
        def mantle(u,v):
            a=.77+u*4.51
            # The cape rides over a shoulder, expands across the blades, and hangs
            # free of the narrow waist. The open side clears the weapon arm.
            rx=.107+.213*sin((1-v)*pi*.62)**.70
            rz=.096+.118*sin((1-v)*pi*.62)**.74
            split=.135*max(0,1-abs(u-.62)*7.5)
            bottom=.478+.27*u+split
            y=bottom+(1.453-bottom)*v+.031*sin(3*a+.25)*(1-v)
            fold=(.009+.020*(1-v))*sin(5*a+.63*v)
            p=((rx+fold)*sin(a)-.021*(1-v),y,(rz+fold)*cos(a)-.053-.028*(1-v))
            return p,(CHEST,HIPS,clamp(.18+v*.98))
        cloth_mat="hero_mantle" if look=="player" else "mantle"
        # Split lower panels leave a real notch between the two short tails.
        for left,right in ((0.,.62),(.62,1.)):
            def tail(u,v):
                gap=.046*(1-smoothstep_cloth(v/.36))
                lo=left+(gap if left>0 else 0.)
                hi=right-(gap if right<1 else 0.)
                return mantle(lo+u*(hi-lo),v)
            s.grid((12 if close else 5) if left==0 else (8 if close else 3),7 if close else 3,tail,cloth_mat)
        s.ribbon([(-.107,1.421,.087),(-.017,1.391,.123),(.089,1.343,.134),(.161,1.303,.136)],
                 .032,"sash",CHEST)
        s.oval((-.105,1.419,.099),(.033,.028,.018),"brass",CHEST,10 if close else 6,4)
    if look=="archer":
        a,b=(-.161,.790,-.226),(.146,1.379,-.267)
        s.tube([a,lerp(a,b,.10),lerp(a,b,.88),b],[.048,.072,.074,.079],"quiver",CHEST,10 if close else 5)
        s.ribbon([(-.17,1.403,.066),(-.104,1.313,.141),(.017,1.19,.161),(.126,1.044,.115)],.049,"leather",CHEST)
        for i in range(4 if close else 2):
            end=add(b,((i%2-.5)*.038,.157+(i%3)*.025,(i//2)*.027))
            s.tube([add(end,(-.088,-.18,0)),end],[.006,.005],"timber",CHEST,4)
            s.ribbon([add(end,(-.051,-.090,0)),add(end,(-.015,-.038,-.003)),end],.031,"headcloth",CHEST)

def limbs(s,look):
    close=s.detail
    n=11 if close else 6
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        hip,knee,ankle=leg_nodes(side)
        x=side*.134
        def leg(p): return (thigh,shin,clamp((p[1]-.424)/.125))
        s.rings([(.274,.053,.059,x,.013),(.363,.057,.071,x,.008),
                 (.426,.076,.085,x,.017),(.454,.087,.095,x,.025),(.497,.083,.089,x,.018),
                 (.591,.095,.110,x,-.008),(.748,.113,.117,side*.127,-.017),(.866,.11,.118,side*.12,-.013)],"felt",leg,n)
        def ankle_blend(p): return (shin,boot,clamp((p[1]-.103)/.082))
        s.rings([(.078,.057,.065,ankle[0],-.010),(.118,.061,.066,ankle[0],-.006),
                 (.217,.057,.066,x,.006),(.332,.067,.076,x,.012),(.368,.064,.073,x,.009)],
                "binding",ankle_blend,n)
        def footwear(p,angle,row):
            toe=max(0.,cos(angle))
            return (ankle[0]+(p[0]-ankle[0])*(1-.23*toe**2),p[1]+.006*toe**4,p[2])
        s.rings([(.006,.059,.129,ankle[0],.057),(.024,.065,.139,ankle[0],.058),
                 (.053,.066,.131,ankle[0],.056),(.092,.060,.087,ankle[0],.029),
                 (.139,.054,.063,ankle[0],-.003)],"boots",boot,n,footwear)
        el,wr=arm_nodes(side)[1:]
        s.tube([lerp(el,wr,.20),lerp(el,wr,.34),lerp(el,wr,.64),wr],
               [.064,.067,.054,.042],"leather" if look!="levy" else "headcloth",fore,n)
        g=grip(side)
        s.oval((g[0]+side*.018,g[1]+.005,g[2]-.004),(.034,.046,.058),"skin",hand,n,5)
        if close:
            for i in range(4):
                z=g[2]-.037+i*.020
                s.tube([(g[0]+side*.029,g[1]+.004,z),(g[0]+side*.028,g[1]-.026,z),
                        (g[0],g[1]-.035,z+.002),(g[0]-side*.021,g[1]-.018,z+.003)],
                       [.011,.013,.013,.008],"skin",hand,5)
        s.tube([(g[0]+side*.025,g[1]+.030,g[2]+.012),(g[0]-.006*side,g[1]+.035,g[2]+.040),
                (g[0]-side*.023,g[1]+.005,g[2]+.034)],[.015,.016,.010],"skin",hand,6 if close else 4)

def costume(look,detail):
    s=Surface(detail)
    coat(s,look)
    limbs(s,look)
    s.rings([(1.372,.071,.067,0,.005),(1.421,.062,.064,0,.008),
             (1.485,.055,.069,0,.016),(1.521,.062,.071,0,.019)],"skin",
            lambda p:(HEAD,CHEST,clamp((p[1]-1.391)/.115)),10)
    head(s,look,HEAD)
    equipment(s,look)
    return s
