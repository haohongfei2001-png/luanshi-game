"""Source19 UV-only editable derivative recipe. Default is READ-ONLY dry-run.
Do not enable write until the frozen source18 Mobile/Metal control is complete.
Does not export GLB, alter rig/actions/weights/geometry, change palette, or remove normals.
"""
import bpy,sys,json,hashlib,struct,zlib
from pathlib import Path
import numpy as np
args=sys.argv[sys.argv.index('--')+1:];source,out=map(Path,args[:2]);write='--write-derived-source' in args[2:];out.mkdir(parents=True,exist_ok=True)
assert hashlib.sha256(source.read_bytes()).hexdigest()=='affeac881437b0c628cc3661c1bfe2fd36b9d9c93ffb1d4cb4fccfd30047820a'
bpy.ops.wm.open_mainfile(filepath=str(source),use_scripts=False,load_ui=False)
armor='V2 continuous lamellar cuirass';linen='V3 thin wrapped linen with physical overlap';rows=[]
# Preserve source vertex positions, topology, weights and all animation data.
def signature():
 return {o.name:hashlib.sha256(repr(([tuple(v.co) for v in o.data.vertices],[(tuple(p.vertices)) for p in o.data.polygons],[[(g.group,g.weight) for g in v.groups] for v in o.data.vertices])).encode()).hexdigest() for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render}
before=signature();actions=[(a.name,tuple(a.frame_range),len(a.fcurves)) for a in bpy.data.actions]
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.hide_render:continue
 names={m.name for m in o.data.materials if m}
 if not names.intersection({armor,linen}):continue
 assert len(names)==1,'Multi-material mesh needs explicit per-loop handling'
 old=next((layer for layer in o.data.uv_layers if layer.active_render),None);assert old is not None
 coords=np.empty(len(old.data)*2,dtype=np.float32);old.data.foreach_get('uv',coords);coords=coords.reshape(-1,2)
 is_armor=armor in names
 if is_armor:assert old.name=='LamellarPatternUV';coords*=np.array([.125,.25])
 rows.append({'object':o.name,'source_render_uv':old.name,'source_render_uv_index':list(o.data.uv_layers.keys()).index(old.name),'new_only_uv':'RuntimeMaterialUV0','scale':[.125,.25] if is_armor else [1,1],'material':next(iter(names)),'loop_count':len(coords)})
 if write:
  o.data=o.data.copy()
  for layer in list(o.data.uv_layers):o.data.uv_layers.remove(layer)
  uv=o.data.uv_layers.new(name='RuntimeMaterialUV0');uv.data.foreach_set('uv',coords.reshape(-1));uv.active_render=True
# Bake normal and ORM periodicity into textures, not colors. Base atlas remains byte-identical.
# Blender UV'=UV/(8,4): tiledMap(UV') == originalMap(UV). Exported V conversion
# applies equally to all channels; no per-texture KHR transform remains.
material=bpy.data.materials[armor];tile_reports=[]
for node_name in ['Image Texture.001','Image Texture.002']:
 node=material.node_tree.nodes[node_name];im=node.image;assert im is not None
 w,h=im.size;assert w>0 and h>0 and len(im.pixels)>0 and im.packed_file is not None
 tile_reports.append({'node':node_name,'source_image':im.name,'source_size':[w,h],'target_size':[w*8,h*4],'periods':[8,4],'no_color_transform':True})
 if write:
  pixels=np.empty(w*h*4,dtype=np.float32);im.pixels.foreach_get(pixels);a=np.clip(np.rint(pixels.reshape(h,w,4)*255),0,255).astype(np.uint8);t=np.tile(a,(4,8,1))
  # PNG stores top row first; Blender Image.pixels begins at the bottom row.
  raw=b''.join(b'\0'+row.tobytes() for row in t[::-1]);filename=out/(node_name.replace(' ','_')+'-uv19.png')
  def chunk(tag,data):return struct.pack('>I',len(data))+tag+data+struct.pack('>I',zlib.crc32(tag+data)&0xffffffff)
  filename.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w*8,h*4,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
  derived=bpy.data.images.load(str(filename),check_existing=False);derived.colorspace_settings.name='Non-Color';derived.pack();node.image=derived
if write:
 # All images now use the same first UV set; remove only the baseColor mapping link.
 color=material.node_tree.nodes['Image Texture.003']
 for link in list(color.inputs['Vector'].links):material.node_tree.links.remove(link)
 for mat_name in [armor,linen]:
  mat=bpy.data.materials[mat_name]
  for n in mat.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.uv_map='RuntimeMaterialUV0'
 assert before==signature(),'UV correction changed geometry or weights'
 assert actions==[(a.name,tuple(a.frame_range),len(a.fcurves)) for a in bpy.data.actions]
 # Original packed source retains invalid old filenames but real image bytes.
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-uv19-editable.blend'))
report={'mother_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'mode':'WRITE_DERIVED_SOURCE' if write else 'DRY_RUN_NO_ASSET_CHANGED','surfaces':rows,'normal_ORM_tile_recipe':tile_reports,'geometry_weights_actions_unchanged':before==signature(),'status':'NOT_ENABLED_NOT_EXPORTED_NOT_GPU_TESTED_NOT_ART_ACCEPTED','limitations':'Exact base-level repeat sampling by construction; exported UV0/tangents, mip sampling and actual GPU still require new independent checks. Does not fix official GLES native Skin tangent packing bug.'}
(out/'source19-uv-plan.json').write_text(json.dumps(report,indent=2));print(report['mode'],len(rows),'surfaces')
