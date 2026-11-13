"""Small battle-camera meshes retain the fitted silhouettes and the same animated joints."""
from company_figures import *
from field_armour import field_helmet
from field_visage import archer_wrap
from company_weapons import field_shield, nocked_arrow
from figure_mesh import Surface, add, lerp

def costume(look,rank=False):
    s=Surface(False)
    heavy=look in ("regular","guard","officer","player")
    if rank:
        def body(p):
            if p[1]<.86: return (LT if p[0]<0 else RT,HIPS,.35)
            return (CHEST,HIPS,clamp((p[1]-.86)*3))
        if look=="levy":
            def tucked(p,a,row):
                take=max(0.,sin(a+.15))
                return (p[0],p[1]+(.22*take-.04*max(0.,-sin(a))) if row==0 else p[1],p[2])
            s.rings([(.48,.229,.153,0,-.019),(.76,.201,.142,0,-.012),(.958,.154,.115,0,-.012),
                     (1.27,.207,.134,0,-.012)],"linen",body,8,tucked)
            s.rings([(1.27,.207,.134,0,-.012),(1.346,.169,.108,0,-.009),
                     (1.43,.078,.069,0,0)],"dyed",body,8)
        else:
            hem=.475 if look=="archer" else .516
            width=.228 if look in ("guard","archer") else .207
            s.rings([(hem,width,.150,0,-.017),(.744,width*.92,.141,0,-.015),
                     (.953,.161,.119,0,-.013),(1.31,.216,.143,0,-.014),
                     (1.447,.070,.069,0,0)],"coat",body,8)
        if heavy:
            issue_vest(s,look,rank=True)
            wrapping(s,look,rank=True)
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
        if look=="player":
            player_half_mantle(s,rank=True)
        elif look=="officer":
            pairs=(
                  [(-.14,1.421,-.084),(-.247,1.297,-.13),(-.262,.943,-.209),(-.241,.572,-.221)],
                  [(.131,1.428,-.082),(.12,1.236,-.197),(.134,1.024,-.236),(.104,.792,-.245)])
            def mantle(u,v):
                row=round(v*3)
                return lerp(pairs[0][row],pairs[1][row],u),(CHEST,HIPS,.99-.56*v)
            s.grid(2,3,mantle,"mantle")
    else:
        coat(s,look)
        equipment(s,look)
    if rank:
        ns=6
        s.rings([(1.426,.050,.057,0,.026),(1.495,.060,.071,0,.044),(1.550,.081,.083,0,.051),
                 (1.635,.085,.099,0,.034),(1.703,.065,.077,0,.018)],"skin",HEAD,ns)
        if heavy and look!="player":
            field_helmet(s,look,HEAD,rank=True)
        elif look=="archer":
            archer_wrap(s,HEAD,rank=True)
        else:
            s.rings([(1.62,.092,.103,0,.015),(1.67,.088,.100,0,.005),(1.719,.044,.065,0,-.003)],"hair",HEAD,ns)
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
                shoulder=lerp(a,b,.28)
                hem=lerp(a,b,.74)
                s.tube([a,shoulder,hem],[.051,.064,.079],
                       "quilt" if look=="guard" else "dyed",upper,5)
                s.tube([hem,b],[.079,.059],"quilt" if look=="guard" else "linen",upper,5)
            elif look=="levy":
                shoulder=lerp(a,b,.40)
                s.tube([a,shoulder],[.078,.083],"dyed",upper,5)
                s.tube([shoulder,lerp(a,b,.74),b],[.083,.079,.060],"linen",upper,5)
            else:
                s.tube([a,lerp(a,b,.68),b],[.078,.082,.060],"dyed",upper,5)
        forearm(s,look,side,n,rank)
        a,b,c=leg_nodes(side)
        # Shape the calf and cloth at the knee; a straight triangle tube at the
        # everyday distance made boots read like pegs beside an otherwise curved tunic.
        width=.91 if look=="levy" else 1.07 if look=="guard" else 1.
        leg_sides=5 if rank else 8
        s.tube([a,lerp(a,b,.35),lerp(a,b,.78),b],[(rx*width,rz*width) for rx,rz in
               ((.103,.118),(.109,.126),(.088,.103),(.079,.093))],"felt",thigh,leg_sides)
        s.tube([b,lerp(b,c,.19),lerp(b,c,.59),c],[(.079,.093),(.078,.085),(.053,.068),(.047,.056)],"binding",shin,leg_sides)
        s.rings([(.007,.065,.136,c[0],.052),(.062,.064,.120,c[0],.054),
                 (.101,.058,.090,c[0],.032),(.145,.050,.061,c[0],0)],"boots",boot,leg_sides)
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
            field_shield(s,False)
    elif kit in (2,3,4):
        stick((0,0,-.697),(0,0,1.69),.031,.026,"timber")
        if kit!=2: blade(add(g,(0,0,1.56)),.343 if kit==3 else .614,.06 if kit==3 else .089,0 if kit==3 else .143,RH)
        if kit==3:
            s.ribbon([add(g,(0,.008,1.56)),add(g,(.052,-.08,1.405))],.049,"dyed",RH)
    elif kit==5:
        nocked_arrow(s,False)
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
