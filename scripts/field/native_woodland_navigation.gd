extends RefCounted
## Exact whole-source placement shared by rendering and experimental navigation.
## Convex low-wood projection is conservative; source evidence is checked in.
const LAYOUT:=[[32.1,-14.8,1.0,-18.0],[34.0,15.7,1.0,-42.0]]
const SOURCE_SHA256:="6024cf385e9e0add29030925f8b891de264b813948f1cb9fb95633e256f50dc7"
const RADIUS:=2.875
static var LOCAL_POLYGON:=PackedVector2Array([Vector2(2.15971994400024,-0.962130010128021),Vector2(2.32789993286133,0.769590020179749),Vector2(-0.0107899997383356,2.26695990562439),Vector2(-0.239959999918938,2.17755007743835),Vector2(-1.5179500579834,1.47348999977112),Vector2(-2.56356000900269,-0.200220003724098),Vector2(-2.67974996566772,-0.841059982776642),Vector2(-2.54391002655029,-1.11757004261017),Vector2(1.53922998905182,-2.42779994010925)])
static func world_polygon(row:Array,extra:float=0.) -> PackedVector2Array:
 var local:=LOCAL_POLYGON
 if extra>0.:local=Geometry2D.offset_polygon(local,extra,Geometry2D.JOIN_MITER)[0]
 var result:=PackedVector2Array()
 for p:Vector2 in local:result.append(Vector2(row[0],row[1])+p.rotated(-deg_to_rad(row[3])))
 return result
static func blocked(p:Vector2) -> bool:
 for row:Array in LAYOUT:
  var center:=Vector2(row[0],row[1])
  if p.distance_squared_to(center)>RADIUS*RADIUS:continue
  if Geometry2D.is_point_in_polygon((p-center).rotated(deg_to_rad(row[3])),LOCAL_POLYGON):return true
 return false
static func segment_clear(a:Vector2,b:Vector2,polygon:PackedVector2Array) -> bool:
 if Geometry2D.is_point_in_polygon((a+b)*.5,polygon):return false
 for i in polygon.size():
  if Geometry2D.segment_intersects_segment(a,b,polygon[i],polygon[(i+1)%polygon.size()])!=null:return false
 return true
static func detour(start:Vector2,goal:Vector2) -> Vector2:
 for row:Array in LAYOUT:
  var center:=Vector2(row[0],row[1]);var near:=Geometry2D.get_closest_point_to_segment(center,start,goal)
  if near.distance_squared_to(center)>RADIUS*RADIUS:continue
  var polygon:=world_polygon(row)
  if segment_clear(start,goal,polygon):continue
  # Source-derived convex footprint, plus a .15m navigation clearance ring.
  # Visibility graph gives the first real bypass point, not a teleport.
  var nodes:=PackedVector2Array([start,goal]);nodes.append_array(world_polygon(row,.15))
  var n:=nodes.size();var distance:=PackedFloat64Array();distance.resize(n);distance.fill(INF);distance[0]=0.
  var previous:=PackedInt32Array();previous.resize(n);previous.fill(-1)
  var done:=PackedByteArray();done.resize(n)
  for step in n:
   var current:=-1
   for i in n:
    if done[i]==0 and (current<0 or distance[i]<distance[current]):current=i
   if current<0 or is_inf(distance[current]):break
   if current==1:break
   done[current]=1
   for other in n:
    if done[other]!=0 or other==current or not segment_clear(nodes[current],nodes[other],polygon):continue
    var candidate:=distance[current]+nodes[current].distance_to(nodes[other])
    if candidate<distance[other]:distance[other]=candidate;previous[other]=current
  if previous[1]>=0:
   var next:=1
   while previous[next]>0:next=previous[next]
   return nodes[next]
  # An unreachable goal inside solid wood is not made reachable by walking
  # through it. Keep the existing position rather than altering game state.
  return start
 return goal
