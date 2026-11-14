import importlib.util,pathlib,tempfile,unittest
P=pathlib.Path(__file__).resolve().parents[1]/'tools/art/regional_sky/decode_radiance.py'
s=importlib.util.spec_from_file_location('decode_sky',P);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class DecodeSky(unittest.TestCase):
 def test_original_high_range_preserved(self):
  # 143 * 2^(145-136) =73216, above RGBE9995's65408 ceiling.
  row=b'\x02\x02\x08\x00'
  for value in [143,143,143,145]:row+=(bytes([255,value])*16)+bytes([144,value])
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/'sky.hdr';p.write_bytes(b'#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1024 +X 2048\n'+row*1024)
   a=m.decode(p);self.assertEqual(a.shape,(1024,2048,3));self.assertEqual(float(a.min()),73216.);self.assertEqual(float(a.max()),73216.)
 def test_missing_run_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/'sky.hdr';p.write_bytes(b'#?RADIANCE\n\n-Y 1024 +X 2048\n\x02\x02\x08\x00\xff')
   with self.assertRaises(ValueError):m.decode(p)
 def test_invalid_orientation_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d)/'sky.hdr';p.write_bytes(b'#?RADIANCE\n\n+Y 1024 +X 2048\n')
   with self.assertRaises(ValueError):m.decode(p)
if __name__=='__main__':unittest.main()
