"""Fitted river-gate issue armour. The same profiles are sampled at all three camera distances."""
from math import cos, pi, sin

from figure_mesh import TAU


def issue_headpiece(surface, guard, bone, rank):
    """Light open ear cut or a deep shield helmet on the same head bind."""
    sides = 10 if rank else (28 if surface.detail else 16)
    # The arming cloth stays inside the shell. The forehead clears the
    # character's existing brows and the side edge stops above the jaw.
    def brow(a):
        base=1.613 + .035*cos(a) + (.009 if guard else .006)*cos(2*a)
        # Tip the shield helmet away from the brow. The hinge and nape retain
        # their depth; the forward opening exposes the cheek under a high camera.
        return base+(.019*max(0.,cos(a))**1.4 if guard else 0.)

    sections = ((0.,.111,.122,.015),(.20,.112,.128,.011),
                (.55,.095,.112,.004),(.84,.059,.079,-.001),(1.,.004,.010,-.008))
    if guard:
        sections = ((0.,.124,.140,.014),(.15,.121,.136,.009),
                    (.49,.099,.123,.001),(.80,.061,.084,-.011),(1.,.005,.014,-.024))
    if rank:
        sections = tuple(sections[i] for i in (0,2,3,4))

    def dome(u,v):
        a=TAU*u
        t,rx,rz,cz=sections[round(v*(len(sections)-1))]
        # The shield shell is raised along the front-to-back fold. The light
        # shell is shallow above the temples. Both retain a continuous surface.
        ridge=(.022 if guard else .010)*abs(cos(a))**5*sin(pi*t)
        height=1.774 if guard else 1.741
        y=brow(a)+(height-brow(a))*t+ridge
        front=max(0.,cos(a))
        pull=.012*front**2*(1.-t) if guard else 0.
        return (rx*sin(a),y,cz+rz*cos(a)-pull),bone
    surface.grid(sides,len(sections)-1,dome,"black_iron")

    # A worked lower edge flares at the temples; it sits well above the eyes.
    # Its dark underside also separates the cap from the lining in side view.
    def brim(u,v):
        a=TAU*u
        radius,depth=(.124,.140) if guard else (.112,.123)
        # The raised front lip ends at the forehead. Enough width remains
        # at the temples to take the load from the long cheek leaves.
        front=max(0.,cos(a))
        flare=(.003+.003*front+.011*sin(a)**2 if guard
               else .004+.004*front+.003*sin(a)**2)
        pull=.012*front**2 if guard else 0.
        if v<.5:
            return ((radius+flare)*sin(a),brow(a)-.008,.015+(depth+flare)*cos(a)-pull),bone
        return (radius*sin(a),brow(a)+(.012 if guard else .006),.015+depth*cos(a)-pull),bone
    surface.grid(sides,1,brim,"black_iron")

    def panel(points,side,mat,n,lo=0.,hi=1.,trim=.0):
        # Stations run from the temple to the nape. Both sides wind outwards.
        def sample(u,v):
            along=u if side>0 else 1.-u
            k=min(len(points)-2,int(along*(len(points)-1)))
            f=along*(len(points)-1)-k
            a,drop,swipe=[p+(q-p)*f for p,q in zip(points[k],points[k+1])]
            down=hi-(hi-lo)*v
            angle=a+swipe*down
            radius=(.123 if guard else .111)+(.009 if guard else .005)*sin(pi*down)
            depth=(.135 if guard else .119)
            rx=radius+(.015 if guard else -.009)*down+trim
            rz=depth+(.029 if guard else .009)*down+trim
            return ((side*rx*sin(angle),brow(a)-.003-down*drop,
                     .014+rz*cos(angle)-.007*down),bone)
        surface.grid(n,1 if rank else 2,sample,mat)

    for side in (-1,1):
        if guard:
            # Two backed leaves on the cheeks and a deeper, outward sloping
            # piece over the nape. The swept notch between them shows the collar.
            cheek=((1.06,.024,.12),(1.37,.097,.11),(1.69,.156,.08),
                   (1.98,.116,.045),(2.14,.071,0.))
            panel(cheek,side,"lames",4 if rank else 8)
            panel(cheek,side,"black_iron",4 if rank else 8,.90,1.018,.0014)
            nape=((2.12,.065,.075),(2.38,.119,.035),(2.70,.146,.0),
                  (2.98,.127,-.012),(pi,.105,.0))
            panel(nape,side,"black_iron",4 if rank else 8)
            panel(nape,side,"binding",4 if rank else 8,.93,1.025,.0014)
        else:
            # Short ear lappets end behind the cheekbone; the darker, inset
            # textile at the nape reveals the neck as the spearman turns.
            ear=((1.01,.025,.02),(1.36,.068,.08),(1.70,.092,.09),
                 (1.97,.066,.045),(2.06,.032,0.))
            panel(ear,side,"black_iron",4 if rank else 8)
            cloth=((1.96,.027,.08),(2.36,.077,.065),(2.74,.112,.025),(pi,.085,0.))
            panel(cloth,side,"felt",3 if rank else 6)
            panel(cloth,side,"binding",3 if rank else 6,.85,1.025,.0014)

    if not guard:
        # The folded corner of the soft nape guard rests on one side of
        # the neck. Even the rank mesh keeps the triangular cloth silhouette.
        left=((-.015,1.574,-.111),(-.034,1.544,-.133),(-.060,1.500,-.139))
        right=((.027,1.572,-.109),(.014,1.540,-.139),(-.020,1.497,-.146))
        def facing(u,v):
            row=round((1.-v)*2)
            p=[x+(y-x)*u for x,y in zip(left[row],right[row])]
            p[2]-=.006*sin(pi*u)
            return tuple(p),bone
        surface.grid(2 if rank else 4,2,facing,"binding")


def field_helmet(surface, look, bone, rank=False):
    """A raised comb, brow band and hinged cheek/nape coverage leave the face open."""
    if look in ("regular", "guard"):
        issue_headpiece(surface, look=="guard", bone, rank)
        return
    sides = 8 if rank else (28 if surface.detail else 14)
    senior = look in ("officer", "player")
    # Forehead, sides and nape sit at different heights over the actual head sculpt.
    def brow(angle):
        return 1.619 + .029*cos(angle) - .008*sin(angle)**2

    sections = ((0., .112, .127), (.17, .114, .125), (.49, .101, .117),
                (.77, .079, .092), (.93, .040, .062), (1., .003, .012))
    if rank:
        sections = tuple(sections[i] for i in (0, 2, 3, 5))

    def crown(u, v):
        angle = TAU * u
        t, rx, rz = sections[round(v * (len(sections) - 1))]
        y0 = brow(angle)
        crown_height=1.766
        y = y0 + (crown_height - y0) * t
        return (rx * sin(angle), y, .020 + rz * cos(angle) - .018 * t), bone
    surface.grid(sides, len(sections) - 1, crown, "black_iron")

    def rim(u, v):
        angle = TAU * u
        y = brow(angle) - .006 + .019 * v
        radius,depth=.115,.130
        return (radius*sin(angle), y, .019+depth*cos(angle)), bone
    surface.grid(sides, 1, rim, "iron_binding")

    # The overlapping cheek flaps are separate from the crown. Their swept front
    # opens away from the mouth; the lower rear edge clears the collar on a turn.
    for side in (-1, 1):
        def flap(u, v):
            angle = side * (.84 + 2.315 * u + .19 * (1. - v))
            drop = (.057 + .073 * sin(pi * u) ** .65 + .029 * u) * (1. - v)
            radius = .110+.011*sin((1.-v)*pi)-.013*(1.-v)
            depth = .122 + .018 * (1. - v) * u
            return (radius * sin(angle), brow(angle) - .001 - drop,
                    .018 + depth * cos(angle)), bone
        surface.grid(3 if rank else (10 if surface.detail else 5), 1 if rank else 3, flap, "lames")
    if not rank:
        # A broad joined rib remains a quiet value change on the small crown.
        spine = [(0., brow(0.) + .010, .148), (0., 1.708, .122), (0., 1.748, .071),
                 (0., 1.759, .003), (0., 1.740, -.082), (0., 1.686, -.111),
                 (0., brow(pi) + .012, -.112)]
        surface.tube(spine, [(.005, .004), (.008, .005), (.009,.005), (.009,.006),
                             (.008,.005), (.006,.004), (.004,.003)],
                     "iron_binding", bone, 6)
    if senior:
        crest = [(0., 1.756, .019), (.004, 1.789, -.020), (.007, 1.782, -.090),
                 (.014, 1.731, -.146), (.023, 1.633, -.164)]
        surface.tube(crest, [.010, .022, .025, .018, .004], "sash", bone,
                     4 if rank else (9 if surface.detail else 6), 1.27)


def skirts(surface, look, hips, thighs, rank=False):
    """Left and right panels are suspended at the waist and can follow a stride independently."""
    light = look == "regular"
    length = .275 if light else (.377 if look=="guard" else .346)
    columns = 3 if rank else (9 if surface.detail else 5)
    # The two side tassets open at the centre. The leading knee is still visible
    # under the edge when a spearman plants his forward foot.
    for side, thigh in zip((-1,1), thighs):
        def point(u, down):
            front=(.61 if light else .30)+(.24 if light else .17)*down
            back=pi-(.56 if light else .23)-.13*down
            angle=(front+(back-front)*u) if side>0 else (-back+(back-front)*u)
            along=(u if side>0 else 1.-u)
            y=.955-length*down+down*(.099*abs(2*along-1)**2-.018*sin(pi*along))
            flare=.053*down+.018*sin(pi*down)
            width=(.237 if look=="guard" else .204)+flare
            depth=(.177 if look=="guard" else .155)+.91*flare
            return ((width*sin(angle),y,-.014+depth*cos(angle)),
                    (thigh,hips,.64*down))
        def iron(u,v): return point(u,1.-v)
        def binding(u,v): return point(u,1.06-.06*v)
        if look in ("regular","guard"):
            # Two suspended iron leaves part over a folded dyed coat at the hip.
            # The visible wedge widens at the knee and folds back between the
            # bound edges. Build all panels on one cut to avoid coplanar paint.
            def cut(u,v):
                breadth=(.103 if light else .085)+(.115 if light else .146)*(1.-v)
                middle=.51+.045*(1.-v)
                return middle+(u*2.-1.)*breadth
            def leaf(u,v):
                edge=cut(0.,v) if left else cut(1.,v)
                x=u*edge if left else edge+u*(1.-edge)
                return iron(x,v)
            def gore(u,v):
                p,weights=iron(cut(u,v),v)
                fold=sin(pi*u)
                return ((p[0]-side*.025*fold,p[1]-.059*(1.-v)*fold,
                         p[2]+.013*fold*(1.-v)),weights)
            for left in (True,False):
                surface.grid(max(2,columns//2),1 if rank else 3,leaf,"lames")
            surface.grid(2 if rank else 4,2,gore,"dyed")
            for lo,hi in ((0.,cut(0.,0.)),(cut(1.,0.),1.)):
                surface.grid(max(1,columns//2),1,
                             lambda u,v: binding(lo+(hi-lo)*u,v),"leather")
        else:
            surface.grid(columns,1 if rank else 3,iron,"lames")
            surface.grid(columns,1,binding,"leather")

    if look in ("guard","officer","player"):
        # A shorter front apron hangs from the belt between the two thigh panels.
        # The broad roll at its centre splits the front from the side under light.
        def apron(u,v):
            down=1.-v
            x=(u-.5)*(.245-.04*down)
            y=.947-.309*down+.032*down*abs(2*u-1)**1.5
            z=.157+.061*down+.014*(1.-abs(2*u-1))-.020*(2*u-1)**2
            return (x,y,z),(hips,thighs[0] if x<0 else thighs[1],1.-.22*down)
        surface.grid(2 if rank else 4,1 if rank else 3,apron,"lamellar")
