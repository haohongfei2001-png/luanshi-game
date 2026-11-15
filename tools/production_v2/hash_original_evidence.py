"""Always retain original image bytes, including failed/partial capture evidence."""
import argparse,hashlib,json
from pathlib import Path

def inventory(root):
    rows=[]
    if root.exists():
        for path in sorted(root.rglob('*')):
            if path.is_file() and path.suffix.lower() in {'.jpg','.jpeg','.png','.jsonl'}:
                digest=hashlib.sha256()
                with path.open('rb') as stream:
                    for chunk in iter(lambda:stream.read(1024*1024),b''):digest.update(chunk)
                rows.append({'path':str(path.relative_to(root)),'bytes':path.stat().st_size,'sha256':digest.hexdigest()})
    root.mkdir(parents=True,exist_ok=True)
    result={'original_files':rows,'capture_or_art_success_inferred':False,'retention':'all original JPEG/PNG/JSONL, even when encoding or validation fails'}
    (root/'original-evidence-sha256.json').write_text(json.dumps(result,indent=2)+'\n')
    return result
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();print(json.dumps(inventory(a.root)))
