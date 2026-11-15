"""Whole structural fortress revision: connected battered walls and gate podium.
Inputs: build04 editable mother, its contract, current shared layout, output.
Changes real authored outer geometry and emits revised gameplay solids/support.
"""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'gate_structure'))
from solid_orientation import orient_closed
from projection_axes import dominant_axis
from export_runtime_architecture import export_runtime
mother,contractfile,layoutfile,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(mother),load_ui=False)
old=json.loads(contractfile.read_text());layout=json.loads(layoutfile.read_text());root=bpy.data.objects['ProductionV2Architecture'];hall=bpy.data.objects['GateHall'];walls=bpy.data.objects['WallWalk']
# Preserve complete mature roof/frame, doors, and complete bridge. Rebuild all
# fort masses and hall infill, not a material label on the rejected coarse shell.
for o in list(bpy.data.objects):
 if o.type!='MESH':continue
 if o.parent==walls or (o.parent==hall and o.name.startswith(('GateLoadBearingPier','GatePierDressedEdge','TunnelLintel','GateHallBearingFloor','FortHallRearBoard','FortHallEndBoard','FortHallWindowApron','FortHallDoorSide'))):bpy.data.objects.remove(o,do_unlink=True)
materials={name:bpy.data.materials[name] for name in ['masonry','timber','timber_cut','tile','iron']}
plaster=bpy.data.materials.new('HallPlasterInfill');plaster.use_nodes=True;b=plaster.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(.30,.28,.235,1);b.inputs['Roughness'].default_value=.96;materials['plaster']=plaster
for o in bpy.data.objects:
 if o.type=='MESH' and any(m and m.name=='masonry' for m in o.data.materials) and 'MaterialUV_Metre' in o.data.uv_layers:
  for v in o.data.uv_layers['MaterialUV_Metre'].data:v.uv*=.75
for n in materials['masonry'].node_tree.nodes:
 if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=.30
solids=[s for s in old['solid_obstacles'] if s['id'].startswith('bridge_rail_')];supports=[s for s in old['support_profiles'] if s['id'].startswith('bridge_abutment_')];audit=[]
def pt(x,y,z):return Vector((x,-z,y))
F=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def mesh(name,verts,faces,mat,parent,along=None):
 faces,a=orient_closed(verts,faces);audit.append({'object':name,'components':a});d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(materials[mat]);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.parent=parent;uv=d.uv_layers.new(name='UVMap');pbr=d.uv_layers.new(name='MaterialUV_Metre') if mat in ['masonry','timber','timber_cut'] else None
 lo=[min(v.co[k] for v in d.vertices) for k in range(3)];hi=[max(v.co[k] for v in d.vertices) for k in range(3)];grain=max(range(3),key=lambda k:hi[k]-lo[k])
 for p in d.polygons:
  for i in p.loop_indices:
   v=d.vertices[d.loops[i].vertex_index].co
   if along is not None:
    across=Vector((-along.y,along.x,0));coords=(v.dot(along),v.dot(across)) if abs(p.normal.z)>.75 else (v.dot(across),v.z) if abs(p.normal.dot(along))>.70 else (v.dot(along),v.z)
   else:
    axis=dominant_axis(p.normal);axes=[k for k in range(3) if k!=axis]
    if mat.startswith('timber') and grain in axes:axes=[k for k in axes if k!=grain]+[grain]
    coords=(v[axes[0]],v[axes[1]])
   uv.data[i].uv=coords
   if pbr:pbr.data[i].uv=(coords[0]/(2 if mat=='masonry' else .6),coords[1]/(2 if mat=='masonry' else .6))
 return o

def box(name,c,s,mat,parent):
 x,y,z=c;a,b,c=[v/2 for v in s];return mesh(name,[pt(x+i*a,y+j*b,z+k*c) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]],F,mat,parent)
def beam(name,a,b,w,h,mat,parent):
 a,b=pt(*a),pt(*b);direction=(b-a).normalized();side=direction.cross(Vector((0,0,1)))
 if side.length<.01:side=direction.cross(Vector((0,1,0)))
 side.normalize();up=direction.cross(side).normalized();v=[p+side*i*w/2+up*j*h/2 for p in [a,b] for i,j in [(-1,-1),(1,-1),(1,1),(-1,1)]]
 return mesh(name,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,parent)
def solid(id,poly,bottom,top,role):solids.append({'id':id,'tag':'solid_obstacle','xz_polygon':poly,'min_y':bottom,'max_y':top,'role':role})
def gate_cell(name,x0,x1,outer0,outer1,inner,y0,y1,sign):
 # Inner jamb remains truly vertical; outside podium batters in X and Z.
 z0,z1=sorted([sign*outer0+3,inner]);zt0,zt1=sorted([sign*outer1+3,inner]);base=[[x0,z0],[60-x0,z0],[60-x0,z1],[x0,z1]];top=[[x1,zt0],[60-x1,zt0],[60-x1,zt1],[x1,zt1]]
 mesh(name,[pt(x,y0,z) for x,z in base]+[pt(x,y1,z) for x,z in top],F,'masonry',hall);return base
for sign,inner in [(-1,-.2),(1,6.2)]:
 base=gate_cell('GateContinuousBatteredFoundation',25.7,26.3,11.7,11.,inner,.2,2.5,sign)
 gate_cell('GateStructuralPodium',26.5,27.,10.8,10.,inner,2.5,7.05,sign)
 solid('gate_pier_'+str(sign),base,.2,7.2,'continuous battered foundation and thick podium; revised outer shape')
 supports.append({'id':'gate_pier_'+str(sign),'xz_polygon':base,'ground_y':1.2,'foundation_bottom':.2,'body_step_height':2.5,'platform_y':7.2})
box('GateBearingPlatform',(30,7.125,3),(6.35,.15,20.35),'masonry',hall)
for x in [26.96,28.5,30,31.5,33.04]:
 beam('GateThroughLintel',(x,6.85,-.7),(x,6.85,6.7),.43,.5,'timber_cut',hall)
for x in [26.96,33.04]:
 for z in [-.38,6.38]:beam('GateHeavyJamb',(x,1.2,z),(x,6.6,z),.28,.32,'timber',hall)
# Infill now is complete plaster panels within the source bay frames, not narrow
# boards recolored white. Source columns/transverse frames/curved rafters survive.
lines=[-4.09,.636666667,5.363333333,10.09]
for left,right in zip(lines,lines[1:]):
 box('HallRearPlasterPanel',(31.72,8.25,(left+right)/2),(.12,2.0,right-left-.2),'plaster',hall)
for z in [-4.09,10.09]:box('HallEndPlasterPanel',(30.0,8.25,z),(3.38,2.0,.12),'plaster',hall)
for bay,(left,right) in enumerate(zip(lines,lines[1:])):
 middle=(left+right)/2
 if bay!=1:box('HallWindowInfill',(29.,7.57,middle),(.12,.70,right-left-.2),'plaster',hall)
 else:
  for a,b in [(left,middle-.82),(middle+.82,right)]:box('HallDoorInfill',(29.,8.25,(a+b)/2),(.12,2.0,b-a-.1),'plaster',hall)
# Continuous mitered foundation and upper wall align at every shared cross section.
# Shoulder stations broaden into integrated flanking platforms, not pasted towers.
paths={'north':[[30,1.2,-7]]+layout['fort_join_anchors']['north']+[[76,1.2,-1.1]],'south':[[30,1.2,13]]+layout['fort_join_anchors']['south']+[[76,1.2,7.1]]}
heights={'north':[6.,5.6,4.8,4.4,4.6,4.6],'south':[6.,5.8,4.9,4.8,4.7,4.6]}
for side,path in paths.items():
 outer_sign=-1 if side=='north' else 1;n=len(path);miters=[]
 for i,p in enumerate(path):
  a=Vector((path[max(0,i-1)][0],path[max(0,i-1)][2]));b=Vector((p[0],p[2]));c=Vector((path[min(n-1,i+1)][0],path[min(n-1,i+1)][2]));d0=(b-a).normalized() if i else(c-b).normalized();d1=(c-b).normalized() if i<n-1 else d0;n0=Vector((-d0.y,d0.x));n1=Vector((-d1.y,d1.x));bis=(n0+n1).normalized();miters.append(bis/max(.625,bis.dot(n1)))
 widths=[2.8,4.0,2.8,2.8,2.8,2.8];tops=[1.8,3.2,1.8,1.8,1.8,1.8]
 def edge(i,width,sign):
  p=path[i];v=Vector((p[0],p[2]))+miters[i]*width*sign
  if i==n-1:v.y=p[2] # full straight rear opening, not skewed by end miter
  return [v.x,v.y]
 def band(i,label,low_widths,high_widths,ys0,ys1):
  low=[edge(i,low_widths[i],1),edge(i+1,low_widths[i+1],1),edge(i+1,low_widths[i+1],-1),edge(i,low_widths[i],-1)];high=[edge(i,high_widths[i],1),edge(i+1,high_widths[i+1],1),edge(i+1,high_widths[i+1],-1),edge(i,high_widths[i],-1)]
  vs=[pt(x,ys0[i if j in [0,3] else i+1],z) for j,(x,z) in enumerate(low)]+[pt(x,ys1[i if j in [0,3] else i+1],z) for j,(x,z) in enumerate(high)]
  d=pt(path[i+1][0]-path[i][0],0,path[i+1][2]-path[i][2]);d.normalize();mesh(side+'_'+label+'_'+str(i),vs,F,'masonry',walls,d);return low
 ground=[p[1] for p in path];walltop=[p[1]+heights[side][i] for i,p in enumerate(path)];foot_top=[y+1.3 for y in ground];base_topwidth=[w-.5 for w in widths];body_bottom=[w-.75 for w in widths]
 for i in range(n-1):
  poly=band(i,'continuous_foundation',widths,base_topwidth,[y-.8 for y in ground],foot_top)
  band(i,'battered_wall_body',body_bottom,tops,foot_top,walltop)
  band(i,'loadbearing_coping',[w+.14 for w in tops],[w+.14 for w in tops],walltop,[y+.22 for y in walltop])
  solid(side+'_defense_'+str(i),poly,min(ground[i],ground[i+1])-.8,max(walltop[i],walltop[i+1])+1.8,'continuous interlocked battered defense and flanking platform')
  supports.append({'id':side+'_defense_'+str(i),'xz_polygon':poly,'axis_endpoints':path[i]+path[i+1],'foundation_embed_m':.8,'top_y_endpoints':[walltop[i],walltop[i+1]],'structural_revision':'connected mitered scarp + loadbearing stepped plinth'})
  a=edge(i,tops[i]-.30,outer_sign);b=edge(i+1,tops[i+1]-.30,outer_sign)
  beam(side+'_continuous_parapet',(a[0],walltop[i]+.66,a[1]),(b[0],walltop[i+1]+.66,b[1]),.62,.88,'masonry',walls)
  length=math.dist(a,b);count=max(1,round(length/2.15));dx=(b[0]-a[0])/length;dz=(b[1]-a[1])/length
  for j in range(count):
   t=(j+.5)/count;x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t;y=walltop[i]+(walltop[i+1]-walltop[i])*t+1.44
   beam(side+'_defense_merlon',(x-dx*.55,y,z-dz*.55),(x+dx*.55,y,z+dz*.55),.66,.68,'masonry',walls)
  # Inner low guard defines a real thick top passage rather than a bare slab.
  a=edge(i,tops[i]-.18,-outer_sign);b=edge(i+1,tops[i+1]-.18,-outer_sign)
  beam(side+'_inner_walk_guard',(a[0],walltop[i]+.46,a[1]),(b[0],walltop[i+1]+.46,b[1]),.32,.48,'masonry',walls)
# Same stable dynamic door; opening approaches extend with the real thicker podium.
walk=[dict(w) for w in old['walk_surfaces']]
for w in walk:
 if w['id']=='gate_tunnel':w['xz_polygon']=[[25.7,-.2],[34.3,-.2],[34.3,6.2],[25.7,6.2]]
 bpy.data.objects[w['id']]['contract_json']=json.dumps(w)
gate=dict(old['gate_dynamic']);gate['entry']=[25.7,1.2,3];gate['exit']=[34.3,1.2,3]
for name,pos in [('gate_entry',gate['entry']),('gate_exit',gate['exit'])]:bpy.data.objects[name].location=pt(*pos)
contract=dict(old);contract.update({'revision':'fortress_mass_002','solid_obstacles':solids,'support_profiles':supports,'walk_surfaces':walk,'gate_dynamic':gate,'structural_change':'new continuous mitered battered defense system; no inherited rectangular shell constraint','layout_sha256':hashlib.sha256(layoutfile.read_bytes()).hexdigest(),'map_profile_must_regenerate':True,'muster_status':'NOT_RUN','status':'NOT_ART_OR_GAMEPLAY_ACCEPTED'})
root['structural_revision']='fortress_mass_002'
contract['architecture_material_policy']='Professional source wood/stone preserved; masonry meter UV corrected to2m; normal.30; full plaster infill panels between professional source frames, not painted boards.'
(out/'architecture-contract.json').write_text(json.dumps(contract,indent=2));(out/'solid-audit.json').write_text(json.dumps(audit,indent=2));(out/'scene-layout-snapshot.json').write_text(json.dumps(layout,indent=2));bpy.ops.wm.save_as_mainfile(filepath=str(out/'architecture-mother.blend'),compress=True);export_runtime(out/'architecture.glb');print('FULL_FORTRESS_MASS_BUILT_NOT_ACCEPTED',len(solids),len(supports))
