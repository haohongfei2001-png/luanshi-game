"""Blender-only bounded PBR intake for the complete structure study."""
import bpy,json,hashlib
from pathlib import Path
def apply(materials,root):
 root=Path(root);source=json.loads(Path(__file__).with_name('surface-sources.json').read_text());scales={}
 for family,spec in source['materials'].items():
  role={}
  for row in spec['files']:
   path=root/row['file'];assert path.stat().st_size==row['bytes'] and hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256'],path
   role[row['role']]=path
  for name in (['timber','timber_cut'] if family=='timber' else ['masonry']):
   m=materials[name];m.node_tree.nodes.clear();nodes=m.node_tree.nodes;links=m.node_tree.links
   bsdf=nodes.new('ShaderNodeBsdfPrincipled');bsdf.inputs['Metallic'].default_value=0.;bsdf.inputs['Alpha'].default_value=1.
   output=nodes.new('ShaderNodeOutputMaterial');links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
   uv=nodes.new('ShaderNodeUVMap');uv.uv_map='MaterialUV_Metre'
   def texture(key,colour=False):
    node=nodes.new('ShaderNodeTexImage');node.image=bpy.data.images.load(str(role[key]),check_existing=True);node.image.colorspace_settings.name='sRGB' if colour else 'Non-Color';links.new(uv.outputs['UV'],node.inputs['Vector']);return node
   links.new(texture('Diffuse',True).outputs['Color'],bsdf.inputs['Base Color'])
   links.new(texture('Rough').outputs['Color'],bsdf.inputs['Roughness'])
   normal=nodes.new('ShaderNodeNormalMap');normal.uv_map='MaterialUV_Metre';normal.inputs['Strength'].default_value=float(spec['normal_strength']);links.new(texture('nor_gl').outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
   # Preserve source micro-occlusion as standard glTF occlusion data. Never
   # multiply it into albedo or pretend this is architectural contact shadow.
   # Blender 4.3 glTF exporter consumes this explicitly named group/socket.
   group=bpy.data.node_groups.get('glTF Material Output')
   if group is None:
    group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree')
    group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
    group.nodes.new('NodeGroupInput');group.nodes.new('NodeGroupOutput')
   settings=nodes.new('ShaderNodeGroup');settings.node_tree=group
   links.new(texture('AO').outputs['Color'],settings.inputs['Occlusion'])
   m['occlusion_scope']='original licensed material micro-occlusion; not baked architectural/global contact shadow'
   scales[name]=float(spec['tile_metres']);m['source']=spec['source'];m['license']='CC0-1.0';m['tile_metres']=scales[name]
 return scales
