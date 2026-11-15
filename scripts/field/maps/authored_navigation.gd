extends RefCounted
## First bounded author-source navigation. No legacy Ground constants, no Battle
## writes. Graph construction is offline/entry work, never each simulation tick.
const Support:=preload("res://scripts/field/maps/authored_support.gd")
const Obstacles:=preload("res://scripts/field/maps/authored_obstacles.gd")
var support:=Support.new()
var obstacles:=Obstacles.new()
var graph:=AStar2D.new()
var _points:Dictionary={}
var _portals:Array=[]
var _gates:Dictionary={}
var _radius:=.45
var _height:=1.9
var _configured:=false
func configure(data:Dictionary,bounds:Rect2,open_gates:Dictionary={},radius:float=.45,height:float=1.9,spacing:float=1.)->Error:
 if _configured:return ERR_ALREADY_IN_USE
 if spacing<=0. or bounds.size.x<=0 or bounds.size.y<=0 or ceil(bounds.size.x/spacing)*ceil(bounds.size.y/spacing)>100000:return ERR_INVALID_PARAMETER
 var result=support.configure(data.get("surfaces",[]))
 if result!=OK:return result
 result=obstacles.configure(data.get("solids",[]))
 if result!=OK:return result
 _portals=data.get("portals",[]).duplicate(true);_gates=open_gates.duplicate(true);_radius=radius;_height=height
 var cells:={}
 for x in range(ceili(bounds.size.x/spacing)):
  for z in range(ceili(bounds.size.y/spacing)):
   var p:=bounds.position+Vector2((x+.5)*spacing,(z+.5)*spacing)
   var hit=support.support(p)
   if hit.error!=OK or obstacles.obstruction(hit.position,_radius,_height,_gates).blocked:continue
   var id:=graph.get_available_point_id();graph.add_point(id,p);_points[id]=hit;cells[Vector2i(x,z)]=id
 for cell:Vector2i in cells:
  var from:int=cells[cell]
  for delta in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
   var other:Vector2i=cell+delta
   if not cells.has(other):continue
   var to:int=cells[other]
   if can_travel(graph.get_point_position(from),graph.get_point_position(to),_points[from].surface_id,_points[to].surface_id):graph.connect_points(from,to)
 _configured=true;return OK
func portal_allows(a:Vector2,b:Vector2,from:String,to:String)->bool:
 if from==to:return true
 for portal in _portals:
  if not ((portal.from_surface==from and portal.to_surface==to) or (portal.to_surface==from and portal.from_surface==to)):continue
  if float(portal.width)<_radius*2 or float(portal.clearance)<_height:continue
  if portal.has("gate_id") and not _gates.get(portal.gate_id,false):continue
  var ends=portal.endpoints3D
  var p:=Vector2(ends[0][0],ends[0][2]);var q:=Vector2(ends[1][0],ends[1][2])
  if Geometry2D.segment_intersects_segment(a,b,p,q)!=null:return true
 return false
func can_travel(a:Vector2,b:Vector2,from:String,to:String)->bool:
 if not portal_allows(a,b,from,to):return false
 var steps:=maxi(1,ceili(a.distance_to(b)/.25));var previous:Vector3;var have_previous:=false
 for step in range(steps+1):
  var p:=a.lerp(b,float(step)/steps);var hit=support.support(p,from)
  if hit.error!=OK and from!=to:hit=support.support(p,to)
  if hit.error!=OK or obstacles.obstruction(hit.position,_radius,_height,_gates).blocked:return false
  var foot:Vector3=hit.position
  if have_previous:
   var run:=Vector2(foot.x-previous.x,foot.z-previous.z).length()
   if absf(foot.y-previous.y)>.1+run*.85:return false
  previous=foot;have_previous=true
 return true
func route(a:Vector2,b:Vector2)->PackedVector2Array:
 if not _configured:return PackedVector2Array()
 var from:=graph.get_closest_point(a);var to:=graph.get_closest_point(b)
 if from<0 or to<0:return PackedVector2Array()
 var ah=support.support(a);var bh=support.support(b)
 if ah.error!=OK or bh.error!=OK:return PackedVector2Array()
 if a.distance_to(graph.get_point_position(from))>1.5 or b.distance_to(graph.get_point_position(to))>1.5:return PackedVector2Array()
 if not can_travel(a,graph.get_point_position(from),ah.surface_id,_points[from].surface_id):return PackedVector2Array()
 if not can_travel(graph.get_point_position(to),b,_points[to].surface_id,bh.surface_id):return PackedVector2Array()
 var middle:=graph.get_point_path(from,to)
 if middle.is_empty():return middle
 var result:=PackedVector2Array([a]);result.append_array(middle);result.append(b);return result
func statistics()->Dictionary:return {"nodes":graph.get_point_count(),"support":support.statistics(),"obstacles":obstacles.statistics(),"agent_radius":_radius,"agent_height":_height,"scope":"AUTHOR_SOURCE_ROUTE_GRAPH_NOT_BATTLE_OR_ART_ACCEPTANCE"}
