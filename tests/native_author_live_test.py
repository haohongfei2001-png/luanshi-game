from pathlib import Path
import sys,unittest,copy,math
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/native_region'))
from validate_author_live import validate_rows

def fixture():
 return [{'kind':'author_dynamic_contract'}, {'kind':'author_dynamic_result','reason':'review_complete','inputs_released':True,'actual_attack_keydown_events':1},*({'kind':'frame','pixels':[2560,1440],'scale':1} for _ in range(2)),{'kind':'author_after_draw_camera','projection':0,'fov':65,'yaw_radians':math.radians(-65),'pitch_radians':math.radians(26),'camera_center':[4,2],'hero_pos':[1,2],'transform':'matrix','projection_matrix':'matrix','review_profile':{'pitch_degrees':26,'look_height':1.5,'follow_lead_world':[3,0]}},{'kind':'author_actual_input','type':'InputEventAction','action':'move_right','pressed':True},{'kind':'author_render_observation','tick':135,'pos':[1,2]},{'kind':'author_render_observation','tick':136,'pos':[1.1,2]}]
class Gate(unittest.TestCase):
 def test_valid_diagnostic_not_game_acceptance(self):
  r=validate_rows(fixture());self.assertEqual(r['input_camera_integrity'],'PASS');self.assertEqual(r['art'],'NOT_ACCEPTED');self.assertEqual(r['hero_impacts_delta'],0)
 def test_gameplay_profile_keeps_real_follow_and_rejects_old_camera(self):
  r=fixture();r[4].update(fov=50,pitch_radians=math.radians(45),camera_center=[2.5,2],review_profile={'pitch_degrees':45,'look_height':1,'follow_lead_world':[1.5,0]})
  self.assertEqual(validate_rows(r,'gameplay45')['input_camera_integrity'],'PASS')
  r[4]['fov']=65;self.assertNotEqual(validate_rows(r,'gameplay45')['input_camera_integrity'],'PASS')
 def test_missing_native_frames(self):self.assertIn('MISSING_NATIVE_REAL_FRAMES',validate_rows([r for r in fixture() if r['kind']!='frame'])['problems'])
 def test_no_real_attack(self):
  r=fixture();r[1]['actual_attack_keydown_events']=0;self.assertIn('NO_ACTUAL_ATTACK_INPUT',validate_rows(r)['problems'])
 def test_camera_drift(self):
  for key,value in [('pitch_degrees',32),('look_height',.8),('follow_lead_world',[0,0])]:
   r=fixture();r[4]['review_profile'][key]=value;self.assertIn('DESTINATION26_CAMERA_CHANGED',validate_rows(r)['problems'])
 def test_frozen_simulation(self):
  r=fixture();r[-1]['tick']=135;self.assertIn('REAL_SIMULATION_DID_NOT_ADVANCE',validate_rows(r)['problems'])
 def test_unreleased_input(self):
  r=fixture();r[1]['inputs_released']=False;self.assertIn('INCOMPLETE_OR_INPUT_NOT_RELEASED',validate_rows(r)['problems'])
 def test_body_join_uses_actual_frame_not_texture_metadata(self):
  r=fixture();r[2]['engine_drawn']=42;r[4]['engine_drawn']=42;r[4]['body']={'valid':True,'height_fraction':.13289,'viewport_texture_reported_size':[4608,2592]}
  result=validate_rows(r);self.assertEqual(result['input_camera_integrity'],'PASS');self.assertAlmostEqual(result['joined_actual_body_pixels'][0]['native_height_px'],191.3616)
  r[4]['engine_drawn']=43;self.assertIn('BODY_WITHOUT_MATCHED_ACTUAL_ATTACHMENT',validate_rows(r)['problems'])
if __name__=='__main__':unittest.main()
