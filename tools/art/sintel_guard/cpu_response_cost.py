"""Single-host response-only microbenchmark, not game FPS."""
import numpy as np,time,json,platform,os,sys,pathlib
from scipy.sparse import csr_matrix
H=np.load(sys.argv[1])['coefficients'].astype('f4');S=csr_matrix(H);rng=np.random.default_rng(19);rows=[]
for count in [1,20,100,250,512]:
 x=rng.normal(0,.1,(566,count*3)).astype('f4')
 for label,mat in [('dense_float32',H),('exact_nonzero_csr_float32',S)]:
  y=mat@x;samples=[]
  for i in range(12):
   start=time.perf_counter_ns();y=mat@x;samples.append((time.perf_counter_ns()-start)/1e6)
  rows.append({'actors':count,'method':label,'avg_ms':float(np.mean(samples)),'p50_ms':float(np.percentile(samples,50)),'p95_ms':float(np.percentile(samples,95)),'p99_ms':float(np.percentile(samples,99)),'bytes_input_frame':int(x.nbytes),'bytes_output_frame':int(y.nbytes)})
p={'platform':platform.platform(),'processor':next((line.split(':',1)[1].strip() for line in pathlib.Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')),platform.processor()),'numpy_version':np.__version__,'threads_env':{k:os.environ.get(k) for k in ['OMP_NUM_THREADS','OPENBLAS_NUM_THREADS']},'scope':'single CPU host matrix response only; NOT complete character/game/GPU FPS; no DQ, normals, multires, rig eval or draw included','rows':rows};open(sys.argv[2],'w').write(json.dumps(p,indent=2));print(json.dumps(p))
