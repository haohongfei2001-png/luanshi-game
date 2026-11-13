"""Patterns for the river levy, bowman, guard, officer and mounted player's company.
The yoke has real armholes: the first sleeve row is the edge of the torso mesh.
"""
from math import atan2, cos, exp, hypot, pi, sin
from field_dress import issue_vest, wrapping
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
    # Station one is the lowest edge, station nine the real neck. The final
    # four stations meet the sewn armholes; the heavy cuts share their sockets.
    if look=="levy":
        hem=[(.455,.237,.151),(.693,.211,.143),(.852,.180,.132),(.972,.151,.112),
             (1.076,.163,.120),(1.188,.185,.132),(1.261,.213,.132),
             (1.328,.234,.125),(1.406,.172,.084),(1.451,.066,.065)]
    elif look=="archer":
        # An archer's waist is tight under the quiver; the right overlap is
        # slit to the thigh, and the long, loose left skirt falls over the knee.
        hem=[(.438,.247,.177),(.684,.226,.163),(.86,.188,.141),(.96,.157,.123),
             (1.075,.183,.138),(1.185,.208,.151),(1.255,.220,.150),
             (1.327,.237,.139),(1.408,.184,.095),(1.456,.070,.071)]
    else:
        guard=look=="guard"
        hem=[(.539 if guard else .481,.234 if guard else .204,.155),
             (.711,.219 if guard else .194,.148),(.851,.196 if guard else .170,.133),
             (.965,.167 if guard else .150,.117),(1.077,.182,.127),
             (1.185,.194,.140),(1.258,.216,.139),(1.328,.228,.129),
             (1.405,.171,.092),(1.449,.068,.067)]
    start=hem[0][0]
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
        # The trapezius falls from the nape to the outside of the shoulder.
        if r>=6:
            slope=(.010,.023,.036,.004)[r-6]
            y-=slope*sin(a)**2
        hanging=clamp((.93-y)/(.93-start))
        biased=cos(a+.63)**8 if cos(a+.63)>0 else 0
        # Cloth clears the inside knee and drops at the outside thigh. A skirt
        # that ends at a single latitude hides stride direction from above.
        cut=abs(sin(a))**1.65
        if look=="levy":
            # The weapon side of the working coat is tucked into the sash.
            # The other skirt panel swings from the hip clear of the bent knee.
            y+=hanging*(.214*max(0.,sin(a+.15))-.040*max(0.,-sin(a))+.092*(1-cut))
        elif look=="archer":
            y+=hanging*(.195*max(0.,sin(a+.32))+.074*(1.-cut)-.067*max(0.,-sin(a)))
        else:
            y+=hanging*(.124*(1.-cut)+.094*max(0.,sin(a+.15))-.049*max(0.,-sin(a)))
        y+=hanging*(.049*biased+.009*sin(3*a+.9))
        # A handful of long folds open from the girdle and continue to the hem.
        pleat=cos(5*a+.45*cos(2*a)-.82*hanging)
        radius=hanging*(.029*pleat-.009*cos(3*a+.2))
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
                material="coat" if r<7 else "linen"
            elif look=="archer" and 3<=r<=7:
                material="quilt" if cos(TAU*(c+.5)/n)<-.25 else "coat"
            elif look=="levy" and 2<=r<8:
                # A dyed shoulder facing runs diagonally over the outer tunic.
                # The chest and rolled elbow still expose the natural hemp.
                outer=cos(TAU*(c+.5)/n-.53)
                material="dyed" if r>=6 or (r==5 and outer>.28) else "linen"
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
        # These sections crown at the upper arm before tapering through the
        # elbow. Each opening still meets the exact armhole of the coat.
        sleeve=[(.224,1.361,.058,.074,-.004),(.237,1.319,.070,.081,-.001),
                (.248,1.251,.074,.078,.005),(.255,1.181,.064,.070,.012),
                (.258,1.144,.062,.067,.015),(.260,1.113,.064,.065,.021),
                (.262,1.082,.052,.053,.029)]
        if look=="levy":
            # A rolled outer sleeve follows the cloth tube under it at the elbow.
            sleeve=[(.220,1.358,.052,.068,-.008),(.232,1.310,.063,.073,-.004),
                    (.246,1.252,.066,.074,.004),(.253,1.173,.072,.075,.010),
                    (.257,1.144,.077,.077,.015),(.261,1.117,.068,.065,.020),
                    (.262,1.098,.055,.055,.024)]
        elif heavy:
            # Wool gathers at the inside of the bent arm. With no circular
            # shoulder plate the upper edge runs directly into the blouse.
            sleeve=[(.218,1.350,.046,.060,-.006),(.231,1.311,.059,.071,-.005),
                    (.244,1.256,.067,.078,.002),(.252,1.183,.075,.077,.008),
                    (.258,1.146,.081,.075,.015),(.262,1.109,.071,.066,.022),
                    (.264,1.081,.049,.051,.030)]
            if look=="guard":
                sleeve=[(cx,y,rx*1.06,rz*1.08,cz) for cx,y,rx,rz,cz in sleeve]
        if not close: sleeve=[sleeve[i] for i in (0,2,3,5,6)]
        for j,(cx,y,rx,rz,cz) in enumerate(sleeve):
            ring=[]
            for out,front in circle:
                angle=atan2(front,out)
                # Three full-length folds meet under the elbow. Tangential
                # twists keep the cuff from looking like a cylindrical socket.
                folds=sin(pi*j/(len(sleeve)-1))
                bulge=.009*(cos(3*angle-.68*j)+.33*cos(2*angle+.21*j))*folds
                fullness=1. if heavy else 1.+.095*sin((j+1)*pi/len(sleeve))
                # The deltoid has a continuous downhill edge, particularly when
                # the elbow lifts for a bow draw. The cuff tilts at the elbow.
                slope=.029*(1-j/(len(sleeve)-1))
                p=(side*(cx+fullness*(rx+bulge)*out),y-slope*max(out,0)-.017*front+.011*cos(2*angle+.35*j)*folds,
                   fullness*(rz+bulge)*front+cz)
                weight=(upper,CHEST,.60) if j==0 else (upper,fore,smoothstep_cloth((y-1.108)/.098))
                ring.append((p,weight))
            rows.append(ring)
        # A trim boundary duplicates UVs only. A triangle joining two atlas tiles
        # would pick up iron or skin halfway across the sleeve when the arm turns.
        edge=len(rows)-1
        if heavy:
            roller=3 if close else 2
            # The narrow sleeveless corselet leaves a large, readable fold of
            # wool. The shieldman's covered upper arm is quieter than his shield.
            panels=[(0,roller,"quilt" if look=="guard" else "dyed"),
                    (roller,edge-1,"linen" if look=="regular" else "quilt")]
        elif look=="levy":
            shoulder=2 if close else 1
            panels=[(0,shoulder,"dyed"),(shoulder,edge-1,"linen")]
        else:
            # The bow sleeve has a substantial blue-grey cuff inside a diagonal
            # fold; the string passes a narrow forearm when the archer draws.
            roller=4 if close else 3
            panels=[(0,roller,"coat"),(roller,edge-1,"linen")]
        panels.append((edge-1,edge,"binding" if heavy else "headcloth"))
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
    s.grid(n,1,collar,"lining" if heavy else "facing")
    if not heavy:
        # Crossing collars follow the front of the coat; the outer lapel reaches
        # the belt. Each is a dark edge and a visible fold, not a drawn X.
        for angle0,angle1,y0,y1,width in ((.81,-.17,1.431,1.265,.27),
                                           (-.83,.85,1.435,1.035,.32)):
            for left,right,material in ((0.,.20,"leather"),(.20,1.,"facing")):
                def lapel(u,v):
                    a=angle0+(angle1-angle0)*v+(left+(right-left)*u-.5)*width
                    y=y0+(y1-y0)*v
                    p=body_at(a,y,.013+.006*sin(pi*u))
                    return p,cloth(p)
                s.grid(1,6 if close else 4,lapel,material)
    if not heavy:
        # A separate cut of the folded-over skirt hangs from the sash. Its
        # textile is visible between the thighs while stepping or drawing.
        front_panels=((-1.62,-.18),(-.16,1.22)) if look=="levy" else ((-.96,.49),(.51,1.42))
        for start_angle,end_angle in front_panels:
            def flap(u,v):
                down=1.-v
                a=start_angle+(end_angle-start_angle)*u+.175*down
                outside=abs(sin(a))
                hem_y=(.682+.139*sin(a)-.078*outside if look=="levy" else .595-.093*outside)+.025*sin(3*a)
                y=.913+(hem_y-.913)*down
                p=body_at(a,y,.010+down*(.018+.012*sin(3.1*u+.29)))
                return p,cloth(p)
            s.grid(5 if close else 3,3,flap,"overskirt")
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
        issue_vest(s,look)
        wrapping(s,look)
    if look in ("player","officer"):
        # Asymmetric half-mantle with a split over the left hip; a readable back
        # silhouette even with a spear lifted or the front arm hidden by the shield.
        def mantle(u,v):
            a=(2.38+u*2.94) if look=="player" else (1.05+u*4.08)
            # The cape rides over a shoulder, expands across the blades, and hangs
            # free of the narrow waist. The open side clears the weapon arm.
            rx=.107+.213*sin((1-v)*pi*.62)**.70
            rz=.096+.118*sin((1-v)*pi*.62)**.74
            split=.105*max(0,1-abs(u-.62)*7.5)
            # The commander's shoulder cloth falls diagonally away from the free
            # arm. Its low left edge streams behind the hip at a run or lunge.
            bottom=(.59+.63*u-.115*sin(pi*u)) if look=="player" else (.56+.26*u)
            bottom+=split
            y=bottom+(1.453-bottom)*v+.031*sin(3*a+.25)*(1-v)
            fold=(.009+.020*(1-v))*sin(5*a+.63*v)
            free=(1.-v)**1.35
            p=((rx+fold)*sin(a)-(.207 if look=="player" else .068)*free,
               y,(rz+fold)*cos(a)-.053-(.303 if look=="player" else .073)*free)
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

def forearm(s,look,side,sides,rank=False):
    fore=LF if side<0 else RF
    elbow,wrist=arm_nodes(side)[1:]
    # The sleeve overlaps a continuous wrist-to-elbow core. Clothing and arm
    # guard take their widths from it, including where the elbows bend sharply.
    rows=((-0.025,.055,.061),(.20,.058,.062),(.34,.059,.061),
          (.58,.052,.056),(.82,.042,.046),(.90,.038,.042),(1.,.035,.038))
    if rank:
        rows=tuple(rows[i] for i in (0,2,4,6))
    sections=[lerp(elbow,wrist,t) for t,_,_ in rows]
    radii=[(rx,rz) for _,rx,rz in rows]
    if look=="archer":
        # Bow arm has a leather bracer on the shooting forearm; the drawing
        # arm keeps the bind of a rolled sleeve above a longer exposed wrist.
        groups=([(0,1,"binding"),(1,2,"leather"),(2,3,"skin")] if rank else
                ([(0,2,"binding"),(2,4,"leather"),(4,5,"binding"),(5,6,"skin")] if side>0 else
                 [(0,2,"binding"),(2,3,"headcloth"),(3,6,"skin")]))
    elif look=="levy":
        # A turned cuff, a short winding, then a bare forearm centred on the real wrist.
        groups=([(0,1,"binding"),(1,3,"skin")] if rank else
                [(0,1,"binding"),(1,2,"headcloth"),(2,6,"skin")])
    else:
        last=len(rows)-1
        groups=[(0,last-1,"leather"),(last-1,last,"skin")]
    for first,last,material in groups:
        s.tube(sections[first:last+1],radii[first:last+1],material,fore,sides)

def limbs(s,look):
    close=s.detail
    n=11 if close else 6
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        hip,knee,ankle=leg_nodes(side)
        x=side*.134
        def leg(p): return (thigh,shin,clamp((p[1]-.424)/.125))
        sections=[(.274,.054,.063,x,.013),(.353,.055,.067,x,.008),
                  (.413,.079,.088,x,.020),(.448,.093,.103,x,.031),(.505,.084,.092,x,.019),
                  (.587,.097,.113,x,-.009),(.715,.108,.124,side*.129,-.023),
                  (.803,.107,.122,side*.123,-.027),(.866,.103,.111,side*.12,-.015)]
        scale=.90 if look=="levy" else (.97 if look=="guard" else .94)
        sections=[(h,rx*scale,rz*scale,cx,cz) for h,rx,rz,cx,cz in sections]
        # A tapered recess behind the kneecap opens when the lower leg folds.
        def knee_cut(p,a,row):
            rear=max(0.,-cos(a))
            knee=exp(-((p[1]-.464)/.069)**2)
            take=.022*rear*knee
            gathered=.0085*cos(3*a-.66*row)*exp(-((p[1]-.52)/.15)**2)
            return (p[0]+gathered*sin(a),p[1]-.022*rear*knee,p[2]+take+gathered*cos(a))
        s.rings(sections,"felt",leg,n,knee_cut)
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
        forearm(s,look,side,n)
        g=grip(side)
        if look=="guard":
            # Dorsal knuckles and the heel of the thumb span the grip of a
            # weighted sword or shield. Fingers wrap from this continuous palm.
            s.rings([(g[1]-.032,.022,.039,g[0]+side*.014,g[2]-.007),
                     (g[1]-.011,.033,.054,g[0]+side*.020,g[2]-.004),
                     (g[1]+.013,.035,.058,g[0]+side*.019,g[2]-.002),
                     (g[1]+.032,.026,.051,g[0]+side*.017,g[2]-.006),
                     (g[1]+.044,.013,.038,g[0]+side*.011,g[2]-.008)],
                     "skin",hand,n)
        else:
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
