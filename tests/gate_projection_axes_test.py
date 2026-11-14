import sys,unittest,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/art/gate_structure'))
from projection_axes import dominant_axis
class Projection(unittest.TestCase):
 def test_exact_diagnosed_local_ci_faces(self):
  rows=json.loads((ROOT/'docs/evidence/gate-structure/CI_DERIVATION_DIAGNOSIS.json').read_text())['exact_uv_source_faces']
  for row in rows:
   self.assertEqual(dominant_axis(row['local_normal']),dominant_axis(row['ci_normal']),row['object'])
   self.assertEqual(dominant_axis(row['local_normal']),0)
 def test_distinct_normals_not_flattened(self):
  for v,expected in [((.2,.8,.1),1),((0,0,1),2),((.2,.20002,.1),1),((-.8,.2,.1),0)]:self.assertEqual(dominant_axis(v),expected)
 def test_invalid_axes_rejected(self):
  for v in [(0,0,0),(1,float('nan'),0),(float('inf'),0,0),(1,2)]:
   with self.assertRaises(ValueError):dominant_axis(v)
 def test_source_preservation_contract(self):
  s=(ROOT/'tools/art/gate_structure/build_architecture.py').read_text()
  self.assertIn('triangles_by_polygon[p.index] if len(p.loop_indices)>4',s)
  self.assertIn('uv.data[i].uv',s);self.assertIn('o.data.corner_normals[i].vector',s)
if __name__=='__main__':unittest.main()
