extends RefCounted
## Spatially indexed author-tagged support triangles, never arbitrary visual rays.
## Does not yet supply obstacles, portal navigation or a complete Battle adapter.
const CELL:=1.0
var _triangles:Array=[]
var _cells:Dictionary={}
var _configured:=false
func configure(surfaces:Array)->Error:
 if _configured:return ERR_ALREADY_IN_USE
 var triangles:Array=[];var cells:Dictionary={};var ids:={}
 for surface in surfaces:
  if not surface is Dictionary:return ERR_INVALID_DATA
  if surface.get("walkable",false)!=true:continue
  var id=surface.get("id","")
  if not id is String or id.is_empty() or ids.has(id):return ERR_INVALID_DATA
  ids[id]=true
  var vertices=surface.get("vertices");var faces=surface.get("triangles")
  if not vertices is Array or not faces is Array or faces.is_empty():return ERR_INVALID_DATA
  var points:Array[Vector3]=[]
  for raw in vertices:
   if not raw is Array or raw.size()!=3:return ERR_INVALID_DATA
   for number in raw:
    if not (number is int or number is float) or not is_finite(float(number)):return ERR_INVALID_DATA
   points.append(Vector3(raw[0],raw[1],raw[2]))
  for face in faces:
   if not face is Array or face.size()!=3:return ERR_INVALID_DATA
   for index in face:
    if not (index is int or index is float) or not is_finite(float(index)) or index!=floor(float(index)) or index<0 or index>=points.size():return ERR_INVALID_DATA
   var a:=points[face[0]];var b:=points[face[1]];var c:=points[face[2]]
   var pa:=Vector2(a.x,a.z);var pb:=Vector2(b.x,b.z);var pc:=Vector2(c.x,c.z)
   var denominator:float=(pb-pa).cross(pc-pa)
   if absf(denominator)<.000001:return ERR_INVALID_DATA
   var tri={"surface_id":id,"a":a,"b":b,"c":c,"denominator":denominator}
   var slot:=triangles.size();triangles.append(tri)
   var low:=Vector2(minf(pa.x,minf(pb.x,pc.x)),minf(pa.y,minf(pb.y,pc.y)))
   var high:=Vector2(maxf(pa.x,maxf(pb.x,pc.x)),maxf(pa.y,maxf(pb.y,pc.y)))
   for x in range(floori(low.x/CELL),floori(high.x/CELL)+1):
    for z in range(floori(low.y/CELL),floori(high.y/CELL)+1):
     var key:=Vector2i(x,z)
     if not cells.has(key):cells[key]=[]
     cells[key].append(slot)
 if triangles.is_empty():return ERR_INVALID_DATA
 _triangles=triangles;_cells=cells;_configured=true
 return OK
func support(p:Vector2,surface_id:String="")->Dictionary:
 if not _configured or not p.is_finite():return {"error":ERR_INVALID_PARAMETER}
 var key:=Vector2i(floori(p.x/CELL),floori(p.y/CELL));var hits:={}
 for slot:int in _cells.get(key,[]):
  var tri:Dictionary=_triangles[slot]
  if not surface_id.is_empty() and tri.surface_id!=surface_id:continue
  var a:Vector3=tri.a;var b:Vector3=tri.b;var c:Vector3=tri.c
  var u:=(Vector2(b.x,b.z)-p).cross(Vector2(c.x,c.z)-p)/float(tri.denominator)
  var v:=(Vector2(c.x,c.z)-p).cross(Vector2(a.x,a.z)-p)/float(tri.denominator)
  var w:=1.-u-v
  if minf(u,minf(v,w))<-.00001:continue
  var y:float=a.y*u+b.y*v+c.y*w
  if hits.has(tri.surface_id) and absf(float(hits[tri.surface_id])-y)>.001:return {"error":ERR_INVALID_DATA,"reason":"MULTIPLE_HEIGHTS_IN_ONE_SURFACE"}
  hits[tri.surface_id]=y
 if hits.is_empty():return {"error":ERR_DOES_NOT_EXIST,"reason":"NO_TAGGED_SUPPORT"}
 if hits.size()!=1:
  var heights=hits.values()
  for y in heights:
   if absf(float(y)-float(heights[0]))>.001:return {"error":ERR_INVALID_DATA,"reason":"EXPLICIT_SURFACE_REQUIRED","surfaces":hits.keys()}
  # Coincident-height seams are support, not an overpass; portal graph still
  # governs transitions between their distinct surface IDs.
 var id:String=hits.keys()[0]
 return {"error":OK,"surface_id":id,"position":Vector3(p.x,hits[id],p.y)}
func statistics()->Dictionary:return {"triangles":_triangles.size(),"spatial_cells":_cells.size(),"configured":_configured,"scope":"TAGGED_SUPPORT_ONLY_NOT_COMPLETE_NAVIGATION"}
