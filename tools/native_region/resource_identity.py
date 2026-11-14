"""Bind original input bytes to imported packed-resource bytes, without conflating them."""
from pathlib import Path, PurePosixPath
import configparser, hashlib, json

def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def local_resource(project, path):
    if not path.startswith('res://'):raise ValueError('Not a project resource')
    relative=PurePosixPath(path[6:])
    if relative.is_absolute() or '..' in relative.parts or '\\' in path:raise ValueError('Unsafe resource path')
    result=project/str(relative)
    if not result.is_file() or result.is_symlink():raise ValueError('Missing regular resource: '+path)
    return result

def collect(project, source_hashes):
    rows={}
    for relative,expected in source_hashes.items():
        source='res://'+relative;original=local_resource(project,source)
        if sha(original)!=expected:raise ValueError('Original input hash differs: '+source)
        packed=source;import_file=Path(str(original)+'.import')
        if import_file.is_file():
            config=configparser.ConfigParser(interpolation=None,strict=True);config.read(import_file)
            packed=json.loads(config['remap']['path'])
            if not packed.startswith('res://.godot/imported/'):raise ValueError('Unexpected import destination')
        rows[source]={'source_resource_path':source,'original_source_sha256':expected,
            'packed_resource_path':packed,'packed_resource_sha256':sha(local_resource(project,packed)),
            'identity_method':'godot_import_remap' if packed!=source else 'direct_resource'}
    return rows

def runtime_rows(rows):
    return {path:{k:v for k,v in row.items() if k!='original_source_sha256'} for path,row in rows.items()}

def verify_runtime_observation(observed, expected):
    if observed!=runtime_rows(expected):raise ValueError('Packed runtime resources differ from verified export inputs')
