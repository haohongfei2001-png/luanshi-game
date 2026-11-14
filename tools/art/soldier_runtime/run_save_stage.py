"""Execute pinned builder through first top-level mother save, not preview renders."""
import ast,pathlib,sys,hashlib,json,os
builder,receipt,*args=sys.argv[sys.argv.index('--')+1:];p=pathlib.Path(builder);raw=p.read_bytes();tree=ast.parse(raw,filename=str(p));end=None
for i,node in enumerate(tree.body):
 if isinstance(node,ast.Expr) and isinstance(node.value,ast.Call) and isinstance(node.value.func,ast.Attribute) and node.value.func.attr=='save_as_mainfile':end=i;break
assert end is not None,'Expected explicit mother save absent'
endline=tree.body[end].end_lineno;tree.body=tree.body[:end+1]
sys.argv=['blender','--']+args
exec(compile(tree,str(p),'exec'),{'__name__':'__main__','__file__':str(p)})
pathlib.Path(receipt).write_text(json.dumps({'pinned_source_commit':os.environ.get('PINNED_BUILDER_COMMIT','945b2c676705460f97ba0d9e5c9d892f2a64390d'),'builder':p.name,'full_script_sha256':hashlib.sha256(raw).hexdigest(),'executed_through_line':endline,'skipped':'only source preview rendering/report code after mother save','same_bytes_as_prior_CI_mother':False},indent=2)+'\n')
