extends SceneTree
const Reference:=preload("res://scripts/field/maps/authored_obstacles.gd")
const Native:=preload("res://scripts/field/maps/experimental_native_obstacles.gd")
var checks:=0
func compare(reference,native,p:Vector3,radius:float,height:float,gates:Dictionary={},linear:bool=false):
 var a:Dictionary=reference.obstruction(p,radius,height,gates,linear)
 var b:Dictionary=native.obstruction(p,radius,height,gates,linear)
 assert(var_to_bytes(a)==var_to_bytes(b),"BODY_MISMATCH "+str([p,radius,height,gates,linear,a,b]));checks+=1
func boundaries(reference,native):
 for solid in reference._solids:
  for i in solid.polygon.size():
   var p:Vector2=solid.polygon[i];var q:Vector2=solid.polygon[(i+1)%solid.polygon.size()]
   for center in [p,p.lerp(q,.5)]:
    for shift in [Vector2.ZERO,Vector2(.000001,0),Vector2(-.000001,0),Vector2(0,.000001),Vector2(0,-.000001)]:
     for y in [solid.min_y-3.4-.00001,solid.min_y-3.4,solid.min_y-3.4+.00001,solid.min_y,solid.max_y-.000011,solid.max_y-.00001,solid.max_y-.000009,solid.max_y]:
      for radius in [0.,.03,.7,1.999999,2.,2.000001]:compare(reference,native,Vector3(center.x+shift.x,y,center.y+shift.y),radius,3.4)
# Algorithmic unit fixtures, unrelated to any authored/map input geometry.
func rectangle(origin:Vector2,size:Vector2,id:String,low:float,high:float)->Dictionary:
 var polygon:=[]
 for corner in 4:
  var x:=origin.x+(size.x if corner==1 or corner==2 else 0.)
  var z:=origin.y+(size.y if corner>=2 else 0.)
  polygon.append([x,z])
 return {"id":id,"xz_polygon":polygon,"min_y":low,"max_y":high}
func concave_fixture(origin:Vector2,extent:float,notch:float)->Dictionary:
 var polygon:=[]
 for corner in 6:
  var x:=origin.x+(extent if corner==1 or corner==2 else notch if corner==3 or corner==4 else 0.)
  var z:=origin.y+(extent if corner==2 or corner==3 else notch if corner>=4 else 0.)
  polygon.append([x,z])
 return {"id":"concave","xz_polygon":polygon,"min_y":-1.,"max_y":3.}
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var reference:=Reference.new();var native:=Native.new()
 assert(reference.configure(data.solids)==OK);assert(native.configure(data.solids)==OK);assert(native.kernel!=null,"BODY_NATIVE_NOT_LOADED")
 boundaries(reference,native)
 var rng:=RandomNumberGenerator.new();rng.seed=61112
 for i in 30000:
  var p:=Vector3(rng.randf_range(-62,86),rng.randf_range(-5,15),rng.randf_range(-44,44))
  compare(reference,native,p,rng.randf_range(0,4),rng.randf_range(.01,8),{},i%3==0)
 var solids:=[rectangle(Vector2(-2,-2),Vector2(4,4),"first",0,2),rectangle(Vector2(-2,-2),Vector2(4,4),"second",1,3),concave_fixture(Vector2(5,0),3,1)]
 var gates:=[{"id":"gate","closed_blocker":rectangle(Vector2(10,-2),Vector2(1,4),"gate",0,6)}]
 var sr:=Reference.new();var sn:=Native.new();assert(sr.configure(solids,gates)==OK);assert(sn.configure(solids,gates)==OK);assert(sn.kernel!=null)
 boundaries(sr,sn)
 for opened in [false,true,false,true]:
  for radius in [0.,.03,.7,2.,2.000001,5.]:
   for height in [.000001,.5,1.9,3.4,8.]:
    for x in [-4.,-2.,0.,2.,4.,5.,6.,8.,9.999999,10.,10.5,11.,11.000001,13.]:
     for linear in [false,true]:compare(sr,sn,Vector3(x,1,0),radius,height,{"gate":opened},linear)
 # Exact float32 distance contact, zero/negative dimensions, nonfinite and safe-cast fallback.
 for p in [Vector3.ZERO,Vector3(2.7,0,0),Vector3(2.700001,0,0),Vector3(2.699999,0,0),Vector3(4,0,0),Vector3(2147483520.,0,0),Vector3(INF,0,0),Vector3(NAN,0,0)]:
  for radius in [-1.,0.,.7,2.,INF,NAN]:
   for height in [-1.,0.,1.9,INF,NAN]:compare(sr,sn,p,radius,height)
 sn.native_enabled=false
 for i in 100:compare(sr,sn,Vector3(i*.15,1,0),.7,3.4,{"gate":i%2==0})
 var kernel=ClassDB.instantiate("HF08ObstacleKernel");assert(kernel.configure(sr._solids,{Vector2i.ZERO:[99999]})==ERR_INVALID_DATA)
 var report={"result":"PASS","body_dictionary_byte_checks":checks,"source_sha256":FileAccess.get_sha256(args[0]),"scope":"Exact Geometry2D engine predicates, original ordered candidates, dynamic gates, vertical/radius/index boundaries, overlap/concavity, invalid input, explicit fallback; Linux only"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("NATIVE_BODY_PARITY ",JSON.stringify(report));quit()
