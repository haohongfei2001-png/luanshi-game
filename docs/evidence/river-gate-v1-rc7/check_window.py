#!/usr/bin/env python3
"""Compatibility entry point for the RC7 evidence commands."""
import runpy
from pathlib import Path

tool = Path(__file__).resolve().parents[3] / "tools" / "check_playfield.py"
if __name__ == "__main__":
    runpy.run_path(str(tool), run_name="__main__")
else:
    playfield = runpy.run_path(str(tool))["playfield"]
