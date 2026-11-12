#!/usr/bin/env python3
"""Inspect delivered GLB bytes; never infer asset completion from a generator manifest.

Python standard library only. Run from any directory. A missing or invalid required
asset produces FAIL and exit 1; reports distinguish structural checks from unrun
engine, visual and target-hardware checks.
"""
from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import sys

REPO = Path(__file__).resolve().parents[3]
FACTIONS = ("frontier", "garrison")
ROLES = ("recruit", "spearman", "shieldman", "archer", "crossbowman", "guard",
         "cavalry", "engineer", "captain", "vanguard", "challenger", "commander")
OFFICERS = {"captain", "vanguard", "challenger", "commander"}
ANIMATIONS = ("idle", "walk", "run", "attack", "guard", "hit", "death", "command", "riding")
BUDGETS = {"soldier": (14000, 3500, 900), "officer": (22000, 6000, 1400)}
COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
              5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
SHAPES = {"SCALAR": (1, 1), "VEC2": (1, 2), "VEC3": (1, 3),
          "VEC4": (1, 4), "MAT2": (2, 2), "MAT3": (3, 3), "MAT4": (4, 4)}


class InvalidAsset(ValueError):
    pass


def need(condition, message):
    if not condition:
        raise InvalidAsset(message)


def relative(path):
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def identified_role(path):
    tokens = re.split(r"[^a-z0-9]+", str(path).lower())
    factions = [x for x in FACTIONS if x in tokens]
    roles = [x for x in ROLES if x in tokens]
    lods = [int(x[3:]) for x in tokens if re.fullmatch(r"lod[012]", x)]
    if len(factions) == len(roles) == len(lods) == 1:
        return factions[0], roles[0], lods[0]
    return None


class GLB:
    def __init__(self, path):
        self.path = path
        self.raw = path.read_bytes()
        need(len(self.raw) >= 20, "GLB header is truncated")
        magic, version, length = struct.unpack_from("<4sII", self.raw)
        need(magic == b"glTF" and version == 2, "Expected glTF 2.0 binary header")
        need(length == len(self.raw), "Declared GLB length differs from actual bytes")
        chunks, cursor = [], 12
        while cursor < len(self.raw):
            need(cursor + 8 <= len(self.raw), "Truncated GLB chunk header")
            size, kind = struct.unpack_from("<I4s", self.raw, cursor)
            need(size % 4 == 0, "GLB chunk length is not four-byte aligned")
            cursor += 8
            need(cursor + size <= len(self.raw), "GLB chunk extends beyond file")
            chunks.append((kind, self.raw[cursor:cursor + size]))
            cursor += size
        need(chunks and chunks[0][0] == b"JSON", "First GLB chunk must be JSON")
        need(sum(kind == b"JSON" for kind, _ in chunks) == 1, "Duplicate JSON chunk")
        need(sum(kind == b"BIN\0" for kind, _ in chunks) <= 1, "Duplicate BIN chunk")
        self.doc = json.loads(chunks[0][1].decode("utf-8").rstrip(" \x00\t\r\n"))
        need(self.doc.get("asset", {}).get("version") == "2.0", "asset.version must be 2.0")
        binary = next((data for kind, data in chunks if kind == b"BIN\0"), None)
        self.buffers = []
        for i, buf in enumerate(self.doc.get("buffers", [])):
            uri = buf.get("uri")
            if uri is None:
                need(i == 0 and binary is not None, f"buffer[{i}] has no URI or BIN chunk")
                data = binary
            elif uri.startswith("data:"):
                need(";base64," in uri, f"buffer[{i}] uses unsupported non-base64 data URI")
                data = base64.b64decode(uri.split(",", 1)[1], validate=True)
            else:
                data = self.external(uri).read_bytes()
            declared = buf.get("byteLength", -1)
            need(isinstance(declared, int) and declared >= 0, f"Invalid buffer[{i}] byteLength")
            need(len(data) >= declared, f"buffer[{i}] is shorter than byteLength")
            if uri is None:
                need(len(data) - declared <= 3, "BIN chunk has more than three padding bytes")
            self.buffers.append(data[:declared])
        self.cache = {}

    def external(self, uri):
        need(not re.match(r"^[a-z]+:", uri, re.I), "Network asset dependency is not self-contained")
        target = (self.path.parent / uri).resolve()
        need(target.is_relative_to(self.path.parent.resolve()), "External URI leaves asset directory")
        need(target.is_file(), f"Missing external dependency: {uri}")
        return target

    def entry(self, collection, index):
        values = self.doc.get(collection, [])
        need(isinstance(index, int) and 0 <= index < len(values),
             f"Invalid {collection} reference: {index}")
        return values[index]

    def view(self, index):
        v = self.entry("bufferViews", index)
        b = v.get("buffer")
        need(isinstance(b, int) and 0 <= b < len(self.buffers), f"bufferView[{index}] invalid buffer")
        offset, length = v.get("byteOffset", 0), v.get("byteLength", -1)
        need(isinstance(offset, int) and isinstance(length, int) and offset >= 0 and length >= 0,
             f"bufferView[{index}] invalid range")
        need(offset + length <= len(self.buffers[b]), f"bufferView[{index}] exceeds buffer")
        return self.buffers[b][offset:offset + length], v

    def accessor(self, index, normalized=False):
        key = (index, normalized)
        if key in self.cache:
            return self.cache[key]
        a = self.entry("accessors", index)
        component, shape, count = a.get("componentType"), a.get("type"), a.get("count")
        need(component in COMPONENTS and shape in SHAPES, f"accessor[{index}] invalid component/type")
        need(isinstance(count, int) and count > 0, f"accessor[{index}] has invalid count")
        fmt, size = COMPONENTS[component]
        cols, rows = SHAPES[shape]
        column_bytes = ((rows * size + 3) // 4 * 4) if cols > 1 else rows * size
        offsets = [c * column_bytes + r * size for c in range(cols) for r in range(rows)]
        element_bytes = cols * column_bytes

        def unpack(view_index, byte_offset, n, use_stride=True):
            data, v = self.view(view_index)
            stride = v.get("byteStride", element_bytes) if use_stride else element_bytes
            need(isinstance(stride, int) and stride >= element_bytes and stride % size == 0,
                 f"accessor[{index}] invalid stride")
            need(isinstance(byte_offset, int) and byte_offset >= 0 and byte_offset % size == 0,
                 f"accessor[{index}] misaligned offset")
            need((v.get("byteOffset", 0) + byte_offset) % size == 0,
                 f"accessor[{index}] absolute offset is misaligned")
            need(byte_offset + (n - 1) * stride + element_bytes <= len(data),
                 f"accessor[{index}] exceeds bufferView")
            unit = struct.Struct("<" + fmt)
            return [tuple(unit.unpack_from(data, byte_offset + row * stride + off)[0]
                          for off in offsets) for row in range(n)]

        if "bufferView" in a:
            values = unpack(a["bufferView"], a.get("byteOffset", 0), count)
        else:
            need("sparse" in a, f"accessor[{index}] has neither data nor sparse values")
            values = [(0,) * (cols * rows) for _ in range(count)]
        if "sparse" in a:
            sparse = a["sparse"]
            n = sparse.get("count", 0)
            need(isinstance(n, int) and 0 < n <= count, f"accessor[{index}] invalid sparse count")
            indices = sparse["indices"]
            kind = indices.get("componentType")
            need(kind in (5121, 5123, 5125), "Sparse index type must be unsigned integer")
            data, _ = self.view(indices["bufferView"])
            form, width = COMPONENTS[kind]
            offset = indices.get("byteOffset", 0)
            need(offset >= 0 and offset + n * width <= len(data), "Sparse indices exceed view")
            ids = struct.unpack_from("<" + form * n, data, offset)
            need(all(0 <= v < count for v in ids) and all(x < y for x, y in zip(ids, ids[1:])),
                 "Sparse indices are not ordered unique in-range values")
            svalues = sparse["values"]
            replacements = unpack(svalues["bufferView"], svalues.get("byteOffset", 0), n, False)
            for i, row in zip(ids, replacements):
                values[i] = row
        need(all(math.isfinite(v) for row in values for v in row), f"accessor[{index}] contains NaN/Inf")
        if normalized and a.get("normalized") and component != 5126:
            if component in (5120, 5122):
                maximum = 127 if component == 5120 else 32767
                values = [tuple(max(v / maximum, -1.0) for v in row) for row in values]
            else:
                maximum = {5121: 255, 5123: 65535, 5125: 4294967295}[component]
                values = [tuple(v / maximum for v in row) for row in values]
        self.cache[key] = values
        return values


def inspect(path):
    row = {"path": relative(path), "bytes": path.stat().st_size,
           "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
           "status": "PASS", "errors": [], "warnings": []}
    try:
        glb = GLB(path)
        d = glb.doc
        for index in range(len(d.get("bufferViews", []))):
            glb.view(index)
        for index, accessor in enumerate(d.get("accessors", [])):
            values = glb.accessor(index)
            for key, function in (("min", min), ("max", max)):
                if key not in accessor:
                    continue
                declared = accessor[key]
                need(len(declared) == len(values[0]) and all(math.isfinite(v) for v in declared),
                     f"accessor[{index}] invalid declared {key}")
                actual = [function(v[k] for v in values) for k in range(len(values[0]))]
                need(all(abs(a - b) <= max(1e-5, abs(a) * 1e-5) for a, b in zip(actual, declared)),
                     f"accessor[{index}] declared {key} does not match decoded values")

        nodes = d.get("nodes", [])
        parents = {}
        for i, node in enumerate(nodes):
            for key, length in (("translation", 3), ("rotation", 4), ("scale", 3), ("matrix", 16)):
                if key in node:
                    need(len(node[key]) == length and all(math.isfinite(v) for v in node[key]),
                         f"node[{i}] has invalid {key}")
            if "rotation" in node:
                need(abs(sum(v * v for v in node["rotation"]) - 1) < .003,
                     f"node[{i}] rotation quaternion is not normalized")
            need(not ("matrix" in node and any(k in node for k in ("translation", "rotation", "scale"))),
                 f"node[{i}] combines matrix and TRS")
            for child in node.get("children", []):
                glb.entry("nodes", child)
                need(child not in parents, f"node[{child}] has multiple parents")
                parents[child] = i
            if "mesh" in node:
                glb.entry("meshes", node["mesh"])
            if "skin" in node:
                glb.entry("skins", node["skin"])
        for node in range(len(nodes)):
            seen, current = set(), node
            while current in parents:
                need(current not in seen, f"Cycle in node hierarchy at node[{current}]")
                seen.add(current)
                current = parents[current]
        for scene in d.get("scenes", []):
            for node in scene.get("nodes", []):
                glb.entry("nodes", node)
                need(node not in parents, "Scene root is also a child node")
        if "scene" in d:
            glb.entry("scenes", d["scene"])

        materials = d.get("materials", [])
        for i, material in enumerate(materials):
            pbr = material.get("pbrMetallicRoughness", {})
            for key in ("metallicFactor", "roughnessFactor"):
                if key in pbr:
                    need(math.isfinite(pbr[key]) and 0 <= pbr[key] <= 1,
                         f"material[{i}] invalid {key}")
            if "baseColorFactor" in pbr:
                need(len(pbr["baseColorFactor"]) == 4 and
                     all(math.isfinite(v) and 0 <= v <= 1 for v in pbr["baseColorFactor"]),
                     f"material[{i}] invalid baseColorFactor")
            for owner, key in ((pbr, "baseColorTexture"), (pbr, "metallicRoughnessTexture"),
                               (material, "normalTexture"), (material, "occlusionTexture"),
                               (material, "emissiveTexture")):
                if key in owner:
                    glb.entry("textures", owner[key]["index"])
        for i, texture in enumerate(d.get("textures", [])):
            if "source" in texture:
                glb.entry("images", texture["source"])
            if "sampler" in texture:
                glb.entry("samplers", texture["sampler"])
        for i, image in enumerate(d.get("images", [])):
            if "bufferView" in image:
                data, _ = glb.view(image["bufferView"])
                need(bool(data), f"image[{i}] empty embedded image")
                need(image.get("mimeType") in ("image/png", "image/jpeg", "image/webp", "image/ktx2"),
                     f"image[{i}] missing/unsupported embedded MIME type")
            elif "uri" in image:
                if not image["uri"].startswith("data:"):
                    glb.external(image["uri"])
            else:
                raise InvalidAsset(f"image[{i}] has no data")

        mesh_triangles, all_positions, used_materials = [], [], set()
        vertices, primitives = 0, 0
        for mi, mesh in enumerate(d.get("meshes", [])):
            triangles = 0
            need(bool(mesh.get("primitives")), f"mesh[{mi}] has no primitives")
            for pi, primitive in enumerate(mesh["primitives"]):
                primitives += 1
                a = primitive.get("attributes", {})
                need("POSITION" in a, f"mesh[{mi}] primitive[{pi}] has no positions")
                pa = glb.entry("accessors", a["POSITION"])
                need(pa["type"] == "VEC3" and pa["componentType"] == 5126,
                     f"mesh[{mi}] POSITION must be float VEC3")
                need("min" in pa and "max" in pa, f"mesh[{mi}] POSITION missing bounds")
                points = glb.accessor(a["POSITION"])
                all_positions.extend(points)
                vertices += len(points)
                for semantic, acc in a.items():
                    need(len(glb.accessor(acc)) == len(points),
                         f"mesh[{mi}] attribute {semantic} count differs from POSITION")
                if "indices" in primitive:
                    ia = glb.entry("accessors", primitive["indices"])
                    need(ia["type"] == "SCALAR" and ia["componentType"] in (5121, 5123, 5125),
                         f"mesh[{mi}] invalid index accessor type")
                    ids = [x[0] for x in glb.accessor(primitive["indices"])]
                else:
                    ids = list(range(len(points)))
                need(all(0 <= x < len(points) for x in ids), f"mesh[{mi}] index exceeds vertex count")
                mode = primitive.get("mode", 4)
                need(mode in range(7), f"mesh[{mi}] invalid primitive mode")
                if mode == 4:
                    need(len(ids) % 3 == 0, f"mesh[{mi}] triangle index count not divisible by three")
                    triangles += len(ids) // 3
                elif mode in (5, 6):
                    triangles += max(0, len(ids) - 2)
                else:
                    row["warnings"].append(f"mesh[{mi}] includes non-triangle mode {mode}")
                if "material" in primitive:
                    glb.entry("materials", primitive["material"])
                    used_materials.add(primitive["material"])
            mesh_triangles.append(triangles)

        skin_errors, influences = 0, 0
        for si, skin in enumerate(d.get("skins", [])):
            joints = skin.get("joints", [])
            need(joints and len(joints) == len(set(joints)), f"skin[{si}] has empty/duplicate joints")
            for joint in joints:
                glb.entry("nodes", joint)
            if "skeleton" in skin:
                glb.entry("nodes", skin["skeleton"])
            if "inverseBindMatrices" in skin:
                ac = glb.entry("accessors", skin["inverseBindMatrices"])
                need(ac["type"] == "MAT4" and ac["componentType"] == 5126 and ac["count"] >= len(joints),
                     f"skin[{si}] inverse-bind matrices do not cover joints")
        for ni, node in enumerate(nodes):
            if "skin" not in node or "mesh" not in node:
                continue
            skin = d["skins"][node["skin"]]
            for primitive in d["meshes"][node["mesh"]]["primitives"]:
                a = primitive["attributes"]
                need("JOINTS_0" in a and "WEIGHTS_0" in a, f"skinned node[{ni}] missing joint attributes")
                sets = [suffix for suffix in (0, 1) if f"JOINTS_{suffix}" in a or f"WEIGHTS_{suffix}" in a]
                decoded = []
                for suffix in sets:
                    jk, wk = f"JOINTS_{suffix}", f"WEIGHTS_{suffix}"
                    need(jk in a and wk in a, f"skinned node[{ni}] incomplete weight set")
                    ja, wa = glb.entry("accessors", a[jk]), glb.entry("accessors", a[wk])
                    need(ja["type"] == "VEC4" and ja["componentType"] in (5121, 5123),
                         f"skinned node[{ni}] invalid JOINTS type")
                    need(wa["type"] == "VEC4" and (wa["componentType"] == 5126 or
                         (wa["componentType"] in (5121, 5123) and wa.get("normalized"))),
                         f"skinned node[{ni}] invalid WEIGHTS type")
                    decoded.append((glb.accessor(a[jk]), glb.accessor(a[wk], True)))
                for vertex in range(len(decoded[0][0])):
                    total = 0.0
                    for joints, weights in decoded:
                        for joint, weight in zip(joints[vertex], weights[vertex]):
                            need(0 <= joint < len(skin["joints"]), f"node[{ni}] vertex joint index out of range")
                            need(0 <= weight <= 1.00001, f"node[{ni}] weight outside [0,1]")
                            total += weight
                            influences += weight > 0
                    skin_errors += abs(total - 1) > .003
        need(skin_errors == 0, f"{skin_errors} skinned vertices have weights not summing to one")

        animation_names, clip_metrics, channel_count = [], [], 0
        for ai, animation in enumerate(d.get("animations", [])):
            animation_names.append(animation.get("name", f"unnamed_{ai}"))
            clip_start, clip_end, moving_channels = math.inf, -math.inf, 0
            samplers = animation.get("samplers", [])
            need(bool(animation.get("channels")), f"animation[{ai}] has no channels")
            for channel in animation["channels"]:
                channel_count += 1
                sampler_index = channel.get("sampler")
                need(isinstance(sampler_index, int) and 0 <= sampler_index < len(samplers),
                     f"animation[{ai}] invalid sampler reference")
                sampler = samplers[sampler_index]
                ia = glb.entry("accessors", sampler["input"])
                need(ia["type"] == "SCALAR" and ia["componentType"] == 5126,
                     f"animation[{ai}] time input is not float SCALAR")
                times = [x[0] for x in glb.accessor(sampler["input"])]
                need(times[0] >= 0 and all(x < y for x, y in zip(times, times[1:])),
                     f"animation[{ai}] key times not strictly increasing nonnegative")
                clip_start, clip_end = min(clip_start, times[0]), max(clip_end, times[-1])
                interpolation = sampler.get("interpolation", "LINEAR")
                need(interpolation in ("LINEAR", "STEP", "CUBICSPLINE"), "Invalid animation interpolation")
                output = glb.accessor(sampler["output"])
                factor = 3 if interpolation == "CUBICSPLINE" else 1
                keys = output[1::3] if factor == 3 else output
                moving_channels += any(any(abs(value - start) > 1e-6 for value, start in zip(key, keys[0]))
                                       for key in keys[1:])
                target = channel.get("target", {})
                glb.entry("nodes", target.get("node"))
                target_path = target.get("path")
                need(target_path in ("translation", "rotation", "scale", "weights"), "Invalid animation target path")
                if target_path != "weights":
                    need(len(output) == len(times) * factor, f"animation[{ai}] output/key count mismatch")
                    need(len(output[0]) == (4 if target_path == "rotation" else 3),
                         f"animation[{ai}] output dimensions mismatch")
                if target_path == "rotation":
                    rotations = output[1::3] if factor == 3 else output
                    need(all(abs(sum(v * v for v in q) - 1) < .004 for q in rotations),
                         f"animation[{ai}] rotation keys are not normalized")
            clip_metrics.append({"name": animation_names[-1], "start_seconds": clip_start,
                                 "end_seconds": clip_end, "duration_seconds": clip_end - clip_start,
                                 "moving_channels": moving_channels})
            if moving_channels == 0:
                row["warnings"].append(f"Animation {animation_names[-1]} contains no varying transform keys")

        def scene_triangles(index, visiting):
            need(index not in visiting, "Scene node cycle")
            node = nodes[index]
            return (mesh_triangles[node["mesh"]] if "mesh" in node else 0) + sum(
                scene_triangles(child, visiting | {index}) for child in node.get("children", []))
        scenes = d.get("scenes", [])
        default_scene = d.get("scene", 0)
        rendered_triangles = (sum(scene_triangles(i, set()) for i in scenes[default_scene].get("nodes", []))
                              if scenes else sum(mesh_triangles))
        row.update(meshes=len(mesh_triangles), primitives=primitives, vertices=vertices,
                   triangles=sum(mesh_triangles), default_scene_triangles=rendered_triangles,
                   materials_declared=len(materials), materials_used=len(used_materials),
                   images=len(d.get("images", [])), skins=len(d.get("skins", [])),
                   joints_per_skin=[len(s["joints"]) for s in d.get("skins", [])],
                   animations=animation_names, animation_metrics=clip_metrics, animation_channels=channel_count,
                   positive_skin_influences=influences,
                   local_position_bounds={"min": [min(p[k] for p in all_positions) for k in range(3)],
                                          "max": [max(p[k] for p in all_positions) for k in range(3)]}
                   if all_positions else None)
        if len(used_materials) > 8:
            row["warnings"].append("More than eight material slots; draw-call cost needs engine review (not an authored hard cap)")
        if d.get("extensionsRequired"):
            row["warnings"].append("Required glTF extensions need importer review: " + ", ".join(d["extensionsRequired"]))
        identity = identified_role(path)
        if identity:
            faction, role, lod = identity
            budget = BUDGETS["officer" if role in OFFICERS else "soldier"][lod]
            row.update(faction=faction, role=role, lod=lod, triangle_budget=budget)
            need(rendered_triangles <= budget, f"LOD{lod} triangles {rendered_triangles} exceed budget {budget}")
            need(row["skins"] > 0 and row["positive_skin_influences"] > 0, "Character has no standard skinned geometry")
            names = {token for name in animation_names for token in re.split(r"[^a-z0-9]+", name.lower())}
            missing = [name for name in ANIMATIONS if name not in names]
            need(not missing, "Missing required animations: " + ", ".join(missing))
            need(row["materials_used"] > 0, "Character has no assigned glTF material")
    except (InvalidAsset, ValueError, KeyError, IndexError, TypeError, OSError, struct.error) as exc:
        row["status"] = "FAIL"
        row["errors"].append(str(exc))
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--asset-root", type=Path, default=REPO / "assets/river_gate/art_v1")
    parser.add_argument("--report-root", type=Path, default=REPO / "docs/art/river-gate-20261113")
    args = parser.parse_args()
    root, report_root = args.asset_root.resolve(), args.report_root.resolve()
    paths = sorted(root.rglob("*.glb")) if root.exists() else []
    rows = [inspect(path) for path in paths]
    inventory, duplicate = {}, []
    for path, row in zip(paths, rows):
        identity = identified_role(path)
        if identity:
            key = "%s/%s/lod%d" % identity
            if key in inventory:
                duplicate.append(key)
            inventory[key] = row["path"]
    expected = [f"{faction}/{role}/lod{lod}" for faction in FACTIONS for role in ROLES for lod in range(3)]
    missing = [key for key in expected if key not in inventory]
    environment = [row for path, row in zip(paths, rows) if identified_role(path) is None]
    errors = []
    if missing:
        errors.append(f"Missing {len(missing)}/{len(expected)} required character/LOD assets")
    if duplicate:
        errors.append("Duplicate character/LOD identities: " + ", ".join(duplicate))
    if not environment:
        errors.append("No environment GLB delivered")
    if any(row["status"] == "FAIL" for row in rows):
        errors.append("One or more delivered GLBs failed structural or character-contract checks")
    try:
        head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True,
                                       stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        head = None
    report = {"schema": "luanshi.art-validation.v1", "generated_at_utc": datetime.now(timezone.utc).isoformat(),
              "source_head_before_validation": head, "asset_root": relative(root),
              "status": "FAIL" if errors else "PASS", "errors": errors,
              "required_character_lods": len(expected), "delivered_character_lods": len(inventory),
              "environment_glbs": len(environment), "missing_character_lods": missing,
              "duplicate_character_lods": duplicate, "asset_count": len(rows),
              "total_bytes": sum(row["bytes"] for row in rows),
              "validation_scope": ["GLB framing, buffer/accessor ranges, finite decoded values and declared bounds",
                                   "Primitive indices, node hierarchy, skin joints and normalized weights",
                                   "Animation channels/key times, required clip inventory and LOD triangle limits",
                                   "Material references and locally resolvable texture dependencies"],
              "not_verified": ["Visual quality and animation motion/hand contact", "Godot import and gameplay integration",
                               "Combat events and hit windows", "M5 performance or macOS runtime"],
              "assets": rows}
    report_root.mkdir(parents=True, exist_ok=True)
    target = report_root / "validation.json"
    temp = target.with_suffix(".json.tmp")
    temp.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(target)
    lines = ["# 河关全套资产：静态验证", "", f"**结果：{report['status']}**", "",
             f"生成时间（UTC）：`{report['generated_at_utc']}`。仅检查当前文件真实字节；不读取清单宣称的完成状态。", "",
             f"角色/LOD：**{len(inventory)} / {len(expected)}**；环境 GLB：**{len(environment)}**；"
             f"所有 GLB：**{len(rows)}**；总大小：**{report['total_bytes']:,} bytes**。", "",
             "## 检查范围", "",
             "检查 GLB 头与缓冲区、访问器偏移与边界、索引、NaN/Inf、声明包围范围、节点引用与循环、"
             "标准蒙皮与权重、动画键时序和必需动作、LOD 面数，以及材质/贴图引用。", "",
             "**此结果不代表画质合格、动作合理、已接入战役、实测帧率或真实 M5 验收。** "
             "这些项目须使用独立的导入与实际画面证据。", "",
             "普通兵预算为 LOD0/1/2 ≤ 14,000 / 3,500 / 900 三角面；"
             "captain、vanguard、challenger、commander 为 ≤ 22,000 / 6,000 / 1,400。"
             "预算按 GLB 默认场景中的实际网格实例总数计；材质超过 8 个仅提示检查绘制成本。", "",
             "必需动作：`" + " / ".join(ANIMATIONS) + "`。", ""]
    if errors:
        lines += ["## 未通过项", ""] + ["- " + error for error in errors] + [""]
    lines += ["## 已交付文件", "", "| 文件 | 结果 | 默认场景三角面 | 材质 | 骨架/动作 |", "|---|---|---:|---:|---|"]
    for row in rows:
        lines.append(f"| `{row['path']}` | {row['status']} | {row.get('default_scene_triangles', '—')} | "
                     f"{row.get('materials_used', '—')} | {row.get('skins', '—')} / {len(row.get('animations', []))} |")
    if not rows:
        lines += ["| 尚无 GLB | FAIL | — | — | — |"]
    problems = [row for row in rows if row["errors"] or row["warnings"]]
    if problems:
        lines += ["", "## 文件问题与提示", ""]
        for row in problems:
            for error in row["errors"]:
                lines.append(f"- **FAIL** `{row['path']}`：{error}")
            for warning in row["warnings"]:
                lines.append(f"- 提示 `{row['path']}`：{warning}")
    if missing:
        lines += ["", "## 尚缺角色/LOD", ""] + [f"- `{key}`" for key in missing]
    lines += ["", "## 重跑", "", "```bash", "python tools/art/river_gate/validate_assets.py", "```", "",
              "完整逐文件 SHA-256、结构数据和未验收项见同目录 `validation.json`。", ""]
    (report_root / "VALIDATION.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"status": report["status"], "assets": len(rows), "character_lods": len(inventory),
                      "expected_character_lods": len(expected), "environment_glbs": len(environment),
                      "failed_glbs": [r["path"] for r in rows if r["status"] == "FAIL"],
                      "errors": errors, "report": relative(target)}, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
