"""Restore only the exact freely redistributable asset revisions, never execute ZIP content."""
import hashlib, http.cookiejar, json, re, sys, urllib.parse, urllib.request, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
CACHE=Path(sys.argv[1]); CACHE.mkdir(parents=True,exist_ok=True)
def checked(data,sha,label,size=None):
    actual=hashlib.sha256(data).hexdigest()
    if actual!=sha or (size is not None and len(data)!=size):
        raise ValueError(f'{label}: unexpected bytes/hash {len(data)} {actual}')
    print('VERIFIED_SOURCE',label,len(data),actual,flush=True)
    return data
nature=ROOT/'assets/river_pass/nature'; metadata=json.loads((nature/'SOURCE.json').read_text())
archive=CACHE/'nature.zip'
if not archive.exists():
    archive.write_bytes(urllib.request.urlopen(metadata['url'],timeout=120).read())
checked(archive.read_bytes(),metadata['archive_sha256'],'nature CC0 Standard revision',104088529)
with zipfile.ZipFile(archive) as z:
    for name,sha in metadata['members'].items():
        assert '/' not in name and '\\' not in name
        (nature/name).write_bytes(checked(z.read('glTF/'+name),sha,name))
    # Keep the precise publisher's embedded license unchanged.
    assert z.read('License_Standard.txt')==(nature/'License_Standard.txt').read_bytes()
pavilion=ROOT/'assets/river_pass/pavilion'; metadata=json.loads((pavilion/'SOURCE.json').read_text())
archive=CACHE/'pavilion.zip'
if not archive.exists():
    # Publisher's public free-download flow; no account, payment or persistent
    # credential. Transient CSRF/download URLs are never printed or committed.
    base=metadata['author_page']
    assert base=='https://vvaytoyek.itch.io/chinese-four-corner-pavilion-free'
    op=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    def page(url):return op.open(url,timeout=30).read().decode()
    def token(html):
        m=re.search(r'name="csrf_token" value="([^"]+)"',html)
        if not m:raise ValueError('Publisher public download form changed')
        return m.group(1)
    def post(url,data,ref):
        return json.loads(op.open(urllib.request.Request(url,urllib.parse.urlencode(data).encode(),headers={'Referer':ref}),timeout=30).read())
    reply=post(base+'/download_url',{'csrf_token':token(page(base))},base)
    download_page=reply['url'];html=page(download_page)
    match=re.search(r'data-upload_id="(\d+)"',html)
    if not match:raise ValueError('Expected public free file not available')
    reply=post(base+'/file/'+match.group(1)+'?source=game_download',{'csrf_token':token(html)},download_page)
    if reply.get('errors') or reply.get('lightbox_type'):raise ValueError('Publisher blocks this download; no bypass')
    assert reply['url'].startswith('https://')
    archive.write_bytes(op.open(reply['url'],timeout=120).read())
checked(archive.read_bytes(),metadata['archive_sha256'],'pavilion CC0 archive',2777866)
with zipfile.ZipFile(archive) as z:
    data=checked(z.read(metadata['original_member']),metadata['fbx_sha256'],'pavilion original FBX')
    (pavilion/'pavilion-source.fbx').write_bytes(data)
