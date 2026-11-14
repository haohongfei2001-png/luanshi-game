"""Independent algebra check of Godot 4.6.3 normalized tangent encoding."""
import json, math

def sign(x):return -1.0 if x < 0 else 1.0

def normalize(v):
 n=math.sqrt(sum(x*x for x in v));return tuple(x/n for x in v)

def encode(v,w):
 n=sum(abs(x) for x in v);x,y,z=[a/n for a in v]
 if z<0:x,y=(1-abs(y))*sign(x),(1-abs(x))*sign(y)
 x,y=x*.5+.5,y*.5+.5;y=max(y,1/32767);y=y*.5+.5
 return (x,y if w>0 else 1-y)

def oct_decode(x,y):
 x,y=x*2-1,y*2-1;z=1-abs(x)-abs(y)
 if z<0:x,y=(1-abs(y))*sign(x),(1-abs(x))*sign(y)
 return normalize((x,y,z))

def decode(e,corrected):
 x,y=e
 if corrected:
  sy=y*2-1;return oct_decode(x,abs(sy)),sign(sy)
 return oct_decode(x,abs(y)*2-1),sign(y)

rows=[]
for v in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]:
 for w in [-1,1]:
  encoded=tuple(round(x*65535)/65535 for x in encode(v,w))
  old,old_w=decode(encoded,False);fixed,fixed_w=decode(encoded,True)
  error=math.dist(v,fixed)
  assert error<0.0001 and fixed_w==w,(v,w,error,fixed_w)
  rows.append(dict(source=v,handedness=w,encoded=encoded,original_error=math.dist(v,old),original_w=old_w,corrected_error=error,corrected_w=fixed_w))
assert any(r['original_w']!=r['handedness'] for r in rows)
print(json.dumps({'cases':rows,'corrected_pass':True,'scope':'algebra only; real native renderer gates still required'},indent=2))
