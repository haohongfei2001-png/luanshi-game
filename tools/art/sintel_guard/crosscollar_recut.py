"""Explicit alternate full sewn-front pattern, not an overlay or old body's shell.
Executes the retained source recut with bounded, asserted pattern substitutions.
"""
import pathlib
p=pathlib.Path(__file__).with_name('recut_front.py');code=p.read_text()
def replace_once(a,b):
 global code
 if code.count(a)!=1:raise RuntimeError('Source pattern changed; review before applying '+a[:40])
 code=code.replace(a,b)
replace_once("endx=(-.065+.19*t) if side=='left' else (-.09+.07*t)","cross=min(1,t/.38);endx=(-.065+.235*cross) if side=='left' else (-.09+.18*cross)")
replace_once("newuv=[u for f,u in kept]","newuv=[u for f,u in kept];collar_faces=[]")
replace_once('newfaces.append(f);newuv.append(u)','newfaces.append(f);newuv.append(u)\n   if c>=columns-2 and r<len(rows)*.5:collar_faces.append(len(newfaces)-1)')
replace_once("bpy.ops.wm.save_as_mainfile(filepath=str(out/'recut-editable.blend'))",'''# The visible facing is part of the newly sewn front mesh with original side seam
# IDs, not a detached strip. Color marks its tailoring boundary; true sheet
# thickness remains the existing Solidify modifier.
facing=plain('Cross collar ivory woven facing',(.66,.63,.53),.93)
ob.data.materials.append(facing)
for fi in collar_faces:ob.data.polygons[fi].material_index=len(ob.data.materials)-1
bpy.ops.wm.save_as_mainfile(filepath=str(out/'recut-editable.blend'))''')
replace_once('# Failed hem experiment preserved, never enabled by default.', r'''# Extend each ORIGINAL sleeve cuff boundary as a sewn forearm panel. No body
# shell, hidden arm cutout or detached tube. Complete original sleeves stay.
ec={}
for f in newfaces:
 for a,b in zip(f,f[1:]+f[:1]):
  e=tuple(sorted((a,b)));ec[e]=ec.get(e,0)+1
adj={}
for (a,b),n in ec.items():
 if n==1:adj.setdefault(a,[]).append(b);adj.setdefault(b,[]).append(a)
seen=set();loops=[]
for start in adj:
 if start in seen or len(adj[start])!=2:continue
 loop=[start];prev=None;cur=start
 for _ in range(len(adj)+1):
  choices=[v for v in adj[cur] if v!=prev]
  if not choices:break
  nxt=choices[0]
  if nxt==start:break
  if nxt in loop:break
  loop.append(nxt);prev,cur=cur,nxt
 if nxt==start:loops.append(loop);seen.update(loop)
used=set()
for side in ['L','R']:
 wrist=rig.matrix_world@rig.pose.bones['DEF-hand.'+side].head
 li=min((i for i in range(len(loops)) if i not in used),key=lambda i:(sum((verts[k] for k in loops[i]),Vector())/len(loops[i])-wrist).length)
 used.add(li);loop=loops[li];center=sum((verts[k] for k in loop),Vector())/len(loop)
 if (center-wrist).length>.35:raise RuntimeError('Missing original sleeve cuff')
 # Match winding to the original open boundary before edge extrusion.
 a,b=loop[:2]
 if any(any(u==a and v==b for u,v in zip(f,f[1:]+f[:1])) for f in newfaces):loop.reverse()
 rows=[loop]
 for j in range(1,9):
  t=j/8;row=[];target=center.lerp(wrist,t*.96)
  for k in loop:
   radial=verts[k]-center
   # Original cuff profile and sculpt remain; smoothly taper toward wrist.
   q=target+radial*(1-.32*t)+radial.normalized()*(.003*math.sin(t*math.pi*4)*math.sin(t*math.pi))
   if j>=7:q+=radial.normalized()*.002
   row.append(len(verts));verts.append(q)
  rows.append(row)
 for j in range(8):
  for c in range(len(loop)):
   k=(c+1)%len(loop);newfaces.append([rows[j][c],rows[j][k],rows[j+1][k],rows[j+1][c]])
   newuv.append([(c/len(loop),j/8),(k/len(loop),j/8),(k/len(loop),(j+1)/8),(c/len(loop),(j+1)/8)])
# Failed hem experiment preserved, never enabled by default.''')
exec(compile(code,str(p),'exec'))
