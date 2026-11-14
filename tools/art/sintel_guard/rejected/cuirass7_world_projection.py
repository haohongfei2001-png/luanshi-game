"""Independent full cuirass: neck/armhole bearing rim and separately articulated skirt.
Retains rebuilt complete cloth and rig; guarded re-authoring of owned armor only.
"""
import pathlib
p=pathlib.Path(__file__).parent.parent/'soldier_whole_layer_system.py';code=p.read_text()
def edit(a,b):
 global code
 if code.count(a)!=1:raise RuntimeError('Armor generator changed: '+a[:60])
 code=code.replace(a,b)
edit("if o.name.startswith(('KIT ','SOURCE lamella')):","if o.name.startswith(('KIT ','SOURCE lamella','REBUILD ')):")
edit("coat.data.materials.clear();coat.data.materials.append(cloth)","# Preserve the rebuilt sewn ivory collar facing and source cloth materials.\nif not coat.data.materials:coat.data.materials.append(cloth)")
edit("return 1.69-.22*abs(math.sin(a))**12","return 1.69+.095*math.sin(2*a)**2-.16*abs(math.sin(a))**12")
edit("make('REBUILD whole contoured breast back and side carrier',points,faces,weights,carrier,uv,.003)","""make('REBUILD whole contoured breast back and side carrier',points,faces,weights,carrier,uv,.0045)
# Entire sewn/riveted bearing edge is continuous around neck/armhole opening.
# Broad enough for normal view, not a noisy line of decorative micro-holes.
for label in ['upper','lower']:
 rp=[];rw=[];rf=[];ru=[]
 for j in range(4):
  for i in range(N):
   a=i*math.tau/N;z=(upper(a)-.018+j*.006) if label=='upper' else (1.35+j*.005)
   rp.append(surface(a,z,.021));rw.append(spine_weights(z));ru.append((i/N,j/3))
 for j in range(3):
  for i in range(N):k=(i+1)%N;rf.append((j*N+i,j*N+k,(j+1)*N+k,(j+1)*N+i))
 make('REBUILD continuous '+label+' bearing welt',rp,rf,rw,carrier,ru,.003)
""")
# Shorter scales retain their staggered overlap but no longer collide with the bound opening.
edit("if z+.032>upper(a):continue","if z+.038>upper(a)-.019:continue")
edit("iron=mat('Rebuild matte weathered iron',(.13,.155,.165),.74,.35)","iron=mat('Rebuild matte weathered iron',(.105,.125,.13),.86,.25)")
# Exact plate surfaces are not smoothed together with thin walls, preventing inflated pillows.
edit("f.use_smooth=True","f.use_smooth=not any(term in name for term in ['lamellar','tasset','overlapping rows'])")
edit("for row in range(6):", "for row in range(9):")
edit("if z+.038>upper(a)-.019:continue", "if z-.020>upper(a)-.019:continue")
edit("p=surface(a+xx*math.tau/40,z+zz*.068,offset)", "aa=a+xx*math.tau/40;p=surface(aa,min(z+zz*.068,upper(aa)-.019),offset)")
edit("vs=[]\n for p,ws in zip(points,weights):", """vs=[]
 if 'shoulder' in name:
  fitted=[]
  for point in points:
   q=Vector(point);hit=bvh.ray_cast(Vector((q.x,q.y,2.3)),Vector((0,0,-1)))
   if hit[0] is None or hit[0].z<1.40:raise RuntimeError('Shoulder support outside full source sleeve')
   q.z=hit[0].z+(.019 if 'overlapping' in name else .010);fitted.append(q)
  points=fitted
 for p,ws in zip(points,weights):""")
exec(compile(code,str(p),'exec'))
