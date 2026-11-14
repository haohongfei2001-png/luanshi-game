from pathlib import Path
import hashlib, importlib.util, json, re, sys, tempfile, unittest, subprocess
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools/native_region'))
from restore_inputs import verified_copy, FILES
from run_native import validate_engine,validate_pack_receipt,window_ready,diagnostic_command,capture_failure,ENTRY
from validate_route import validate
from export_pack import transform_preset,transform_project
from capture_mode import arguments,capture_budget

class NativeRegionInputs(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory();self.path = Path(self.temp.name)
    def tearDown(self):self.temp.cleanup()
    def test_copy_and_idempotent(self):
        s=self.path/'source';t=self.path/'dest';s.write_bytes(b'original');h=hashlib.sha256(s.read_bytes()).hexdigest()
        verified_copy(s,t,h);verified_copy(s,t,h);self.assertEqual(t.read_bytes(),b'original')
    def test_input_corruption_rejected(self):
        s=self.path/'source';s.write_bytes(b'wrong')
        with self.assertRaises(ValueError):verified_copy(s,self.path/'dest','0'*64)
        self.assertFalse((self.path/'dest').exists())
    def test_existing_wrong_target_preserved(self):
        s=self.path/'source';t=self.path/'dest';s.write_bytes(b'original');t.write_bytes(b'existing')
        with self.assertRaises(ValueError):verified_copy(s,t,hashlib.sha256(s.read_bytes()).hexdigest())
        self.assertEqual(t.read_bytes(),b'existing')
    def test_symlink_source_rejected(self):
        s=self.path/'source';link=self.path/'link';s.write_bytes(b'original');link.symlink_to(s)
        with self.assertRaises(ValueError):verified_copy(link,self.path/'dest',hashlib.sha256(s.read_bytes()).hexdigest())
    def test_pinned_lengths(self):
        self.assertEqual(len(FILES),3)
        for v in FILES.values():self.assertRegex(v,r'^[0-9a-f]{64}$')
    def test_engine_hash_rejected(self):
        (self.path/'provenance.json').write_text(json.dumps({'engine_source':'35e80b3a8822a9df9be390814b62f44c0a9c69e8','angle_archive_sha256':'9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d','patched_binary_sha256':'0'*64}))
        (self.path/'godot.macos.template_release.arm64').write_bytes(b'incorrect')
        with self.assertRaises(ValueError):validate_engine(self.path)
    def test_incomplete_route_not_capture_success(self):
        p=self.path/'frames';p.write_text(json.dumps({'kind':'end','reason':'review_complete'})+'\n'+json.dumps({'kind':'traversal_result','status':'NOT_COMPLETED','reached':1,'required':2}))
        with self.assertRaises(ValueError):validate(p)
    def test_route_only_not_art_acceptance(self):
        p=self.path/'frames';p.write_text(json.dumps({'kind':'traversal_result','status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW','reached':2,'required':2}))
        self.assertEqual(validate(p)['art_status'],'NOT_ACCEPTED')
    def test_duplicate_result_rejected(self):
        p=self.path/'frames';row=json.dumps({'kind':'traversal_result','status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW','reached':2,'required':2});p.write_text(row+'\n'+row)
        with self.assertRaises(ValueError):validate(p)
    def test_internal_pack_filter_only_one_preset(self):
        data=(ROOT/'export_presets.cfg').read_bytes();converted=transform_preset(data)
        self.assertEqual(converted.count(b'exclude_filter="docs/*,artifacts/*,builds/*"'),1)
        self.assertEqual(converted.count(b'exclude_filter="tests/*,tools/*,docs/*,artifacts/*,builds/*"'),1)
        self.assertEqual(converted.count(b'include_filter="tests/fixtures/author_thrust_peak.json,'),1)
        self.assertEqual(converted.count(b'script_export_mode=0'),1)
        self.assertEqual(converted.count(b'script_export_mode=2'),1)
    def test_unknown_pack_config_rejected(self):
        with self.assertRaises(ValueError):transform_preset(b'wrong')
    def test_project_mainloop_is_normal_export_setting(self):
        data=(ROOT/'project.godot').read_bytes();converted=transform_project(data)
        self.assertEqual(converted.count(b'run/main_loop_type="DotNativeRegionCapture"'),1)
        self.assertEqual(converted.count(b'run/main_scene="res://tests/native_region_bootstrap.tscn"'),1)
        self.assertNotIn(b'run/main_scene="res://scenes/game.tscn"',converted)
        self.assertIn(b'run/main_scene="res://scenes/game.tscn"',data)
    def test_unknown_project_entry_rejected(self):
        for data in [b'wrong',b'run/main_scene="res://scenes/game.tscn"\nrun/main_loop_type="Unexpected"']:
            with self.assertRaises(ValueError):transform_project(data)
    def test_pack_entry_receipt(self):
        row={'entry':ENTRY,'original_project_restored':True,'original_export_config_restored':True,'isolated_pack_setup_passed':True}
        validate_pack_receipt(row)
        for key,value in [('entry','old --script entry'),('original_project_restored',False),('original_export_config_restored',False),('isolated_pack_setup_passed',False)]:
            with self.subTest(key=key):
                wrong={**row,key:value}
                with self.assertRaises(ValueError):validate_pack_receipt(wrong)
    def test_no_capture_side_effect_inside_release_assert(self):
        for name in ['tests/authored_architecture_capture.gd','scripts/review/traversal_review.gd','scripts/review/freeze_shader_clock.gd']:
            text=(ROOT/name).read_text()
            self.assertNotRegex(text,r'assert\([^\n]*(?:\.save_png|\.compile|recorder\.start)\(')
    def test_native_window_readiness(self):
        focus={'pid':123};row={'pid':123,'focused':True,'display':'macOS'}
        self.assertTrue(window_ready(focus,row));self.assertFalse(window_ready(None,row))
        for key,value in [('pid',124),('focused',False),('display','headless')]:
            self.assertFalse(window_ready(focus,{**row,key:value}))
    def test_capture_mode_is_explicit_and_bounded(self):
        self.assertEqual(arguments('gate-context-study'),['--gate-context-study','--road-section-study','--author-oracle'])
        self.assertNotIn('--traversal-review',arguments('gate-context-study'))
        self.assertEqual(capture_budget('gate-context-study'),240)
        self.assertEqual(capture_budget('camera-study'),120)
        self.assertIn('--author-dynamic-review',arguments('destination-action'))
        self.assertIn('--wall-clock-action',arguments('destination-action'))
        self.assertEqual(capture_budget('destination-action'),240)
        self.assertEqual(arguments('destination-study'),['--destination-study','--road-section-study','--author-oracle'])
        self.assertEqual(capture_budget('destination-study'),240)
        with self.assertRaises(ValueError):arguments('unexpected')
        with self.assertRaises(ValueError):capture_budget('unexpected')

    def test_destination_pack_mode_must_match(self):
        r={'entry':ENTRY,'original_project_restored':True,'original_export_config_restored':True,'isolated_pack_setup_passed':True,'validated_capture_mode':'destination-study'}
        validate_pack_receipt(r,'destination-study')
        with self.assertRaises(ValueError):validate_pack_receipt(r,'gate-context-study')
    def test_optional_diagnostic_timeout_is_recorded_not_raised(self):
        with patch('run_native.subprocess.run',side_effect=subprocess.TimeoutExpired(['sample'],10,output=b'partial')) as run:
            r=diagnostic_command(['sample'],10)
        self.assertEqual(r['status'],'TIMEOUT');self.assertEqual(r['stdout'],'partial');self.assertIsNone(r['exit']);self.assertEqual(run.call_count,1)
    def test_optional_diagnostic_denial_is_recorded_without_retry(self):
        with patch('run_native.subprocess.run',side_effect=PermissionError('denied')) as run:
            r=diagnostic_command(['sample'],10)
        self.assertEqual(r['status'],'OS_ERROR');self.assertIn('denied',r['error']);self.assertEqual(run.call_count,1)
    def test_optional_diagnostic_exit_is_not_capture_status(self):
        with patch('run_native.subprocess.run',return_value=subprocess.CompletedProcess(['sample'],1,'','error')):
            r=diagnostic_command(['sample'],10)
        self.assertEqual(r['status'],'EXITED');self.assertEqual(r['exit'],1)
    def test_capture_failure_not_hidden_by_optional_diagnostic(self):
        focus={'window_ready':True};metal='Metal 4.0 - Forward Mobile - Apple Paravirtual'
        self.assertIsNone(capture_failure(None,0,focus,metal))
        self.assertEqual(capture_failure('GODOT_ERROR',0,focus,metal),'GODOT_ERROR')
        self.assertEqual(capture_failure('NATIVE_CAPTURE_TIMEOUT',0,focus,metal),'NATIVE_CAPTURE_TIMEOUT')
        self.assertEqual(capture_failure(None,1,focus,metal),'PROCESS_EXIT_NOT_ZERO')
        self.assertEqual(capture_failure(None,None,focus,metal),'PROCESS_EXIT_NOT_ZERO')
        self.assertEqual(capture_failure(None,0,None,metal),'NATIVE_WINDOW_NOT_VERIFIED')
        self.assertEqual(capture_failure(None,0,focus,'llvmpipe'),'NATIVE_METAL_NOT_VERIFIED')
if __name__=='__main__':unittest.main()
