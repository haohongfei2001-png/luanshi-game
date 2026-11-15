#!/usr/bin/env python3
"""Prepare the exact official legacy-node source evaluator, without replacing Blender.
Requires Python3.12+ for tar's data-filter extraction. Does not install plugins,
accounts, or system packages. The caller chooses its cache directory.
"""
import argparse,hashlib,json,shutil,subprocess,tarfile,urllib.request
from pathlib import Path
VERSION='3.1.2'
NAME='blender-3.1.2-linux-x64'
URL='https://download.blender.org/release/Blender3.1/'+NAME+'.tar.xz'
SHA256='c1d345b25c6f83708b2681d354d70a3e6023c04bb73cc7943366c0c19e542958'
SIZE=187294308
EXTRACTED_SIZE=716073849

def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def prepare(cache):
 cache.mkdir(parents=True,exist_ok=True);binary=cache/NAME/'blender';receipt=cache/(NAME+'.json')
 if binary.exists():
  if not receipt.exists() or json.loads(receipt.read_text()).get('archive_sha256')!=SHA256:raise RuntimeError('EXISTING_BINARY_WITHOUT_VERIFIED_RECEIPT: do not overwrite')
  version=subprocess.check_output([str(binary),'--version'],text=True)
  if not version.startswith('Blender '+VERSION):raise RuntimeError('WRONG_SOURCE_BLENDER_VERSION')
  print(binary);return
 archive=cache/(NAME+'.tar.xz')
 needed=EXTRACTED_SIZE+128*1024*1024+(0 if archive.exists() else SIZE)
 if shutil.disk_usage(cache).free<needed:raise RuntimeError(f'INSUFFICIENT_DISK_REQUIRE_{needed}_BYTES')
 if not archive.exists():
  partial=archive.with_suffix(archive.suffix+'.part')
  if partial.exists():raise RuntimeError('PENDING_DOWNLOAD_EXISTS: inspect before retry')
  with urllib.request.urlopen(URL,timeout=60) as r,partial.open('xb') as f:
   shutil.copyfileobj(r,f,1024*1024)
  if partial.stat().st_size!=SIZE or digest(partial)!=SHA256:raise RuntimeError('OFFICIAL_ARCHIVE_HASH_MISMATCH: preserve failed file; never extract')
  partial.rename(archive)
 if archive.stat().st_size!=SIZE or digest(archive)!=SHA256:raise RuntimeError('CACHED_ARCHIVE_HASH_MISMATCH')
 with tarfile.open(archive,'r:xz') as tf:
  if not hasattr(tarfile,'data_filter'):raise RuntimeError('PYTHON_3_12_DATA_FILTER_REQUIRED')
  members=tf.getmembers()
  if any(Path(m.name).parts[0]!=NAME for m in members):raise RuntimeError('UNEXPECTED_ARCHIVE_ROOT')
  tf.extractall(cache,filter='data')
 version=subprocess.check_output([str(binary),'--version'],text=True)
 if not version.startswith('Blender '+VERSION):raise RuntimeError('EXTRACTED_VERSION_MISMATCH')
 receipt.write_text(json.dumps({'version':VERSION,'url':URL,'archive_size':SIZE,'archive_sha256':SHA256,'official_checksum_url':'https://download.blender.org/release/Blender3.1/blender-3.1.2.sha256'},indent=2))
 print(binary)
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--cache',type=Path,required=True);prepare(ap.parse_args().cache)
