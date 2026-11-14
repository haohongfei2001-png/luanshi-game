#!/usr/bin/env python3
"""Inspect an unchanged generated atlas. Does not synthesize missing animation."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image
import numpy as np

def audit(path):
    im=Image.open(path)
    if im.mode!='RGBA' or im.size!=(1536,1024):
        raise ValueError('Expected original RGBA 1536x1024 atlas')
    a=np.asarray(im)[:,:,3]
    names=['front','front_right','right','back_right','back','back_left','left','front_left']
    # Two ground contacts visually estimated. Not calibrated from a 3D camera.
    contacts=[[[121.4,429],[273.6,442]],[[124,376],[250.8,454]],[[150,345],[177.9,469]],[[99.6,386],[195.1,464]],[[132.2,453],[250.2,454]],[[123,409],[215.6,476]],[[207,367],[155.3,478]],[[118.8,397],[233,486]]]
    frames=[]
    for i,name in enumerate(names):
        x,y=i%4*384,i//4*512
        cell=a[y:y+512,x:x+384]; ys,xs=np.where(cell>=128)
        edge=max(cell[0].max(),cell[-1].max(),cell[:,0].max(),cell[:,-1].max())
        assert len(xs)>10000 and edge<128, ('clipped/empty frame',i)
        frames.append(dict(index=i,intended_direction=name,intended_yaw_degrees=i*45,rect=[x,y,384,512],alpha128_bounds=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],edge_max_alpha=int(edge),provisional_ground_contacts_px=contacts[i],anchor_px=np.mean(contacts[i],axis=0).tolist(),anchor_status='VISUAL_ESTIMATE_NOT_CALIBRATED',foreground_pixels=int(len(xs))))
    return dict(schema=1,source_sha256=hashlib.sha256(Path(path).read_bytes()).hexdigest(),source_bytes=Path(path).stat().st_size,source_kind='AI_GENERATED_STATIC_ASSET_EXPERIMENT',unchanged_source=True,size=[1536,1024],cell_size=[384,512],frames=frames,alpha_scissor_candidate=128/255,alpha_policy='Raw low-alpha residual retained in source; discard below threshold in probe only. Actual edge quality requires Godot review.',motions_available=['static_stance'],motions_missing=['walk','stop_transition','turn_transition','attack','defend','hit','death'],not_claimed=['camera_calibrated','direction_consistency_pass','gameplay_integration','art_acceptance','animation_complete'],reference_sha256='fef54505bf0adb82646cd5c9e955170b255b3cbb8c5d6cfe1dc49c623167a932',ordinary_spear_tassel=False,shipping_enabled=False)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('atlas');p.add_argument('--out',required=True);args=p.parse_args()
    result=audit(args.atlas);Path(args.out).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'sha256':result['source_sha256'],'frames':len(result['frames']),'boundary_check':'PASS','art_status':'NOT_ACCEPTED'}))
