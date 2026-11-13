"""Fitted issue coats and two distinct constructions of lamellar body defence.

Positions are in metres on the field bind. A vest hangs from the shoulders and
skirts from the girdle; neither is rigidly attached to a moving forearm.
"""
from math import cos, pi, sin

from figure_mesh import TAU

HIPS, CHEST, LEFT_UPPER_ARM = 0, 1, 3
THIGHS = (9, 12)


def cut_radii(look):
    # Waist, ribs, bottom of the suspended body and breadth of the side panels.
    if look == "regular":
        return .171, .229, .997, .88
    if look == "guard":
        return .194, .254, .884, 1.40
    return .184, .246, .931, 1.16


def issue_vest(s, look, rank=False):
    waist, ribs, bottom, sweep = cut_radii(look)
    cols = 4 if rank else (14 if s.detail else 8)
    heavy = look != "regular"

    def surface(a, h):
        # True armholes with a concave low edge at each armpit. Two straps
        # leave the neck, blouse and both shoulders free of the cuirass.
        side = abs(sin(a))
        crown = 1.335 - .109 * side**2 + .021 * max(0., -cos(a))
        top = crown + .026 * max(0., cos(4*a + .18))
        y = bottom + (top-bottom)*h
        belly = sin(h*pi*.79)
        rx = waist + (ribs-waist)*belly + (.014 if heavy else .007)
        rz = (.158 if heavy else .146) + .046*belly
        # Distinct left and right pectorals merge into a quiet central seam.
        ridge = .010 + .007*max(0.,cos(a))*(1.-abs(sin(2*a)))
        return ((rx+ridge)*sin(a), y, -.017+(rz+ridge)*cos(a)), (CHEST,HIPS,min(1.,max(0.,(y-.858)*3.9)))

    # Several apron-width strips of iron cross the ribs. A row shares its
    # highlight across several laced plates; the round back remains visible.
    count = 3 if heavy else 2
    for i in range(count):
        lo, hi = i/count, (i+1)/count
        for start, end in ((-1.50,1.50),(1.57,4.72)):
            def panel(u,v):
                a=start+(end-start)*u
                pt,skin=surface(a,lo+(hi-lo)*v)
                # A slight rise over the flank and the crossing of each lacing
                # row keep the body round even at the lowest mesh distance.
                flank=abs(sin(a))
                rise=.019*flank*(1.-(2*v-1.)**2)
                lip=(.0040 if heavy else .0030)*(1.-v)
                return (pt[0]+lip*sin(a),pt[1]+rise,pt[2]+lip*cos(a)),skin
            s.grid(cols,1 if rank else 3,panel,"lamellar" if heavy else "lames")
    # Supporting leather straps swept along the actual shoulder slope. They
    # stay above the body at the front and back then disappear under the plates.
    for side in (-1,1):
        def strap(u,v):
            a=pi*v
            width=.024 if heavy else .019
            x=side*(.126+.021*sin(a)+width*(u-.5)*2)
            return (x,1.283+.155*sin(a)-.013*v,-.017+.147*cos(a)),(CHEST,HIPS,1.)
        s.grid(2 if s.detail else 1,7 if s.detail else 4,strap,"leather")

    # The spear carrier's light corselet ends above a visible crossing skirt.
    # The shieldman's deeper defence has distinct open hanger panels at each hip.
    for side,bone in zip((-1,1),THIGHS):
        def apron(u,v):
            down=1.-v
            breadth=sweep+.16*down
            a=side*(pi*.5+.13*down)+(u-.5)*breadth
            length=.212 if not heavy else (.390 if look=="guard" else .324)
            edge=abs(2*u-1)
            y=.972-down*(length-.110*edge**1.6)+.015*sin(a)*down
            width=waist+.030+(.061 if heavy else .047)*down
            depth=(.159 if heavy else .141)+.050*down
            fold=.012*sin(pi*u)*sin(pi*down)
            return ((width+fold)*sin(a),y,-.020+(depth+fold)*cos(a)),(bone,HIPS,.64*down)
        s.grid(max(3,cols//2),1 if rank else 3,apron,"lamellar" if heavy else "leather")

    # A soft split tab under the shieldman's defensive coat lies on the thigh.
    # The lower left corner peeks out during a step rather than joining both legs.
    if heavy:
        def falling(u,v):
            down=1.-v
            x=-.099+.206*u+.024*down
            y=.926-down*(.292+.092*(1.-u))+.035*down*(2*u-1)**2
            z=.162+.084*down+.011*sin(1.6*pi*u)-.024*(2*u-1)**2
            bone=THIGHS[0] if x<0 else THIGHS[1]
            return (x,y,z),(HIPS,bone,1.-.18*down)
        s.grid(3 if rank else 6,2 if rank else 3,falling,"overskirt")


def wrapping(s, look, rank=False):
    """A front overlap and its reverse are hung from the actual cloth waist."""
    if look not in ("regular", "guard", "player", "officer"):
        return
    guard = look == "guard"
    cols = 4 if rank else (10 if s.detail else 6)
    # On an infantryman the lower tunic swings clear along the working thigh.
    # The shorter, opposite skirt shows a different step even from the rear.
    for front in (True,False):
        center=.12 if front else pi-.34
        span=2.13 if front else 2.54
        def fold(u,v):
            d=1.-v
            a=center+(u-.5)*span+.24*d
            # Measured curvature of the cut piece, from a low left corner to
            # the opposite outer hip. Its lower edge is neither a cone nor a point.
            if front:
                low=.462+.218*u+.085*abs(2*u-1.)**2
            else:
                low=.465+.137*(1.-u)+.082*abs(2*u-1.)**2
            if guard: low+=.052
            y=.939+(low-.939)*d
            radius=(.205 if guard else .174)+(.088 if guard else .092)*d
            depth=(.163 if guard else .145)+.079*d
            turn=.029*sin(2*pi*u-.80*d)*d
            x=(radius+turn)*sin(a)
            z=-.022+(depth+turn)*cos(a)+(.011 if front else -.012)
            side=min(1.,abs(x)/.21)
            return (x,y,z),(THIGHS[0] if x<0 else THIGHS[1],HIPS,d*(.16+.38*side))
        # The broad outer panel is one fabric. A turned facing catches the
        # light under a diagonal fold as the crossed skirts open.
        for lo,hi,material in ((0.,.14,"felt"),(.14,1.,"overskirt" if front else "coat")):
            s.grid(max(1,round(cols*(hi-lo))),2 if rank else 4,
                   lambda u,v:fold(lo+(hi-lo)*u,v),material)


def player_half_mantle(s, rank=False):
    """A shoulder cloth cut to fall on the left of the sword hand and girdle."""
    # Each horizontal station follows the shoulder, then settles against the ribs.
    # The free left-back corner is longest; the front hem finishes above the elbow.
    # The short point passes over the upper arm. Back cloth then opens away
    # from the shoulder blade and comes to rest beside the rear girdle.
    stations = ((1.467,.098,.093), (1.443,.166,.135), (1.404,.228,.173),
                (1.341,.270,.213), (1.255,.270,.236), (1.163,.250,.229))

    def cut(u, v):
        f = v * (len(stations)-1)
        row = min(int(f), len(stations)-2)
        blend = f-row
        y, width, depth = (a+(b-a)*blend for a,b in zip(stations[row],stations[row+1]))
        angle = -.36-2.76*u-v*(.63-.79*u)
        shoulder=max(0.,-sin(angle))
        back=max(0.,-cos(angle))
        # Weigh a long back corner against a shorter front point. The hem is
        # a continuously cut curve rather than separate hanging strips.
        y+=v*v*(.092*(1.-u)-.215*back**.82-.035*shoulder)
        fold=.014*sin(2.40*pi*u-.52*v)*sin(.91*pi*v)
        breath=sin(pi*v)*shoulder
        x=(width+fold+.010*breath)*sin(angle)
        z=-.012+(depth+fold)*cos(angle)-.084*back*v*v
        # Shoulder motion near the seam rolls into the thorax. The lower
        # back of the mantle is held by its own weight against the girdle.
        arm=.235*shoulder*sin(pi*min(1.,v/.80))*(1.-.69*back) if v<.80 else 0.
        skin=(LEFT_UPPER_ARM,CHEST,arm) if arm>.005 else (CHEST,HIPS,1.-.27*v*v)
        return (x,y,z),skin

    divisions = 4 if rank else (11 if s.detail else 7)
    height = 4 if rank else 7
    for start,end,cloth in ((0.,.85,"mantle"),(.85,1.,"hero_mantle")):
        def panel(u,v):
            return cut(start+(end-start)*u,v)
        s.grid(max(1,round(divisions*(end-start))),height,panel,cloth)
