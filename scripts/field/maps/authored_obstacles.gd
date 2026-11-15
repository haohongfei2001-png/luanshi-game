extends RefCounted
## Exact authored planar solid footprints with vertical extents and per-call gate
## state. This is body clearance, not a replacement for surface/portal routing.
var _solids:Array=[]
var _configured:=false
func configure(solids:Array,gates:Array=[])->Error:
 if _configured:return ERR_ALREADY_IN_USE
 var rows:=solids.duplicate(true)
 for gate in gates:
  if not gate is Dictionary or not gate.get("id") is String or not gate.get("closed_blocker") is Dictionary:return ERR_INVALID_DATA
  var blocker:Dictionary=gate.closed_blocker.duplicate(true);blocker.id=gate.id;blocker.gate_id=gate.id;rows.append(blocker)
 var parsed:=[];var ids:={}
 for row in rows:
  if not row is Dictionary or not row.get("id") is String or ids.has(row.id):return ERR_INVALID_DATA
  ids[row.id]=true
  var polygon= row.get("xz_polygon")
  if not polygon is Array or polygon.size()<3:return ERR_INVALID_DATA
  var points:=PackedVector2Array()
  for raw in polygon:
   if not raw is Array or raw.size()!=2:return ERR_INVALID_DATA
   for number in raw:
    if not (number is int or number is float) or not is_finite(float(number)):return ERR_INVALID_DATA
   points.append(Vector2(raw[0],raw[1]))
  var low=row.get("min_y");var high=row.get("max_y")
  if not (low is int or low is float) or not (high is int or high is float) or not is_finite(float(low)) or not is_finite(float(high)) or high<=low:return ERR_INVALID_DATA
  if Geometry2D.triangulate_polygon(points).is_empty():return ERR_INVALID_DATA
  parsed.append({"id":row.id,"polygon":points,"min_y":float(low),"max_y":float(high),"gate_id":row.get("gate_id","")})
 _solids=parsed;_configured=true;return OK
func obstruction(foot:Vector3,radius:float,height:float,open_gates:Dictionary={})->Dictionary:
 if not _configured or not foot.is_finite() or not is_finite(radius) or not is_finite(height) or radius<0 or height<=0:return {"error":ERR_INVALID_PARAMETER,"blocked":true}
 var p:=Vector2(foot.x,foot.z)
 for solid:Dictionary in _solids:
  if not solid.gate_id.is_empty() and open_gates.get(solid.gate_id,false)==true:continue
  if foot.y>=solid.max_y-.00001 or foot.y+height<=solid.min_y+.00001:continue
  var polygon:PackedVector2Array=solid.polygon
  if Geometry2D.is_point_in_polygon(p,polygon):return {"error":OK,"blocked":true,"solid_id":solid.id}
  for i in polygon.size():
   var nearest:=Geometry2D.get_closest_point_to_segment(p,polygon[i],polygon[(i+1)%polygon.size()])
   if p.distance_squared_to(nearest)<=radius*radius:return {"error":OK,"blocked":true,"solid_id":solid.id}
 return {"error":OK,"blocked":false}
func statistics()->Dictionary:return {"solids":_solids.size(),"scope":"BODY_CLEARANCE_NOT_FULL_PATH_OR_BATTLE"}
