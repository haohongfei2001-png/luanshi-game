"""Decode the exact rendered palette and instanced transforms of the real actor."""
import json
import sys
from pathlib import Path
from math import dist, floor
from PIL import Image
from check_company_motion import decoded
from company_motion import LB,RB,leg_nodes,trans

def ankles(row,bank):
    data=row["instance"]["custom"]
    code=floor(data[0]*128.)
    state=code%8
    slot=(code//8)%4
    kit=row["kit"]
    phase=data[1]
    if state==0:
        clip=floor(phase*32.) if phase>.001 else 1
        phase=data[2]
    elif state in (1,2):clip=(2 if state==1 else 6)+slot
    elif state==3:clip=10
    elif state==4:clip=11
    elif state==5:clip=12;phase=data[2]
    elif state==6:clip=13
    else:clip=14
    sample_kit=2 if (code//32)%2 and state in (1,2) else kit
    strip=sample_kit*31+clip
    if code<64 and sample_kit==kit:
        lot=floor(data[3]*8.)
        variant=1 if lot in (1,4) else 2 if lot in (2,5,7) else 0
        carrier=0 if kit==3 else 1 if kit==4 else 2 if kit==7 else -1
        carry=0 if clip==1 else 1 if clip==0 else clip-14 if 16<=clip<=22 else clip+7 if 2<=clip<=9 else -1
        if variant and carrier>=0 and carry>=0:
            strip=279+carrier*34+(variant-1)*17+carry
    if clip in (10,11) and slot in (1,2):
        strip=381+kit*4+(0 if clip==10 else 2)+slot-1
    phase=max(0.,min(1.,phase))
    frame=phase*(32. if clip in (0,1,12) or clip>=15 else 31.)
    if bank.height>=1756 and code<64 and sample_kit==3 and clip in (2,6):
        segment=min(floor(phase*8.),7)
        strip=423+(8 if clip==6 else 0)+segment
        frame=(phase*8.-segment)*31.
    matrix=row["instance"]["transform"]
    result={}
    for side,bone in ((-1,LB),(1,RB)):
        p=trans(decoded(bank,bone,0,strip,frame),leg_nodes(side)[2])
        result[str(side)]=[sum(matrix[column][axis]*p[column] for column in range(3))+matrix[3][axis] for axis in range(3)]
    return result

def main():
    folder=Path(sys.argv[1])
    report={}
    for label,palette in (("before",sys.argv[2]),("after",sys.argv[3])):
        bank=Image.open(palette).convert("RGBA")
        data=json.loads((folder/(label+".json")).read_text())
        rows=[{"tick":row["tick"],"state":row["state"],"ankles":ankles(row,bank)} for row in data["index"]]
        steps=[]
        for previous,row in zip(rows,rows[1:]):
            steps.append({"to_tick":row["tick"],"state":row["state"],"from_state":previous["state"],
                          "ankle_step_m":{side:dist(previous["ankles"][side],row["ankles"][side]) for side in ("-1","1")}})
        report[label]={"frames":rows,"steps":steps}
    (folder/"actual-ankles.json").write_text(json.dumps(report,indent=2)+"\n")
    print("ACTUAL_ANKLE_BOUNDARIES",json.dumps({label:[r for r in data["steps"] if r["state"]!=r["from_state"]] for label,data in report.items()}))

if __name__=="__main__": main()
