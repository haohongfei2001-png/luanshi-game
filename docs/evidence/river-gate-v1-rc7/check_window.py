#!/usr/bin/env python3
"""Read a Godot RGB/RGBA8 PNG and check for a nonblank playfield, without Pillow.

The HUD at the bottom and the minimap cannot make a blank centre pass. This
checks actual image data only; it does not certify attractive art or real hits.
"""
import argparse
import json
import struct
import sys
import zlib
from pathlib import Path


def playfield(path):
    data = Path(path).read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, compressed = 8, []
    width = height = channels = 0
    while pos + 12 <= len(data):
        size, name = struct.unpack_from(">I4s", data, pos)
        end = pos + 12 + size
        if end > len(data):
            raise ValueError("truncated PNG")
        start = pos + 8
        chunk = data[start:start + size]
        if name == b"IHDR":
            width, height, depth, colour, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunk)
            if not (2 <= width <= 8192 and 2 <= height <= 8192 and
                    depth == 8 and colour in (2, 6) and compression == filtering == interlace == 0):
                raise ValueError("expected Godot RGB/RGBA8 noninterlaced image")
            channels = {2: 3, 6: 4}[colour]
        elif name == b"IDAT":
            compressed.append(chunk)
        elif name == b"IEND":
            break
        pos = end
    stride = width * channels
    if not stride or not compressed:
        raise ValueError("missing PNG pixels")
    pixels = zlib.decompress(b"".join(compressed))
    if len(pixels) != height * (1 + stride):
        raise ValueError("incomplete image")
    # All four colour stages in use are lit daytime scenes. Sample only the
    # central field, away from the command text, map and status overlay.
    xs = sorted({int(width * (.12 + .75 * (i + .5) / 32)) for i in range(32)})
    ys = {int(height * (.16 + .63 * (i + .5) / 22)) for i in range(22)}
    prev = bytearray(stride)
    values = []
    bright = set()
    for y in range(max(ys) + 1):
        offset = y * (stride + 1)
        method = pixels[offset]
        row = bytearray(pixels[offset + 1:offset + 1 + stride])
        if method == 1:
            for i in range(channels, stride):
                row[i] = (row[i] + row[i-channels]) & 255
        elif method == 2:
            row = bytearray((x + t) & 255 for x, t in zip(row, prev))
        elif method in (3, 4):
            for i in range(stride):
                a, b, c = (row[i-channels] if i >= channels else 0), prev[i], (prev[i-channels] if i >= channels else 0)
                if method == 3:
                    v = (a + b) // 2
                else:
                    v = a + b - c
                    da, db, dc = abs(v - a), abs(v - b), abs(v - c)
                    v = a if da <= db and da <= dc else (b if db <= dc else c)
                row[i] = (row[i] + v) & 255
        elif method != 0:
            raise ValueError("unknown PNG filter")
        if y in ys:
            for x in xs:
                off = x * channels
                r, g, b = row[off:off+3]
                if channels == 4 and row[off+3] < 32:
                    r = g = b = 0
                light = (54*r + 183*g + 19*b) >> 8
                values.append(light)
                if light >= 12:
                    bright.add((r >> 4, g >> 4, b >> 4))
        prev = row
    values.sort()
    p10 = values[len(values)//10]
    p90 = values[len(values)*9//10]
    valid = p90 >= 24 and p90 - p10 >= 12 and len(bright) >= 10
    return {"valid": valid, "size": [width, height], "sampled": len(values),
            "center_p10": p10, "center_p90": p90, "color_bins": len(bright)}


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("png", nargs="+", type=Path)
    args = ap.parse_args()
    ok = True
    for p in args.png:
        row = playfield(p)
        print(p.name, json.dumps(row, ensure_ascii=False))
        ok = ok and row["valid"]
    sys.exit(0 if ok else 1)
