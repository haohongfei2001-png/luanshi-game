"""Restore the previously licensed original whole tree, not inflated-leaf derivative.
No source geometry/UV/material adaptation. Exact historical input MD5 + new SHA256.
"""
import argparse,hashlib,json,pathlib,urllib.request
from pathlib import Path

def restore(manifest,output):
    source=json.loads(manifest.read_text()); output.mkdir(parents=True,exist_ok=True)
    frozen=json.loads(Path(__file__).with_name('original_tree_manifest.json').read_text())
    files=[(entry['path'],entry['md5'],entry['url']) for entry in frozen['files']]
    receipt=[]
    for name,md5,location in files:
        path=output/name;path.parent.mkdir(parents=True,exist_ok=True)
        if not path.exists():
            existing=manifest.parent/Path(name).name
            if existing.is_file() and hashlib.md5(existing.read_bytes()).hexdigest()==md5:
                path.write_bytes(existing.read_bytes())
        if not path.exists():
            req=urllib.request.Request(location,headers={'User-Agent':'LuanshiAssetRecovery/1.0'})
            with urllib.request.urlopen(req,timeout=90) as r:
                data=r.read(160_000_001)
            if len(data)>160_000_000: raise ValueError('Bounded original-tree download exceeded 160MB/file')
            if hashlib.md5(data).hexdigest()!=md5:raise ValueError('Original source MD5 mismatch: '+name)
            path.write_bytes(data)
        data=path.read_bytes()
        if hashlib.md5(data).hexdigest()!=md5:raise ValueError('Local original source mismatch: '+name)
        receipt.append({'path':name,'bytes':len(data),'md5':md5,'sha256':hashlib.sha256(data).hexdigest(),'source':location})
    document=json.loads((output/'island_tree_01_2k.gltf').read_text())
    dependencies=[r['uri'] for key in ['buffers','images'] for r in document.get(key,[]) if 'uri' in r]
    for dependency in dependencies:
        if not (output/dependency).is_file():raise ValueError('Missing original dependency '+dependency)
    result={'source':source['page'],'author':source['author'],'license':source['license'],'geometry_policy':'all original primitives and original leaf sizes; no simplification or enlarged foliage','status':'SOURCE_RESTORED_NOT_VISUALLY_ACCEPTED','files':receipt,'dependencies':dependencies}
    (output/'restoration.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('output',type=pathlib.Path);a=p.parse_args()
    restore(pathlib.Path(__file__).resolve().parents[3]/'assets/river_gate/world/masters/island_tree_01/SOURCE.json',a.output)
