"""Complete structural gate portal, not decorative scatter or a new gameplay obstacle.
Use existing authored arch geometry and licensed stone/timber families. Runtime door
parts remain exclusively under the original HP-controlled GateDoor pivot.
"""
import math,bpy

def build_vault(mesh,pt,gate,R,cz,angle):
    # Real depth courses, rather than 6.8m-long individual voussoir stones.
    start,end=46.43,53.45;courses=11
    for depth in range(courses):
        x0=start+(end-start)*depth/courses+.006
        x1=start+(end-start)*(depth+1)/courses-.006
        for i in range(17):
            a=-angle+2*angle*i/17+.001
            b=-angle+2*angle*(i+1)/17-.001
            vertices=[pt(x,cz+r*math.cos(t),r*math.sin(t)) for x in [x0,x1] for r,t in [(R,a),(R,b),(R+.55,b),(R+.55,a)]]
            obj=mesh('GateVault_course%02d_stone%02d'%(depth,i),vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'masonry',gate)
            obj['structural_role']='load-bearing segmented barrel arch; depth course and radial joint'

def build_leaves(mesh,box,beam,pt,gate,door,R,cz):
    def roof(z):return cz+math.sqrt(max(0.,R*R-z*z))-.07
    def softened(obj,width=.008):
        bevel=obj.modifiers.new('real carpentry edge','BEVEL');bevel.width=width;bevel.segments=2
        bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=bevel.name);obj.select_set(False)
    for sign in [-1,1]:
        # Both jambs outside the protected z±4 opening, no raised road threshold.
        for row in range(7):
            box('PortalJamb_quoins',(46.48,.30+row*.60,sign*4.24),(.34,.588,.42),'masonry',gate,.018)
        # Two curved-top leaves close the actual arch reveal, with individual
        # full-height tongue-and-groove boards and deliberate narrow seam.
        for i in range(13):
            a=.025+(3.955/13)*i+.004;b=.025+(3.955/13)*(i+1)-.004
            za,zb=sorted([sign*a,sign*b]);topa,topb=roof(za),roof(zb)
            vertices=[pt(x,y,z) for x in [47.87,48.13] for y,z in [(.035,za),(.035,zb),(topb,zb),(topa,za)]]
            o=mesh('PortalLeaf_%s_board_%02d'%(sign,i),vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'timber',door)
            softened(o);o['structural_role']='full-height curved-top gate leaf board; no gameplay lift'
        for z,width in [(sign*.13,.19),(sign*3.83,.23)]:
            height=roof(z)-.07
            box('PortalLeaf_stile',(48.18,.035+height*.5,z),(.19,height,width),'timber_cut',door,.012)
        for y in [.72,2.12,3.52]:
            # Inside ledges and a continuous exterior strap describe one joined
            # leaf. They are not arbitrary ornamental studs over a solid plane.
            box('PortalLeaf_inner_ledge',(48.24,y,sign*1.99),(.19,.22,3.86),'timber',door,.015)
            box('PortalLeaf_forged_band',(47.82,y,sign*1.99),(.055,.105,3.87),'iron',door,.010)
            for i in range(6):
                box('PortalLeaf_band_pin',(47.779,y,sign*(.30+i*.66)),(.035,.045,.045),'iron',door,.006)
            box('PortalHinge_fixed_eye',(47.98,y,sign*4.08),(.38,.17,.16),'iron',gate,.012)
            box('PortalHinge_leaf_pin',(47.99,y,sign*3.94),(.18,.25,.16),'iron',door,.016)
        beam('PortalLeaf_inner_diagonal',(48.36,.78,sign*3.73),(48.36,3.45,sign*.27),.17,.14,'timber',door)
    return {'version':'complete-arched-two-leaf-portal-01','door_bottom_m':.035,'door_top_center_m':roof(0.),'clear_opening_width_m':8.,'arch_depth_courses':11,'radial_stones_per_course':17,'closed_leaf_board_count':26,'road_threshold_added':False,'art':'NOT_ACCEPTED'}
