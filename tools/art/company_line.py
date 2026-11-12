"""Army-line meshes use the same tailoring, gripping sockets and 16 bones as close kits.

At player zoom their body is usually 18–45 pixels high. Stitching, fingers and helmet
lames then live in the mapped material, while the silhouette retains the jaw, bun,
collar, wrist, waist, knee, shoe and distinct length of each weapon.
"""
from company_figures import *
from company_weapons import FRONT_GRIP
from figure_mesh import Surface, add, lerp

def costume(look):
    s=Surface(False)
    heavy=look in ("guard","officer","player")
    def tailor(p):
        if p[1]<.84: return (LT if p[0]<0 else RT,HIPS,.5)
        return (CHEST,HIPS,max(0,min(1,(p[1]-.85)*3.5)))
    s.rings([(.507,.302,.206,0,-.006),(.788,.229,.164,0,.003),(.938,.187,.14,0,.004),
             (1.14,.215,.163,0,0),(1.345,.245,.133,0,-.002),(1.429,.086,.077,0,.007)],"dyed",tailor,6)
    s.rings([(.964,.201,.154,0,.002),(1.21,.248,.177,0,-.006),(1.372,.211,.114,0,-.005)],
            "lamellar" if heavy else ("linen" if look=="archer" else "quilt"),CHEST,6)
    s.rings([(.916,.198,.149,0,.006),(.979,.206,.158,0,.005)],"leather",HIPS,6)
    s.ribbon([(-.085,1.43,.087),(-.128,1.35,.135),(.015,1.21,.187),(.112,1.094,.147)],.043,"lining",CHEST)
    s.rings([(1.435,.062,.078,0,.031),(1.497,.111,.108,0,.034),(1.605,.133,.128,0,.014),
             (1.677,.119,.12,0,-.005)],"skin",HEAD,7)
    s.panel([(-.021,1.55,.153),(.02,1.55,.153),(.014,1.57,.179),(-.012,1.57,.179)],"skin",HEAD)
    if heavy:
        s.rings([(1.602,.147,.141,0,-.012),(1.641,.156,.151,0,-.012),(1.73,.087,.086,0,-.017),
                 (1.758,.017,.019,0,-.02)],"iron",HEAD,6)
    else:
        s.rings([(1.616,.139,.14,0,-.012),(1.653,.142,.14,0,-.013)],"linen" if look!="archer" else "felt",HEAD,6)
        s.rings([(1.649,.14,.139,0,-.012),(1.724,.055,.063,0,-.028)],"hair",HEAD,6)
        s.rings([(1.72,.045,.041,0,-.045),(1.766,.034,.033,0,-.052)],"hair",HEAD,4)
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        a,b,c=arm_nodes(side)
        s.tube([a,lerp(a,b,.33),b],[.075,.107,.075],"dyed",upper,4)
        s.tube([b,lerp(b,c,.35),c],[.072,.067,.039],"leather" if heavy or look=="archer" else "linen",fore,4)
        p=grip(side)
        s.tube([add(p,(0,0,-.057)),p,add(p,(0,-.004,.063))],[.032,.046,.034],"skin",hand,4)
        a,b,c=leg_nodes(side)
        s.tube([a,b],[.103,.085],"felt",thigh,4)
        s.tube([b,lerp(b,c,.52),c],[.08,.071,.061],"binding",shin,4)
        s.rings([(.029,.082,.137,c[0],.052),(.080,.076,.128,c[0],.062),(.117,.06,.076,c[0],.003)],"boots",boot,4)
    if look=="archer":
        s.tube([(-.16,.797,-.168),(.123,1.373,-.196),(.16,1.458,-.201)],[.049,.07,.027],"leather",CHEST,4)
    return s

def arms(kit):
    s=Surface(False)
    g=grip(1)
    def stick(a,b,r0,r1,mat,j=RH):
        s.tube([add(g,a),add(g,b)],[r0,r1],mat,j,3)
    def blade(c,length,width,rise,bone):
        base=add(c,(0,0,.126))
        shoulder=add(base,(0,rise*.25,length*.71))
        tip=add(base,(0,rise,length))
        for side in [-1,1]:
            root=add(base,(side*.013,0,0));mid=add(shoulder,(side*.01,0,0))
            for sign,material in ((1,"iron"),(-1,"edge")):
                p=add(base,(0,sign*width,0));q=add(shoulder,(0,sign*width*.96,0))
                s.panel([root,p,q,mid],material,bone)
                s.panel([mid,q,tip,lerp(tip,mid,.018)],material,bone)
    if kit in (0,1,7,8):
        for side in ((-1,1) if kit==8 else (1,)):
            c=grip(side);bone=RH if side==1 else LH
            s.tube([add(c,(0,0,-.146)),add(c,(0,0,.13))],[.034,.033],"binding",bone,4)
            s.tube([add(c,(-.078,0,.15)),add(c,(.078,0,.15))],[.02,.02],"brass",bone,3)
            blade(c,.71 if kit==8 else .91,.048 if kit==1 else .036,.141 if kit==1 else .015,bone)
        if kit==7:
            c=add(grip(-1),(0,.02,.112))
            rim=[add(c,(x,y,-.06)) for x,y in ((-.1,-.4),(-.23,-.25),(-.24,.22),(-.13,.36),(.13,.36),(.24,.22),(.23,-.25),(.1,-.4))]
            for i,p in enumerate(rim):
                q=rim[(i+1)%len(rim)]
                s.panel([p,q,lerp(q,c,.98),lerp(p,c,.98)],"shield",LH)
            s.tube([add(c,(0,-.355,-.035)),c,add(c,(0,.338,-.034))],[.018,.027,.017],"iron",LH,3)
    elif kit in (2,3,4):
        stick((0,0,-.697),(0,0,1.69),.031,.026,"timber")
        if kit!=2: blade(add(g,(0,0,1.56)),.343 if kit==3 else .614,.06 if kit==3 else .089,0 if kit==3 else .143,RH)
        if kit==3:
            s.ribbon([add(g,(0,.008,1.56)),add(g,(.052,-.08,1.405))],.049,"dyed",RH)
    elif kit==5:
        for side in (-1,1):
            p=[add(g,(0,y*side,z)) for y,z in ((0,0),(.35,.095),(.53,.053),(.69,-.122))]
            s.tube(p,[.031,.025,.018,.01],"timber",RH,3)
            nock=add(g,(0,0,-.159));tip=p[-1]
            s.tube([tip,nock],[.006,.006],"lining",lambda v:(NOCK,RH,min(1,max(0,1-abs(v[1]-nock[1])/.69))),3)
    else:
        stick((0,-.014,-.39),(0,.03,.55),.049,.035,"timber")
        for side in (-1,1):
            tip=(side*.407,.053,.302)
            stick((0,.065,.432),tip,.033,.009,"timber")
            stick(tip,(0,.073,-.053),.006,.006,"lining")
    return s
