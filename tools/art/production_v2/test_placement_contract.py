import json,math,unittest
from pathlib import Path
from placement_contract import matrix,point,transform_contract
class PlacementTest(unittest.TestCase):
 def fixture(self):
  return {'walk_surfaces':[{'id':'deck','xz_polygon':[[0,0],[2,0],[2,3],[0,3]],'y':1,'clear_height':5}], 'solid_obstacles':[{'xz_polygon':[[0,0],[2,0],[2,3],[0,3]],'min_y':-1,'max_y':6}], 'support_profiles':[{'axis_endpoints':[0,1,0,2,2,3],'ground_y':1,'foundation_bottom':0,'top_y_endpoints':[6,7],'top_above_local_ground':5}], 'gate_dynamic':{'pivot':[30,1.2,3],'entry':[25.7,1.2,3],'exit':[34.3,1.2,3],'width':6.4,'clear_height':5.4,'closed_blocker':{'xz_polygon':[[29.8,-.2],[30.2,-.2],[30.2,6.2],[29.8,6.2]],'min_y':1.2,'max_y':6.6}},'retreat_portal':{'center':[76,1.2,3],'width':8}}
 def test_quarter_turn(self):
  original=self.fixture();before=json.dumps(original);c=transform_contract(original,90,[11,3,-7]);p=c['gate_dynamic']['pivot']
  for x,y in zip(p,[14,4.2,-37]):self.assertAlmostEqual(x,y)
  self.assertEqual(c['walk_surfaces'][0]['y'],4);self.assertEqual(c['walk_surfaces'][0]['clear_height'],5);self.assertEqual(c['support_profiles'][0]['top_above_local_ground'],5);self.assertEqual(c['support_profiles'][0]['top_y_endpoints'],[9,10]);self.assertEqual(c['gate_dynamic']['width'],6.4);self.assertEqual(json.dumps(original),before)
 def test_basis_matches_blender_rotation(self):
  for yaw in [0,13,90,-90,180]:
   m=matrix(yaw,[11,3,-7]);a=math.radians(yaw)
   for p in [[0,0,0],[30,1.2,3],[-14,5,20]]:
    godot=point(p,m);blender_expected=[math.cos(a)*p[0]+math.sin(a)*p[2]+11,math.sin(a)*p[0]-math.cos(a)*p[2]+7,p[1]+3]
    for x,y in zip([godot[0],-godot[2],godot[1]],blender_expected):self.assertAlmostEqual(x,y)
 def test_no_double_transform_or_nonfinite(self):
  c=transform_contract(self.fixture(),13,[1,2,3])
  with self.assertRaises(ValueError):transform_contract(c,13,[1,2,3])
  for yaw,t in [(float('nan'),[0,0,0]),(0,[0,float('inf'),0]),(0,[0,0])]:
   with self.assertRaises(ValueError):matrix(yaw,t)
if __name__=='__main__':unittest.main()
