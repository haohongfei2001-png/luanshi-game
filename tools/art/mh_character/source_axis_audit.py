"""Audit imported rest axes against the documented MH local-X plane convention.
Readonly. Independent vector-basis reconstruction; does not execute upstream code.
"""
import bpy,hashlib,json,pathlib,sys,math
from mathutils import Vector,Matrix
args=sys.argv[sys.argv.index('--')+1:];blend,core,out=map(pathlib.Path,args[:3]);before=hashlib.sha256(blend.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(blend))
pts=[]
for line in (core/'makehuman_data_3dobjs_base.obj').read_text().splitlines():
 if line.startswith('v '):pts.append(Vector(tuple(map(float,line.split()[1:4]))))
for line in (core/'makehuman_data_targets_macrodetails_asian-male-young.target').read_text().splitlines():
 f=line.split()
 if f and not f[0].startswith('#'):pts[int(f[0])]+=Vector(tuple(map(float,f[1:4])))
r=json.loads((core/'makehuman_data_rigs_default.mhskel').read_text());rig=bpy.data.objects['MH163']
def j(name):return sum((pts[i] for i in r['joints'][name]),Vector())/len(r['joints'][name])
def convert(v):return Vector((v.x,-v.z,v.y))
rows=[]
floor=json.loads((blend.parent.parent/'master-report.json').read_text())['source_floor_y']
for name,spec in r['bones'].items():
 plane=r['planes'].get(spec.get('rotation_plane'))
 if plane:
  a,b,c=[j(k) for k in plane];normal=convert((c-b).cross(b-a)).normalized()
 else:normal=convert(Vector((0,1,0)))
 bone=rig.data.bones[name];y=(bone.tail_local-bone.head_local).normalized();z=normal.cross(y).normalized();x=y.cross(z).normalized();expected=Matrix((x,y,z)).transposed()
 actual=bone.matrix_local.to_3x3();angle=math.degrees(expected.to_quaternion().rotation_difference(actual.to_quaternion()).angle)
 if angle>180:angle=360-angle
 error=max(abs(expected[i][k]-actual[i][k]) for i in range(3) for k in range(3))
 expected_head=convert(j(spec['head'])-Vector((0,floor,0)))*.1;expected_tail=convert(j(spec['tail'])-Vector((0,floor,0)))*.1
 endpoint_error=max((expected_head-bone.head_local).length,(expected_tail-bone.tail_local).length)
 rows.append({'axis_component_max_error':error,'endpoint_max_error_m':endpoint_error,'bone':name,'plane':spec.get('rotation_plane'),'rotation_error_degrees':angle,'head_tail_preserved':endpoint_error<1e-6,'expected_axis_columns':[list(x),list(y),list(z)],'actual_axis_columns':[list(actual.col[i]) for i in range(3)]})
assert hashlib.sha256(blend.read_bytes()).hexdigest()==before
report={'source_blend_sha256':before,'official_reference':'https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/shared/skeleton.py','basis':'official plane normal maps to local X, local Y=head-to-tail; independent reconstruction','frozen_source_changed':False,'bones':rows,'over_1_degree':sum(x['rotation_error_degrees']>1 for x in rows),'max_rotation_error_degrees':max(x['rotation_error_degrees'] for x in rows),'max_axis_component_error':max(x['axis_component_max_error'] for x in rows),'max_endpoint_error_m':max(x['endpoint_max_error_m'] for x in rows)}
out.write_text(json.dumps(report,indent=2)+'\n');print('SOURCE_AXIS_AUDIT',report['over_1_degree'],report['max_rotation_error_degrees'])
