from pathlib import Path
import base64,hashlib,json,os,struct,subprocess,sys
from urllib.request import Request,urlopen

def git_blob(path):
    b=path.read_bytes()
    digest=hashlib.sha1(('blob '+str(len(b))+'\x00').encode()+b).hexdigest()
    data=json.dumps({'content':base64.b64encode(b).decode(),'encoding':'base64'}).encode()
    hdr={'Accept':'application/vnd.github+json','Authorization':'Bearer '+os.environ['GITHUB_TOKEN'],'User-Agent':'luanshi-art-study','Content-Type':'application/json'}
    request=Request(os.environ['GITHUB_API_URL']+'/repos/'+os.environ['GITHUB_REPOSITORY']+'/git/blobs',data=data,headers=hdr)
    with urlopen(request,timeout=90) as resp: sha=json.load(resp)['sha']
    assert sha==digest
    print('TAIL_BLOB',path.name,sha,len(b),hashlib.sha256(b).hexdigest(),flush=True)

def geometry(path):
    src=path.read_bytes()
    length=struct.unpack_from('<I',src,12)[0]
    doc=json.loads(src[20:20+length]); raw=src[28+length:]
    result={}
    for mesh in doc['meshes']:
        p=mesh['primitives'][0]; result[mesh['name']]=[]
        for i in list(p['attributes'].values())+[p['indices']]:
            a=doc['accessors'][i]
            v=doc['bufferViews'][a['bufferView']];off=v.get('byteOffset',0)
            result[mesh['name']].append((hashlib.sha256(raw[off:off+v['byteLength']]).hexdigest(),a['count']))
    return result
if sys.argv[1]=='mesh':
    a,b=map(lambda p:geometry(Path(p)),sys.argv[2:4]); changes=[m for m in a if a[m]!=b[m]]
    assert len(a)==len(b)==36 and set(changes)=={"ArcherClose","ArcherLine","ArcherRank"},changes
    print('TAIL_MESHES',[(m,a[m][-1][1]//3,b[m][-1][1]//3) for m in changes])
else:
    for name in sys.argv[2:]:git_blob(Path(name))
