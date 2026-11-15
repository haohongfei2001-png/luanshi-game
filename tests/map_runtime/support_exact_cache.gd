extends SceneTree
const Support:=preload("res://scripts/field/maps/authored_support.gd")
func _initialize():
 var support:=Support.new();var point:=Vector2(2,2)
 assert(support.support(point).error==ERR_INVALID_PARAMETER)
 assert(support._exact_cache.is_empty(),"Unconfigured errors must not poison later configured support")
 var surface={"id":"floor","walkable":true,"vertices":[[0,0,0],[4,0,0],[4,1,4],[0,1,4]],"triangles":[[0,1,2],[0,2,3]]}
 assert(support.configure([surface])==OK)
 var first:=support.support(point);assert(first.error==OK and first.is_read_only())
 assert(support.support(point+Vector2(0,.0001)).position.y!=first.position.y,"No same-cell height quantization")
 support.profile_enabled=true
 for i in 40000:
  var p:=Vector2((i%201)*.02,(i/201)*.02001)
  support.exact_cache_enabled=false;var original:=support.support(p)
  support.exact_cache_enabled=true;var cached:=support.support(p);assert(cached==original)
  assert(support.support(p)==original);assert(support._exact_cache.size()<=support.EXACT_CACHE_CAPACITY)
 assert(support._exact_cache.size()==support.EXACT_CACHE_CAPACITY)
 assert(support.support(point)==first,"Evicted exact point recomputes identical barycentric support")
 assert(support.support(point,"floor").position==first.position)
 print("EXACT_SUPPORT_CACHE_PASS 40000 unquantized parity queries + repeated hits + bounded32768 FIFO + immutable output + cold unconfigured rejection; NOT_GPU_PERFORMANCE");quit()
