"""Whole-scene volume design. NO shipping assets and NO game footage.
blender -b -t 2 --python tools/art/authored_reset/build_design_blend.py -- /tmp/river-authored-design
"""
import bpy,json,math,pathlib,sys
from mathutils import Vector
root=pathlib.Path(__file__).resolve().parent
plan=json.loads((root/'layout.json').read_text())
out=pathlib.Path(sys.argv[sys.argv.index('--')+1]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,hexcode):
 c=tuple(int(hexcode[i:i+2],16)/255 for i in (1,3,5))
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=.95
 return m
mats={k:mat(k,v['base']) for k,v in plan['material_families'].items()}
def box(name,bounds,height,material,bottom=0):
 x0,z0,x1,z1=bounds
 bpy.ops.mesh.primitive_cube_add(size=1,location=((x0+x1)/2,-(z0+z1)/2,bottom+height/2))
 o=bpy.context.object;o.name='DESIGN_VOLUME_'+name;o.dimensions=(x1-x0,z1-z0,height)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
 o['production_status']='PLACEHOLDER_NOT_SHIPPING_ART';return o
box('survey_plane',[-160,-128,160,128],.1,mats['earth'],-.15)
for a in plan['assemblies']:
 b=a['bounds_xz'];kind=a['kind'];material=mats[a['family']]
 if kind=='gateway':
  x0,z0,x1,z1=b;w=a['opening_width']/2
  box(a['id']+'_north_pier',[x0,z0,x1,-w],a['height'],material)
  box(a['id']+'_south_pier',[x0,w,x1,z1],a['height'],material)
  box(a['id']+'_lintel',b,a['height']-a['opening_height'],mats['tile'],a['opening_height'])
 elif kind in ('canopy_mass','background'):
  # Single envelopes explicitly represent forest bounds, never fake tree assets.
  o=box(a['id'],b,a['height'],material)
  bevel=o.modifiers.new('Envelope edges only','BEVEL');bevel.width=2;bevel.segments=3
 elif kind=='hydrology': box(a['id'],b,.02,material,.01)
 elif kind=='bridge':box(a['id'],b,.12,material,.02)
 elif kind=='ground':box(a['id'],b,.015,material,.02)
 else:box(a['id'],b,a.get('height',.1),material)
# A human scale witness is a measuring rod, not a new soldier model.
box('1_75m_scale_witness',[35,-.15,35.3,.15],1.75,mats['tile'])
world=bpy.data.worlds.new('Design daylight');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[1].default_value=.7;bpy.context.scene.world=world
sun=bpy.data.lights.new('DesignSun','SUN');o=bpy.data.objects.new('DesignSun',sun);bpy.context.collection.objects.link(o);o.rotation_euler=(.5,-.4,-.3);sun.energy=2
camdata=bpy.data.cameras.new('Same_game_22m');cam=bpy.data.objects.new('Same_game_22m',camdata);bpy.context.collection.objects.link(cam);bpy.context.scene.camera=cam
c=plan['camera'];yaw=math.radians(c['yaw_degrees']);pitch=math.radians(c['pitch_degrees']);d=Vector((math.sin(yaw)*math.cos(pitch),-math.cos(yaw)*math.cos(pitch),math.sin(pitch)))
def camera(center,size):
 x,y,z=center;target=Vector((x,-z,y));cam.location=target+d*150;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=size*16/9
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=8;s.cycles.use_denoising=False;s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100;s.render.image_settings.file_format='PNG'
camera(c['center'],22);bpy.ops.wm.save_as_mainfile(filepath=str(out/'whole-scene-DESIGN-ONLY.blend'))
s.render.filepath=str(out/'22m-DESIGN-NOT-GAME.png');bpy.ops.render.render(write_still=True)
camera([10,0,0],115);s.render.filepath=str(out/'whole-DESIGN-NOT-GAME.png');bpy.ops.render.render(write_still=True)
