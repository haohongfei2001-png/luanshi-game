"""Exact donor Hit_Chest body/feet reaction with existing braced-hand constraint.
Not source full-arm equivalence, accepted hit animation, damage or gameplay mapping.
"""
import pathlib
p=pathlib.Path(__file__).with_name('spearman_controlled_walk.py');code=p.read_text()
for a,b in [("a.name=='Walk_Loop_Armature'","a.name=='Hit_Chest_Armature'"),("EXPERIMENT full-rig source Walk with unaccepted spear grip","EXPERIMENT donor Hit Chest torso legs with braced unaccepted hands"),("'No attack/death clips claimed'","'Donor Hit_Chest torso/neck/legs only; hands constrained to existing carry, not full source-arm equivalence; not accepted hit/combat animation'")]:
 if code.count(a)!=1:raise RuntimeError('Retarget source changed; review needed')
 code=code.replace(a,b)
exec(compile(code,str(p),'exec'))
