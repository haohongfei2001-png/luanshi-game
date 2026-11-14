import importlib.util,json,pathlib,tempfile,unittest,hashlib
from unittest.mock import patch
PATH=pathlib.Path(__file__).resolve().parents[1]/'tools/art/native_woodland/restore_original_tree.py'
spec=importlib.util.spec_from_file_location('tree_restore',PATH);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
class OriginalTreeRestore(unittest.TestCase):
 def test_frozen_original_has_all_dependencies_and_no_changed_leaf_geometry(self):
  m=json.loads(PATH.with_name('original_tree_manifest.json').read_text());root=PATH.parents[3];old=json.loads((root/'assets/river_gate/world/masters/island_tree_01/SOURCE.json').read_text());rows={r['path']:r for r in m['files']}
  self.assertEqual(len(rows),11);self.assertEqual(rows['island_tree_01_2k.gltf']['md5'],old['gltf_md5'])
  for name,digest in old['inputs'].items():self.assertEqual(rows[name]['md5'],digest)
  self.assertEqual(sum('nor_gl' in name for name in rows),3);self.assertEqual(sum('_arm_' in name for name in rows),3)
  self.assertEqual(rows['island_tree_01.bin']['size'],60709812)
 def test_local_original_reuses_only_exact_bytes(self):
  m=json.loads(PATH.with_name('original_tree_manifest.json').read_text())
  self.assertTrue(all(r['url'].startswith('https://dl.polyhaven.org/') for r in m['files']))
  self.assertTrue(all(not pathlib.PurePosixPath(r['path']).is_absolute() and '..' not in pathlib.PurePosixPath(r['path']).parts for r in m['files']))
  self.assertTrue(all(len(r['md5'])==32 for r in m['files']))
if __name__=='__main__':unittest.main()
