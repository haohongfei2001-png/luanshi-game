import tempfile,pathlib,subprocess,sys
script=pathlib.Path(__file__).with_name('assert_clean_logs.py')
with tempfile.TemporaryDirectory() as d:
 p=pathlib.Path(d)/'log'
 def check(text,code):
  p.write_text(text);r=subprocess.run([sys.executable,str(script),str(p)],capture_output=True);assert r.returncode==code
 check('Godot Engine 4.6.3\nWARNING: VSync unsupported\n',0)
 for line in ['SCRIPT ERROR: failed','SHADER ERROR: Redefinition of E','ERROR: Shader compilation failed.']:check(line,1)
 check('',1)
 p.unlink();assert subprocess.run([sys.executable,str(script),str(p)],capture_output=True).returncode==1
 print('6 log gate tests passed: clean warning allowed, 3 errors/empty/missing rejected')
