from pathlib import Path
import copy, math, sys, unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools/native_region'))
from validate_stills import VIEWS,validate_records
from restore_complete import RUNTIME_FILES
from resource_identity import runtime_rows

def identities():
    return {'res://'+p:{'source_resource_path':'res://'+p,'original_source_sha256':h,'packed_resource_path':'res://.godot/imported/gate.scn' if p.endswith('.glb') else 'res://'+p,'packed_resource_sha256':'1'*64 if p.endswith('.glb') else h,'identity_method':'godot_import_remap' if p.endswith('.glb') else 'direct_resource'} for p,h in RUNTIME_FILES.items()}

def context_validate(rows):return validate_records(rows,'a'*40,'gate-context-study',identities())

def rows():
    result=[]
    for name,size in VIEWS['camera-study'].items():
        r={k:list(size) for k in ['pixels','internal_pixels','attachment_size','viewport']}
        r.update(source='a'*40,view=name,battle_snapshot_sha256='b'*64,seed='61112',tick=135,ordinary=[20,20],internal_scale=1,
                 camera_review_profile={'projection':'perspective','nominal_body_fraction':.1,'pitch_degrees':32.,'fov_degrees':55.},
                 camera_yaw=math.radians(-75 if name.endswith('road75') else -65))
        result.append(r)
    return result

def context_rows():
    result=[]
    for name,size in VIEWS['gate-context-study'].items():
        r=rows()[0]
        r.update({k:list(size) for k in ['pixels','internal_pixels','attachment_size','viewport']})
        r.update(view=name, camera_yaw=math.radians(-65),
            camera_review_profile={'projection':'perspective','nominal_body_fraction':.1,'pitch_degrees':32 if name.endswith('road65') else 38,'fov_degrees':55},
            runtime_resource_identities=runtime_rows(identities()),logical_viewport_size=[1422,800],
            runtime_architecture_sha256='1'*64,runtime_ground_sha256=RUNTIME_FILES['assets/river_authored/ground/continuous-region.scn'],runtime_woodland_sha256=RUNTIME_FILES['assets/river_authored/woodland/region.scn'],
            shader_clock={'fixed_seconds':6.75},
            single_real_unit_author_oracle={'mesh_count':43,'unit_is_real_hero':True,'art_pass':False,'actions_accepted':False,
                'battle_state_written':False,'single_actor_author_oracle_not_army_runtime':True,'ground_lift_m':0,
                'metadata_sha256':'4'*64,'source_files':{'walk':{'sha256':'5'*64}}},
            actual_author_body_projection={'display_backend':'macOS','coordinate_space':'logical_viewport_units','projection_viewport':[1422,800],'top_y':360.,
                'boot_bottom_y':456.,'height_px':96.,'height_fraction':.12,'vertices_checked':13242,
                'attachment_projection':{'attachment_size':list(size),'scale_xy':[size[0]/1422,size[1]/800],'top_y':size[1]*.45,'boot_bottom_y':size[1]*.57,'height_px':size[1]*.12}})
        result.append(r)
    return result

def destination_rows():
    result=[]
    for name,size in VIEWS['destination-study'].items():
        r=context_rows()[0]
        r.update({k:list(size) for k in ['pixels','internal_pixels','attachment_size','viewport']})
        r['view']=name
        b=r['actual_author_body_projection'];b['attachment_projection']={'attachment_size':list(size),'scale_xy':[size[0]/1422,size[1]/800],'top_y':size[1]*.45,'boot_bottom_y':size[1]*.57,'height_px':size[1]*.12}
        if 'destination' in name:
            variant=name.split('-')[-1];pitch,fov=(26,65) if variant=='destination26' else (28,70)
            r['camera_review_profile'].update(pitch_degrees=pitch,fov_degrees=fov,look_height=1.5)
            r['destination_fit']={'error':0,'variant':variant,'before':{'height_fraction':.12},'after':{'height_fraction':.12}}
            r['actual_gate_projection']={'all_bounds_inside':True,'bound_points':40,'normalized_rect':[.4,.06,.8,.34]}
        result.append(r)
    return result

def destination_validate(rows):return validate_records(rows,'a'*40,'destination-study',identities())

class StillGate(unittest.TestCase):
    def test_live_mode_keeps_exact_static_gate(self):
        self.assertEqual(validate_records(destination_rows(),'a'*40,'destination-action',identities()),'b'*64)
        wrong=destination_rows();wrong[1]['internal_scale']=.5
        with self.assertRaises(ValueError):validate_records(wrong,'a'*40,'destination-action',identities())

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
    def test_context_correct(self):self.assertEqual(context_validate(context_rows()),'b'*64)
    def test_context_rejects_drift_and_wrong_evidence(self):
        mutations=[('runtime_ground_sha256',None,'f'*64),('single_real_unit_author_oracle','mesh_count',1),
            ('single_real_unit_author_oracle','actions_accepted',True),('single_real_unit_author_oracle','ground_lift_m',.04),
            ('actual_author_body_projection','display_backend','headless'),('actual_author_body_projection','projection_viewport',[1280,800]),
            ('actual_author_body_projection','height_px',float('nan')),('actual_author_body_projection','height_fraction',.1),
            ('camera_review_profile','pitch_degrees',32),('shader_clock','fixed_seconds',0)]
        for top,sub,value in mutations:
            with self.subTest(top=top,sub=sub):
                r=context_rows()
                if sub is None:r[1][top]=value
                else:r[1][top][sub]=value
                with self.assertRaises(ValueError):context_validate(r)
    def test_consistent_but_shrunken_actor_is_rejected(self):
        r=context_rows();b=r[1]['actual_author_body_projection'];b.update(height_px=80,height_fraction=.1,boot_bottom_y=b['top_y']+80);b['attachment_projection'].update(height_px=144,boot_bottom_y=(b['top_y']+80)*1.8)
        with self.assertRaisesRegex(ValueError,'resized'):context_validate(r)
    def test_original_raw_glb_is_not_runtime_hash(self):
        r=context_rows();r[0]['runtime_architecture_sha256']=RUNTIME_FILES['assets/river_authored/architecture/architecture.glb']
        with self.assertRaises(ValueError):context_validate(r)
    def test_missing_export_identity_rejected(self):
        with self.assertRaises(ValueError):validate_records(context_rows(),'a'*40,'gate-context-study')
    def test_packed_resource_mutation_rejected(self):
        r=context_rows();r[1]['runtime_resource_identities']['res://assets/river_authored/architecture/architecture.glb']['packed_resource_sha256']='9'*64
        with self.assertRaises(ValueError):context_validate(r)
    def test_no_false_native_projection_label(self):
        for key,value in [('height_px',96),('scale_xy',[1,1]),('attachment_size',[1422,800])]:
            r=context_rows();r[0]['actual_author_body_projection']['attachment_projection'][key]=value
            with self.assertRaises(ValueError):context_validate(r)
    def test_missing_logical_provenance_rejected(self):
        r=context_rows();r[1].pop('logical_viewport_size')
        with self.assertRaises(ValueError):context_validate(r)
    def test_destination_correct(self):self.assertEqual(destination_validate(destination_rows()),'b'*64)
    def test_destination_clipped_gate_rejected(self):
        for key,value in [('all_bounds_inside',False),('normalized_rect',[.4,-.01,.8,.34]),('bound_points',0)]:
            r=destination_rows();r[1]['actual_gate_projection'][key]=value
            with self.assertRaises(ValueError):destination_validate(r)
    def test_wrong_destination_camera_rejected(self):
        for key,value in [('pitch_degrees',38),('fov_degrees',55),('look_height',.8)]:
            r=destination_rows();r[1]['camera_review_profile'][key]=value
            with self.assertRaises(ValueError):destination_validate(r)
    def test_missing_or_changed_destination_fit_rejected(self):
        r=destination_rows();r[1]['destination_fit']['before']['height_fraction']=.1
        with self.assertRaises(ValueError):destination_validate(r)
        r=destination_rows();r[1]['destination_fit']={}
        with self.assertRaises(ValueError):destination_validate(r)
    def test_primary_native_pair_keeps_all_integrity_gates(self):
        r=[x for x in destination_rows() if x['view'].endswith('destination26')]
        self.assertEqual(validate_records(r,'a'*40,'destination-primary-action',identities()),'b'*64)
        r[1]['internal_scale']=.5
        with self.assertRaises(ValueError):validate_records(r,'a'*40,'destination-primary-action',identities())
if __name__=='__main__':unittest.main()
