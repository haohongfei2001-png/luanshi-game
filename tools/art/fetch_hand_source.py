"""Download the three verified CC0 source files used by the optional Blender bake."""
import hashlib
from pathlib import Path
import sys
from urllib.request import urlopen

BASE="https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/"
FILES=(("3dobjs/base.obj","d26635e9326e3cca30778fd7b9c00062b03cce09"),
       ("rigs/default.mhskel","b02cbecae00143856410d7561adf006d83bf9b3e"),
       ("rigs/default_weights.mhw","66185806afacf87749be8e5cf6dbf66496b2a6b0"))

def main():
    folder=Path(sys.argv[1]);folder.mkdir(parents=True,exist_ok=True)
    for path,digest in FILES:
        target=folder/Path(path).name
        data=target.read_bytes() if target.is_file() else urlopen(BASE+path,timeout=45).read()
        if hashlib.sha1(f"blob {len(data)}\0".encode()+data).hexdigest()!=digest:
            raise ValueError(f"Wrong source for {path}")
        target.write_bytes(data)
        print(path,digest)

if __name__=="__main__":
    main()
