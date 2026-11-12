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


def shoulders(surface, look, chest, upper_arms, rank=False):
    """A narrow shoulder suspension turns into a broad, mobile upper-arm defence."""
    light = look == "regular"
    for side, upper in zip((-1,1), upper_arms):
        def form(u, v):
            a = (u - .5) * pi * 1.23
            lower = 1.249 if light else 1.195
            ry = sin(pi * v)
            cx = .257 - .086 * v ** 1.55
            rx = .088 - .057 * v + .023 * ry
            rz = .103 - .034 * v + .010 * ry
            y = lower + (1.436 - lower) * v + .036 * (1. - cos(a)) * (1. - v)
            return (side * (cx + rx * cos(a)), y, -.003 + rz * sin(a)), (upper, chest, 1. - .84 * v ** 2)
        n = 4 if rank else (12 if surface.detail else 7)
        surface.grid(n, 2 if rank else 4, form, "lames")
        if not rank:
            def binding(u, v):
                p, joints = form(u, .014 + .060 * v)
                return (p[0] + side * .0018, p[1], p[2] + (u - .5) * .0024), joints
            surface.grid(n, 1, binding, "iron_binding")


def skirts(surface, look, hips, thighs, rank=False):
    """Left and right panels are suspended at the waist and can follow a stride independently."""
    light = look == "regular"
    length = .271 if light else .352
    n = 4 if rank else (12 if surface.detail else 6)
    for side, thigh in zip((-1,1), thighs):
        def panel(u,v):
            edge = .064 + .116 * (1. - v) ** 1.7
            angle = side * (edge + (pi - 2. * edge) * u)
            front = (.5 + .5 * cos(angle))
            y = .951 - length * (1. - v) + .036 * (1.-v) * (front ** 3 + (1.-front) ** 3)
            width = .204 + .065 * (1. - v)
            depth = .157 + .053 * (1. - v)
            return (width * sin(angle), y, -.014 + depth * cos(angle)), (thigh, hips, .58 * (1.-v))
        surface.grid(n, 1 if rank else 3, panel, "lames")
