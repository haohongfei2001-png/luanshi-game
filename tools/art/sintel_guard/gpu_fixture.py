"""Pack full original DQ and exact-nonzero response, never truncate weights."""
import bpy, numpy as np, pathlib,sys,json
from mathutils import Matrix
args=sys.argv[sys.argv.index('--')+1:];reference,response,out=map(pathlib.Path,args[:3]);out.mkdir(parents=True,exist_ok=True);z=np.load(reference);h=np.load(response)
def save(name,a):np.asarray(a,dtype='<f4').tofile(out/(name+'.f32'))
def rgba(a):return np.pad(a,((0,0),(0,4-a.shape[1])))
def mul(a,b):
 w,x,y,z=a;v,i,j,k=b;return np.array([w*v-x*i-y*j-z*k,w*i+x*v+y*k-z*j,w*j-x*k+y*v+z*i,w*k+x*j-y*i+z*v])
w=z['raw_weights'];packed=np.zeros((5,len(w),4))
for v,row in enumerate(w):
 ids=np.flatnonzero(row);assert len(ids)<=5
 for k,b in enumerate(ids):packed[k,v,:2]=[b,row[b]]
save('weights',packed);save('rest',rgba(z['raw_cage']));save('cage_rest',rgba(h['cage_rest']));save('top_rest',rgba(h['top_rest']))
H=h['coefficients'];packed=np.zeros((218,len(H),4));assert np.count_nonzero(H,axis=1).max()<=218
for v,row in enumerate(H):
 for k,c in enumerate(np.flatnonzero(row)):packed[k,v,:2]=[c,row[c]]
save('response',packed)
for i in range(25):
 m=z[f'pose_{i}_matrices'];q=np.array([Matrix(x.tolist()).to_quaternion()[:] for x in m]);d=np.array([.5*mul(np.r_[0.,x[:3,3]],a) for x,a in zip(m,q)]);save(f'dq_{i}',np.stack([q,d]));save(f'cage_{i}',z[f'pose_{i}_cage']);save(f'top_{i}',z[f'pose_{i}_top'])
(out/'meta.json').write_text(json.dumps({'cage_to_top':h['cage_to_top_linear'].tolist(),'poses':25,'scope':'coat base cage only; not multires or full outfit'}))
