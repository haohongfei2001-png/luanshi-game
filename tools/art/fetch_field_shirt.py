"""Read the one CC0 garment chosen from MakeHuman's curated pack."""
import hashlib
from pathlib import Path
import shutil
import tempfile
from urllib.request import urlopen,Request
from zipfile import ZipFile
import sys

PACK="https://files.makehumancommunity.org/asset_packs/shirts01/shirts01_cc0.zip"
MIRROR="https://files2.makehumancommunity.org/asset_packs/shirts01/shirts01_cc0.zip"

def main():
    dest=Path(sys.argv[1]);dest.mkdir(parents=True,exist_ok=True)
    archive=dest/"shirts01.zip"
    if not archive.exists():
        for endpoint in (PACK,MIRROR):
            try:
                with urlopen(Request(endpoint,headers={"User-Agent":"Luanshi garment study"}),timeout=60) as response, tempfile.TemporaryFile() as tmp:
                    shutil.copyfileobj(response,tmp)
                    tmp.seek(0)
                    with archive.open("wb") as out: shutil.copyfileobj(tmp,out)
                break
            except OSError:
                if endpoint==MIRROR: raise
    with ZipFile(archive) as articles:
        found=[]
        for entry in articles.namelist():
            if not any(name in entry.lower() for name in ("toigo_basic_tucked","fisherman_sweater","elvs_crude_t-shirt_male")): continue
            if Path(entry).suffix.lower() not in (".obj",".mhclo",".mhmat",".txt"): continue
            target=dest/Path(entry).name
            data=articles.read(entry)
            target.write_bytes(data)
            print("GARMENT_INPUT",entry,len(data),hashlib.sha256(data).hexdigest())
            if target.suffix.lower()==".obj":
                text=data.decode("utf-8-sig")
                verts=[[float(x) for x in l.split()[1:4]] for l in text.splitlines() if l.startswith("v ")]
                print("GARMENT_HEADER",target.name,text[:230].replace("\n"," "))
                print("GARMENT_OBJ",len(verts),[tuple(round(f(p[i] for p in verts),4) for f in (min,max)) for i in range(3)],sum(1 for l in text.splitlines() if l.startswith("f ")),[l for l in text.splitlines() if l.startswith(("g ","o ","usemtl "))][:40])
                found.append(target)
            if target.suffix.lower()==".mhclo": print("GARMENT_META",data[:650].decode("utf-8-sig").replace("\n"," "))
        assert len(found)>=2

if __name__=="__main__": main()
