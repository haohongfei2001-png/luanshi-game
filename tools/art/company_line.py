"""Small battle-camera meshes retain the fitted silhouettes and the same animated joints."""
from company_figures import *
from field_armour import field_helmet, skirts
from figure_mesh import Surface, add, lerp

def costume(look,rank=False):
    s=Surface(False)
    heavy=look in ("regular","guard","officer","player")
    if rank:
        def body(p):
            if p[1]<.86: return (LT if p[0]<0 else RT,HIPS,.35)
            return (CHEST,HIPS,clamp((p[1]-.86)*3))
        hem=.58 if look=="archer" else .53 if heavy else .58
        s.rings([(hem,.255,.183,0,-.015),(.953,.18,.135,0,-.013),(1.31,.243,.147,0,-.014),
                 (1.447,.083,.07,0,0)],"dyed",body,6)
        if heavy:
            s.rings([(1.03,.199,.154,0,-.014),(1.29,.251,.16,0,-.009),(1.38,.208,.119,0,-.01)],"lamellar",CHEST,8)
            skirts(s,look,HIPS,(LT,RT),rank=True)
        if look=="levy":
            for front in (True,False):
                def sling(u,v):
                    angle=((-1.03+1.64*v) if front else (pi+1.03-1.64*v))+(u-.5)*.31
                    # Fit to the same six-sided coat, with a skin weight at the belt.
                    width=.199+.058*sin(pi*v)
                    depth=.148+.032*sin(pi*v)
                    p=(width*sin(angle),.947+.432*v,-.012+depth*cos(angle))
                    return p,body(p)
                s.grid(1,3,sling,"leather")
        if look in ("player","officer"):
            # The same oblique drape and split tail as the close uniform.
            hero=look=="player"
            pairs=([(-.11,1.428,-.075),(-.283,1.309,-.144),(-.341,1.017,-.233),(-.431,.600,-.360)],
                   [(.072,1.451,-.097),(.042,1.302,-.206),(-.091,1.074,-.312),(-.298,.739,-.440)]) if hero else (
                  [(-.14,1.421,-.084),(-.247,1.297,-.13),(-.262,.943,-.209),(-.241,.572,-.221)],
                  [(.131,1.428,-.082),(.12,1.236,-.197),(.134,1.024,-.236),(.104,.792,-.245)])
            def mantle(u,v):
                row=round(v*3)
                return lerp(pairs[0][row],pairs[1][row],u),(CHEST,HIPS,.99-.56*v)
            s.grid(2,3,mantle,"hero_mantle" if hero else "mantle")
    else:
        coat(s,look)
        equipment(s,look)
    if rank:
        ns=6
        s.rings([(1.426,.050,.057,0,.026),(1.495,.060,.071,0,.044),(1.550,.081,.083,0,.051),
                 (1.635,.085,.099,0,.034),(1.703,.065,.077,0,.018)],"skin",HEAD,ns)
        if heavy and look!="player":
            field_helmet(s,look,HEAD,rank=True)
        else:
            s.rings([(1.62,.092,.103,0,.015),(1.67,.088,.100,0,.005),(1.719,.044,.065,0,-.003)],"facing" if look=="archer" else "hair",HEAD,ns)
            s.rings([(1.625,.095,.108,0,.015),(1.646,.096,.109,0,.013)],"leather" if look=="player" else "headcloth",HEAD,ns)
            if look=="player":
                s.oval((-.016,1.750,-.054),(.057,.058,.067),"hair",HEAD,7,4)
    else:
        head(s,look,HEAD)
    n=3 if rank else 5
    for side in (-1,1):
        upper,fore,hand=(LU,LF,LH) if side<0 else (RU,RF,RH)
        thigh,shin,boot=(LT,LS,LB) if side<0 else (RT,RS,RB)
        a,b,c=arm_nodes(side)
        if rank:
            if heavy:
                hem=lerp(a,b,.59 if look=="regular" else .79)
                s.tube([a,lerp(a,hem,.37),hem],[.081,.100,.082],"lames",upper,5)
                s.tube([hem,b],[.070,.067],"dyed",upper,4)
            else:
                s.tube([a,b],[.084,.069],"dyed",upper,n)
        forearm(s,look,side,n,rank)
        p=grip(side)
        s.tube([add(p,(0,0,-.050)),p,add(p,(0,-.005,.049))],[.032,.040,.029],"skin",hand,n)
        a,b,c=leg_nodes(side)
        s.tube([a,b],[.096,.079],"felt",thigh,n)
        s.tube([b,c],[.074,.053],"binding",shin,n)
        s.rings([(.007,.066,.136,c[0],.052),(.067,.065,.111,c[0],.043),(.141,.052,.061,c[0],0)],"boots",boot,n+1)
    if rank and look=="archer":
        s.tube([(-.16,.797,-.168),(.123,1.373,-.196),(.17,1.505,-.201)],[.048,.067,.022],"quiver",CHEST,4)
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
            s.oval(add(c,(0,.008,.027)),(.087,.103,.039),"iron",LH,6,3)
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
