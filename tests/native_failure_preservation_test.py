"""Synthetic failure injection, not a real game performance claim."""
import contextlib,sys,tempfile
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import whole_native_delivery as delivery
from evidence_steps import attempt
with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp); data=root/'data'; failures=[]
    @contextlib.contextmanager
    def temporary_data(path):
        (path/'frame-times').mkdir(parents=True)
        try: yield
        finally:
            for file in (path/'frame-times').glob('*'): file.unlink()
            (path/'frame-times').rmdir()
    def fake_game(exe,destination,helper,args):
        (data/'frame-times'/'partial.jsonl').write_text('{"kind":"synthetic"}\n')
        if args==['fail']: raise RuntimeError('injected game failure')
        return 'BRIDGE_WINDOW true'
    delivery.empty_game_data=temporary_data; delivery.run_game=fake_game
    for mode in ['fail','pass']:
        ok=attempt(mode,lambda: delivery.preserve_profile(None,root/mode,None,data,[mode]),failures,root/'status.json')
        assert ok==(mode=='pass')
        assert (root/mode/'frame-times'/'partial.jsonl').read_text()=='{"kind":"synthetic"}\n'
    assert len(failures)==1 and failures[0]['step']=='fail'
print('NATIVE_FAILURE_PRESERVATION_SYNTHETIC_PASS')
