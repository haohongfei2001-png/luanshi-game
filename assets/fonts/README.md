# Bundled Chinese font

`LuanshiUISCR-Regular.otf` is a renamed, modified subset of **Noto Sans CJK SC Regular 2.004**, licensed under SIL OFL 1.1. Full redistribution terms and copyright notices are in `license.txt`, included both inside the game pack and the exported third-party notices. No license is granted to the game itself by this font license.

Source: upstream https://github.com/notofonts/noto-cjk, Sans/OTC/NotoSansCJK-Regular.ttc (Sans 2.004); supplied here by Debian `fonts-noto-cjk` at `/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc`. Upstream font metadata identifies Adobe copyright and SIL OFL 1.1; Debian `/usr/share/doc/fonts-noto-cjk/copyright` supplies the full license and Google copyright. The Debian packaging's GPL is not the font license.

Pinned source SHA256: `b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a`. Collection face 2 is Simplified Chinese. Both OpenType name records and CFF font/family names are renamed to Luanshi UI SC, avoiding any reserved-name ambiguity. Copyright/license metadata is retained.

Rebuild with Python 3 and `fonttools==4.61.1`:

```
python3 tools/build_chinese_font.py /path/to/NotoSansCJK-Regular.ttc
./tools/test-youth-ui.sh
```

The script checks the source digest, retains printable ASCII and Latin-1, every GB2312 character and every printable character in runtime GDScripts, and emits `coverage.txt`. FontTools preserves layout closure and hinting. Font timestamps are preserved for reproducibility. The source font must support all required characters; otherwise regeneration fails explicitly. New unsupported UI characters fail the source-scan Godot test until the font is regenerated. Tests and exported youth smoke validate actual glyph availability for the full manifest, resource caching, disabled OS fallback and packaged licensing. No Python font dependency is required to run the game or normal CI.
