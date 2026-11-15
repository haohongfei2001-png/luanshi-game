"""Reconstruct the exact project AI PNG; never resample or silently overwrite."""
import pathlib,json,base64,hashlib,sys
root=pathlib.Path(__file__).resolve().parent;m=json.loads((root/'source-manifest.json').read_text());parts=[]
for row in m['parts']:
 data=(root/'parts'/row['name']).read_bytes()
 assert len(data)==row['chars'],row['name']
 assert hashlib.sha256(data).hexdigest()==row['sha256'],row['name']
 assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==row['git_blob_sha'],row['name']
 parts.append(data)
raw=base64.b64decode(b''.join(parts),validate=True)
assert len(raw)==m['original_bytes']
assert hashlib.sha256(raw).hexdigest()==m['asset_sha256']
assert raw[:8]==b'\x89PNG\r\n\x1a\n'
output=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else root/'lamellar-color.png'
if output.exists():
 assert output.read_bytes()==raw,'Refusing to replace a different existing file'
else:
 output.parent.mkdir(parents=True,exist_ok=True);tmp=output.with_suffix(output.suffix+'.tmp');tmp.write_bytes(raw);tmp.replace(output)
print(json.dumps({'file':str(output),'bytes':len(raw),'sha256':m['asset_sha256'],'status':'EXACT_ORIGINAL_PNG_RESTORED'}))
