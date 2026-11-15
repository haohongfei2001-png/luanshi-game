extends SceneTree
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const NativeNavigation:=preload("res://scripts/field/maps/experimental_native_navigation.gd")
var point_checks:=0
var segment_checks:=0
func compare_segment(reference,native,a:Vector2,b:Vector2,from:String,to:String,check_points:bool=true):
 if check_points:
  var steps:=maxi(1,ceili(a.distance_to(b)/.25))
  var result:Dictionary=native.support.kernel.segment_support(a,b,steps,from,to);assert(result.error==OK)
  var points:=PackedVector2Array();var positions:=PackedVector3Array();var errors:=PackedInt32Array()
  for step in range(steps+1):
   var p:=a.lerp(b,float(step)/steps);points.append(p);var hit:Dictionary=reference.support.support(p,from)
   if hit.error!=OK and from!=to:hit=reference.support.support(p,to)
   errors.append(hit.error);positions.append(hit.position if hit.error==OK else Vector3.ZERO);point_checks+=1
  assert(points.to_byte_array()==result.points.to_byte_array(),"LERP_POINT_BYTES "+str(a)+" "+str(b))
  assert(errors.to_byte_array()==result.errors.to_byte_array(),"ERROR_BYTES")
  assert(positions.to_byte_array()==result.positions.to_byte_array(),"POSITION_BYTES "+str(a)+" "+str(b))
 assert(reference.can_travel(a,b,from,to)==native.can_travel(a,b,from,to),"TRAVEL_MISMATCH "+str(a)+" "+str(b)+" "+from+" "+to)
 segment_checks+=1
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var bounds:=Rect2(-60,-42,144,84)
 var reference:=Navigation.new();var native:=NativeNavigation.new()
 assert(reference.configure(data,bounds,{"gate_main":true},.7,3.4)==OK)
 assert(native.configure(data,bounds,{"gate_main":true},.7,3.4)==OK);assert(native.support.kernel!=null)
 assert(reference.graph.get_point_ids()==native.graph.get_point_ids())
 for id in reference.graph.get_point_ids():assert(reference.graph.get_point_connections(id)==native.graph.get_point_connections(id),"GRAPH_EDGES_CHANGED")
 reference.support.exact_cache_enabled=false;native.support.exact_cache_enabled=false
 var rng:=RandomNumberGenerator.new();rng.seed=61112
 var tags:=["","west_terrace","east_terrace","west_landing","east_landing","gate_tunnel","bridge_main_deck","unknown"]
 for i in 2000:
  var a:=Vector2(rng.randf_range(-60,84),rng.randf_range(-42,42));var b:=a+Vector2(rng.randf_range(-8,8),rng.randf_range(-8,8))
  var ah=reference.support.support(a);var bh=reference.support.support(b)
  var from:String=ah.surface_id if ah.error==OK else tags[i%tags.size()]
  var to:String=bh.surface_id if bh.error==OK else tags[(i+3)%tags.size()]
  if i%7==0:from=tags[i%tags.size()];to=tags[(i+1)%tags.size()]
  compare_segment(reference,native,a,b,from,to)
 # Exact-quarter distances, zero lengths, opposite directions and cell boundaries.
 for x in [-60.,-41.5,-1.,0.,1.,14.8,45.,79.,84.]:
  for length in [0.,.249999,.25,.250001,.499999,.5,.500001,1.,6.000001]:
   for sign_value in [-1.,1.]:compare_segment(reference,native,Vector2(x,0),Vector2(x+length*sign_value,.00001),"","")
 # Gate state and body dimensions are read on every call, never captured by batch.
 for portal in data.portals:
  var ep=portal.endpoints3D;var p:=Vector2(ep[0][0],ep[0][2]);var q:=Vector2(ep[1][0],ep[1][2]);var center:=(p+q)*.5
  var direction:=(q-p).orthogonal().normalized();var a:=center-direction;var b:=center+direction
  for opened in [true,false,true]:
   for radius in [0.,.45,.7,2.1]:
    for height in [.5,3.4,6.]:
     reference._gates={"gate_main":opened};native._gates={"gate_main":opened};reference._radius=radius;native._radius=radius;reference._height=height;native._height=height
     compare_segment(reference,native,a,b,portal.from_surface,portal.to_surface)
     compare_segment(reference,native,b,a,portal.to_surface,portal.from_surface)
 native.batch_enabled=false
 for i in 100:compare_segment(reference,native,Vector2(-42+i*.01,0),Vector2(-41+i*.01,0),"west_terrace","west_terrace",false)
 var report={"result":"PASS","point_bytes_checked":point_checks,"segment_decisions_checked":segment_checks,"graph_nodes":native.graph.get_point_count(),"graph_connections_exact":true,"source_sha256":FileAccess.get_sha256(args[0]),"explicit_fallback_segments":100,"scope":"Native lerp/ordered support bytes; original per-sample gate/obstacle/slope decisions, no samples removed; Linux only"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("NATIVE_SEGMENT_PARITY ",JSON.stringify(report));quit()
