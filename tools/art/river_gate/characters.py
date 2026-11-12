"""River Gate art pack: proportion-corrected, layered, editable character library.

Run with Blender 4.3+: blender -b --python tools/art/river_gate/characters.py -- --sample
Then without --sample to build the complete two-army library.

Reuses this project's original surface/weapon and two-link motion authorship, not
the legacy exported meshes. New tailoring, plate geometry, proportions, materials,
standard glTF skins and animation are authored here. Nothing replaces live battle art.
"""
from pathlib import Path
import argparse, json, math, struct, sys, hashlib
from math import sin, cos, pi
import bpy
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/art'))
import figure_atlas as atlas
import company_figures as cf
import company_weapons as cw
import company_motion as motion
from figure_mesh import Surface, add, sub, lerp

OUT = ROOT / 'assets/river_gate/art_v1'
DOC = ROOT / 'docs/art/river-gate-20261113'
ROLES = {
 'recruit':('levy',2,'征募兵',False),
 'spearman':('guard',3,'枪兵',False),
 'shieldman':('guard',7,'刀剑盾兵',False),
 'archer':('archer',5,'弓兵',False),
 'crossbowman':('archer',6,'弩兵',False),
 'guard':('guard',1,'重装近卫',False),
 'cavalry':('guard',3,'轻骑乘员',False),
 'engineer':('levy',2,'工兵与辎重护兵',False),
 'captain':('officer',0,'队正',True),
 'vanguard':('officer',4,'先锋',True),
 'challenger':('player',8,'锐将',True),
 'commander':('officer',0,'主将',True),
}
BONE_NAMES = ['pelvis','chest','head','upper_arm.L','forearm.L','hand.L',
              'upper_arm.R','forearm.R','hand.R','thigh.L','shin.L','foot.L',
              'thigh.R','shin.R','foot.R','bow_nock']
CLIPS = [('idle',1,1.8),('walk',0,1.0),('run',0,.64),('attack',2,1.05),
         ('guard',10,1.0),('hit',11,.45),('death',14,1.4),('command',1,1.5),
         ('riding',15,1.0),('rout',12,.72)]
C = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))

def body_map(p):
    """Metre-preserving redesign: longer legs, modest shoulders, 7.4-head adult."""
    x,y,z=p
    levels=[(0.,0.),(.123,.123),(.477,.514),(.858,.930),(1.008,1.075),
            (1.405,1.444),(1.46,1.495),(1.8,1.81)]
    yy=y
    for (a,b),(c,d) in zip(levels,levels[1:]):
        if a<=y<=c:
            yy=b+(d-b)*(y-a)/(c-a);break
    return (x*.90, yy, z*.88)

def map_point(p, a=None, is_weapon=False):
    if is_weapon:
        # Keep actual blade/shaft lengths; only relocate the grip to the new wrist.
        bone=cf.LH if a==cf.LH else cf.RH
        g=cf.grip(-1 if bone==cf.LH else 1)
        return add(body_map(g),sub(p,g))
    if a==cf.HEAD:
        x,y,z=p
        # Head height .230 m versus adult height 1.74 m. Helmet is not head height.
        zz=z*.74
        if abs(x)<.045 and z>.157 and 1.51<y<1.62:
            zz=.157*.74+(z-.157)*.47
        return (x*.75,1.505+(y-1.425)*.75,zz)
    if a in (cf.LH,cf.RH):
        g=cf.grip(-1 if a==cf.LH else 1)
        return add(body_map(g),tuple(v*.79 for v in sub(p,g)))
    return body_map(p)

def decode_skin(v):
    n=int(v[0]*1024)
    return n//32,n%32,max(0.,min(1.,v[1]))

def layered_torso(s,role,faction):
    full=s.detail
    armoured=role not in ('recruit','archer','engineer')
    heavy=role in ('guard','vanguard','commander')
    n=24 if full else 12
    def bind(p):
        return (cf.CHEST,cf.HIPS,max(0,min(1,(p[1]-.91)*3.4)))
    def fold(p,a,j):
        x,y,z=p
        f=.007*sin(9*a+.43*j)+.003*sin(17*a-.5*j)
        return (x+sin(a)*f,y,z+cos(a)*f)
    # Fitted upper coat, crossing collar and separate hanging panels, not a barrel.
    s.rings([(.881,.176,.128,0,.002),(.925,.175,.129,0,0),
             (1.05,.184,.137,0,0),(1.17,.213,.145,0,0),
             (1.30,.232,.131,0,-.005),(1.379,.212,.102,0,-.012),
             (1.437,.077,.068,0,.003)],'dyed',bind,n,fold)
    hem=.59 if role in ('archer','crossbowman','cavalry','challenger') else .53
    # Front split and lateral overlap remain open enough for a full stride.
    for k,(a0,a1) in enumerate([(-1.52,-.055),(.055,1.52),(1.49,3.12),(-3.12,-1.49)]):
        def skirt(u,v,a0=a0,a1=a1,k=k):
            a=a0+(a1-a0)*u
            yy=hem+v*(.93-hem)+.018*cos(a*3)*(1-v)
            r=.232-(.232-.178)*v
            f=.009*sin(u*5*pi+.5*k)*(1-v*.55)
            p=(sin(a)*(r+f),yy,cos(a)*(.155+f)*(1-.15*v))
            limb=cf.LT if p[0]<0 else cf.RT
            return p,(cf.HIPS,limb,.72+.28*v)
        s.grid(9 if full else 4,5 if full else 2,skirt,'dyed')
        # A darker turned hem makes each layer legible at ordinary game distance.
        pts=[]
        for j in range(10):
            a=a0+(a1-a0)*j/9
            pts.append((sin(a)*.237,hem+.018*cos(a*3),cos(a)*.161))
        s.tube(pts,[.006]*len(pts),'lining',cf.HIPS,5)
    for side in (-1,1):
        s.ribbon([(side*.072,1.44,.065),(side*.116,1.365,.111),
                  (side*.105,1.304,.15),(-side*.03,1.207,.158),
                  (-side*.145,1.076,.134)],.032,'linen',cf.CHEST)
    if armoured:
        s.rings([(.96,.184,.14,0,0),(1.06,.199,.153,0,0),
                 (1.22,.229,.162,0,-.004),(1.32,.227,.14,0,-.008),
                 (1.379,.202,.103,0,-.01)],'quilt',bind,n)
        # Individually raised iron plates, three loops per plate in the shared atlas.
        rows=7 if heavy else 5
        for row in range(rows):
            yy=1.015+row*.047
            rx=.20+max(0,yy-1.05)*.11
            rz=.159 if yy<1.29 else .145
            count=20 if full else 12
            for col in range(count):
                a=col*2*pi/count+(row%2)*pi/count
                if not heavy and cos(a)<-.30:continue
                half=.41*(2*pi/count)
                low=yy-.038;high=yy+.024
                # Raised lower rim; outer plate actually projects over the next row.
                points=[(sin(a-half)*rx,low,cos(a-half)*(rz+.006)),
                        (sin(a+half)*rx,low,cos(a+half)*(rz+.006)),
                        (sin(a+half)*rx,high,cos(a+half)*rz),
                        (sin(a-half)*rx,high,cos(a-half)*rz)]
                s.panel(points,'lamellar',cf.CHEST)
                if full and col%2==0:
                    p=points[0];q=points[1]
                    s.tube([p,q],[.0028,.0028],'edge',cf.CHEST,4)
        if heavy:
            for side in (-1,1):
                for row in range(3):
                    yy=.68+row*.07
                    for col in range(4):
                        xx=side*(.048+col*.046)
                        s.panel([(xx-.02,yy,.161),(xx+.02,yy,.161),
                                 (xx+.02,yy+.08,.143),(xx-.02,yy+.08,.143)],
                                'lamellar',cf.LT if side<0 else cf.RT)
    else:
        # Clearly cut vest for scarce-equipment and engineer silhouettes.
        vest='linen' if role=='recruit' else 'felt'
        s.rings([(.98,.184,.14,0,.001),(1.18,.225,.153,0,0),
                 (1.33,.229,.136,0,-.005),(1.38,.197,.098,0,-.01)],vest,bind,n)
    s.rings([(.922,.182,.136,0,.005),(.934,.190,.143,0,.005),
             (.981,.193,.146,0,.005),(.991,.188,.14,0,.005)],'leather',cf.HIPS,n)
    s.panel([(-.031,.94,.152),(.031,.94,.152),(.031,.975,.153),(-.031,.975,.153)],'brass',cf.HIPS)
    # Worn diagonal straps and practical tie ends, not a fantasy cape.
    s.ribbon([(-.17,1.36,.105),(-.11,1.24,.176),(.04,1.08,.177),(.15,.97,.12)],
             .022,'leather',cf.CHEST)
    if role in ('captain','vanguard','commander'):
        s.ribbon([(-.17,1.371,-.075),(-.15,1.24,-.17),(-.16,.99,-.151),(-.21,.73,-.173)],
                 .07,'dyed',cf.CHEST)
        s.ribbon([(.12,.955,.14),(.175,.81,.155),(.16,.65,.162)],.055,'lining',cf.HIPS)
    if role=='engineer':
        s.oval((-.206,.86,.0),(.065,.09,.055),'leather',cf.HIPS,10,6)
        s.tube([(.195,.83,.03),(.20,1.07,.02)],[.013,.013],'timber',cf.HIPS,8)
        s.oval((.20,1.07,.02),(.067,.027,.025),'iron',cf.HIPS,8,4)

def build_surface(role,faction):
    look,kit,_,_=ROLES[role]
    s=Surface(True)
    layered_torso(s,role,faction)
    cf.limbs(s,look)
    cf.head(s,look if role!='engineer' else 'archer')
    if role in ('archer','crossbowman'):
        a,b=(-.145,.82,-.15),(.10,1.35,-.19)
        s.tube([a,lerp(a,b,.1),lerp(a,b,.9),b],[.04,.057,.053,.057],'leather',cf.CHEST,12)
        for i in range(7):
            end=add(b,((i%3-1)*.018,.09+.02*(i%2),(i//3)*.019))
            s.tube([add(end,(-.10,-.3,0)),end],[.003,.003],'timber',cf.CHEST,5)
            s.ribbon([add(end,(-.027,-.06,0)),end],.011,'lining',cf.CHEST)
    if role in ('commander','captain'):
        for side in (-1,1):
            s.tube([(side*.025,1.49,.132),(side*.04,1.46,.118),
                    (side*.022,1.437,.112)],[.017,.018,.003],'hair',cf.HEAD,7)
    return s

def make_textures(faction):
    from PIL import Image, ImageDraw
    import numpy as np
    dst=OUT/'textures';dst.mkdir(parents=True,exist_ok=True)
    atlas.TILE=256;atlas.PAD=8
    # Palette is a military cloth dye, never a different colour of human skin.
    dye=(82,103,112) if faction=='frontier' else (122,76,64)
    stripe=(132,148,148) if faction=='frontier' else (157,111,82)
    atlas.SURFACES=[
      ((171,156,126),(228,0,0)),(dye,(219,0,240)),((77,53,40),(175,0,0)),
      ((78,85,82),(151,175,0)),((83,91,91),(128,205,0)),
      ((151,159,155),(107,218,0)),((139,111,68),(145,175,0)),
      ((119,84,52),(201,0,0)),((177,126,93),(197,0,0)),
      ((40,34,29),(191,0,0)),(stripe,(224,0,0)),
      ((100,98,80),(229,0,0)),((57,43,34),(185,0,0)),
      ((100,76,52),(186,3,0)),((131,112,82),(216,0,0)),
      ((92,96,84),(236,0,0))]
    work=OUT/'source'/('texture_work_'+faction);work.mkdir(parents=True,exist_ok=True)
    atlas.make_atlas(work)
    al=Image.open(work/'cloth_and_iron.png').convert('RGB')
    response=Image.open(work/'surface_response.png').convert('RGB')
    arr=np.asarray(al,dtype=np.float32)
    # Subtle micro normal. Macro folds are geometry, not baked fake illumination.
    lum=arr.mean(axis=2)/255
    gx=np.roll(lum,-1,1)-np.roll(lum,1,1);gy=np.roll(lum,-1,0)-np.roll(lum,1,0)
    norm=np.stack([-gx*.7,gy*.7,np.ones_like(gx)],axis=2)
    norm/=np.linalg.norm(norm,axis=2,keepdims=True)
    normal=Image.fromarray(np.uint8(np.clip(norm*.5+.5,0,1)*255))
    r,g,b=response.split()
    orm=Image.merge('RGB',(Image.new('L',al.size,255),r,g))
    al.save(dst/f'{faction}_albedo.png',optimize=True)
    normal.save(dst/f'{faction}_normal.png',optimize=True)
    orm.save(dst/f'{faction}_orm.png',optimize=True)
    for p in work.iterdir():p.unlink()
    work.rmdir()

def material(faction):
    name='river_'+faction+'_shared_PBR'
    if name in bpy.data.materials:return bpy.data.materials[name]
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nt=mat.node_tree;bsdf=nt.nodes.get('Principled BSDF')
    for suffix,space in [('albedo','sRGB'),('orm','Non-Color'),('normal','Non-Color')]:
        img=bpy.data.images.load(str(OUT/'textures'/f'{faction}_{suffix}.png'),check_existing=True)
        img.colorspace_settings.name=space
        tex=nt.nodes.new('ShaderNodeTexImage');tex.image=img;tex.label=suffix
        if suffix=='albedo':nt.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
        elif suffix=='orm':
            sep=nt.nodes.new('ShaderNodeSeparateColor');nt.links.new(tex.outputs['Color'],sep.inputs['Color'])
            nt.links.new(sep.outputs['Green'],bsdf.inputs['Roughness'])
            nt.links.new(sep.outputs['Blue'],bsdf.inputs['Metallic'])
        else:
            nm=nt.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.35
            nt.links.new(tex.outputs['Color'],nm.inputs['Color']);nt.links.new(nm.outputs['Normal'],bsdf.inputs['Normal'])
    return mat

def surface_mesh(name,s,mat,is_weapon=False,role=None):
    verts=[];weights=[]
    for p,j in zip(s.positions,s.joints):
        a,b,w=decode_skin(j)
        q=map_point(p,a,is_weapon)
        # Three modest body builds; no giant officers or inflated heads.
        fac=.955 if role in ('recruit','archer','challenger') else 1.035 if role in ('guard','vanguard') else 1.
        if a!=cf.HEAD and not is_weapon:q=(q[0]*fac,q[1],q[2]*fac)
        verts.append((q[0],-q[2],q[1]));weights.append((a,b,w))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],s.faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    uv=mesh.uv_layers.new(name='UVMap')
    # Source authoring uses top-down bitmap coordinates; Blender UV is bottom-up.
    for poly in mesh.polygons:
        poly.use_smooth=True
        for li in poly.loop_indices:
            st=s.tex[mesh.loops[li].vertex_index];uv.data[li].uv=(st[0],1-st[1])
    obj.data.materials.append(mat)
    groups=[obj.vertex_groups.new(name=n) for n in BONE_NAMES]
    for i,(a,b,w) in enumerate(weights):
        if a==b:groups[a].add([i],1.,'REPLACE')
        else:
            if w>0:groups[a].add([i],w,'REPLACE')
            if w<1:groups[b].add([i],1-w,'REPLACE')
    # Merge exact UV seam positions (not folds) for stable smooth normals.
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    return obj

def rig_for(name):
    ad=bpy.data.armatures.new(name+'_skeleton');rig=bpy.data.objects.new(name+'_rig',ad)
    bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig
    rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    root=ad.edit_bones.new('root');root.head=(0,0,0);root.tail=(0,0,.15)
    pts={cf.HIPS:((0,.86,0),(0,1.008,0)),cf.CHEST:((0,1.008,0),(0,1.405,0)),
         cf.HEAD:((0,1.425,.015),(0,1.736,.015)),
         cf.NOCK:(add(cf.grip(1),(0,0,-.159)),add(cf.grip(1),(0,.07,-.159)))}
    for side in (-1,1):
        a,b,c=cf.arm_nodes(side);u,f,h=(cf.LU,cf.LF,cf.LH) if side<0 else (cf.RU,cf.RF,cf.RH)
        pts[u]=(a,b);pts[f]=(b,c);pts[h]=(c,add(c,(0,-.08,.02)))
        a,b,c=cf.leg_nodes(side);u,f,h=(cf.LT,cf.LS,cf.LB) if side<0 else (cf.RT,cf.RS,cf.RB)
        pts[u]=(a,b);pts[f]=(b,c);pts[h]=(c,add(c,(0,-.04,.16)))
    for i,n in enumerate(BONE_NAMES):
        b=ad.edit_bones.new(n);a0,b0=pts[i]
        a=map_point(a0,i if i==cf.HEAD else None);z=map_point(b0,i if i==cf.HEAD else None)
        b.head=(a[0],-a[2],a[1]);b.tail=(z[0],-z[2],z[1]);b.parent=root
    for name,parent,point in [('weapon.R','hand.R',body_map(cf.grip(1))),
                              ('weapon.L','hand.L',body_map(cf.grip(-1))),
                              ('back','chest',body_map((0,1.25,-.18))),
                              ('saddle','pelvis',body_map((0,.86,0)))]:
        b=ad.edit_bones.new(name);b.head=(point[0],-point[2],point[1]);b.tail=b.head+Vector((0,0,.06));b.parent=ad.edit_bones[parent];b.use_deform=False
    bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True
    rig['metres_per_unit']=1.;rig['adult_head_ratio']=7.4
    rig['skeleton_note']='16 shared deform joints plus root and 4 sockets; closed hands have five authored digits.'
    return rig

def remapped_pose(kit,clip,t,command=False):
    old=motion.pose(kit,clip,t)
    new=[None]*16
    pelvis=body_map((0,.86,0));chest=body_map((0,1.008,0))
    new[cf.HIPS]=motion.placed(pelvis,body_map(motion.trans(old[cf.HIPS],(0,.86,0))),old[cf.HIPS][0])
    new[cf.CHEST]=motion.placed(chest,motion.trans(new[cf.HIPS],chest),old[cf.CHEST][0])
    hp=map_point((0,1.427,.015),cf.HEAD)
    new[cf.HEAD]=motion.placed(hp,motion.trans(new[cf.CHEST],hp),old[cf.HEAD][0])
    for side in (-1,1):
        u,f,h=(cf.LU,cf.LF,cf.LH) if side<0 else (cf.RU,cf.RF,cf.RH)
        original=cf.grip(side);g=body_map(original)
        target=body_map(motion.trans(old[h],original));q=old[h][0]
        if command and side<0:
            lift=sin(pi*t)**2
            target=lerp(target,(-.34,1.56,.28),lift)
            q=motion.euler(-35*lift,-15,0)
        new[h]=motion.placed(g,target,q)
        binds=tuple(body_map(p) for p in cf.arm_nodes(side))
        end=motion.trans(new[h],binds[2])
        new[u],new[f]=motion.two_link(binds,motion.trans(new[cf.CHEST],binds[0]),end,(side*.65,-.52,-.83))
        u,f,h=(cf.LT,cf.LS,cf.LB) if side<0 else (cf.RT,cf.RS,cf.RB)
        binds=tuple(body_map(p) for p in cf.leg_nodes(side))
        target=body_map(motion.trans(old[h],cf.leg_nodes(side)[2]))
        new[u],new[f]=motion.two_link(binds,motion.trans(new[cf.HIPS],binds[0]),target,(side*.16,-.08,1))
        new[h]=motion.placed(binds[2],target,old[h][0])
    origin=body_map(add(cf.grip(1),(0,0,-.159)))
    new[cf.NOCK]=motion.placed(origin,body_map(motion.trans(old[cf.NOCK],add(cf.grip(1),(0,0,-.159)))),old[cf.NOCK][0])
    return new

def set_pose(rig,kit,clip,t,command=False):
    ms=remapped_pose(kit,clip,t,command)
    for i,n in enumerate(BONE_NAMES):
        q,tr=ms[i];q=Quaternion((q[3],q[0],q[1],q[2]))
        m=q.to_matrix().to_4x4();m.translation=Vector(tr)
        rig.pose.bones[n].matrix=C@m@C.inverted()@rig.data.bones[n].matrix_local
    bpy.context.view_layer.update()

def animate(rig,kit,prefix):
    rig.animation_data_create()
    for name,clip,duration in CLIPS:
        act=bpy.data.actions.new(prefix+'__'+name);act.use_fake_user=True
        rig.animation_data.action=act
        frames=max(12,round(duration*24))
        for frame in range(frames+1):
            t=frame/frames
            if name=='attack':
                c,tt=(2,t/.58) if t<.58 else (6,(t-.58)/.42)
            else:c,tt=clip,t
            set_pose(rig,kit,c,tt,name=='command')
            for n in BONE_NAMES:
                p=rig.pose.bones[n];p.rotation_mode='QUATERNION'
                p.keyframe_insert('location',frame=frame+1,group=n)
                p.keyframe_insert('rotation_quaternion',frame=frame+1,group=n)
                p.keyframe_insert('scale',frame=frame+1,group=n)
        for fc in act.fcurves:
            for kp in fc.keyframe_points:kp.interpolation='LINEAR'
        rig.animation_data.action=None
        track=rig.animation_data.nla_tracks.new();track.name=name
        strip=track.strips.new(name,1,act);strip.action_frame_start=1;strip.action_frame_end=frames+1
        track.mute=True
    for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(1)

def lod_copy(obj,name,target):
    copy=obj.copy();copy.data=obj.data.copy();copy.name=name
    bpy.context.collection.objects.link(copy)
    copy.animation_data_clear()
    for mod in list(copy.modifiers):
        if mod.type=='ARMATURE':copy.modifiers.remove(mod)
    triangles=sum(len(p.vertices)-2 for p in copy.data.polygons)
    if triangles>target:
        bpy.context.view_layer.objects.active=copy
        mod=copy.modifiers.new('authored_LOD','DECIMATE');mod.ratio=target/triangles
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return copy

def attach(obj,rig):
    obj.parent=rig
    mod=obj.modifiers.new('shared_skeleton','ARMATURE');mod.object=rig

def externalise_glb(path):
    """Remove duplicated image bytes; use one shared PBR atlas per army."""
    data=path.read_bytes();size,kind=struct.unpack_from('<I4s',data,12)
    doc=json.loads(data[20:20+size]);p=20+size
    blen,bkind=struct.unpack_from('<I4s',data,p);binary=data[p+8:p+8+blen]
    views=doc.get('bufferViews',[]);image_views=set()
    for img in doc.get('images',[]):
        vi=img.pop('bufferView',None)
        if vi is not None:
            image_views.add(vi)
            view=views[vi];raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
            nm=img.get('name','texture')
            filename=nm if nm.endswith('.png') else nm+'.png'
            # Blender may synthesize an ORM image from our separate-channel graph.
            (OUT/'textures'/filename).write_bytes(raw)
            img['uri']='../textures/'+filename
            img.pop('mimeType',None)
    fresh=bytearray();mapping={};newviews=[]
    for i,v in enumerate(views):
        if i in image_views:continue
        while len(fresh)%4:fresh.append(0)
        nv=dict(v);nv['byteOffset']=len(fresh);nv['buffer']=0
        off=v.get('byteOffset',0);fresh.extend(binary[off:off+v['byteLength']])
        mapping[i]=len(newviews);newviews.append(nv)
    for a in doc.get('accessors',[]):
        if 'bufferView' in a:a['bufferView']=mapping[a['bufferView']]
    doc['bufferViews']=newviews;doc['buffers']=[{'byteLength':len(fresh)}]
    for anim in doc.get('animations',[]):
        anim['name']=anim.get('name','idle').split('__')[-1]
    doc['asset']['generator']='Luanshi river-gate character library / Blender 4.3 / original project sources'
    desc=bytearray(json.dumps(doc,separators=(',',':')).encode())
    while len(desc)%4:desc.append(32)
    while len(fresh)%4:fresh.append(0)
    path.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(desc)+len(fresh))+
                     struct.pack('<I4s',len(desc),b'JSON')+desc+
                     struct.pack('<I4s',len(fresh),b'BIN\0')+fresh)
    return doc

def export_glb(path,objects,animation=True):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.hide_set(False);o.hide_viewport=False;o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
        export_animations=animation,export_animation_mode='NLA_TRACKS',export_nla_strips=True,
        export_force_sampling=True,export_frame_range=False,export_yup=True,
        export_extras=True,export_cameras=False,export_lights=False)
    return externalise_glb(path)

def metrics(doc,path):
    triangles=0
    for mesh in doc.get('meshes',[]):
        for p in mesh['primitives']:
            if 'indices' in p:triangles+=doc['accessors'][p['indices']]['count']//3
    return dict(file=str(path.relative_to(ROOT)),triangles=triangles,
                joints=max([len(s['joints']) for s in doc.get('skins',[])] or [0]),
                materials=len(doc.get('materials',[])),animations=[a.get('name') for a in doc.get('animations',[])],
                bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())

def make_character(faction,role,mat):
    prefix=faction+'_'+role;kit=ROLES[role][1]
    bpy.ops.object.select_all(action='DESELECT')
    body=surface_mesh(prefix+'_body',build_surface(role,faction),mat,role=role)
    arm=surface_mesh(prefix+'_equipment',cw.weapon(kit,True),mat,True)
    # Fine shoulder/hem layers stay crisp; each LOD is a separately inspectable mesh.
    rig=rig_for(prefix)
    rigs=[rig];result=[];models=[]
    animate(rig,kit,prefix)
    officer=ROLES[role][3]
    for lod in range(3):
        if lod==0:b,a=body,arm
        else:
            bt=3300 if officer else 2300
            wt=420
            if lod==2:bt=850 if officer else 650;wt=180
            b=lod_copy(body,prefix+'_body_lod'+str(lod),bt)
            a=lod_copy(arm,prefix+'_equipment_lod'+str(lod),wt)
        attach(b,rig);attach(a,rig)
        path=OUT/'characters'/f'{prefix}_lod{lod}.glb'
        doc=export_glb(path,[rig,b,a])
        result.append(dict(id=prefix,role=role,faction=faction,label=ROLES[role][2],lod=lod,
                           weapon_index=kit,status='asset_preview',**metrics(doc,path)))
        models.extend([b,a])
        if lod>0:b.hide_render=True;a.hide_render=True;b.hide_set(True);a.hide_set(True)
    set_pose(rig,kit,1,.22)
    return result,rig,[body,arm],models

def camera(point,target,lens=55):
    bpy.ops.object.camera_add(location=point);cam=bpy.context.object
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=3.9;cam.data.lens=lens
    bpy.context.scene.camera=cam;return cam

def studio_render(entries,path):
    # Genuine render of the deliverable meshes, separately labelled in the docs.
    for ob in bpy.context.scene.objects:ob.hide_render=True
    for i,(rig,meshes,kit) in enumerate(entries):
        rig.hide_render=False;rig.location=(i*1.25-(len(entries)-1)*.625,0,0)
        rig.rotation_euler[2]=-.12 if i%2 else .12
        for m in meshes:m.hide_render=False
        set_pose(rig,kit,1,.23+i*.11)
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.008));plane=bpy.context.object
    mat=bpy.data.materials.new('studio_ground');mat.diffuse_color=(.23,.25,.24,1);mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.23,.25,.24,1);bs.inputs['Roughness'].default_value=.83;plane.data.materials.append(mat)
    cam=camera((4,-7,3.0),(0,0,.88));cam.data.ortho_scale=max(3.65,len(entries)*1.1)
    for loc,power,size in [((1,-4,7),1050,5),((-5,-1,4),700,4),((1,4,5),900,4)]:
        bpy.ops.object.light_add(type='AREA',location=loc);ob=bpy.context.object;ob.data.energy=power;ob.data.shape='DISK';ob.data.size=size
        ob.rotation_euler=(Vector((0,0,.9))-ob.location).to_track_quat('-Z','Y').to_euler()
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
    scene.cycles.use_denoising=False;scene.render.resolution_x=1600;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
    if scene.world is None:scene.world=bpy.data.worlds.new('Studio daylight')
    scene.world.color=(.18,.18,.18);scene.view_settings.view_transform='AgX'
    scene.render.image_settings.file_format='PNG';scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--sample',action='store_true');parser.add_argument('--render',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for d in ['characters','weapons','textures','source']:(OUT/d).mkdir(parents=True,exist_ok=True)
    records=[];render_items=[]
    for faction in ['frontier','garrison']:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.context.scene.render.fps=24
        make_textures(faction);mat=material(faction)
        roles=['spearman','commander'] if args.sample else list(ROLES)
        for role in roles:
            rec,rig,meshes,models=make_character(faction,role,mat);records.extend(rec)
            render_items.append((rig,meshes,ROLES[role][1]))
            print('ASSET_DONE',faction,role,sum(r['bytes'] for r in rec),flush=True)
        # Source is laid out as an editable cast, with all three LODs and actions.
        for i,(rig,meshes,kit) in enumerate(render_items[-len(roles):]):rig.location=(i%4*1.8,i//4*2.3,0)
        for img in bpy.data.images:
            if img.source=='FILE':
                try:img.pack()
                except RuntimeError:pass
        source=OUT/'source'/f'characters_{faction}.blend'
        bpy.ops.wm.save_as_mainfile(filepath=str(source),compress=True)
        if args.render or args.sample:
            subset=[render_items[-len(roles)],render_items[-1]]
            studio_render(subset,DOC/'renders'/f'{faction}_mesh_study.png')
        render_items=[]
    (OUT/'characters'/'catalogue.json').write_text(json.dumps({'version':'1.0','units':'metres','forward':'+Z',
      'head_ratio':7.4,'source':'tools/art/river_gate/characters.py',
      'status':'standard_glTF_asset_preview_not_live_battle_replacement','assets':records},ensure_ascii=False,indent=2)+'\n')
    print('CHARACTER_CATALOGUE',len(records),flush=True)

if __name__=='__main__':main()
