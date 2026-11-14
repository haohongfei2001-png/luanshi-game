"""Report approximations against held-out native points; never enable them."""
import numpy as np,time,json,pathlib,sys
reference,response,output=map(pathlib.Path,sys.argv[1:4]);output.mkdir(parents=True,exist_ok=True);z=np.load(reference);h=np.load(response);H=h['coefficients'];start=time.perf_counter();u,s,v=np.linalg.svd(H,full_matrices=False);rows=[]
for rank in [8,16,32,64,96,128,192,256,384,566]:
 L=u[:,:rank]*s[:rank];R=v[:rank];worst=0.;rms=0.
 for i in range(25):
  c=z[f'pose_{i}_cage']-h['cage_rest'];pred=h['top_rest']+L@(R@c)@h['cage_to_top_linear'].T;d=np.linalg.norm(pred-z[f'pose_{i}_top'],axis=1);worst=max(worst,float(d.max()));rms=max(rms,float(np.sqrt(np.mean(d*d))))
 rows.append({'rank':rank,'max_m':worst,'max_pose_rms_m':rms,'shared_bytes_float32':int((L.size+R.size)*4),'scalar_macs_per_frame':int((L.size+R.size)*3),'discarded_spectral_norm':float(s[rank]) if rank<len(s) else 0.})
r={'poses':25,'scope':'top1373 only, author evaluated cage; not GPU timing or full outfit','svd_seconds':time.perf_counter()-start,'ranks':rows};(output/'rank-cost.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))

rows=[]
for threshold in [0,1e-8,1e-7,1e-6,1e-5,1e-4,1e-3]:
 K=np.where(np.abs(H)>threshold,H,0);worst=0.;bound=0.
 for i in range(25):
  c=z[f'pose_{i}_cage']-h['cage_rest'];pred=h['top_rest']+(K@c)@h['cage_to_top_linear'].T;worst=max(worst,float(np.linalg.norm(pred-z[f'pose_{i}_top'],axis=1).max()));bound=max(bound,float(np.abs(H-K).sum(axis=1).max()*np.linalg.norm(c,axis=1).max()*np.linalg.norm(h['cage_to_top_linear'],2)))
 rows.append({'threshold':threshold,'nonzero':int(np.count_nonzero(K)),'max_row_entries':int(np.count_nonzero(K,axis=1).max()),'max_error_m':worst,'max_row_l1_omitted':float(np.abs(H-K).sum(axis=1).max()),'worst_pose_extra_error_bound_m':bound})
(output/'sparse-cost.json').write_text(json.dumps(rows,indent=2)+'\n')
