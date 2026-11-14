"""Restore exact public complete-scene assets and external single-actor oracle."""
from pathlib import Path, PurePosixPath
import argparse, hashlib, json, shutil, sys, tarfile, tempfile
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from bounded_artifact_groups import restore as restore_groups
from restore_inputs import verified_copy, sha
SOURCE='287e2ae375bc2f33cd03cbf37508faf388d7e85e'
RUN=43648903794
ACTOR_SOURCE='945b2c676705460f97ba0d9e5c9d892f2a64390d'
ACTOR_RUN=43635849360
ACTOR_ARCHIVE='a738117dad6e22249e80b2394fe03f080dfde4368b2e81ab0acb9a4a268e2cee'
RUNTIME_FILES={'assets/river_authored/architecture/architecture.glb': '2dc5018e859c0fcd331d6f33c035f45d4abf5fc9c31eebe0ec1d386a846f622a', 'assets/river_authored/ground/continuous-region.scn': '41e5a5bda57ad8e923e487f76629076a4a11201f016af6748d27fff4907bcb01', 'assets/river_authored/woodland/region.scn': '52047795a7efa22f80504cc80a90046fd33b87e3a8f046d0a6eb55e8d4d9bd59', 'assets/river_authored/grass/region.scn': '2779459c919b556b9e2c0c61df2655355e7840a2b66ebeffb3cfd956a4a04629'}

def safe_relative(name):
    p=PurePosixPath(name)
    if p.is_absolute() or not p.parts or any(x in ('','..','.') for x in p.parts) or '\\' in name:
        raise ValueError('Unsafe manifest path')
    return p

def restore_runtime(groups, project, recovered):
    restore_groups(groups,recovered)
    m=json.loads((recovered/'runtime-manifest.json').read_text())
    if m.get('source')!=SOURCE or m.get('art')!='NOT_ACCEPTED':raise ValueError('Wrong complete-scene source')
    if m.get('profile_sha256')!=sha(project/'scripts/field/authored_landform_profile.gd'):
        raise ValueError('Runtime ground and game Ground profile differ')
    if len(m['files'])!=4 or {r['path'] for r in m['files']}!=set(RUNTIME_FILES):raise ValueError('Incomplete runtime closure')
    rows=[]
    for row in m['files']:
        p=safe_relative(row['path']);src=recovered/str(p)
        if row['sha256']!=RUNTIME_FILES[row['path']]:raise ValueError('Wrong pinned runtime bytes')
        if src.stat().st_size!=row['bytes']:raise ValueError('Wrong runtime byte length')
        verified_copy(src,project/str(p),row['sha256']);rows.append(row)
    return {'source':SOURCE,'run':RUN,'profile_sha256':m['profile_sha256'],'files':rows}

def restore_actor(groups, destination, expected_archive=ACTOR_ARCHIVE):
    m=json.loads((groups/'manifest.json').read_text())
    if m.get('source_commit')!=ACTOR_SOURCE or m.get('art_pass') is not False or m.get('archive_sha256')!=expected_archive:
        raise ValueError('Wrong author cache source')
    names=[str(safe_relative(r['path'])) for r in m['files']]
    if len(names)!=len(set(names)) or 'character.json' not in names:raise ValueError('Invalid author cache file index')
    members={r['path']:r for r in m['files']}
    destination.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='verified-author-',dir=destination.parent) as temp:
        temp=Path(temp);archive=temp/'cache.tar.gz'
        with archive.open('wb') as output:
            for row in m['parts']:
                name=str(safe_relative(row['file']));p=groups/name
                if p.is_symlink() or p.stat().st_size!=row['bytes'] or sha(p)!=row['sha256']:
                    raise ValueError('Corrupt author cache part')
                with p.open('rb') as source:shutil.copyfileobj(source,output)
        if archive.stat().st_size!=m['archive_bytes'] or sha(archive)!=expected_archive:raise ValueError('Corrupt complete author archive')
        seen=set()
        with tarfile.open(archive,'r:gz') as tar:
            for member in tar:
                p=safe_relative(member.name)
                if len(p.parts)<2 or p.parts[0]!='cache' or not member.isfile():raise ValueError('Unsafe author archive member')
                name=str(PurePosixPath(*p.parts[1:]))
                if name not in members or name in seen or member.size!=members[name]['bytes']:raise ValueError('Unexpected author archive member')
                seen.add(name);file=temp/name;file.parent.mkdir(parents=True,exist_ok=True)
                with tar.extractfile(member) as source,file.open('wb') as target:shutil.copyfileobj(source,target)
                if sha(file)!=members[name]['sha256']:raise ValueError('Author member hash mismatch')
        if seen!=set(names):raise ValueError('Missing author cache member')
        if sha(temp/'character.json')!=m['character_json_sha256']:raise ValueError('Wrong author metadata')
        for name in names:verified_copy(temp/name,destination/name,members[name]['sha256'])
    return {'source':ACTOR_SOURCE,'run':ACTOR_RUN,'archive_sha256':expected_archive,'members_verified':len(names),
            'metadata_sha256':m['character_json_sha256'],'external_cache':str(destination),
            'source_files':m['source_files'],'single_actor_only':True,'art':'NOT_ACCEPTED','mapped_animation':'NOT_ACCEPTED'}

if __name__=='__main__':
    p=argparse.ArgumentParser()
    for name in ('runtime_groups','actor_groups','project','recovered','actor_destination'):p.add_argument(name,type=Path)
    a=p.parse_args()
    print(json.dumps({'runtime':restore_runtime(a.runtime_groups,a.project,a.recovered),
        'actor':restore_actor(a.actor_groups,a.actor_destination),'no_rebake':True,'M5':'DEVICE_NOT_RUN'},indent=2))
