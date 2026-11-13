"""Fitted river-gate issue armour. The same profiles are sampled at all three camera distances."""
from math import cos, pi, sin

from figure_mesh import TAU


def field_helmet(surface, look, bone, rank=False):
    """A raised comb, brow band and hinged cheek/nape coverage leave the face open."""
    sides = 8 if rank else (28 if surface.detail else 14)
    senior = look in ("officer", "player")
    # Forehead, sides and nape sit at different heights over the actual head sculpt.
    def brow(angle):
        return 1.626 + .029 * cos(angle) - .008 * sin(angle) ** 2

    sections = ((0., .112, .127), (.17, .114, .125), (.49, .101, .117),
                (.77, .079, .092), (.93, .040, .062), (1., .003, .012))
    if rank:
        sections = tuple(sections[i] for i in (0, 2, 3, 5))

    def crown(u, v):
        angle = TAU * u
        t, rx, rz = sections[round(v * (len(sections) - 1))]
        y0 = brow(angle)
        y = y0 + (1.757 - y0) * t
        return (rx * sin(angle), y, .020 + rz * cos(angle) - .018 * t), bone
    surface.grid(sides, len(sections) - 1, crown, "black_iron")

    def rim(u, v):
        angle = TAU * u
        y = brow(angle) - .006 + .019 * v
        return (.115 * sin(angle), y, .019 + .130 * cos(angle)), bone
    surface.grid(sides, 1, rim, "iron_binding")

    # The overlapping cheek flaps are separate from the crown. Their swept front
    # opens away from the mouth; the lower rear edge clears the collar on a turn.
    for side in (-1, 1):
        def flap(u, v):
            angle = side * (.84 + 2.315 * u + .19 * (1. - v))
            drop = (.057 + .073 * sin(pi * u) ** .65 + .029 * u) * (1. - v)
            radius = .110 + .011 * sin((1. - v) * pi) - .013 * (1. - v)
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
            width=.204+flare
            depth=.155+.91*flare
            return ((width*sin(angle),y,-.014+depth*cos(angle)),
                    (thigh,hips,.64*down))
        def iron(u,v): return point(u,1.-v)
        def binding(u,v): return point(u,1.06-.06*v)
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
