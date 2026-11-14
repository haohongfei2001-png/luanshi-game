extends SceneTree
const LOD=preload("res://tools/representation_compare/explicit_lod.gd")
func _initialize():go.call_deferred()
func go():
 var source=load("res://assets/ubc_lab/ubc_animated.glb").instantiate();root.add_child(source)
 var checks=0;var rows=[]
 for native:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  for tier in [0,1,2,3]:
   var selected=LOD.select(native.mesh,tier);assert(not selected.has("error"),str(selected))
   var mesh:ArrayMesh=selected.mesh
   for s in mesh.get_surface_count():
    var before=native.mesh.surface_get_arrays(s);var after=mesh.surface_get_arrays(s)
    for channel in Mesh.ARRAY_MAX:
     if channel==Mesh.ARRAY_INDEX:continue
     assert(var_to_bytes(before[channel])==var_to_bytes(after[channel]),str([native.name,tier,channel]));checks+=1
    assert(mesh.surface_get_material(s)==native.mesh.surface_get_material(s));checks+=1
    assert(mesh.surface_get_array_index_len(s)<=native.mesh.surface_get_array_index_len(s));checks+=1
   rows.append({"name":native.name,"tier":tier,"surfaces":selected.inventory})
 print("EXPLICIT_LOD ",JSON.stringify({"checks":checks,"tiers":rows,"image_quality_validated":false,"bones_and_weights_unchanged":true}));quit()
