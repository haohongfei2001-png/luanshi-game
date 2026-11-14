"""Cut and hang the River Gate field coats on their original Wildfire armholes.

The dappled commercial-style reference is a silhouette guide only. New geometry
comes from actual measured fitted issue sections; no pixels from it enter the game.
"""
from math import cos, sin, pi
import numpy as np
from company_figures import HIPS, CHEST, LT, RT

def saturate(v):
    return max(0., min(1., v))

def original_uv(role, x, y):
    slot={"Regular":0,"Guard":1,"Archer":2}[role]
    return (2.+((slot%2)*264.+4.5+255.*saturate(x))/528.,
            ((slot//2)*264.+4.5+255.*saturate(y))/528.)

def clip_body(source, seam):
    """Clip the old closed cylinder at the binding; keep upper issue, sleeves and UVs."""
    from figure_mesh import Surface
    out=Surface()
    used={}
    for face in source.faces:
        vertices=[]
        for i in face:
            uv=source.tex[i]; encoded=source.joints[i]; joint=int(encoded[0]*1024)
            vertices.append((np.asarray(source.positions[i]),np.asarray(uv),(joint//32,joint%32,encoded[1])))
        clip=[]
        for i,current in enumerate(vertices):
            prev=vertices[i-1]
            keep=current[0][1]>=seam
            other=prev[0][1]>=seam
            if keep!=other:
                t=(seam-prev[0][1])/(current[0][1]-prev[0][1])
                clip.append((prev[0]+t*(current[0]-prev[0]), prev[1]+t*(current[1]-prev[1]),(HIPS,HIPS,1.)))
            if keep: clip.append(current)
        ids=[]
        for p,uv,bones in clip:
            key=tuple(round(v,6) for v in (*p,*uv,*bones))
            if key not in used:
                used[key]=out.vertex(tuple(p),tuple(uv),bones)
            ids.append(used[key])
        for j in range(1,len(ids)-1): out.faces.append((ids[0],ids[j],ids[j+1]))
    return out

def refit_issue(source,role):
    # A tailored robe hangs from a cinched waist. The two front gores overlap
    # at the belt and separate at the working knee; the back retains a wider
    # panel and two small side openings. No face stretches from thigh to thigh.
    seam=.968
    out=clip_body(source,seam)
    heavy=role=="Guard"
    archer=role=="Archer"
    # Measure real upstream cross-sections at the hip. Its eight waist vertices
    # are intentionally slightly asymmetric; carry that forward on all panels.
    hip=np.array([v for v in source.positions if abs(v[1]-.962)<.025 and abs(v[0])<.27])
    center_z=(hip[:,2].min()+hip[:,2].max())*.5
    waist_x=max(abs(hip[:,0]))+.010
    waist_z=np.ptp(hip[:,2])*.5+.010
    def add_grid(cols,rows,fn,reverse=False):
        grid=[]
        for j in range(rows+1):
            grid.append([])
            for i in range(cols+1):
                xyz,uv,bones=fn(i/cols,j/rows)
                grid[-1].append(out.vertex(tuple(xyz),uv,bones))
        for j in range(rows):
            for i in range(cols):
                a,b=grid[j][i:i+2]
                d,c=grid[j+1][i:i+2]
                # Row zero is the belt. Reverse the descending parameter order.
                out.quad(d,c,b,a) if not reverse else out.quad(a,b,c,d)
    def textile(a, h):
        # Map the concave garment folds to the upstream dye, keeping the
        # largely untextured cloth of the lower han sheet separate from iron.
        return original_uv(role,(a/(2*pi)+.5)%1.,.883+.076*h)
    # All three take a generous sleeve-to-waist taper; heavy cloth is short
    # underneath the separate pair of laced hip pieces.
    for part in ("left_front","right_front","back"):
        left=part=="left_front"
        back=part=="back"
        def panel(u,d):
            if back:
                start=1.48+.32*d; end=4.83-.27*d
                a=start+(end-start)*u
                hem=(.545 if archer else .497)+.105*abs(2*u-1.)**1.45
                follow=.19+.21*abs(sin(a))
            elif left:
                start=-1.69+.27*d; end=.17-.52*d
                a=start+(end-start)*u
                hem=(.49 if archer else .45)+.18*(1.-u)**1.7+.13*u**2
                follow=.25+.40*abs(sin(a))
            else:
                start=-.10+.52*d; end=1.67-.27*d
                a=start+(end-start)*u
                hem=(.56 if archer else .52)+.135*(1.-u)**2+.10*u**2
                follow=.27+.43*abs(sin(a))
            if heavy: hem+=.060
            # Small angular stagger opens the working side and keeps the tail
            # weighted toward the rear, avoiding a rotationally symmetric bell.
            a+=.115*d*(1. if back else -.65)
            fullness=sin(pi*d)
            crease=.021*cos((4 if back else 2)*pi*u+.55*d)*(.15+.85*d)
            rx=waist_x*(1.-.092*sin(pi*min(1.,d/.26)))+.036*d+.033*d*d+crease
            rz=waist_z+.052*d+.024*fullness+crease*.87
            if back: rz+=.016*d
            y=seam+.012+(hem-seam-.012)*d+.016*fullness*(cos(2*pi*u)+.25)
            x=sin(a)*rx
            z=center_z+cos(a)*rz-(.017+.032*max(0.,-cos(a)))*d
            if not back and not left: z-=.012*(1.-d)
            thigh=RT if x>=0 else LT
            bone=(thigh,HIPS,follow*d**.93)
            return (x,y,z),textile(a,d),bone
        add_grid(9 if back else 6,4,panel)
    if heavy:
        # The shield course is rigid laced armour suspended over the soft
        # dark tunic, with daylight at its front and real openings at the hips.
        for side in (-1,1):
            def lames(u,d):
                a=(.49+.20*d)+(2.52-.31*d)*u
                # For the negative half build in increasing angular order.
                if side<0: a=-((.49+.20*d)+(2.52-.31*d)*(1.-u))
                x=(waist_x+.019+.048*d)*sin(a)
                z=center_z+(waist_z+.031+.046*d)*cos(a)-.023*d
                y=.982-(.255+.035*sin(pi*u))*d+.035*d*abs(2*u-1.)**2
                uu=.12+.70*u
                vv=.583+.185*d
                return (x,y,z),original_uv(role,uu,vv),(RT if side>0 else LT,HIPS,.51*d)
            add_grid(7,3,lames)
    if archer:
        # The workman's collar folds diagonally across the chest and returns to
        # the girdle on the left. Measure the stitched front from the published
        # garment rather than drawing a broad X through the cuirass or the skin.
        face_points=np.array([source.positions[i] for tri in source.faces
                              for i in tri if source.positions[i][2]>.025])
        def fronts(x,y):
            dx=(face_points[:,0]-x)/.22
            dy=(face_points[:,1]-y)/.24
            distance=dx*dx+dy*dy
            ii=np.argsort(distance)[:6]
            weight=1./(distance[ii]+.0025)
            return np.dot(weight,face_points[ii,2])/sum(weight)
        for long_side in (False,True):
            spine=((-.075,1.452),(-.090,1.395),(-.033,1.321),(.040,1.256)) if not long_side else ((.075,1.458),(.098,1.400),(.051,1.335),(-.009,1.265),(-.076,1.173),(-.145,1.060),(-.154,1.003))
            def facing(u,d):
                h=d*(len(spine)-1)
                i=min(int(h),len(spine)-2)
                (x0,y0),(x1,y1)=spine[i:i+2]
                k=h-i
                x=x0+(x1-x0)*k
                y=y0+(y1-y0)*k
                norm=np.hypot(y1-y0,x1-x0)
                width=.023*(.77+.23*sin(pi*d))
                x+=width*(2*u-1.)*(y1-y0)/norm
                y-=width*(2*u-1.)*(x1-x0)/norm
                z=fronts(x,y)+.012+(.010 if long_side else .001)+.006*sin(pi*u)
                return (x,y,z),original_uv(role,.214+.085*u,.55+.16*d),(CHEST,HIPS,saturate((y-.914)/.32))
            add_grid(2,len(spine)-1,facing,reverse=True)
    # Continuous waist tie over the join uses one existing upstream leather
    # course, keeping the two large dyed fields separate at everyday distance.
    def belt(u,d):
        a=2*pi*u
        y=.992-.048*d-.013*sin(a+.55)
        r=.005*sin(pi*d)
        return ((waist_x+.006+r)*sin(a),y,center_z+(waist_z+.007+r)*cos(a)),original_uv(role,u,.744+.026*d),(HIPS,CHEST,1.)
    add_grid(16,2,belt)
    return out
