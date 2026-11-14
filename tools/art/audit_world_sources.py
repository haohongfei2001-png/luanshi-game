"""Inspect the exact runtime botanical geometry and unmodified surface scans."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/evidence/river-whole-rebuild/review"
OUT.mkdir(parents=True, exist_ok=True)
paths = [
    ROOT / "assets/river_gate/world/ground" / (name + ".jpg")
    for name in ("brown_mud_dry", "leafy_grass", "forest_ground_04")
]
paths.append(ROOT / "assets/river_gate/world/masters/island_tree_01/island_tree_01_leaves_diff_2k.png")
board = Image.new("RGB", (1280, 680), "#202522")
draw = ImageDraw.Draw(board)
report = {"textures": [], "leaf_components": {}}
for i, path in enumerate(paths):
    with Image.open(path) as original:
        pixels = np.asarray(original.convert("RGB"), dtype=np.float32) / 255.
        linear = np.where(pixels <= .04045, pixels / 12.92, ((pixels + .055) / 1.055) ** 2.4)
        brightness = linear @ np.array([.2126, .7152, .0722])
        row = {
            "source": str(path.relative_to(ROOT)),
            "pixels": original.size,
            "mode": original.mode,
            "linear_luminance_percentiles": np.percentile(brightness, [0, 5, 25, 50, 75, 95, 100]).tolist(),
        }
        if "A" in original.getbands():
            alpha = np.asarray(original.getchannel("A"))
            row["alpha_range"] = [int(alpha.min()), int(alpha.max())]
            row["alpha_coverage_40"] = float(np.mean(alpha >= 102))
        report["textures"].append(row)
        sample = original.convert("RGB")
        sample.thumbnail((620, 300), Image.Resampling.LANCZOS)
        left, top = (i % 2) * 640, (i // 2) * 340
        board.paste(sample, (left, top + 28))
        draw.text((left + 8, top + 6), path.stem, fill="white")
board.save(OUT / "native-source-atlas.jpg", quality=94, subsampling=0)

source = ROOT / "assets/river_gate/world/masters/island_tree_01/island_tree_01.gltf"
document = json.loads(source.read_text())
buffers = [(source.parent / entry["uri"]).read_bytes() for entry in document["buffers"]]
def accessor(index):
    entry = document["accessors"][index]
    view = document["bufferViews"][entry["bufferView"]]
    dtype = {5126: "<f4", 5125: "<u4", 5123: "<u2"}[entry["componentType"]]
    columns = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[entry["type"]]
    offset = entry.get("byteOffset", 0) + view.get("byteOffset", 0)
    stride = view.get("byteStride", np.dtype(dtype).itemsize * columns)
    return np.ndarray((entry["count"], columns), dtype=dtype,
                      buffer=buffers[view["buffer"]], offset=offset,
                      strides=(stride, np.dtype(dtype).itemsize)).copy()

for mesh in document["meshes"]:
    for primitive in mesh["primitives"]:
        material = document["materials"][primitive["material"]]
        if "leaves" not in material["name"]:
            continue
        vertices = accessor(primitive["attributes"]["POSITION"])
        # Weld exact native positions across UV/normal splits for island sizes.
        points, remap = np.unique(vertices, axis=0, return_inverse=True)
        triangles = remap[accessor(primitive["indices"]).reshape(-1)].reshape(-1, 3)
        parents = list(range(len(points)))
        def find(index):
            while parents[index] != index:
                parents[index] = parents[parents[index]]
                index = parents[index]
            return index
        for a, b, c in triangles.tolist():
            root = find(a)
            parents[find(b)] = root
            parents[find(c)] = root
        labels = np.array([find(i) for i in range(len(points))])
        unique, compact = np.unique(labels, return_inverse=True)
        lower = np.full((len(unique), 3), np.inf)
        upper = np.full((len(unique), 3), -np.inf)
        np.minimum.at(lower, compact, points)
        np.maximum.at(upper, compact, points)
        span = np.linalg.norm(upper - lower, axis=1)
        report["leaf_components"] = {
            "triangles": len(triangles),
            "native_vertices": len(vertices),
            "welded_vertices": len(points),
            "connected_islands": len(unique),
            "island_span_m_percentiles": np.percentile(span, [0, 5, 25, 50, 75, 95, 100]).tolist(),
            "tree_bounds_m": (points.max(axis=0) - points.min(axis=0)).tolist(),
            "leaf_islands_under_20cm": int(np.sum(span < .20)),
        }
(OUT / "native-source-audit.json").write_text(json.dumps(report, indent=2) + "\n")
print("WORLD_SOURCE_AUDIT", json.dumps(report), flush=True)
