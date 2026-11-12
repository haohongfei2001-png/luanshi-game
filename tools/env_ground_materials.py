"""Grade the three CC0 scans into tileable game materials. Requires Pillow 11.3.0 for authoring.
The shipped game loads the PNGs directly. Use --cache to keep or supply verified source JPGs.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import tempfile
import urllib.request
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

# SHA-256 of the original, verified public CC0 albedos. Stored RGB is colour; alpha is a
# derived height mask for joining the roots to the exposed earth at their edge.
SOURCES = {
    "root-turf": ("sparse_grass", "ae94f2b34597b9108eefd88217f55eccaec6d6b382e858a478ee92df90e66617",
                  ((38, 49, 42), (67, 85, 57), (112, 121, 82))),
    "compacted-loam": ("brown_mud_dry", "a56281b644de614787340f3db45e28d2f72ec32fc19a442f99002bae0ab11398",
                       ((60, 51, 38), (101, 86, 65), (150, 132, 104))),
    "bank-silt": ("sandy_gravel_02", "c9d143db07db9a6be2eba285fae961d868520422ee5fa4d38d55da24f9968d51",
                  ((43, 52, 48), (72, 76, 63), (119, 112, 87))),
}


def source_bytes(asset: str, expected: str, cache: Path) -> bytes:
    cache.mkdir(parents=True, exist_ok=True)
    dest = cache / f"{asset}_diff_1k.jpg"
    if dest.is_file():
        data = dest.read_bytes()
    else:
        url = f"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/{asset}/{dest.name}"
        request = urllib.request.Request(url, headers={
            "User-Agent": "LuanshiGame-MaterialAuthoring (https://github.com/haohongfei2001-png/luanshi-game)"
        })
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f"Source checksum mismatch for {asset}")
    if not dest.exists():
        dest.write_bytes(data)
    print(f"SOIL_SOURCE {asset} {hashlib.sha256(data).hexdigest()} {len(data)}")
    return data


def clamp(number: float, low: float = 0, high: float = 1) -> float:
    return max(low, min(high, number))


def wrap_blur(image: Image.Image, radius: float) -> Image.Image:
    # A complete border neighbourhood at both sides preserves the scan's tiling.
    n = image.width
    border = Image.new("L", (n * 3, n * 3))
    for y in range(3):
        for x in range(3):
            border.paste(image, (x * n, y * n))
    return border.filter(ImageFilter.GaussianBlur(radius)).crop((n, n, n * 2, n * 2))


def grade(data: bytes, name: str, palette: tuple) -> Image.Image:
    n = 512
    photo = Image.open(io.BytesIO(data)).convert("RGB").resize((n, n), Image.Resampling.LANCZOS)
    gray = ImageOps.grayscale(photo)
    gr = gray.tobytes()
    middle = wrap_blur(gray, 1.45).tobytes()
    pools = wrap_blur(gray, 11.5).tobytes()
    pixels = photo.tobytes()
    ordered = sorted(gr)
    lo, mid, hi = [ordered[round((len(ordered) - 1) * q)] for q in (.06, .50, .94)]
    span = max(hi - lo, 8)
    paint = bytearray(n * n * 4)
    dark, earth, light = palette
    for i, original in enumerate(gr):
        broad = (pools[i] - mid) / span
        edges = (middle[i] - pools[i]) / span
        grain = (original - middle[i]) / span
        t = clamp(.49 + 1.23 * broad + .81 * edges + .44 * grain)
        colors = (dark, earth) if t < .5 else (earth, light)
        v = 2 * t if t < .5 else 2 * t - 1
        r, g, b = pixels[i*3:i*3+3]
        hue = clamp(.49 + (g - r) / max(span * .9, 16), 0, 1) - .49
        if name == "root-turf":
            adjustment = (-12*hue, 13*hue, 4*hue)
            height = clamp(.47 + .67*edges + .48*grain + .36*hue)
        elif name == "compacted-loam":
            adjustment = (2.5*hue, 2*hue, .9*hue)
            height = clamp(.49 + .48*edges + .68*grain)
        else:
            adjustment = (-3*hue, 6*hue, 5*hue)
            height = clamp(.47 + .39*edges + .54*grain)
        for k in range(3):
            paint[i*4+k] = round(clamp(colors[0][k]*(1-v)+colors[1][k]*v+adjustment[k], 0, 255))
        paint[i*4+3] = round(height*255)
    return Image.frombytes("RGBA", (n, n), bytes(paint))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", type=Path)
    args = parser.parse_args()
    destination = Path(__file__).resolve().parents[1] / "assets" / "environment"
    with tempfile.TemporaryDirectory(prefix="luanshi-soils-") as tmp:
        cache = args.cache or Path(tmp)
        for name, (asset, checksum, palette) in SOURCES.items():
            sample = source_bytes(asset, checksum, cache)
            texture = grade(sample, name, palette)
            target = destination / f"{name}.png"
            texture.save(target, format="PNG", compress_level=9)
            print(f"SOIL_LAYER {name} {hashlib.sha256(target.read_bytes()).hexdigest()} {target.stat().st_size}")


if __name__ == "__main__":
    main()
