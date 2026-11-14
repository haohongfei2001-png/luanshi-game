"""Fetch only explicit, reviewed public source members. No accounts/payment/executable downloads.
Every member is pinned by SHA256; ZIP ranges additionally verify file name, size and CRC.
"""
import concurrent.futures,hashlib,json,pathlib,struct,sys,urllib.request,zlib

def fetch(root,offline=False):
 manifest=json.loads(pathlib.Path(__file__).with_name('sources.json').read_text());root=root.resolve();root.mkdir(parents=True,exist_ok=True)
 jobs=[(None,item) for item in manifest['raw']]+[(archive,item) for archive in manifest['archives'] for item in archive['members']]
 def one(job):
  archive,item=job;dest=(root/item['destination']).resolve();assert dest.is_relative_to(root)
  data=dest.read_bytes() if dest.exists() else None
  if data is None:
   if offline:raise FileNotFoundError(dest)
   if archive is None:
    data=urllib.request.urlopen(item['url'],timeout=90).read()
   else:
    end=min(archive['archive_bytes']-1,item['offset']+item['compressed_bytes']+4095)
    req=urllib.request.Request(archive['source_url'],headers={'Range':f"bytes={item['offset']}-{end}"})
    with urllib.request.urlopen(req,timeout=180) as response:
     assert response.status==206,'Server must support reviewed member ranges';blob=response.read()
    assert blob[:4]==b'PK\x03\x04';nl,el=struct.unpack_from('<HH',blob,26)
    assert blob[30:30+nl].decode()==item['path'];start=30+nl+el;compressed=blob[start:start+item['compressed_bytes']]
    if item['type']==8:data=zlib.decompress(compressed,-15)
    elif item['type']==0:data=compressed
    else:raise ValueError('Unsupported compression')
    assert zlib.crc32(data)&0xffffffff==item['crc']
  assert len(data)==item['bytes'] and hashlib.sha256(data).hexdigest()==item['sha256'],item['destination']
  dest.parent.mkdir(parents=True,exist_ok=True)
  if not dest.exists():dest.write_bytes(data)
  return item['destination']
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:verified=list(pool.map(one,jobs))
 print(json.dumps({'verified_files':len(verified),'offline':offline,'all_sha256_match':True}))
if __name__=='__main__':fetch(pathlib.Path(sys.argv[1]),'--offline' in sys.argv)
