"""Tiny PCK sidecar extracted from the exact immutable source GLB, no binary copy."""
import json,pathlib,sys,hashlib,struct
source,out=map(pathlib.Path,sys.argv[1:]);raw=source.read_bytes();sha=hashlib.sha256(raw).hexdigest();assert sha=='afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b';g=json.loads(raw[20:20+struct.unpack_from('<I',raw,12)[0]])
names=['V2 continuous lamellar cuirass','V3 thin wrapped linen with physical overlap'];d={'materials':[m for m in g['materials'] if m['name'] in names],'textures':g['textures'],'samplers':g['samplers']};assert len(d['materials'])==2
contract={'schema':'luanshi-source18-texture-uv-v1','source_glb_sha256':sha,'source_glb_bytes':len(raw),'expected_target_surfaces':18,'document':d,'source_integrity_scope':'Raw GLB SHA verified at extraction/preparation. Runtime sidecar SHA validates material contract, not unavailable remapped GLB bytes.'}
b=(json.dumps(contract,sort_keys=True,indent=2)+'\n').encode();out.write_bytes(b);print(hashlib.sha256(b).hexdigest(),len(b))
