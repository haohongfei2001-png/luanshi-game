"""Skirt plates of the river-company cuirass."""
from math import cos, pi, sin

from figure_mesh import TAU


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
