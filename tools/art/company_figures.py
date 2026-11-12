"""Patterns for the river levy, bowman, guard, officer and mounted player's company.
The yoke has real armholes: the first sleeve row is the edge of the torso mesh.
"""
from math import atan2, cos, exp, hypot, pi, sin
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

def coat(s,look):
    close=s.detail
    n=24 if close else 12
    start={"levy":.575,"archer":.667,"guard":.601,"officer":.494,"player":.528}[look]
    hem=[(start,.254,.183),(.75,.241,.170),(.86,.211,.15),(.96,.177,.135),
         (1.075,.19,.141),(1.185,.219,.151),(1.255,.233,.153),(1.327,.245,.142),
         (1.408,.199,.100),(1.456,.077,.074)]
    lo,hi=6,8
    def cloth(p):
        x,y,z=p
        if y<.86:
            return (LT if x<0 else RT,HIPS,clamp((.88-y)*1.37))
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
        radius=hanging*(.012*pleat-.005*cos(3*a+.2))
        return ((rx+radius)*sin(a),y,(rz+radius)*cos(a)-.009*(1-cos(a))-.006)
    def body_vertex(c,r):
        p=point(c,r)
        return s.vertex(p,uv("dyed",c/n,clamp((1.46-p[1])/(1.46-start))),cloth(p))
    rows=[[body_vertex(c,r) for c in range(n+1)] for r in range(len(hem))]
    span=3 if close else 2
    slots=(n//4,3*n//4)
    for r in range(len(hem)-1):
        for c in range(n):
            if lo<=r<hi and any(center-span<=c<center+span for center in slots): continue
            s.quad(rows[r][c],rows[r][c+1],rows[r+1][c+1],rows[r+1][c])
    for side,center in ((1,slots[0]),(-1,slots[1])):
        left,right=center-span,center+span
        rim=([(c,lo) for c in range(left,right)]+[(right,r) for r in range(lo,hi)]
             +[(c,hi) for c in range(right,left,-1)]+[(left,r) for r in range(hi,lo,-1)])
        previous=[rows[r][c] for c,r in rim]
        # Rotate each edge's section from the body side to the drooping sleeve.
        circle=[]
        for c,r in rim:
            x,y,z=point(c,r)
            lateral=(y-1.333)/.077
            front=(z+.014)/.125
            length=max(.001,hypot(lateral,front))
            circle.append((lateral/length,front/length))
        upper,fore=(LU,LF) if side<0 else (RU,RF)
        sleeve=[(.238,1.356,.087,.10,-.004),(.249,1.283,.092,.094,0),
                (.254,1.202,.069,.077,.008),(.259,1.146,.080,.079,.019),
                (.262,1.115,.067,.061,.024),(.264,1.075,.063,.056,.032)]
        if not close: sleeve=[sleeve[i] for i in (0,2,3,5)]
        for j,(cx,y,rx,rz,cz) in enumerate(sleeve):
            ring=[]
            for i,(out,front) in enumerate(circle):
                bulge=.004*cos(atan2(front,out)*3+j*.74)
                p=(side*(cx+(rx+bulge)*out),y-.009*front,(rz+bulge)*front+cz)
                weight=(upper,CHEST,.76) if j==0 else (upper,fore,clamp((y-1.105)/.109))
                mat="headcloth" if j==len(sleeve)-1 else "dyed"
                ring.append(s.vertex(p,uv(mat,i/len(circle),j/(len(sleeve)-1)),weight))
            for i in range(len(rim)):
                k=(i+1)%len(rim)
                s.quad(previous[i],previous[k],ring[k],ring[i])
            previous=ring
    # Broad, tapered cross collar follows the chest's contour to the side fastening.
    for side in (-1,1):
        path=[(side*.062,1.458,.048),(side*.103,1.403,.088),(side*.093,1.358,.123),
              (side*.041,1.302,.151),(-side*.025,1.241,.156)]
        if side==-1: path.extend([(.110,1.168,.128),(.155,1.104,.086)])
        s.ribbon(path,.042 if close else .048,"headcloth",CHEST)
    n_belt=18 if close else 8
    s.rings([(.923,.187,.148,0,-.005),(.966,.189,.150,0,-.006),
             (.992,.187,.145,0,-.006)],"sash" if look in ("player","officer") else "leather",HIPS,n_belt)
    if close:
        s.oval((.107,.953,.118),(.031,.026,.012),"brass",HIPS,9,4)

def equipment(s,look):
    close=s.detail
    heavy=look in ("guard","officer","player")
    if heavy:
        s.rings([(1.014,.199,.156,0,-.006),(1.065,.208,.161,0,-.007),
                 (1.208,.245,.168,0,-.006),(1.314,.253,.162,0,-.007),
                 (1.376,.209,.123,0,-.009)],"lamellar",CHEST,18 if close else 8)
        for side in (-1,1):
            bone=LT if side<0 else RT
            def tassets(u,v):
                a=side*(.41+u*1.90)
                rx=.263-.064*v
                ry=.57+.397*v+.048*(u-.48)**2
                return (rx*sin(a),ry,(.183-.034*v)*cos(a)-.012),(bone,HIPS,.42*(1-v))
            s.grid(7 if close else 3,3 if close else 1,tassets,"lamellar")
    if look in ("player","officer"):
        # Asymmetric half-mantle with a split over the left hip; a readable back
        # silhouette even with a spear lifted or the front arm hidden by the shield.
        def mantle(u,v):
            a=1.06+u*3.99
            collar=.102
            rx=collar+(.328-collar)*(1-v)**.65
            rz=.089+(.242-.089)*(1-v)**.58
            split=.128*max(0,1-abs(u-.70)*11)
            bottom=.48+.27*u+split
            y=bottom+(1.445-bottom)*v+.022*sin(3*a)*(1-v)
            fold=(.014+.014*(1-v))*sin(5*a+v)
            p=((rx+fold)*sin(a)-.011*(1-v),y,(rz+fold)*cos(a)-.028-.028*(1-v))
            return p,(CHEST,HIPS,clamp(.18+v*.98))
        cols=18 if close else 7
        s.grid(cols,6 if close else 3,mantle,"mantle")
        def facing(u,v): return mantle(u,.018+.035*v)
        s.grid(cols,1,facing,"headcloth")
        s.ribbon([(-.107,1.421,.087),(-.017,1.391,.123),(.089,1.343,.134),(.161,1.303,.136)],
                 .032,"sash",CHEST)
        s.oval((-.105,1.419,.099),(.033,.028,.018),"brass",CHEST,10 if close else 6,4)
    if look=="archer":
        a,b=(-.154,.815,-.194),(.141,1.379,-.206)
        s.tube([a,lerp(a,b,.10),lerp(a,b,.88),b],[.045,.068,.067,.075],"quiver",CHEST,10 if close else 5)
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
        s.rings([(.006,.065,.137,ankle[0],.059),(.024,.071,.145,ankle[0],.060),
                 (.053,.070,.141,ankle[0],.064),(.092,.064,.099,ankle[0],.033),
                 (.139,.058,.067,ankle[0],-.003)],"boots",boot,n)
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
    head(s,look,HEAD)
    equipment(s,look)
    return s
