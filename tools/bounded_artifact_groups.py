"""Byte-exact bounded artifact groups; restore only verified manifest paths."""
import argparse, hashlib, json, os, tempfile
from pathlib import Path
CHUNK = 60 * 1024 * 1024
LIMIT = 120 * 1024 * 1024  # 8 MiB headroom below the 128 MiB artifact limit.
MAX_GROUPS = 32

def digest(data): return hashlib.sha256(data).hexdigest()

def stage(source, target, chunk_size=CHUNK, limit=LIMIT, max_groups=MAX_GROUPS):
    source, target = Path(source).resolve(), Path(target).resolve()
    if target.exists() or source == target or source in target.parents:
        raise ValueError('Fresh destination outside source required')
    if not 0 < chunk_size <= limit: raise ValueError('Invalid bounds')
    target.mkdir(parents=True)
    manifest = {'version': 1, 'files': [], 'group_limit_bytes': limit,
                'artifact_hard_limit_bytes': 128*1024*1024, 'groups': [], 'complete': False}
    # The recovery index has its own group, never eating payload headroom.
    (target/'group-00').mkdir()
    group = 1; used = 0
    def directory():
        p = target / f'group-{group:02d}'; p.mkdir(exist_ok=True); return p
    try:
        for index, path in enumerate(sorted(source.rglob('*'))):
            if path.is_symlink(): raise ValueError('Symlinks are not evidence files')
            if not path.is_file(): continue
            record = {'path': str(path.relative_to(source)), 'bytes': 0, 'chunks': []}
            full = hashlib.sha256()
            with path.open('rb') as stream:
                n = 0
                while True:
                    data = stream.read(chunk_size)
                    if not data and n: break
                    if used + len(data) > limit:
                        group += 1; used = 0
                    if group >= max_groups: raise ValueError('Bounded group capacity exceeded; no complete delivery claimed')
                    name = f'payload-{index:05d}-{n:04d}.part'
                    (directory()/name).write_bytes(data)
                    record['chunks'].append({'file': name, 'bytes': len(data), 'sha256': digest(data), 'group': group})
                    used += len(data); record['bytes'] += len(data); full.update(data); n += 1
                    if not data: break
            record['sha256'] = full.hexdigest(); manifest['files'].append(record)
        manifest['complete'] = True
    finally:
        manifest['groups'] = [{'name': p.name, 'bytes': sum(f.stat().st_size for f in p.iterdir())} for p in sorted(target.glob('group-*'))]
        index_path = target/'group-00'/'recovery.json'
        index_path.write_text(json.dumps(manifest,indent=2)+'\n')
        # Include the index's own bytes; its decimal size converges quickly.
        for _ in range(8):
            groups = [{'name': p.name, 'bytes': sum(f.stat().st_size for f in p.iterdir())} for p in sorted(target.glob('group-*'))]
            if groups == manifest['groups']: break
            manifest['groups'] = groups
            index_path.write_text(json.dumps(manifest,indent=2)+'\n')
        else: raise ValueError('Recovery index size did not stabilize')
        # Manifest itself counts toward the strict payload cap.
        for p in target.glob('group-*'):
            if sum(f.stat().st_size for f in p.iterdir()) > LIMIT:
                raise ValueError('Artifact group exceeds hard limit')
    return manifest

def restore(source, target):
    source, target = Path(source).resolve(), Path(target).resolve()
    manifest = json.loads((source/'recovery.json').read_text())
    if not manifest['complete']: raise ValueError('Incomplete groups cannot restore a deliverable')
    target.mkdir(parents=True, exist_ok=True)
    for record in manifest['files']:
        path = (target/record['path']).resolve()
        if target not in path.parents: raise ValueError('Unsafe manifest path')
        if path.exists():
            h = hashlib.sha256()
            with path.open('rb') as existing:
                for block in iter(lambda: existing.read(1024*1024), b''): h.update(block)
            if path.stat().st_size == record['bytes'] and h.hexdigest() == record['sha256']:
                continue  # A verified earlier file survives an interrupted restore.
            raise ValueError('Refuse to overwrite an existing incorrect file')
        path.parent.mkdir(parents=True, exist_ok=True)
        full = hashlib.sha256(); size = 0
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='wb', prefix='.restoring-', dir=path.parent, delete=False) as out:
                temporary = Path(out.name)
                for chunk in record['chunks']:
                    name = chunk['file']
                    if Path(name).name != name: raise ValueError('Unsafe chunk name')
                    data = (source/name).read_bytes()
                    if len(data) != chunk['bytes'] or digest(data) != chunk['sha256']: raise ValueError('Corrupt chunk')
                    out.write(data); full.update(data); size += len(data)
                out.flush(); os.fsync(out.fileno())
            if size != record['bytes'] or full.hexdigest() != record['sha256']: raise ValueError('Restored file mismatch')
            # Atomic publication without ever replacing a concurrently created file.
            os.link(temporary, path)
        finally:
            if temporary is not None: temporary.unlink(missing_ok=True)
    return manifest

if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['stage','restore']);parser.add_argument('source',type=Path);parser.add_argument('target',type=Path);a=parser.parse_args()
    result=(stage if a.mode=='stage' else restore)(a.source,a.target)
    print(json.dumps({'mode':a.mode,'files':len(result['files']),'complete':result['complete']}))
