"""Verify that only the nine real falling strips changed."""
from pathlib import Path
from PIL import Image
import json
import sys
from company_motion import CLIPS, CARRY_KITS, CARRY_CLIPS, REACTIONS

def main():
    baseline=Image.open(sys.argv[1]).convert("RGBA")
    current=Image.open("assets/river_gate/figures/company_motion.png").convert("RGBA")
    strips=9*CLIPS+len(CARRY_KITS)*2*len(CARRY_CLIPS)+9*len(REACTIONS)
    assert current.size==baseline.size==(528,strips*4)
    falling={kit*CLIPS+14 for kit in range(9)}
    for lane in range(strips):
        if lane in falling:
            continue
        box=(0,lane*4,current.width,(lane+1)*4)
        assert current.crop(box).tobytes()==baseline.crop(box).tobytes(),f"Live strip {lane} changed"
    report={"preserved_existing_strips":strips-len(falling),"falling_strips":sorted(falling),
            "dimensions":current.size,"new_runtime_samples":0}
    out=Path("docs/evidence/river-gate-v1-rc23/ground-contact/palette-check.json")
    out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(report,indent=2)+"\n")
    print("GROUND_CONTACT_PALETTE",json.dumps(report),flush=True)

if __name__=="__main__":
    main()
