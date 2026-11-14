extends SceneTree
## Counts only. Does not certify any LOD's visible image quality.
func _initialize():go.call_deferred()
func go():
 var source=load("res://assets/ubc_lab/ubc_animated.glb").instantiate();root.add_child(source)
 var report={"source_sha":FileAccess.get_sha256("res://assets/ubc_lab/ubc_animated.glb"),"image_quality_validated":false,"meshes":[]}
 for native:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  for surface in native.mesh.get_surface_count():
   var raw=RenderingServer.mesh_get_surface(native.mesh.get_rid(),surface)
   var count=native.mesh.surface_get_array_len(surface)
   var stride=RenderingServer.mesh_surface_get_format_index_stride(raw.format,count)
   var row={"mesh":native.name,"surface":surface,"vertices":count,"full_triangles":native.mesh.surface_get_array_index_len(surface)/3,"lods":[]}
   for lod:Dictionary in raw.get("lods",[]):
    var bytes:PackedByteArray=lod.index_data
    assert(stride in [2,4] and bytes.size()%stride==0)
    row.lods.append({"edge_length":lod.edge_length,"triangles":bytes.size()/stride/3})
   report.meshes.append(row)
 var path=OS.get_environment("LOD_INVENTORY_OUTPUT")
 if not path.is_empty():FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("LOD_INVENTORY ",JSON.stringify(report));quit()
