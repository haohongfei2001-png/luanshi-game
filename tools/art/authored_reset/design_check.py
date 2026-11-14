"""Executable space contract, not an aesthetic acceptance test."""
import json, math, pathlib
ROOT=pathlib.Path(__file__).resolve().parent

def overlaps(a,b):
    return a[0]<b[2] and a[2]>b[0] and a[1]<b[3] and a[3]>b[1]

def check(plan):
    assert plan['status']=='DESIGN_ONLY_NOT_ART_CANDIDATE'
    assert plan['camera']['orthographic_vertical']==22
    ids=[a['id'] for a in plan['assemblies']]
    assert len(ids)==len(set(ids))
    for a in plan['assemblies']:
        x0,z0,x1,z1=a['bounds_xz']
        assert x1>x0 and z1>z0
        assert a['family'] in plan['material_families']
        if a['kind'] in ('canopy_mass','background','wall'):
            for route in plan['protected_routes']:
                assert not overlaps(a['bounds_xz'],route['bounds_xz']), (a['id'],route['id'])
    gate=next(a for a in plan['assemblies'] if a['id']=='gate')
    assert gate['opening_width']==8 and gate['opening_height']>=4
    return {'status':'SPACE_CONTRACT_PASS_NOT_VISUAL_ACCEPTANCE', 'assemblies':len(ids),
            'protected_routes':len(plan['protected_routes']), 'runtime_changed':False,
            'professional_asset_selection':'PENDING', 'game_visuals':'NOT_RUN'}

if __name__=='__main__':
    print(json.dumps(check(json.loads((ROOT/'layout.json').read_text())),indent=2))
