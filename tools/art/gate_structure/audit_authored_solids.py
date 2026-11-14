"""Post-modifier source audit of explicitly authored solids, never open source sheets."""
import bpy,json,sys,re
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from solid_orientation import orient_closed
source,output=map(Path,sys.argv[sys.argv.index('--')+1:]);audit=json.loads((source.parent.parent/'solid-orientation-audit.json').read_text());names={a['object'] for a in audit}
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
rows=[];tops=[]
for o in bpy.data.objects:
 if o.type!='MESH':continue
 base=re.sub(r'\.\d{3}$','',o.name)
 if o.name not in names and base not in names:continue
 faces=[tuple(p.vertices) for p in o.data.polygons];verts=[tuple(v.co) for v in o.data.vertices];_,components=orient_closed(verts,faces)
 if any(c['flipped'] for c in components):raise RuntimeError('Still inward after modifiers: '+o.name)
 rows.append({'object':o.name,'closed_components':len(components),'positive_volume_m3':sum(c['signed_volume_after_m3'] for c in components)})
 if base in ['GateGalleryBearing','GatePier_walk_jamb','HallFloorJoists','HallScreenBoard','BridgeRailPost']:
  top=max(o.data.polygons,key=lambda p:p.center.z)
  if top.normal.z<.999:raise RuntimeError('Top face not upward: '+o.name)
  tops.append({'object':o.name,'normal':list(top.normal)})
if len(rows)!=len(audit):raise RuntimeError('Authored object provenance count mismatch '+str((len(rows),len(audit))))
report={'objects_checked':len(rows),'upward_top_faces_checked':len(tops),'rows':rows,'tops':tops,'scope':'post-modifier closed authored sources only; professional surfaces deliberately excluded; not game/image acceptance'}
output.write_text(json.dumps(report,indent=2));print('AUTHORED_SOLID_NORMALS_PASS',len(rows),len(tops))
