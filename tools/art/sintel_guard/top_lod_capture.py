"""Actual Blender static whole-top comparison, never Godot gameplay evidence."""
import bpy,sys,pathlib,json,math
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source),use_scripts=False,load_ui=False)
scene=bpy.context.scene;camera=scene.camera;camera.data.type='PERSP';camera.data.lens_unit='FOV';camera.data.angle=math.radians(50);scene.cycles.samples=16
high=bpy.data.objects['DERIVED_TOP_high'];low=bpy.data.objects['DERIVED_TOP_low'];target=Vector((0,-.02,1.5));direction=Vector((2,-3,.5)).normalized();records=[]
for distance,width,height in [(3,3840,2160),(22,2560,1440)]:
 camera.location=target+direction*distance;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();scene.render.resolution_x=width;scene.render.resolution_y=height;scene.render.resolution_percentage=100
 for label,obj in [('high',high),('low',low)]:
  high.hide_render=obj!=high;low.hide_render=obj!=low;path=out/f'{label}-{distance}m-native-{width}x{height}-blender.png';scene.render.filepath=str(path);bpy.ops.render.render(write_still=True);records.append({'file':path.name,'distance_m':distance,'width':width,'height':height,'internal_render_percentage':100,'horizontal_fov_degrees':50,'source':'Blender static garment-only diagnostic'})
(out/'capture.json').write_text(json.dumps(records,indent=2)+'\n')
