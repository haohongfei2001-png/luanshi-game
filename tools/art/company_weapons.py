"""Nine separate fitted weapons, built around the same hand sockets used in the motion bake."""
from math import sin,cos,pi
from figure_mesh import Surface,add,lerp
from company_figures import grip,RH,LH,NOCK
TWO_HAND={2,3,4,6}
FRONT_GRIP={2:.48,3:.55,4:.54,6:.31}

def weapon(kit,detail):
    s=Surface(detail)
    n=9 if detail else 5
    g=grip(1)
    def at(p): return add(g,p)
    def stick(points,radii,material,bone=RH,sides=n):
        s.tube([at(p) for p in points],radii,material,bone,sides)
    def binding(first,last,bone=RH,offset=(0,0,0)):
        def pt(z): return add(offset,(0,0,z))
        stick([pt(first),pt(last)],[.034,.034],"binding",bone)
        if detail:
            for q in range(4):
                z=first+(last-first)*(q+.35)/4
                stick([pt(z),pt(z+.012)],[.036,.035],"leather",bone,7)
    def blade(start,length,breadth,curvature,bone=RH):
        sections=[(0,.68,0),(.10,1,.02),(.45,1,.11),(.76,1.03,.43),(.91,.71,.76),(1,.006,1)]
        rings=[]
        for t,w,rise in sections:
            c=add(start,(0,curvature*rise,length*t))
            rings.append([add(c,(0,-breadth*w,0)),add(c,(.019*(1-.65*t),breadth*w*.12,0)),
                          add(c,(0,breadth*w,0)),add(c,(-.019*(1-.65*t),breadth*w*.12,0))])
        for j in range(len(rings)-1):
            for i in range(4):
                i2=(i+1)%4
                s.panel([rings[j][i],rings[j][i2],rings[j+1][i2],rings[j+1][i]],
                        "edge" if i in (0,3) else "iron",bone)
    if kit in (0,1,7,8):
        for side in ([-1,1] if kit==8 else [1]):
            bone=RH if side>0 else LH
            off=(grip(side)[0]-g[0],0,0)
            binding(-.139,.116,bone,off)
            stick([add(off,(0,0,-.168)),add(off,(0,0,-.139))],[.047,.042],"brass",bone)
            stick([add(off,(-.083,-.005,.151)),add(off,(-.037,.005,.13)),add(off,(.037,.005,.13)),
                   add(off,(.083,-.005,.151))],[.014,.026,.026,.014],"brass",bone)
            blade(add(grip(side),(0,0,.145)),.71 if kit==8 else .91,.047 if kit==1 else .033,
                  .142 if kit==1 else .012,bone)
        if kit==7:
            c=add(grip(-1),(0,.025,.105))
            profile=[(-.10,-.4),(-.217,-.298),(-.244,.214),(-.16,.35),(0,.402),(.16,.35),(.244,.214),(.217,-.298),(.10,-.4)]
            rim=[add(c,(x,y,-abs(x)*.24-.023)) for x,y in profile]
            for i,p in enumerate(rim):
                q=rim[(i+1)%len(rim)]
                # A shallow convex layered face, raised spine, hide rim and working grip.
                mid=add(c,(0,0,.056))
                s.panel([p,q,lerp(q,mid,.98),lerp(p,mid,.98)],"shield",LH)
                s.tube([p,q],[.016,.016],"leather",LH,5)
            s.tube([add(c,(0,-.34,-.004)),add(c,(0,0,.069)),add(c,(0,.34,-.002))],
                   [.018,.025,.018],"iron",LH,6)
            s.tube([add(c,(-.077,0,-.02)),grip(-1),add(c,(.082,0,-.02))],[.019,.025,.02],"binding",LH,6)
            # The bound board domes over its working grip. Broad faces stay
            # wooden; the shallow forged boss takes the central blow.
            s.oval(add(c,(0,.008,.053)),(.089,.108,.043),"iron",LH,12,5)
            for x in [-.131,.131]:
                for y in [-.231,.220]:
                    s.oval(add(c,(x,y,.012)),(.012,.014,.010),"brass",LH,6,3)
    elif kit in (2,3,4):
        stick([(0,0,-.69),(0,0,-.54),(0,0,1.52),(0,.004,1.69)],
              [.031,.032,.027,.024],"timber")
        binding(-.095,.095)
        binding(FRONT_GRIP[kit]-.074,FRONT_GRIP[kit]+.065)
        stick([(0,0,-.716),(0,0,-.669)],[.032,.033],"iron")
        if kit in (3,4):
            stick([(0,0,1.55),(0,0,1.71)],[.036,.037],"iron")
            blade(at((0,0,1.694)),.34 if kit==3 else .61,.061 if kit==3 else .085,
                  0 if kit==3 else .143)
            if kit==3:
                for i in range(5 if detail else 2):
                    a=i*1.72
                    s.tube([at((0,0,1.56)),at((sin(a)*.036,-.05,1.49)),at((sin(a)*.074,-.091+i*.011,1.40))],
                           [.019,.016,.004],"dyed",RH,4)
    elif kit==5:
        for side in (-1,1):
            limb=[(0,side*y,z) for y,z in ((0,0),(.13,.029),(.32,.096),(.49,.081),(.59,.011),(.63,-.095),(.694,-.123))]
            stick(limb,[.03,.029,.026,.023,.019,.014,.009],"timber",RH,n)
            tip=at(limb[-1])
            centre=at((0,0,-.159))
            # The nocking point follows the draw hand, the tips remain fixed to the stave.
            for k in range(4):
                t0=k/4;t1=(k+1)/4
                u=lerp(tip,centre,t0);v=lerp(tip,centre,t1)
                s.tube([u,v],[.005,.005],"lining",lambda p,t=t0,u=u,v=v,t1=t1:
                       (NOCK,RH,t+(t1-t)*(sum((p[j]-u[j])*(v[j]-u[j]) for j in range(3))/max(.00001,sum((v[j]-u[j])**2 for j in range(3))))),4)
        stick([(0,-.068,0),(0,.068,0)],[.033,.032],"binding")
    else:
        stick([(0,-.013,-.39),(0,-.015,-.28),(0,0,.03),(0,.031,.43),(0,.034,.54)],
              [(.043,.052),(.047,.062),(.044,.049),(.036,.042),(.027,.032)],"timber")
        for side in (-1,1):
            stick([(0,.064,.432),(side*.16,.071,.449),(side*.322,.068,.39),(side*.407,.052,.302)],
                  [.033,.028,.02,.008],"timber")
            stick([(side*.407,.052,.302),(0,.073,-.053)],[.0055,.006],"lining")
        stick([(0,-.038,.005),(0,-.092,-.016),(0,-.103,-.042)],[.015,.013,.008],"brass")
        stick([(0,.072,-.077),(0,.096,-.042),(0,.083,-.015)],[.018,.023,.012],"brass")
        stick([(0,.086,-.063),(0,.088,.664)],[.008,.006],"timber")
    return s
