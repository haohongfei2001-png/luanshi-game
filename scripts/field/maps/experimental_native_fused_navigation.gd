extends "res://scripts/field/maps/experimental_native_obstacle_navigation.gd"
## Fourth explicit experiment. Preserve original caller portal and step arithmetic.
## Native stops at the original support/body/slope early return, not past it.
var fused_enabled:=true
func _init():super()
func can_travel(a:Vector2,b:Vector2,from:String,to:String)->bool:
 if not fused_enabled or not batch_enabled or support.kernel==null or obstacles.kernel==null or not support.native_enabled or not obstacles.native_enabled:return super.can_travel(a,b,from,to)
 if not a.is_finite() or not b.is_finite() or maxf(maxf(absf(a.x),absf(a.y)),maxf(absf(b.x),absf(b.y)))>2147480000.:return super.can_travel(a,b,from,to)
 if not portal_allows(a,b,from,to):return false
 var steps:=maxi(1,ceili(a.distance_to(b)/.25))
 if steps>65536:return super.can_travel(a,b,from,to)
 var result:int=support.kernel.travel_fused(a,b,steps,from,to,_radius,_height,_gates,obstacles.kernel)
 if result<0:return super.can_travel(a,b,from,to)
 return result==1
