"""Check preserved clip pixels, including every seated basic attack strip."""
from pathlib import Path
from PIL import Image
import json
import sys
from company_motion import CLIPS, CARRY_KITS, CARRY_CLIPS, REACTIONS, MOUNTED_ATTACKS

def main():
    baseline=Image.open(sys.argv[1]).convert("RGBA")
    current=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
    start=9*CLIPS+len(CARRY_KITS)*2*len(CARRY_CLIPS)+9*len(REACTIONS)
    assert baseline.height==start*4
    assert current.size==(baseline.width,(start+len(MOUNTED_ATTACKS))*4)
    changed={kit*CLIPS+clip for kit,clip in MOUNTED_ATTACKS}
    carrier=CARRY_KITS.index(7)
    changed.update(9*CLIPS+(carrier*2+variant)*len(CARRY_CLIPS)+CARRY_CLIPS.index(clip)
                   for variant in range(2) for clip in (2,6))
    changed.update(kit*CLIPS+14 for kit in range(9))
    unchanged=0
    for lane in range(start):
        if lane in changed:
            continue
        box=(0,lane*4,current.width,(lane+1)*4)
        assert current.crop(box).tobytes()==baseline.crop(box).tobytes(),f"preserved lane {lane} changed"
        unchanged+=1
    for index,(kit,clip) in enumerate(MOUNTED_ATTACKS):
        expected=baseline.crop((0,(kit*CLIPS+clip)*4,baseline.width,(kit*CLIPS+clip+1)*4))
        actual=current.crop((0,(start+index)*4,current.width,(start+index+1)*4))
        assert actual.tobytes()==expected.tobytes(),f"mounted kit {kit} clip {clip} changed"
    report={"preserved_existing_strips":unchanged,"changed_ground_strips":sorted(changed),
            "mounted_strips_identical_to_baseline":len(MOUNTED_ATTACKS),
            "baseline_dimensions":baseline.size,"new_dimensions":current.size}
    out=Path("docs/evidence/river-gate-v1-rc23/native-combat/mounted-strip-check.json")
    out.write_text(json.dumps(report,indent=2)+"\n")
    print("MOUNTED_BASELINE_CHECK",json.dumps(report),flush=True)

if __name__=="__main__":
    main()
