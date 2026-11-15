"""Pure author-field invariants. These are not native navigation/capacity claims."""
import copy,unittest
import numpy as np
from layout import height,base_height,road_weight,bank_samples,edge
from topology_identity import topology_digest
class AuthorFieldTests(unittest.TestCase):
 def test_finite_heightfield(self):
  x=np.linspace(-60,84,200)[None,:];z=np.linspace(-42,42,140)[:,None]
  for side in ['west','east']:self.assertTrue(np.isfinite(height(x,z,side)).all())
 def test_packed_central_approach(self):
  for x in np.linspace(-21,-5,40):self.assertAlmostEqual(float(height(x,0)),1.,places=6)
 def test_actual_apron_rise(self):
  for x in np.linspace(5,9.7,20):self.assertAlmostEqual(float(height(x,0)),1.+(x-5)/4.7*.2,places=6)
 def test_tunnel_level(self):
  for x in np.linspace(9.7,15.5,20):self.assertAlmostEqual(float(height(x,0)),1.2,places=6)
 def test_scalar_vector_agree(self):
  x=np.array([-40,-15,-11,-13,9,14,35]);z=np.array([-5,0,12,-13,-14,0,10]);out=height(x,z,'west')
  self.assertTrue(np.allclose(out,[height(a,b,'west') for a,b in zip(x,z)]))
 def test_shoreline_is_c1_continuous(self):
  for side in ['west','east']:
   for z in [-31,-22,-14,-8,0,7,15,23,32]:
    eps=.0001;left=(float(edge(z,side))-float(edge(z-eps,side)))/eps;right=(float(edge(z+eps,side))-float(edge(z,side)))/eps
    self.assertAlmostEqual(left,right,places=3)
 def test_runtime_gate_landmark_changes_identity(self):
  a={'gate_dynamic':{'id':'gate_main','pivot':[14.8,1.2,0]}};b=copy.deepcopy(a);b['gate_dynamic']['pivot'][0]=14.9
  self.assertNotEqual(topology_digest(a),topology_digest(b))
 def test_visual_annotations_do_not_fake_topology_change(self):
  x={'surfaces':[{'id':'p','vertices':[[0,0,0],[1,0,0],[0,0,1]],'triangles':[[0,2,1]],'walkable':True,'agent_clearance_m':4}]};y=copy.deepcopy(x);y['visual_revision']=12;y['status']='UNFROZEN';self.assertEqual(topology_digest(x),topology_digest(y));y['surfaces'][0]['vertices'][1][1]=.01;self.assertNotEqual(topology_digest(x),topology_digest(y))
if __name__=='__main__':unittest.main()
