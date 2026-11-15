"""Resolve true shingle depth, not coplanar overlapping shoulder layers."""
import bpy,sys,pathlib,json
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
changed=[]
for o in bpy.data.objects:
 if o.name.startswith('V3 supported shoulder') and o.name.endswith('course 0'):
  for v in o.data.vertices:v.co+=v.normal*.0015
  o.data.update();changed.append(o.name)
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-editable.blend'))
(out/'finalize-report.json').write_text(json.dumps({'changed':changed,'additional_upper_course_thickness_m':.0015,'reason':'resolve otherwise coplanar 6mm overlap','status':'WIP_NOT_ART_ACCEPTED'},indent=2)+'\n')
