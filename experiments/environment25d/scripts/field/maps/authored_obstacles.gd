extends RefCounted
var profile_enabled:=false
var profile:Dictionary={} # Inclusive query times; nested totals must not be summed.
## Exact authored planar solid footprints with vertical extents and per-call gate
## state. This is body clearance, not a replacement for surface/portal routing.
var _solids:Array=[]
var _configured:=false
var _cells:Dictionary={}
const CELL:=4.0
const INDEX_MARGIN:=2.0
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
 _solids=parsed
 for slot in _solids.size():
  var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
  for point in _solids[slot].polygon:low=low.min(point);high=high.max(point)
  low-=Vector2.ONE*INDEX_MARGIN;high+=Vector2.ONE*INDEX_MARGIN
  for x in range(floori(low.x/CELL),floori(high.x/CELL)+1):
   for z in range(floori(low.y/CELL),floori(high.y/CELL)+1):
    var cell:=Vector2i(x,z)
    if not _cells.has(cell):_cells[cell]=[]
    _cells[cell].append(slot)
 _configured=true;return OK
func obstruction(foot:Vector3,radius:float,height:float,open_gates:Dictionary={},force_linear:bool=false)->Dictionary:
 if not profile_enabled:return _obstruction_impl(foot,radius,height,open_gates,force_linear)
 var started:=Time.get_ticks_usec();var result:=_obstruction_impl(foot,radius,height,open_gates,force_linear)
 profile["obstruction_calls"]=int(profile.get("obstruction_calls",0))+1
 profile["obstruction_us"]=int(profile.get("obstruction_us",0))+Time.get_ticks_usec()-started
 return result
func _obstruction_impl(foot:Vector3,radius:float,height:float,open_gates:Dictionary={},force_linear:bool=false)->Dictionary:
 if not _configured or not foot.is_finite() or not is_finite(radius) or not is_finite(height) or radius<0 or height<=0:return {"error":ERR_INVALID_PARAMETER,"blocked":true}
 var p:=Vector2(foot.x,foot.z)
 var candidates:Array=range(_solids.size()) if force_linear or radius>INDEX_MARGIN else _cells.get(Vector2i(floori(p.x/CELL),floori(p.y/CELL)),[])
 for slot:int in candidates:
  var solid:Dictionary=_solids[slot]
  if not solid.gate_id.is_empty() and open_gates.get(solid.gate_id,false)==true:continue
  if foot.y>=solid.max_y-.00001 or foot.y+height<=solid.min_y+.00001:continue
  var polygon:PackedVector2Array=solid.polygon
  if Geometry2D.is_point_in_polygon(p,polygon):return {"error":OK,"blocked":true,"solid_id":solid.id}
  for i in polygon.size():
   var nearest:=Geometry2D.get_closest_point_to_segment(p,polygon[i],polygon[(i+1)%polygon.size()])
   if p.distance_squared_to(nearest)<=radius*radius:return {"error":OK,"blocked":true,"solid_id":solid.id}
 return {"error":OK,"blocked":false}
func statistics()->Dictionary:return {"solids":_solids.size(),"scope":"BODY_CLEARANCE_NOT_FULL_PATH_OR_BATTLE"}
func segment_obstruction(a:Vector3,b:Vector3,open_gates:Dictionary={},radius:float=.03,height:float=.05)->bool:
 if not profile_enabled:return _segment_obstruction_impl(a,b,open_gates,radius,height)
 var started:=Time.get_ticks_usec();var result:=_segment_obstruction_impl(a,b,open_gates,radius,height)
 profile["segment_obstruction_calls"]=int(profile.get("segment_obstruction_calls",0))+1
 profile["segment_obstruction_us"]=int(profile.get("segment_obstruction_us",0))+Time.get_ticks_usec()-started
 return result
func _segment_obstruction_impl(a:Vector3,b:Vector3,open_gates:Dictionary={},radius:float=.03,height:float=.05)->bool:
 if not a.is_finite() or not b.is_finite():return true
 for solid:Dictionary in _solids:
  if not solid.gate_id.is_empty() and open_gates.get(solid.gate_id,false)==true:continue
  var lower:=0.;var upper:=1.;var dy:=b.y-a.y
  if absf(dy)<.000001:
   if a.y+height<solid.min_y or a.y>solid.max_y:continue
  else:
   var first:float=(solid.min_y-height-a.y)/dy;var last:float=(solid.max_y-a.y)/dy
   lower=maxf(0.,minf(first,last));upper=minf(1.,maxf(first,last))
   if lower>upper:continue
  var p3:=a.lerp(b,lower);var q3:=a.lerp(b,upper)
  var p:=Vector2(p3.x,p3.z);var q:=Vector2(q3.x,q3.z);var polygon:PackedVector2Array=solid.polygon
  if Geometry2D.is_point_in_polygon(p,polygon) or Geometry2D.is_point_in_polygon(q,polygon):return true
  for i in polygon.size():
   if Geometry2D.segment_intersects_segment(p,q,polygon[i],polygon[(i+1)%polygon.size()])!=null:return true
   var c:=polygon[i];var d:=polygon[(i+1)%polygon.size()]
   if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,c,d))<=radius*radius or q.distance_squared_to(Geometry2D.get_closest_point_to_segment(q,c,d))<=radius*radius or c.distance_squared_to(Geometry2D.get_closest_point_to_segment(c,p,q))<=radius*radius or d.distance_squared_to(Geometry2D.get_closest_point_to_segment(d,p,q))<=radius*radius:return true
 return false
