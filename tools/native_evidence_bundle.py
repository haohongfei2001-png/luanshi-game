"""Curate persistent evidence, never silently equating JPEG samples with all raw frames."""
from pathlib import Path
import hashlib, json, re, shutil
RAW = re.compile(r'frame-\d{6}(?:-preview)?\.jpg$')
CHUNK_BYTES = 64 * 1024 * 1024

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
    return h.hexdigest()

def selected_frames(source, errors=None):
    errors = [] if errors is None else errors
    selected=set()
    for journal in source.rglob('frames.jsonl'):
        rows=[]
        for number,line in enumerate(journal.read_text().splitlines(),1):
            if not line.strip():continue
            try:rows.append(json.loads(line))
            except json.JSONDecodeError:
                errors.append({'journal':str(journal.relative_to(source)),'line':number,'reason':'invalid_or_interrupted_json_line_retained_verbatim'})
        frames=[r for r in rows if r.get('kind')=='frame']
        if not frames:continue
        indices={0,len(frames)-1,len(frames)//4,len(frames)//2,3*len(frames)//4}
        for predicate in [lambda r:sum(r.get('state',{}).get('hits',[]))>0,
                          lambda r:r.get('state',{}).get('blocks',0)>0,
                          lambda r:r.get('state',{}).get('hero_impacts',0)>0,
                          lambda r:r.get('state',{}).get('vehicle')==1 and r.get('state',{}).get('hero_in_frame'),
                          lambda r:r.get('state',{}).get('hero_hp',100)<frames[0].get('state',{}).get('hero_hp',0)]:
            match=next((i for i,r in enumerate(frames) if predicate(r)),None)
            if match is not None:indices.add(match)
        selected.update(journal.parent/frames[i]['file'] for i in indices)
    return selected

def curate(source, target, chunk_bytes=CHUNK_BYTES):
    source=Path(source).resolve();target=Path(target).resolve()
    if target.exists():raise ValueError('Fresh evidence destination required')
    if source==target or source in target.parents:raise ValueError('Evidence output must be outside source')
    target.mkdir(parents=True)
    journal_errors=[]
    selected=selected_frames(source,journal_errors);files=[];raw=[];omitted=[]
    for path in sorted(source.rglob('*')):
        if not path.is_file():continue
        relative=path.relative_to(source)
        if relative.parts[0] in ('take','unpacked'):continue
        if RAW.fullmatch(path.name):
            raw.append({'file':str(relative),'bytes':path.stat().st_size,'sha256':sha(path),'selected_native_still':path in selected})
            if path not in selected:continue
        if path.suffix.lower() not in ('.jpg','.json','.jsonl','.txt','.log','.mp4'):continue
        destination=target/relative;destination.parent.mkdir(parents=True,exist_ok=True)
        size=path.stat().st_size;digest=sha(path)
        record={'file':str(relative),'bytes':size,'sha256':digest}
        if size>chunk_bytes:
            # Complete byte-preserving chunks, not a shortened/re-encoded movie.
            chunks=[]
            with path.open('rb') as stream:
                index=0
                while block:=stream.read(chunk_bytes):
                    part=destination.with_name(destination.name+f'.part{index:04d}')
                    part.write_bytes(block);chunks.append({'file':str(part.relative_to(target)),'bytes':len(block),'sha256':sha(part)});index+=1
            record['chunks']=chunks;record['recovery']='Concatenate listed chunks in order; verify complete file SHA256.'
        else:shutil.copyfile(path,destination)
        files.append(record)
    manifest={'journal_parse_errors':journal_errors,'files':files,'all_sampled_jpeg_sha256':raw,'selected_native_stills':len(selected),
              'complete_raw_jpeg_persisted':False,'raw_policy':'Only selected native JPEG samples persist in this bundle. Other JPEGs remain transient runner files until runner cleanup. No lossless PNG or complete raw-frame delivery is claimed.',
              'movie_policy':'Complete encoded VFR MP4 bytes retained, directly or reconstructably chunked; JPEG/H264 are lossy. Timing journals and every sampled JPEG hash retained.',
              'artifact_upload':'Upload each file/chunk as a separate bounded artifact or bounded group; do not zip all chunks into a single oversized artifact.',
              'max_payload_file_bytes':chunk_bytes,'omitted':omitted}
    (target/'bundle.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('target',type=Path);a=p.parse_args()
    curate(a.source,a.target)
