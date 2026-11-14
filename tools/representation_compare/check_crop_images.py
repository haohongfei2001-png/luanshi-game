"""Report raw full-canvas differences; never call this an art/body-mask pass."""
import pathlib,json,sys
from PIL import Image,ImageChops
original=pathlib.Path(sys.argv[1]);candidate=pathlib.Path(sys.argv[2]);rows=[]
for name in ['smoke-2560x1440-sprite8-lod0','smoke-2560x1440-sprite16-lod0','smoke-3840x2160-sprite16-lod0']:
 a=json.loads((original/name/'report.json').read_text());b=json.loads((candidate/name/'report.json').read_text())
 for k in ['seed','end_tick','end_snapshot_sha','viewport','camera_ortho_size','internal_scale']:assert a[k]==b[k],(name,k)
 old=Image.open(original/name/'same-tick-native.png').convert('RGB');new=Image.open(candidate/name/'same-tick-native.png').convert('RGB');assert old.size==new.size
 diff=ImageChops.difference(old,new);maximum=ImageChops.lighter(ImageChops.lighter(*diff.split()[:2]),diff.split()[2]);hist=maximum.histogram();pixels=old.width*old.height
 rows.append({'case':name,'full_canvas_pixels':pixels,'changed_pixels':pixels-hist[0],'over_two_levels_pixels':sum(hist[3:]),'max_channel_error_levels':max(i for i,n in enumerate(hist) if n),'mean_max_channel_error_levels':sum(i*n for i,n in enumerate(hist))/pixels,'difference_bounds':diff.getbbox(),'compressed_bytes_before':a['atlas_compressed_mip_bytes'],'compressed_bytes_after':b['atlas_compressed_mip_bytes'],'gpu_counter_after':b['texture_memory'],'resident_process_memory_after':b['resident_process_memory']})
(candidate/'crop-image-differences.json').write_text(json.dumps({'same_real_battle':True,'image_metric_scope':'full canvas, NOT character-mask error; no automatic quality acceptance','filter_compression_review':'REQUIRED','art_pass':False,'samples':rows},indent=2)+'\n')
