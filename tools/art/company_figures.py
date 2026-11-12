"""Model sheets for levy, bowman, armoured guard, field officer and the player.

Body materials follow the construction of the garment. Face, overlapping robe panels,
helmet lames and the four articulated fingers are modelled in the same metre-scale bind.
"""
from math import sin, cos, exp, pi
from figure_mesh import Surface, TAU, add, lerp

# Bind skeleton. Mirrored bones are explicit because a second hand can have a different grip.
HIPS, CHEST, HEAD, LU, LF, LH, RU, RF, RH, LT, LS, LB, RT, RS, RB, NOCK = range(16)
def arm_nodes(s):
    return ((s*.225,1.405,-.012),(s*.258,1.145,.014),(s*.273,.915,.055))
def grip(s): return (s*.273,.943,.075)
def leg_nodes(s):
    return ((s*.12,.858,-.012),(s*.134,.477,.021),(s*.141,.123,-.016))

def torso(s,look):
    full=s.detail
    n=22 if full else 9
    armour=look in ("guard","officer","player")
    def cloth_skin(p):
        x,y,z=p
        if y<.86: return (LT if x<0 else RT,HIPS,max(0.,min(.82,(.89-y)*1.96)))
        return (CHEST,HIPS,max(0.,min(1.,(y-.85)*3.4)))
    def drape(p,a,row):
        x,y,z=p
        folds=cos(10*a+.55*sin(a)+.7*row)*(max(0.,.96-y)*.072+.002)
        opening=max(0,cos(a))**10
        return (x+sin(a)*folds,y+.035*sin(2*a+.3)*max(0.,1-row*.35)+.04*opening*(row==0),
                z+cos(a)*folds)
    lengths=[(.50,.298,.208,0,-.005),(.518,.304,.216,0,-.006),(.64,.275,.195,0,0),
             (.79,.228,.164,0,.003),(.924,.181,.135,0,.01),(1.02,.189,.149,0,0),
             (1.17,.226,.161,0,.006),(1.32,.25,.15,0,-.002),(1.397,.21,.107,0,-.008),(1.443,.088,.081,0,.008)]
    if not full: lengths=[lengths[i] for i in (0,2,4,6,8,9)]
    s.rings(lengths,"dyed",cloth_skin,n,drape)
    if full:
        # Independent front lap overlaps the belted robe with a biased hem.
        def lap(u,v):
            angle=-.88+u*1.45+v*.24
            y=.49+v*.44+.045*u
            width=.307-.131*v
            return (width*sin(angle),y,(.224-.084*v)*cos(angle)+.01),cloth_skin((sin(angle),y,0))
        s.grid(8,4,lap,"dyed")
        s.ribbon([(-.092,.544,.217),(-.097,.641,.207),(-.112,.78,.163),(-.126,.906,.118)],.013,"lining",HIPS)
    outer="lamellar" if armour else ("quilt" if look!="archer" else "linen")
    lengths=[(.955,.194,.151,0,0),(.976,.207,.161,0,0),(1.097,.221,.174,0,0),
             (1.216,.253,.181,0,-.002),(1.31,.254,.166,0,-.002),(1.382,.212,.121,0,-.004)]
    s.rings(lengths if full else [lengths[i] for i in (0,2,4,5)],outer,cloth_skin,n)
    for side in (-1,1):
        # Facing strips meet at the collar with one flap passing beneath the other.
        path=[(side*.073,1.452,.07),(side*.124,1.391,.108),(side*.122,1.34,.148),
              (side*.061,1.277,.183),(-side*.022,1.19,.187)]
        if side==-1: path.append((.162,1.049,.112))
        s.ribbon(path,.048,"lining" if look not in ("officer","guard") else "leather",CHEST)
    s.rings([(.918,.191,.145,0,.006),(.929,.197,.15,0,.006),(.981,.20,.157,0,.005),(.988,.196,.15,0,.005)],"leather",HIPS,n)
    if full:
        s.panel([(-.039,.937,.162),(.035,.937,.162),(.035,.969,.164),(-.039,.969,.164)],"brass",HIPS)
        s.ribbon([(.114,.956,.134),(.138,.84,.167),(.109,.706,.19)],.038,"leather",HIPS)
        if armour:
            for side in (-1,1):
                s.rings([(.623,.102,.137,side*.167,-.008),(.654,.112,.157,side*.159,-.003),
                         (.872,.108,.14,side*.122,-.004),(.91,.103,.13,side*.12,-.005)],
                         "lamellar",LT if side<0 else RT,9)
        if look in ("officer","player"):
            s.ribbon([(-.17,1.38,-.084),(-.136,1.27,-.179),(-.114,.97,-.181),(-.197,.63,-.212)],.093,"lining",CHEST)

def head(s,look):
    full=s.detail
    # Crown, temples, eye sockets, malar eminence, mouth and the tapering jaw belong
    # to one continuous surface. The nose ridge grows out of that same topology.
    s.rings([(1.374,.061,.06,0,.006),(1.477,.067,.066,0,.018)],"skin",HEAD,12 if full else 6)
    profile=[(1.425,.050,.063,.035),(1.449,.080,.087,.035),(1.476,.105,.104,.033),
             (1.506,.116,.109,.035),(1.533,.119,.112,.036),(1.559,.126,.116,.027),
             (1.584,.13,.122,.022),(1.606,.128,.127,.017),(1.631,.132,.128,.008),
             (1.654,.13,.126,.001),(1.69,.115,.114,0),(1.722,.073,.079,-.004),
             (1.736,.004,.006,-.007)]
    def face(p,a,j):
        x,y,z=p
        front=max(0,cos(a))**4
        def bump(cx,cy,wx,wy):
            return exp(-((x-cx)/wx)**2-((y-cy)/wy)**2)
        relief=.067*bump(0,1.555,.024,.033)+.039*bump(0,1.592,.018,.055)
        relief+=.012*bump(0,1.511,.054,.013)+.015*bump(0,1.468,.05,.024)
        relief+=.020*bump(abs(x),1.57,.07,.031)-.032*bump(abs(x)-.053,1.605,.033,.016)
        return (x,y,z+front*relief)
    s.rings([(y,x,z,0,cz) for y,x,z,cz in profile],"skin",HEAD,32 if full else 10,face)
    if full:
        for side in (-1,1):
            x=side*.057
            s.oval((side*.126,1.556,.012),(.026,.046,.027),"skin",HEAD,10)
            # Narrow, inset lids; dark irises are visible without painting white doll-eyes.
            s.tube([(x-.028,1.605,.133),(x,1.612,.145),(x+.027,1.606,.136)],[.003,.005,.002],"hair",HEAD,5)
            s.oval((x,1.603,.141),(.008,.0045,.004),"hair",HEAD,7,4)
            s.tube([(x-.03,1.622,.137),(x-.004,1.632,.151),(x+.026,1.628,.138)],[.003,.007,.002],"hair",HEAD,6)
            s.oval((side*.013,1.543,.188),(.008,.003,.006),"leather",HEAD,6,4)
        s.tube([(-.034,1.502,.153),(0,1.5,.168),(.034,1.505,.153)],[.002,.004,.0015],"leather",HEAD,5)
        if look=="officer":
            for side in (-1,1):
                s.tube([(side*.006,1.519,.161),(side*.031,1.51,.151),(side*.055,1.497,.133)],[.003,.009,.001],"hair",HEAD,6)
    helmet=look in ("officer","guard","player")
    n=18 if full else 8
    if helmet:
        s.rings([(1.607,.141,.139,0,-.012),(1.628,.154,.149,0,-.009),(1.649,.153,.149,0,-.012),
                 (1.704,.124,.123,0,-.017),(1.746,.073,.073,0,-.02),(1.765,.02,.023,0,-.02)],"iron",HEAD,n)
        s.rings([(1.621,.151,.147,0,-.009),(1.642,.157,.15,0,-.009)],"brass" if look=="officer" else "leather",HEAD,n)
        def apron(u,v):
            a=1.02+u*(TAU-2.04)
            return (sin(a)*(.139+.02*(1-v)),1.478+v*.157+.037*cos(a*2),( .151+.005*v)*cos(a)-.012),HEAD
        s.grid(n,3,apron,"lamellar")
        if full:
            for a in (-1.1,.03,1.14,3.1):
                path=[(sin(a)*r,y,cos(a)*r-.012) for r,y in ((.151,1.644),(.137,1.682),(.104,1.724),(.033,1.762))]
                s.tube(path,[.004,.005,.005,.002],"brass" if look=="officer" else "iron",HEAD,5)
    else:
        s.rings([(1.618,.136,.135,0,-.012),(1.651,.141,.139,0,-.017),(1.703,.116,.119,0,-.023),
                 (1.729,.061,.07,0,-.031),(1.735,.006,.01,0,-.031)],"hair",HEAD,n)
        s.rings([(1.618,.141,.142,0,-.01),(1.651,.146,.145,0,-.012),(1.663,.138,.138,0,-.013)],"felt" if look=="archer" else "linen",HEAD,n)
        s.oval((.003,1.751,-.052),(.052,.044,.05),"hair",HEAD,10 if full else 6,5)
        s.ribbon([(.06,1.65,-.121),(.094,1.59,-.15),(.106,1.475,-.136)],.035,"linen",HEAD)

def limbs(s,look):
    full=s.detail
    n=12 if full else 6
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        hip,knee,ankle=leg_nodes(side)
        def leg(p):
            return (thigh,shin,max(0,min(1,(p[1]-.42)/.14)))
        x=side*.134
        s.rings([(.298,.057,.061,x,.006),(.385,.074,.083,x,-.003),(.445,.095,.09,x,.022),
                 (.493,.101,.098,x,.012),(.603,.103,.112,x,-.014),(.753,.125,.125,side*.129,-.024),
                 (.859,.105,.113,side*.116,-.013)],"felt",leg,n)
        s.rings([(.087,.065,.076,ankle[0],-.008),(.146,.074,.084,ankle[0],-.005),
                 (.282,.068,.074,x,.009),(.386,.081,.087,x,.006)],"binding",shin,n)
        s.rings([(.026,.078,.135,ankle[0],.053),(.038,.084,.139,ankle[0],.054),
                 (.087,.081,.129,ankle[0],.063),(.119,.063,.077,ankle[0],.003)],"boots",boot,n)
        if full:
            path=[(x+sin(i*TAU/10)*.076,.151+i*.006,cos(i*TAU/10)*.08+.003) for i in range(34)]
            s.tube(path,[.007]*len(path),"linen",shin,4)
        sh,el,wr=arm_nodes(side)
        def arm(p):
            return (upper,fore,max(0,min(1,(p[1]-1.106)/.096)))
        centres=[(sh[1]+.023,.06,.081,sh[0]*.94,sh[2]),(sh[1]-.038,.109,.115,sh[0],sh[2]),
                 (1.295,.092,.101,side*.244,-.001),(1.219,.077,.092,side*.251,.008),
                 (1.155,.091,.094,el[0],el[2]),(1.128,.074,.074,el[0],el[2])]
        s.rings(list(reversed(centres)),"dyed",arm,n)
        s.tube([el,lerp(el,wr,.31),lerp(el,wr,.78),wr],[.073,.069,.052,.041],
               "leather" if look in ("guard","officer","player","archer") else "linen",fore,n)
        if look in ("guard","officer","player"):
            s.rings([(1.288,.104,.123,side*.252,-.01),(1.323,.112,.127,side*.245,-.012),
                     (1.377,.109,.123,side*.235,-.012),(1.423,.075,.085,side*.217,-.014)],"lamellar",upper,n)
        g=grip(side)
        s.oval((g[0]+side*.027,g[1]+.006,g[2]),(.039,.051,.067),"skin",hand,n,6 if full else 4)
        if full:
            for i in range(4):
                z=g[2]-.044+i*.024
                s.tube([(g[0]+side*.035,g[1]+.007,z),(g[0]+side*.032,g[1]-.026,z),
                        (g[0],g[1]-.04,z+.002),(g[0]-side*.027,g[1]-.021,z+.003)],
                       [.015,.016,.015,.009],"skin",hand,6)
            s.tube([(g[0]+side*.027,g[1]+.037,g[2]+.02),(g[0]-.007*side,g[1]+.041,g[2]+.048),
                    (g[0]-side*.03,g[1]+.008,g[2]+.038)],[.018,.018,.011],"skin",hand,6)

def costume(look,detail):
    s=Surface(detail)
    torso(s,look)
    limbs(s,look)
    head(s,look)
    if look=="archer":
        a,b=(-.16,.793,-.156),(.117,1.357,-.194)
        s.tube([a,lerp(a,b,.08),lerp(a,b,.84),b],[.051,.072,.064,.073],"leather",CHEST,10 if detail else 6)
        if detail:
            for i in range(5):
                end=add(b,((i%3-1)*.025,.118+.018*(i%2),(i//3)*.031))
                s.tube([add(end,(-.076,-.17,0)),end],[.007,.006],"timber",CHEST,4)
                s.ribbon([add(end,(-.039,-.076,0)),end],.019,"lining",CHEST)
    return s
