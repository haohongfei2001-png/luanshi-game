"""A complete enclosed fort, built within the existing gameplay wall footprints.
This is a fictional late-Tang-inspired military compound, NOT an archaeological
reconstruction. Door, bridge, front wall-walk and retreat postern remain real.
"""
import math

def prism(mesh,pt,name,low,high,mat,parent):
    # Godot-coordinate rectangular footprints with independent vertical edge heights.
    xa,xb,za,zb,bottom=low;ha,hb=high
    vertices=[pt(x,y,z) for x in [xa,xb] for y,z in [(bottom,za),(bottom,zb),(hb,zb),(ha,za)]]
    return mesh(name,vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,parent)

def build(mesh,box,beam,pt,walls):
    floor=3.25; parapet_top=4.24; merlon_top=4.77
    # Front facing sits entirely inside WALL_X±1.4. The wall is not a thin
    # decorative screen: a sloped, solid internal backing carries the real ramp.
    for sign in [-1,1]:
        za,zb=sorted([sign*8.15,sign*23.98])
        prism(mesh,pt,'FortFrontContinuousMass',(46.62,49.38,za,zb,-.55),(floor,floor),'masonry',walls)
        # Long inner ramp continues only to the real Ground.parapet endpoint21.8,
        # not old visual23.0. Each top edge uses the exact shared height formula.
        count=34; start=5.5;end=21.8
        for i in range(count):
            a=start+(end-start)*i/count;b=start+(end-start)*(i+1)/count
            ya=min(floor,(a-5.5)*.43);yb=min(floor,(b-5.5)*.43)
            z0,z1=sorted([sign*a,sign*b]);h0,h1=(ya,yb) if sign>0 else (yb,ya)
            ob=prism(mesh,pt,'FortInnerRampCore',(49.4,52.6,z0,z1,-.55),(h0,h1),'masonry',walls)
            ob['role']='full support below exact existing navigable wall-walk, no new walking surface claim'
        # Parapet is broad continuous masonry, with substantial alternating
        # merlons, not skinny disconnected blocks sitting on a hollow plane.
        box('FortFrontParapet',(47.06,(floor+parapet_top)/2,(za+zb)/2),(.88,parapet_top-floor,zb-za),'masonry',walls,.02)
        count=8;pitch=(zb-za)/count
        for i in range(count):
            box('FortFrontMerlon',(47.06,(parapet_top+merlon_top)/2,za+(i+.5)*pitch),(.92,merlon_top-parapet_top,pitch*.54),'masonry',walls,.025)
    # Return walls reveal the fort's actual depth (Ground side walls at z±23).
    # Their complete core is inside the existing blocked strip; no hidden new
    # navigation obstruction or inaccessible pretend walk lane is introduced.
    for sign in [-1,1]:
        z0,z1=sorted([sign*21.82,sign*23.98]);xa,xb=49.38,87.82
        prism(mesh,pt,'FortReturnWallCore',(xa,xb,z0,z1,-.55),(floor,floor),'masonry',walls)
        outside=sign*23.46
        box('FortReturnParapet',((xa+xb)/2,(floor+parapet_top)/2,outside),(xb-xa,parapet_top-floor,.88),'masonry',walls,.02)
        count=18;pitch=(xb-xa)/count
        for i in range(count):box('FortReturnMerlon',(xa+(i+.5)*pitch,(parapet_top+merlon_top)/2,outside),(pitch*.54,merlon_top-parapet_top,.92),'masonry',walls,.025)
    # The retreat postern is physically OPEN, matching Ground.POSTERN_HALF1.65.
    # No arbitrary gate prop is placed in its route. Header remains above horses.
    for sign in [-1,1]:
        za,zb=sorted([sign*1.68,sign*23.98])
        prism(mesh,pt,'FortRearWallCore',(87.82,90.18,za,zb,-.55),(floor,floor),'masonry',walls)
        box('FortRearParapet',(89.62,(floor+parapet_top)/2,(za+zb)/2),(.88,parapet_top-floor,zb-za),'masonry',walls,.02)
        count=11;pitch=(zb-za)/count
        for i in range(count):box('FortRearMerlon',(89.62,(parapet_top+merlon_top)/2,za+(i+.5)*pitch),(.92,merlon_top-parapet_top,pitch*.54),'masonry',walls,.025)
    for sign in [-1,1]:
        box('FortRearPosternShoulder',(89.,3.475,sign*2.02),(2.36,.45,.68),'masonry',walls,.015)
    box('FortRearPosternHeader',(89.,3.97,0),(2.36,.54,4.72),'masonry',walls,.025)
    return {'variant':'complete-fort-enclosure-02','front_gate_clear_width_m':8,'postern_clear_width_m':3.36,'postern_clear_height_m':3.7,'front_wall_x':[46.62,49.38],'return_wall_z_abs':[21.82,23.98],'return_wall_x':[49.38,87.82],'rear_wall_x':[87.82,90.18],'actual_wallwalk_x':[49.4,52.6],'actual_wallwalk_z_abs':[5.5,21.8],'new_blocking_footprint':False,'upper_gallery_walkable_in_simulation':False,'status':'EXPERIMENTAL_NOT_ART_ACCEPTED'}

def build_upper_hall(box,beam,gate,floor,head,lines):
    """Whole room/front-gallery plan replaces a flat fence of narrow black slots.
    Original professional roof/frame/columns remain; no material brightness change.
    This structural upper space is not newly advertised as a simulated actor route.
    """
    front,back=49.05,51.77
    # Rear weather wall and closed end walls make a real three-bay sheltered hall.
    for first,last in zip(lines,lines[1:]):
        for j in range(12):
            z=first+(j+.5)*(last-first)/12
            box('FortHallRearBoard',(back,floor+1.03,z),(.10,2.02,(last-first)/12-.008),'timber',gate,.008)
        beam('FortHallRearSill',(back,floor+.10,first),(back,floor+.10,last),.20,.18,'timber_cut',gate)
    for sign in [-1,1]:
        z=sign*7.09
        for j in range(9):
            x=front+(j+.5)*(back-front)/9
            box('FortHallEndBoard',(x,floor+1.03,z),((back-front)/9-.008,2.02,.10),'timber',gate,.008)
    # Two side rooms have broad framed openings, a low boarded wall and recessed
    # shutters. The central bay has a genuinely open1.60m door, not a painted gap.
    for bay,(first,last) in enumerate(zip(lines,lines[1:])):
        middle=(first+last)/2
        if bay==1:
            for a,b in [(first,middle-.8),(middle+.8,last)]:
                count=max(1,round((b-a)/.30))
                for j in range(count):box('FortHallDoorSide',(front,floor+1.03,a+(j+.5)*(b-a)/count),(.10,2.02,(b-a)/count-.008),'timber',gate,.008)
            for z in [middle-.84,middle+.84]:beam('FortHallDoorJamb',(front,floor+.04,z),(front,head-.07,z),.17,.17,'timber_cut',gate)
            beam('FortHallDoorHead',(front,head-.1,middle-.92),(front,head-.1,middle+.92),.20,.20,'timber_cut',gate)
        else:
            for j in range(12):box('FortHallWindowApron',(front,floor+.40,first+(j+.5)*(last-first)/12),(.10,.74,(last-first)/12-.008),'timber',gate,.008)
            for y in [floor+.78,head-.12]:beam('FortHallWindowHorizontal',(front,y,first),(front,y,last),.15,.16,'timber_cut',gate)
            for z in [first+.22,middle,last-.22]:beam('FortHallWindowUpright',(front,floor+.8,z),(front,head-.14,z),.14,.14,'timber_cut',gate)
        beam('FortHallInnerSill',(front,floor+.05,first),(front,floor+.05,last),.20,.18,'timber_cut',gate)
    # Connected waist railing only at the exposed ends of the front gallery;
    # front bays remain open to show the actual columns and structural depth.
    for sign in [-1,1]:
        z=sign*7.09
        beam('FortGalleryEndRail',(47.96,floor+.98,z),(front,floor+.98,z),.14,.14,'timber_cut',gate)
        for x in [48.22,48.58,48.92]:beam('FortGalleryEndUpright',(x,floor+.1,z),(x,floor+.98,z),.08,.08,'timber',gate)
    return {'room_plan':'three-bay sheltered hall with1.09m-deep front gallery and open central door','front_enclosure_x':front,'rear_enclosure_x':back,'central_clear_door_m':1.6,'original_native_columns_frames_roof_preserved':True,'material_brightness_changed':False,'simulated_upper_route':'NOT_ADDED'}
