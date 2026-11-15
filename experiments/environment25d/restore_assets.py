from pathlib import Path
import gzip,hashlib,json
root=Path(__file__).parent
source=root/'assets/spearman-v2-source18.glb.gz'
target=root/'assets/spearman-v2-wip.glb'
packed=source.read_bytes();assert len(packed)==10442257
assert hashlib.sha256(packed).hexdigest()=='caf49a68890e78644448489a8df7e2bafe2d2dc1617f6270fa886248e65737d7'
raw=gzip.decompress(packed);assert len(raw)==14173132
sha=hashlib.sha256(raw).hexdigest();assert sha=='afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b'
if target.exists():assert target.read_bytes()==raw,'refuse to overwrite unexpected runtime file'
else:target.write_bytes(raw)
print(json.dumps({'asset':target.name,'bytes':len(raw),'sha256':sha,'restore':'exact compressed source, not derivative or texture replacement'}))
