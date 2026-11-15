"""Acquire one exact licensed original; reject historical repo derivative bytes."""
import sys,hashlib,urllib.request
from pathlib import Path
URL='https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/brown_mud_dry/brown_mud_dry_diff_2k.jpg'
SHA='5f567f61a7e139101441a1209e9c174a4f92dce489b28bb168f6bfd0ca07e411'
out=Path(sys.argv[1])
if out.exists() and hashlib.sha256(out.read_bytes()).hexdigest()==SHA:print('EXACT_MINERAL_SOURCE_CACHED');sys.exit(0)
request=urllib.request.Request(URL,headers={'User-Agent':'LuanshiAssetResearch/1.0 (CC0 material verification)'})
with urllib.request.urlopen(request,timeout=40) as response:data=response.read(4_000_001)
assert len(data)==3_519_711 and hashlib.sha256(data).hexdigest()==SHA,'Official source changed: do not continue'
out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data);print('EXACT_MINERAL_SOURCE_VERIFIED',SHA)
