"""Explicit nonzero error gate. Bash `! grep` is exempt from errexit."""
import pathlib,re,sys
assert len(sys.argv)>1,'At least one real log is required'
errors=[]
for arg in sys.argv[1:]:
 p=pathlib.Path(arg)
 if not p.is_file() or p.stat().st_size==0:errors.append(f'{p}: missing or empty log');continue
 for n,line in enumerate(p.read_text(errors='replace').splitlines(),1):
  if re.search(r'SCRIPT ERROR|SHADER ERROR|ERROR:',line):errors.append(f'{p}:{n}:{line}')
if errors:
 print('\n'.join(errors),file=sys.stderr);sys.exit(1)
print('Real nonempty logs contain no SCRIPT ERROR / SHADER ERROR / ERROR:')
