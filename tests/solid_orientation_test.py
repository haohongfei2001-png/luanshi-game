import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"tools/art/gate_structure"))
from solid_orientation import orient_closed
class Solids(unittest.TestCase):
 def test_inside_out_cube_and_translation(self):
  v=[(x,y,z) for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
  faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
  for offset in [0,50,100000]:
   out,a=orient_closed([(x+offset,y,z) for x,y,z in v],faces)
   self.assertTrue(a[0]['flipped']);self.assertAlmostEqual(a[0]['signed_volume_after_m3'],8)
   again,b=orient_closed(v,out);self.assertFalse(b[0]['flipped']);self.assertEqual(out,again)
 def test_open_shell_rejected(self):
  with self.assertRaises(ValueError):orient_closed([(0,0,0),(1,0,0),(0,1,0)],[(0,1,2)])
if __name__=='__main__':unittest.main()
