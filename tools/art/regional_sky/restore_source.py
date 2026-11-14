import pathlib,json,hashlib,urllib.request,sys
manifest=json.loads(pathlib.Path(__file__).with_name('source.json').read_text())
root=pathlib.Path(sys.argv[1]);root.mkdir(parents=True,exist_ok=True);path=root/manifest['file']
if not path.exists():
 with urllib.request.urlopen(urllib.request.Request(manifest['url'],headers={'User-Agent':'LuanshiAssetRecovery/1.0'}),timeout=60) as r:data=r.read(manifest['size']+1)
 if len(data)!=manifest['size'] or hashlib.sha256(data).hexdigest()!=manifest['sha256']:raise ValueError('Sky source differs from frozen original')
 path.write_bytes(data)
assert hashlib.sha256(path.read_bytes()).hexdigest()==manifest['sha256']
print(path)
