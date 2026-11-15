extends SceneTree
const Reference:=preload("res://scripts/field/maps/authored_support.gd")
const Native:=preload("res://scripts/field/maps/experimental_native_support.gd")
var comparisons:=0
func compare(reference, native, p:Vector2,id:String=""):
 var expected:Dictionary=reference.support(p,id);var actual:Dictionary=native.support(p,id)
 assert(var_to_bytes(expected)==var_to_bytes(actual),"BYTE_MISMATCH "+str(p)+" "+id+" "+str(expected)+" != "+str(actual))
 comparisons+=1
func surface(id:String,y:float)->Dictionary:
 return {"id":id,"walkable":true,"vertices":[[0,y,0],[4,y,0],[4,y+1,4],[0,y+1,4]],"triangles":[[0,1,2],[0,2,3]]}
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var reference:=Reference.new();var native:=Native.new()
 reference.exact_cache_enabled=false;native.exact_cache_enabled=false
 assert(reference.configure(d.surfaces)==OK);assert(native.configure(d.surfaces)==OK);assert(native.kernel!=null)
 # Every triangle: center, every vertex and all three edge midpoints, both implicit
 # and explicit tags, including overlapping surface boundaries and cell edges.
 for t:Dictionary in reference._triangles:
  var a:Vector3=t.a;var b:Vector3=t.b;var c:Vector3=t.c
  var pa:=Vector2(a.x,a.z);var pb:=Vector2(b.x,b.z);var pc:=Vector2(c.x,c.z)
  for p:Vector2 in [pa,pb,pc,(pa+pb+pc)/3.,(pa+pb)*.5,(pb+pc)*.5,(pc+pa)*.5]:
   compare(reference,native,p);compare(reference,native,p,t.surface_id)
 var rng:=RandomNumberGenerator.new();rng.seed=61112
 for i in 20000:
  var p:=Vector2(rng.randf_range(-65,90),rng.randf_range(-45,45));compare(reference,native,p)
  if i%13==0:
   for offset in [-.00002,-.00001,-.000001,0.,.000001,.00001,.00002]:
    compare(reference,native,Vector2(floorf(p.x)+offset,p.y))
 for id in ["","unknown","west_terrace"]:
  for p in [Vector2(NAN,0),Vector2(INF,0),Vector2(-INF,INF),Vector2(1e25,1e25),Vector2(-1e25,1e25),Vector2(-0.,0.)]:compare(reference,native,p,id)
 # Layer errors, coincident seams, reversed winding, same-surface conflicting heights.
 var conflict=surface("conflict",0.);conflict.vertices.append_array([[0,5,0],[4,5,0],[4,6,4],[0,6,4]]);conflict.triangles.append_array([[4,5,6],[4,6,7]])
 var reversed=surface("reverse",0.);reversed.triangles=[[2,1,0],[3,2,0]]
 for rows in [[surface("ground",0.)],[surface("ground",0.),surface("bridge",5.)],[surface("ground",0.),surface("seam",0.)],[conflict],[reversed]]:
  var r:=Reference.new();var n:=Native.new();r.exact_cache_enabled=false;n.exact_cache_enabled=false
  assert(r.configure(rows)==OK);assert(n.configure(rows)==OK);assert(n.kernel!=null)
  for x in [-.0001,-.00004,-.00001,0.,.00001,1.99999,2.,2.00001,3.99999,4.,4.00001,4.00004,4.0001]:
   for z in [-.0001,-.00004,-.00001,0.,.00001,1.99999,2.,2.00001,3.99999,4.,4.00001,4.00004,4.0001]:
    compare(r,n,Vector2(x,z))
    for row in rows:compare(r,n,Vector2(x,z),row.id)
 # Same instance can explicitly fall back without a platform dependency.
 native.native_enabled=false
 for i in 1000:compare(reference,native,Vector2(rng.randf_range(-65,90),rng.randf_range(-45,45)))
 var invalid=ClassDB.instantiate("HF08SupportKernel")
 assert(invalid.configure([{}],{})==ERR_INVALID_DATA)
 assert(invalid.support(Vector2.ZERO,"").error==ERR_INVALID_PARAMETER)
 assert(invalid.configure(reference._triangles,{Vector2i.ZERO:[-1]})==ERR_INVALID_DATA)
 assert(invalid.configure(reference._triangles,reference._cells)==OK)
 assert(invalid.configure(reference._triangles,reference._cells)==ERR_ALREADY_IN_USE)
 var report={"result":"PASS","byte_equal_queries":comparisons,"source_sha256":FileAccess.get_sha256(args[0]),"vector_real_bytes":PackedVector2Array([Vector2.ZERO]).to_byte_array().size()/2,"scalar_preserves_2_pow_minus_40":1.+pow(2.,-40)!=1.,"vector_rounds_2_pow_minus_40":Vector2(1.+pow(2.,-40),0).x==1.,"native_kernel_loaded":native.kernel!=null,"explicit_fallback_queries":1000,"malformed_native_index_rejected":true,"scope":"Same ordered source cells, float32 vectors/cross, float64 scalar arithmetic, exact dictionary bytes; Linux only, not FPS"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("NATIVE_SUPPORT_PARITY ",JSON.stringify(report));quit()
