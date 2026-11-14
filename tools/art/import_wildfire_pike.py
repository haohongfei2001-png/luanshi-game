"""Sample one verified complete 0 A.D. two-handed thrust; no source pose edits."""
import json,sys
from pathlib import Path
from import_garrison_issues import source_file,UPSTREAM
from import_wildfire_combat import extract

SOURCES=(("pike_02","animation/biped/infantry/pikeman/attack_melee_02.dae","1f319000b3e49a12bf85262a553442472feca293"),)

def main():
    cache=Path(sys.argv[1])
    result={"authors":"Wildfire Games contributors","license":"CC BY-SA 3.0","upstream":UPSTREAM,"curves":{}}
    for name,path,blob in SOURCES:
        folder=cache/name
        folder.mkdir(parents=True,exist_ok=True)
        curve=extract(source_file(folder,path,blob))
        curve.update(source_path=path,source_blob=blob)
        result["curves"][name]=curve
        print("PIKE_SOURCE",name,curve["duration"],curve["bind_matrix_error"],blob,flush=True)
    Path("tools/art/source/wildfire_pike_curves.json").write_text(json.dumps(result,separators=(",",":"))+"\n")

if __name__=="__main__":main()
