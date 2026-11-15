"""Restore only frozen author inputs. No art regeneration, old oracle or old map."""
import argparse,gzip,hashlib,json,shutil,zipfile
from pathlib import Path, PurePosixPath
MOTHER_SHA='f5ac12b501293da966a12072509550d91ac60fd5fafc283f8b55aa8475cb91f4'
ACTOR_GZ_SHA='caf49a68890e78644448489a8df7e2bafe2d2dc1617f6270fa886248e65737d7'
ACTOR_SHA='afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b'
TIMING_SHA='ae7094c96039fea428a310330e25a1fe501aca18f6a6461f6abdc2f843f5c2ab'
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def prepare(project,mother_zip,actor_directory):
    if digest(mother_zip)!=MOTHER_SHA:raise ValueError('Exact HF08 ZIP hash mismatch')
    destination=project/'assets/production_v2/valley_hf08'
    if destination.exists():raise ValueError('Refuse overwrite of existing mother inputs')
    with zipfile.ZipFile(mother_zip) as archive:
        names=archive.namelist()
        if len(names)!=len(set(names)) or len(names)!=9:raise ValueError('Unexpected mother member set')
        for item in archive.infolist():
            p=PurePosixPath(item.filename)
            if p.is_absolute() or '..' in p.parts or len(p.parts)!=2 or p.parts[0]!='valley_hf08' or item.file_size>250_000_000:raise ValueError('Unsafe or excessive mother member')
            if (item.external_attr>>16)&0o170000==0o120000:raise ValueError('Symlink in source ZIP')
        manifest=json.loads(archive.read('valley_hf08/runtime-package-files.json'))
        declared={'valley_hf08/'+r['path']:r for r in manifest['files']}
        if set(names)!=set(declared)|{'valley_hf08/runtime-package-files.json'}:raise ValueError('Incomplete mother manifest')
        for name,row in declared.items():
            data=archive.read(name)
            if len(data)!=row['size'] or hashlib.sha256(data).hexdigest()!=row['sha256']:raise ValueError('Mother member hash mismatch: '+name)
        archive.extractall(destination.parent)
    actor_out=project/'assets/production_v2/source18'
    if actor_out.exists():raise ValueError('Refuse overwrite of existing actor input')
    compressed=actor_directory/'spearman-v2-source18.glb.gz';timing=actor_directory/'timing.json'
    if digest(compressed)!=ACTOR_GZ_SHA or digest(timing)!=TIMING_SHA:raise ValueError('Actor gzip/timing input hash mismatch')
    data=gzip.decompress(compressed.read_bytes())
    if len(data)!=14_173_132 or hashlib.sha256(data).hexdigest()!=ACTOR_SHA:raise ValueError('Source18 decompressed bytes mismatch')
    licenses=actor_directory/'source18-license'
    if not licenses.is_dir() or not list(licenses.rglob('*')):raise ValueError('Source18 license packet missing')
    if digest(licenses/'license-packet-manifest.json')!='bba316af65ddc1aece36b73e7f90f6b57547b9cf55004c3d9efc2cb3ff5bfaec':raise ValueError('Original license manifest bytes differ')
    license_manifest=json.loads((licenses/'license-packet-manifest.json').read_text())
    if license_manifest['glb_sha256']!=ACTOR_SHA:raise ValueError('License packet actor identity differs')
    for row in license_manifest['files']:
        relative=PurePosixPath(row['path'])
        if relative.is_absolute() or '..' in relative.parts or digest(licenses/relative)!=row['sha256']:raise ValueError('License packet original bytes differ: '+row['path'])
    actor_out.mkdir(parents=True);(actor_out/'spearman.glb').write_bytes(data);shutil.copy2(timing,actor_out/'timing.json');shutil.copytree(licenses,actor_out/'license')
    handoff=json.loads((destination/'native-handoff.json').read_text());manifest=handoff['identity']|{k:handoff[k] for k in ['scene','navigation']}
    manifest['schema']=1
    for key in ['scene','navigation']:manifest[key]['derived_from_source_sha256']=manifest['authored_source_sha256']
    manifest.update(internal_mode='open_gate_field_no_campaign',ordinary_per_side=20,ordinary_spearmen_per_team=3,seed=61112,actor={'path':'res://assets/production_v2/source18/spearman.glb','sha256':ACTOR_SHA,'timing_path':'res://assets/production_v2/source18/timing.json','timing_sha256':TIMING_SHA})
    output=project/'assets/production_v2/native-manifest-source.json';output.write_text(json.dumps(manifest,indent=2)+'\n')
    return {'mother_zip_sha256':MOTHER_SHA,'actor_sha256':ACTOR_SHA,'manifest':str(output),'scope':'source restoration only; actual platform import/export/graphics not yet verified'}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('project',type=Path);p.add_argument('mother_zip',type=Path);p.add_argument('actor_directory',type=Path);a=p.parse_args();print(json.dumps(prepare(a.project,a.mother_zip,a.actor_directory),indent=2))
