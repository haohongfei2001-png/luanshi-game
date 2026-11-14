extends RefCounted
## Index-only selection from importer LODs, preserving packed vertex attributes.
## Uses Godot 4.6.3 ArrayMesh serialization, deliberately version-scoped.
## Never an automatic quality pass. A screen-space image test must select a tier.
static func select(source:ArrayMesh,tier:int)->Dictionary:
 if tier<0:return {"error":"negative tier"}
 if source.get_blend_shape_count()>0:return {"error":"unbaked blendshapes unsupported"}
 var result=ArrayMesh.new();var inventory=[]
 var surfaces:Array=source.get("_surfaces").duplicate(true)
 for surface in surfaces.size():
  var raw:Dictionary=surfaces[surface]
  var count:int=raw.vertex_count
  var lods:Array=raw.get("lods",[])
  var chosen=mini(tier,lods.size()/2)
  var edge=0.
  var full_count:int=raw.index_count
  if chosen>0:
   var stride=RenderingServer.mesh_surface_get_format_index_stride(raw.format,count)
   var bytes:PackedByteArray=lods[(chosen-1)*2+1]
   if stride not in [2,4] or bytes.size()%stride!=0:return {"error":"LOD encoding unsupported"}
   for offset in range(0,bytes.size(),stride):
    var index=bytes.decode_u16(offset) if stride==2 else bytes.decode_u32(offset)
    if index>=count:return {"error":"LOD index outside original vertices"}
   raw.index_data=bytes;raw.index_count=bytes.size()/stride;edge=lods[(chosen-1)*2]
  raw.erase("lods")
  inventory.append({"source_vertices":count,"source_triangles":full_count/3,"selected_triangles":raw.index_count/3,"selected_tier":chosen,"edge_length":edge})
 result.set("_surfaces",surfaces)
 return {"mesh":result,"inventory":inventory,"quality_validated":false,"vertex_processing_reduction_claimed":false}
