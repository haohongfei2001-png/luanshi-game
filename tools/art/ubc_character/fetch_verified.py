"""Fetch exact CC0 public free packs, no account/purchase. Reject any version drift.
Usage: python fetch_verified.py CACHE_DIRECTORY EXTRACT_DIRECTORY [--offline]
"""
import hashlib,http.cookiejar,json,pathlib,re,sys,urllib.parse,urllib.request,zipfile
PACKS=[('universal-base-characters-standard.zip','https://quaternius.itch.io/universal-base-characters','fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40',128968391),('ual-standard-current.zip','https://quaternius.itch.io/universal-animation-library','cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724',15904933)]
def fetch(base):
 op=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
 def read(url):return op.open(url,timeout=60).read().decode()
 def token(text):
  m=re.search(r'name="csrf_token" value="([^"]+)"',text)
  if not m:raise RuntimeError('Expected public free download form missing; do not bypass login/payment')
  return m.group(1)
 def post(url,data,ref):return json.loads(op.open(urllib.request.Request(url,urllib.parse.urlencode(data).encode(),headers={'Referer':ref}),timeout=60).read())
 page=read(base);response=post(base+'/download_url',{'csrf_token':token(page)},base)
 url=response.get('url')
 if not url:raise RuntimeError('No public free download; no payment/account fallback')
 page=read(url);csrf=token(page);uploads=re.findall(r'data-upload_id="(\d+)"',page)
 if not uploads:raise RuntimeError('No public asset download identifiers')
 # Hash below is authoritative: a changed first entry must fail, never silently license new bytes.
 r=post(base+'/file/'+uploads[0]+'?source=game_download',{'csrf_token':csrf},url)
 if r.get('errors') or r.get('lightbox_type') or not r.get('url'):raise RuntimeError('Download permission unavailable')
 return op.open(r['url'],timeout=180).read()
def run(cache,out,offline=False):
 cache.mkdir(parents=True,exist_ok=True);out.mkdir(parents=True,exist_ok=True);report=[]
 for filename,url,sha,size in PACKS:
  path=cache/filename
  if not path.exists():
   if offline:raise FileNotFoundError(path)
   data=fetch(url)
  else:data=path.read_bytes()
  if len(data)!=size or hashlib.sha256(data).hexdigest()!=sha:raise ValueError('Package differs from audited CC0 bytes: '+filename)
  if not path.exists():path.write_bytes(data)
  with zipfile.ZipFile(path) as archive:
   for member in archive.infolist():
    dest=(out/member.filename).resolve()
    if not dest.is_relative_to(out.resolve()):raise ValueError('Unsafe ZIP path')
   licenses=[n for n in archive.namelist() if 'license' in n.lower() and n.endswith('.txt')]
   if not any('CC0 1.0' in archive.read(n).decode('utf-8',errors='replace') for n in licenses):raise ValueError('Expected CC0 license missing')
   archive.extractall(out)
  report.append({'filename':filename,'source':url,'sha256':sha,'bytes':size,'verified_cc0':True})
 (out/'verified-sources.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
if __name__=='__main__':run(pathlib.Path(sys.argv[1]),pathlib.Path(sys.argv[2]),'--offline' in sys.argv)
