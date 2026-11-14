from pathlib import Path
import copy, math, sys, unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/native_region'))
from validate_stills import VIEWS,validate_records

def rows():
    result=[]
    for name,size in VIEWS['camera-study'].items():
        r={k:list(size) for k in ['pixels','internal_pixels','attachment_size','viewport']}
        r.update(source='a'*40,view=name,battle_snapshot_sha256='b'*64,seed='61112',tick=135,ordinary=[20,20],internal_scale=1,
                 camera_review_profile={'projection':'perspective','nominal_body_fraction':.1,'pitch_degrees':32.,'fov_degrees':55.},
                 camera_yaw=math.radians(-75 if name.endswith('road75') else -65))
        result.append(r)
    return result

class StillGate(unittest.TestCase):
    def test_correct(self):self.assertEqual(validate_records(rows(),'a'*40,'camera-study'),'b'*64)
    def test_missing(self):
        with self.assertRaises(ValueError):validate_records(rows()[:2],'a'*40,'camera-study')
    def test_duplicate(self):
        r=rows();r[1]=copy.deepcopy(r[0])
        with self.assertRaises(ValueError):validate_records(r,'a'*40,'camera-study')
    def test_corrupt_conditions(self):
        for key,value in [('source','c'*40),('battle_snapshot_sha256','d'*64),('internal_scale',.7),('pixels',[1280,720]),('ordinary',[512,512]),('seed','123'),('camera_yaw',0),('camera_review_profile',{})]:
            with self.subTest(key=key):
                r=rows();r[1][key]=value
                with self.assertRaises(ValueError):validate_records(r,'a'*40,'camera-study')
if __name__=='__main__':unittest.main()
