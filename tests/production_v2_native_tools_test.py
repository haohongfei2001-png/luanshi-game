import importlib.util,json,re,struct,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/production_v2'))
from export_native_pack import project_config,preset_config,ENTRY
from validate_native import validate
from prepare_native_inputs import prepare
class NativePreparation(unittest.TestCase):
 def test_release_entry_graph_has_no_unreviewed_assertions(self):
  # Parse every static GDScript dependency, not just the top-level runner.
  pending=['scripts/review/production_v2_native_capture.gd','tools/production_v2/collect_resource_identities.gd'];seen=set();found={}
  allowed={
   'scripts/field/battle.gd':['assert(n>0 and defenders>0 and roster.is_empty())'],
   'scripts/field/river_master_map.gd':['assert(parts.has(part),"Missing authored world part "+part)','assert(names.size()>=3)'],
   'scripts/field/experimental/frustum_footprint.gd':['assert(height_max >= height_min and horizontal_pad >= 0.0)']}
  while pending:
   name=pending.pop()
   if name in seen:continue
   seen.add(name);source=(ROOT/name).read_text()
   for dependency in re.findall(r'(?:preload|load|extends)\s*\(?\s*["\']res://([^"\']+\.gd)',source):
    if (ROOT/dependency).exists():pending.append(dependency)
   lines=[line.strip() for line in source.splitlines() if re.search(r'\bassert\s*\(',line) and not line.lstrip().startswith('#')]
   if lines:found[name]=lines
  self.assertGreaterEqual(len(seen),67)
  self.assertEqual(found,allowed)
  # Legacy diagnostic predicates above have no initialization side effects.
  # Native entry guards the Battle setup count before calling the fresh instance.
  entry=(ROOT/'scripts/review/production_v2_entry.gd').read_text()
  self.assertLess(entry.index('if not count in [20,100,250,512]'),entry.index('battle.setup('))
  for call in ['nav.configure(', 'runtime.bind(', 'actor.setup(', 'host.configure(']:
   self.assertIn('if '+call,entry)
 def test_mainloop_is_normal_and_guarded(self):
  source=(ROOT/'project.godot').read_bytes();changed=project_config(source)
  self.assertIn(b'run/main_loop_type="DotProductionV2NativeCapture"',changed)
  self.assertIn(b'production_v2_bootstrap.tscn',changed)
  with self.assertRaises(ValueError):project_config(changed)
  self.assertNotEqual(source,changed)
 def test_presets_only_first_platform(self):
  original=(ROOT/'export_presets.cfg').read_bytes();changed=preset_config(original)
  self.assertEqual(changed.split(b'[preset.1]',1)[1],original.split(b'[preset.1]',1)[1])
  self.assertIn(b'assets/production_v2/**/*.json',changed)
  self.assertIn(b'script_export_mode=0',changed.split(b'[preset.1]',1)[0])
 def test_wrong_source_zip_refused_before_writes(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);bad=root/'bad.zip';bad.write_bytes(b'not the author zip')
   with self.assertRaises(ValueError):prepare(root,bad,root/'actor')
   self.assertFalse((root/'assets').exists())
 def test_action_report_does_not_invent_coverage(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);(root/'action').mkdir();stills=[]
   for w,h in [(2560,1440),(3840,2160)]:
    name=f'{w}.png';(root/name).write_bytes(b'\x89PNG\r\n\x1a\n'+b'\0'*8+struct.pack('>II',w,h))
    stills.append({'file':name,'actual_pixels':[w,h],'internal_scale':1,'battle_snapshot_sha256':'same'})
   (root/'stills.json').write_text(json.dumps(stills))
   frames=[{'kind':'frame','monotonic_us':t,'pixels':[2560,1440],'scale':1,'state':{'new_ordinary':[]},'hero_binding':{'semantic':'idle'}} for t in [100,200]]
   rows=frames+[{'kind':'end','monotonic_us':300}];(root/'action/frames.jsonl').write_text('\n'.join(map(json.dumps,rows)))
   result=validate(root);self.assertEqual(result['action_scope'],'INCOMPLETE');self.assertIn('death',result['missing_requested_actions'])
   frames[1]['pixels']=[1024,645];(root/'action/frames.jsonl').write_text('\n'.join(map(json.dumps,rows)))
   with self.assertRaises(ValueError):validate(root)
if __name__=='__main__':unittest.main()
