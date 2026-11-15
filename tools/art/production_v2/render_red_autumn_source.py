"""Original-source EEVEE diagnostic. NOT Godot or a game-quality acceptance."""
import bpy, gpu, hashlib, json, struct, sys, zlib
from pathlib import Path
source, output = map(Path, sys.argv[sys.argv.index('--')+1:])
assert hashlib.sha256(source.read_bytes()).hexdigest() == 'b60bd6d566d202cc9cd8c0bd260a45be0ab8c37fc24e0d2e9c909efa41e94655'
assert bpy.app.version[:3] == (5,2,4), bpy.app.version_string
bpy.ops.wm.open_mainfile(filepath=str(source), use_scripts=False)
s=bpy.context.scene
assert s.render.engine == 'BLENDER_EEVEE', s.render.engine
assert s.camera and s.camera.name == 'Camera_1'
assert not any(n.bl_idname == 'NodeUndefined' for g in list(bpy.data.node_groups)+[m.node_tree for m in bpy.data.materials if m.use_nodes] for n in g.nodes)
def identity():
 return {'camera':s.camera.name,'camera_matrix':[list(r) for r in s.camera.matrix_world], 'lights':[{ 'name':o.name,'matrix':[list(r) for r in o.matrix_world],'energy':o.data.energy,'color':list(o.data.color)} for o in s.objects if o.type=='LIGHT'], 'engine':s.render.engine,'frame':s.frame_current,'materials':[(m.name, len(m.node_tree.nodes) if m.use_nodes else 0) for m in bpy.data.materials]}
before=identity(); output.mkdir(parents=True,exist_ok=True)
report={'scope':'original Blender source, not Godot, not art acceptance','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'blender':bpy.app.version_string,'original_resolution':[s.render.resolution_x,s.render.resolution_y,s.render.resolution_percentage],'original':before,'license':'Robin Tran / Red Autumn Forest / CC-BY-SA 3.0','source_url':'https://download.blender.org/demo/splash/blender-2.91-splash.blend'}
(output/'started.json').write_text(json.dumps(report,indent=2))
s.render.resolution_x=850;s.render.resolution_y=312;s.render.resolution_percentage=100
s.render.image_settings.media_type='IMAGE';s.render.image_settings.file_format='PNG';s.render.use_stamp=False
s.render.filepath=str(output/'original-eevee-NOT-GAME.png')
bpy.ops.render.render(write_still=True)
assert identity()==before, 'Source camera, lights or engine changed'
p=Path(s.render.filepath); data=p.read_bytes(); assert data[:8]==b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II',data[16:24])==(850,312)
pos=8; idat=b''; ended=False
while pos<len(data):
 size=struct.unpack('>I',data[pos:pos+4])[0]; tag=data[pos+4:pos+8]; block=data[pos+8:pos+8+size]; crc=struct.unpack('>I',data[pos+8+size:pos+12+size])[0]
 assert zlib.crc32(tag+block)&0xffffffff==crc
 if tag==b'IDAT':idat+=block
 if tag==b'IEND':ended=True
 pos+=size+12
assert ended and len(zlib.decompress(idat))>850*312
report.update(completed=True,png_sha256=hashlib.sha256(data).hexdigest(),png_bytes=len(data),dimensions=[850,312])
report['gpu']={}
for name in ['backend_type_get','vendor_get','renderer_get','version_get','device_type_get']:
 try:report['gpu'][name]=getattr(gpu.platform,name)()
 except Exception as e:report['gpu'][name]='unavailable: '+str(e)
(output/'completed.json').write_text(json.dumps(report,indent=2));print('SOURCE_RENDER_COMPLETE',json.dumps(report),flush=True)
