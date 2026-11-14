extends SceneTree
## Offline editor-tools step only; no substitute renderer or invented GPU size.
func _initialize()->void:run.call_deferred()
func run()->void:
 var path=OS.get_environment("COMPARE_ASSETS")
 var meta=JSON.parse_string(FileAccess.get_file_as_string(path.path_join("atlas.json")))
 assert(meta.padding_failures.is_empty(),"Source body was cropped")
 for clip:String in meta.clips:
  for directions in [8,16]:
   var receipt=meta.clips[clip]["atlas"+str(directions)];var descriptors=[];var bytes=0;var raw_mips=0
   for page in int(receipt.png_pages):
    var image=Image.load_from_file(path.path_join(clip+"-"+str(directions)+"-page"+str(page)+".png"))
    assert(image!=null);image.convert(Image.FORMAT_RGBA8);image.generate_mipmaps();raw_mips+=image.get_data().size()
    assert(image.compress(Image.COMPRESS_S3TC)==OK,"Run this offline compressor in official editor, not template")
    bytes+=image.get_data().size()
    var filename=clip+"-"+str(directions)+"-page"+str(page)+".s3tc"
    FileAccess.open(path.path_join(filename),FileAccess.WRITE).store_buffer(image.get_data())
    descriptors.append({"file":filename,"width":image.get_width(),"height":image.get_height(),"format":image.get_format(),"mipmaps":image.has_mipmaps(),"mipmap_count":image.get_mipmap_count(),"bytes":image.get_data().size(),"sha256":FileAccess.get_sha256(path.path_join(filename))})
   receipt["compressed_mip_bytes"]=bytes;receipt["rgba8_mip_bytes"]=raw_mips;receipt["layers"]=descriptors.size();receipt["image_format"]=descriptors[0].format;receipt["mipmaps"]=descriptors[0].mipmap_count;receipt["pages"]=descriptors
   print("PACKED_CONTROL ",clip," ",directions," bytes=",bytes)
   await process_frame
 meta["compression"]="S3TC direct Image byte payload, no dummy-renderer Texture2DArray serialization; runtime constructs actual graphics textures; renderer remains patched35e80"
 meta["compressor_engine"]=Engine.get_version_info()
 FileAccess.open(path.path_join("atlas.json"),FileAccess.WRITE).store_string(JSON.stringify(meta,"  "));quit()
