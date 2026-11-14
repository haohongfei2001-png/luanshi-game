import json,pathlib,sys
p=pathlib.Path(sys.argv[1]);r=json.loads((p/'report.json').read_text());m=r['motion_video'];f=json.loads((p/'movie-probe.json').read_text())['streams'][0]
assert f['width']==2560 and f['height']==1440 and f['r_frame_rate']=='24/1'
assert int(f['nb_read_frames'])==m['total_frames']==sum(x['frames'] for x in m['clips'])
assert {x['clip'] for x in m['clips']}=={'Idle','Walk','Jog_Fwd','Sprint','Sword_Attack','Sword_Idle','Hit_Chest','Hit_Head','Death01'}
assert len(m['clips'])==9
print('Actual full original cycles encoded:',m['total_frames'],'frames; simulated 24fps, NOT measured wall-clock gameplay FPS')
