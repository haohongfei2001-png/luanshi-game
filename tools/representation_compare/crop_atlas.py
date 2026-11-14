"""Lossless visible-pixel crop, no resampling; source root anchors preserved.
Produces new PNG/metadata only. Filtered mip/alpha/depth quality still requires GPU.
"""
import pathlib,json,sys,math,hashlib,copy
from PIL import Image,ImageChops
src=pathlib.Path(sys.argv[1]);out=pathlib.Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
original=json.loads((src/'atlas.json').read_text());meta=copy.deepcopy(original)
ppm=original['pixels_per_metre'];bounds={(r[0],int(r[1]),int(r[2])):tuple(map(int,r[3:])) for r in original['alpha_pixel_bounds']}
checks=0;pixel_count=0;records=[];new_bounds=[];guard=16
for clip,old in original['clips'].items():
 info=meta['clips'][clip];oldw,oldh=map(int,old['tile']);count=int(old['count'])
 used=[bounds[clip,f,d] for f in range(count) for d in range(16)]
 w=math.ceil((max(r[2] for r in used)+2*guard)/16)*16;h=math.ceil((max(r[3] for r in used)+2*guard)/16)*16
 cols=4096//w;rows=4096//h;capacity=cols*rows;page_size=(cols*w,rows*h)
 info['tile']=[w,h];info['world_size']=[w/ppm,h/ppm];info['page_rows']=rows
 centers=[]
 for f in range(count):
  for d in range(16):
   x,y,bw,bh=bounds[clip,f,d]
   centers.append([old['center_projected'][0]+(x-guard+w/2-oldw/2)/ppm,old['center_projected'][1]-(y-guard+h/2-oldh/2)/ppm])
   new_bounds.append([clip,f,d,guard,guard,bw,bh])
 info['center_offsets16']=centers
 for directions in [16,8]:
  info['columns'+str(directions)]=cols
  page=Image.new('RGBA',page_size);n=0;loaded=-1;original_page=None
  oldcols=int(old['columns16']);oldcap=oldcols*int(old['page_rows'])
  for f in range(count):
   for d in range(directions):
    source_dir=d if directions==16 else d*2
    index=f*16+source_dir;source_page=index//oldcap;local=index%oldcap
    if source_page!=loaded:
     if original_page:original_page.close()
     original_page=Image.open(src/f'{clip}-16-page{source_page}.png').convert('RGBA');loaded=source_page
    tile=original_page.crop(((local%oldcols)*oldw,(local//oldcols)*oldh,(local%oldcols+1)*oldw,(local//oldcols+1)*oldh))
    x,y,bw,bh=bounds[clip,f,source_dir];assert tile.getchannel('A').getbbox()==(x,y,x+bw,y+bh)
    cropped=tile.crop((x,y,x+bw,y+bh));target=f*directions+d;slot=target%capacity
    page.paste(cropped,((slot%cols)*w+guard,(slot//cols)*h+guard))
    # Reconstruct full original alpha and every nonzero-alpha pixel exactly.
    reconstructed=Image.new('RGBA',tile.size);reconstructed.paste(cropped,(x,y))
    assert ImageChops.difference(tile.getchannel('A'),reconstructed.getchannel('A')).getbbox() is None
    visible=tile.getchannel('A').point(lambda a:255 if a else 0)
    assert ImageChops.multiply(ImageChops.difference(tile.convert('RGB'),reconstructed.convert('RGB')),Image.merge('RGB',(visible,visible,visible))).getbbox() is None
    # Algebraic same camera projected root anchor, no manual foot repositioning.
    center=centers[index]
    assert abs((center[0]+(guard-w/2)/ppm)-(old['center_projected'][0]+(x-oldw/2)/ppm))<1e-10
    assert abs((center[1]-(guard-h/2)/ppm)-(old['center_projected'][1]-(y-oldh/2)/ppm))<1e-10
    checks+=4;pixel_count+=bw*bh
    if slot==capacity-1 or target==count*directions-1:
     page.save(out/f'{clip}-{directions}-page{n}.png');n+=1;page=Image.new('RGBA',page_size)
  if original_page:original_page.close()
  info['atlas'+str(directions)]={'png_pages':n,'dimensions':list(page_size),'rgba8_bytes':page_size[0]*page_size[1]*4*n}
 records.append({'clip':clip,'old_tile':[oldw,oldh],'new_tile':[w,h],'copied_body_extent_max':[max(r[2] for r in used),max(r[3] for r in used)]})
meta['alpha_pixel_bounds']=new_bounds
meta['compression']='pending offline compression of lossless-cropped original PNGs'
meta['crop_proof']={'method':'exact source alpha bounding boxes, 16px transparent guards, no resample; original root projection via per-frame offsets','checks':checks,'copied_bbox_pixels_with_repeated_8way_subset':pixel_count,'visible_pixels_exact':True,'root_projected_anchor_exact':True,'filtered_mipmap_quality':'NOT_YET_GPU_TESTED','original_meta_sha256':hashlib.sha256((src/'atlas.json').read_bytes()).hexdigest(),'records':records}
(out/'atlas.json').write_text(json.dumps(meta,indent=2)+'\n')
print(json.dumps(meta['crop_proof'],indent=2))
