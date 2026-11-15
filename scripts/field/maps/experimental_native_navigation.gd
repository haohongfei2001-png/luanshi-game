extends "res://scripts/field/maps/authored_navigation.gd"
## Explicit opt-in only. Same support samples; every obstacle/gate/slope check
## remains in the original order. No graph-edge or nearby-position shortcut.
const NativeSupport:=preload("res://scripts/field/maps/experimental_native_support.gd")
var batch_enabled:=true
func _init():support=NativeSupport.new()
func can_travel(a:Vector2,b:Vector2,from:String,to:String)->bool:
 if not batch_enabled or support.get("kernel")==null or not a.is_finite() or not b.is_finite():return super.can_travel(a,b,from,to)
 if maxf(maxf(absf(a.x),absf(a.y)),maxf(absf(b.x),absf(b.y)))>2147480000.:return super.can_travel(a,b,from,to)
 if not portal_allows(a,b,from,to):return false
 var steps:=maxi(1,ceili(a.distance_to(b)/.25))
 if steps>65536:return super.can_travel(a,b,from,to)
 var samples:Dictionary=support.kernel.segment_support(a,b,steps,from,to)
 if samples.error!=OK:return super.can_travel(a,b,from,to)
 var errors:PackedInt32Array=samples.errors;var positions:PackedVector3Array=samples.positions
 var previous:Vector3;var have_previous:=false
 for step in range(steps+1):
  if errors[step]!=OK or obstacles.obstruction(positions[step],_radius,_height,_gates).blocked:return false
  var foot:Vector3=positions[step]
  if have_previous:
   var run:=Vector2(foot.x-previous.x,foot.z-previous.z).length()
   if absf(foot.y-previous.y)>.1+run*.85:return false
  previous=foot;have_previous=true
 return true
