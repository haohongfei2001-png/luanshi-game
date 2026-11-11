#!/usr/bin/env python3
"""Rebuild the OFL font from the pinned upstream TTC; fonttools==4.61.1."""
import argparse
import hashlib
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA256 = 'b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a'

def repertoire():
    codes = set(range(32, 127)) | set(range(160, 256))
    for lead in range(0xA1, 0xF8):
        for trail in range(0xA1, 0xFF):
            try:
                codes.add(ord(bytes([lead, trail]).decode('gb2312')))
            except UnicodeDecodeError:
                pass
    for path in sorted((ROOT / 'scripts').glob('*.gd')):
        codes.update(ord(c) for c in path.read_text() if c.isprintable())
    return codes

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    if hashlib.sha256(args.source.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise SystemExit('Wrong source TTC: obtain the pinned Noto Sans CJK 2.004 regular TTC.')
    font = TTFont(args.source, fontNumber=2, recalcTimestamp=False)
    assert font['name'].getDebugName(1) == 'Noto Sans CJK SC'
    codes = repertoire()
    missing = codes - set(font.getBestCmap())
    if missing:
        raise SystemExit(f'Upstream font lacks required codepoints: {sorted(missing)}')
    options = subset.Options()
    options.name_IDs = ['*']
    options.name_languages = ['*']
    options.name_legacy = True
    worker = subset.Subsetter(options=options)
    worker.populate(unicodes=sorted(codes))
    worker.subset(font)
    names = {1: 'Luanshi UI SC', 2: 'Regular', 3: 'LuanshiUISCR-Regular-2.004',
             4: 'Luanshi UI SC Regular', 6: 'LuanshiUISCR-Regular',
             16: 'Luanshi UI SC', 17: 'Regular'}
    for record in font['name'].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    cff = font['CFF '].cff
    cff.fontNames = ['LuanshiUISCR-Regular']
    cff.topDictIndex[0].FamilyName = names[1]
    cff.topDictIndex[0].FullName = names[4]
    for fd in cff.topDictIndex[0].FDArray:
        if hasattr(fd, 'FontName'):
            fd.FontName = 'LuanshiUISCR-Regular-' + fd.FontName.rsplit('-', 1)[-1]
    target = ROOT / 'assets/fonts/LuanshiUISCR-Regular.otf'
    font.save(target)
    (target.parent / 'coverage.txt').write_text(''.join(chr(c) for c in sorted(codes)) + '\n')
    print(f'{len(codes)} codepoints; {target.stat().st_size} bytes; SHA256 {hashlib.sha256(target.read_bytes()).hexdigest()}')

if __name__ == '__main__':
    main()
