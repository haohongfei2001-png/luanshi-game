extends SceneTree
const Reference:=preload("res://scripts/field/maps/authored_navigation.gd")
const Native:=preload("res://scripts/field/maps/experimental_native_fused_navigation.gd")
var checks:=0
var observed:={"support_reject":0,"body_reject":0,"slope_reject":0,"portal_reject":0,"accepted":0}
func traced_reference(nav,a:Vector2,b:Vector2,from:String,to:String)->Dictionary:
 var r:={"decision":false,"calls":0,"planned":0,"visited":0,"body":0,"slope":0,"support_reject":0,"body_reject":0,"slope_reject":0}
 if not nav.portal_allows(a,b,from,to):observed.portal_reject+=1;return r
 var steps:=maxi(1,ceili(a.distance_to(b)/.25));r.calls=1;r.planned=steps+1
 var previous:Vector3;var have_previous:=false
 for step in range(steps+1):
  r.visited+=1
  var p:=a.lerp(b,float(step)/steps);var hit:Dictionary=nav.support.support(p,from)
  if hit.error!=OK and from!=to:hit=nav.support.support(p,to)
  if hit.error!=OK:r.support_reject=1;observed.support_reject+=1;return r
  r.body+=1
  if nav.obstacles.obstruction(hit.position,nav._radius,nav._height,nav._gates).blocked:r.body_reject=1;observed.body_reject+=1;return r
  var foot:Vector3=hit.position
  if have_previous:
   r.slope+=1;var run:=Vector2(foot.x-previous.x,foot.z-previous.z).length()
   if absf(foot.y-previous.y)>.1+run*.85:r.slope_reject=1;observed.slope_reject+=1;return r
  previous=foot;have_previous=true
 r.decision=true;observed.accepted+=1;return r
func compare(reference,native,a:Vector2,b:Vector2,from:String,to:String):
 var expected:=traced_reference(reference,a,b,from,to)
 assert(expected.decision==reference.can_travel(a,b,from,to),"TEST_OBSERVER_DIVERGED")
 native.support.kernel.reset_profile();native.obstacles.kernel.reset_profile()
 assert(expected.decision==native.can_travel(a,b,from,to),"FUSED_DECISION "+str([a,b,from,to,expected]))
 var actual:Dictionary=native.support.kernel.statistics()
 for pair in [["calls","fused_calls"],["planned","fused_planned_samples"],["visited","fused_visited_samples"],["body","fused_body_checks"],["slope","fused_slope_checks"],["support_reject","fused_support_rejections"],["body_reject","fused_body_rejections"],["slope_reject","fused_slope_rejections"]]:
  assert(expected[pair[0]]==actual[pair[1]],"EARLY_RETURN_COUNT "+str([pair,expected,actual,a,b]))
 assert(actual.fused_fallbacks==0)
 assert(native.obstacles.kernel.statistics().body_calls==expected.body)
 checks+=1
# Algorithmic unit fixtures, unrelated to any authored/map input geometry.
func rectangle(origin:Vector2,size:Vector2,id:String,low:float,high:float)->Dictionary:
 var polygon:=[]
 for corner in 4:
  var x:=origin.x+(size.x if corner==1 or corner==2 else 0.)
  var z:=origin.y+(size.y if corner>=2 else 0.)
  polygon.append([x,z])
 return {"id":id,"xz_polygon":polygon,"min_y":low,"max_y":high}
func plane_surface(slope:float)->Dictionary:
 var vertices:=[];var triangles:=[]
 for corner in 4:
  var x:=4. if corner==1 or corner==2 else 0.
  var z:=4. if corner>=2 else 0.
  vertices.append([x,x*slope,z])
 for corner in range(1,3):triangles.append([0,corner,corner+1])
 return {"id":"plane","walkable":true,"vertices":vertices,"triangles":triangles}
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var reference:=Reference.new();var native:=Native.new()
 assert(reference.configure(data,Rect2(-60,-42,144,84),{"gate_main":true},.7,3.4)==OK);assert(native.configure(data,Rect2(-60,-42,144,84),{"gate_main":true},.7,3.4)==OK)
 assert(native.support.kernel!=null and native.obstacles.kernel!=null)
 var rng:=RandomNumberGenerator.new();rng.seed=61112
 for i in 1500:
  var a:=Vector2(rng.randf_range(-60,84),rng.randf_range(-42,42));var b:=a+Vector2(rng.randf_range(-8,8),rng.randf_range(-8,8))
  var ah:Dictionary=reference.support.support(a);var bh:Dictionary=reference.support.support(b)
  compare(reference,native,a,b,ah.surface_id if ah.error==OK else "",bh.surface_id if bh.error==OK else "")
 # Exact .1 + run*.85 boundary on a quarter-step: slope 1.25 gives dy .3125.
 for slope in [0.,1.249999,1.25,1.250001,-1.249999,-1.25,-1.250001,2.]:
  var gate:=rectangle(Vector2(2,0),Vector2(.1,2),"gate",-20,20);gate.gate_id="test_gate"
  var fixture:={"surfaces":[plane_surface(slope)],"solids":[gate],"portals":[]}
  var sr:=Reference.new();var sn:=Native.new();assert(sr.configure(fixture,Rect2(0,0,4,4),{"test_gate":true},0.,1.9)==OK);assert(sn.configure(fixture,Rect2(0,0,4,4),{"test_gate":true},0.,1.9)==OK)
  for opened in [true,false,true]:
   for radius in [0.,.7,2.000001]:
    sr._gates={"test_gate":opened};sn._gates=sr._gates.duplicate();sr._radius=radius;sn._radius=radius
    for length in [0.,.249999,.25,.250001,.5,1.,3.25,4.]:
     compare(sr,sn,Vector2(.5,1),Vector2(.5+length,1),"plane","plane")
     compare(sr,sn,Vector2(.5+length,1),Vector2(.5,1),"plane","plane")
 native.fused_enabled=false
 for i in 100:assert(reference.can_travel(Vector2(-41+i*.01,0),Vector2(-40+i*.01,0),"west_terrace","west_terrace")==native.can_travel(Vector2(-41+i*.01,0),Vector2(-40+i*.01,0),"west_terrace","west_terrace"))
 for key in observed:assert(observed[key]>0,"Missing boundary outcome "+key)
 var report={"result":"PASS","exact_early_return_counter_cases":checks,"observed":observed,"explicit_disable_cases":100,"source_sha256":FileAccess.get_sha256(args[0]),"contract":"Original per-step generation/support/body/slope order and first rejection; no speculative later points; precise GDScript-double/Vector2-float32 slope boundary"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("NATIVE_FUSED_PARITY ",JSON.stringify(report));quit()
