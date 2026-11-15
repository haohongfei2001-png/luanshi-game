"""Offline audit of the actual exported glTF, never a Godot screenshot."""
import bpy,json,math,sys,hashlib,os
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
sys.path.insert(0,str(Path(__file__).resolve().parent))
from layout import *
ROOT=Path(os.environ['LUANSHI_WORKSPACE_ROOT']);SHARED=Path(os.environ['LUANSHI_PRODUCTION_ROOT']);args=sys.argv[sys.argv.index('--')+1:];SOURCE=Path(args[0]);OUT=Path(args[1]);OUT.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def pt(x,y,z):return Vector((x,-z,y))
def gp(v):return [float(v.x),float(v.z),float(-v.y)]
def group(name,parent=None):
 o=bpy.data.objects.new(name,None);sc.collection.objects.link(o);o.parent=parent;return o
bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene;bpy.ops.import_scene.gltf(filepath=str(SOURCE/'river-valley-hf01.glb'),export_import_convert_lighting_mode='COMPAT');door=bpy.data.objects.get('GateMain_DynamicLeaves');assert door
w=bpy.data.worlds.new('AuthorClearDay');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.61,.69,.77,1);w.node_tree.nodes['Background'].inputs[1].default_value=.65;sc.world=w
sc.render.engine='CYCLES';sc.cycles.samples=64;sc.cycles.use_denoising=False;sc.render.resolution_x=1600;sc.render.resolution_y=900;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast'
source=Path(__file__).with_name('build_valley.py').read_text();review=source.split("# Independent visual scale audit uses current real WIP18 posed actor, never spheres/sticks.\n",1)[1]
if '--yaw' in args:
 yaw_deg=float(args[args.index('--yaw')+1]);assert -180<=yaw_deg<=180
 review=review.replace('yaw=math.radians(-65)','yaw=math.radians('+str(yaw_deg)+')')
 fixed=(1.8*math.cos(math.pi/4)+(.55*math.sin(math.radians(65))+.35*math.cos(math.radians(65)))*math.sin(math.pi/4))/(2*math.tan(math.radians(25))*.125)
 review=review.replace('distance=span/(2*math.tan(fov/2)*.125)','distance='+str(fixed))
if '--view' in args:
 which=args[args.index('--view')+1];assert which in ['nearshore','bridge','threshold']
 review=review.replace('for name,x,z,typ in views:',"views=[v for v in views if v[0]=="+repr(which)+"]\nfor name,x,z,typ in views:")
exec(compile(review,str(Path(__file__)),'exec'))
