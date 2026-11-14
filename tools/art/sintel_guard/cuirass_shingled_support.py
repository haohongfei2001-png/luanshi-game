"""Whole chest shingle profile: local overlap tilt, not cumulative radial floating.
Explicit continuous bearing welt outside the high edges; source cloth untouched.
An independent art candidate, not acceptance or correction of known motion failures.
"""
import pathlib
path=pathlib.Path(__file__).with_name('articulated_cuirass.py');source=path.read_text()
marker="exec(compile(code,str(p),'exec'))"
assert source.count(marker)==1
source=source.replace(marker,'''# This occurs after prior complete-cuirass substitutions, before evaluation.
edit("offset=.026+row*.0022", "offset=.029")
edit("p=surface(aa,min(z+zz*.068,upper(aa)-.019),offset)", "p=surface(aa,min(z+zz*.068,upper(aa)-.019),offset+.006*(.5-zz))")
edit("rp.append(surface(a,z,.021))", "rp.append(surface(a,z,.037 if label=='upper' else .034))")
'''+marker)
exec(compile(source,str(path),'exec'))
