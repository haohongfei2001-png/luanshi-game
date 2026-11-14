"""Measure original authored horse contacts before changing its runtime pose."""
from pathlib import Path
import json
import sys
import numpy as np
from bake_native_remount import ANIMATIONS, MESHES, rig, tracks, pose, fitted
from import_garrison_issues import source_file, read_dae

cache = Path(sys.argv[1])
cache.mkdir(parents=True, exist_ok=True)
body = source_file(cache, *MESHES[0])
names, inverse, nodes = rig(body)
initial = pose(nodes, {}, 0.)
points, uv, faces, seams, influences, _ = read_dae(body, need_bind_positions=False)
weights = np.zeros((len(points), len(names)))
for index, entries in enumerate(influences):
    for name, value in entries:
        weights[index, names.index(name)] += value
weights /= np.maximum(weights.sum(axis=1)[:, None], 1.e-10)
rest = fitted(points, 0)
homogeneous = np.column_stack((points, np.ones(len(points))))
samples = 80
reports = []
for clip_name, path, signature in ANIMATIONS:
    source = source_file(cache, path, signature)
    source_names, source_inverse, source_nodes = rig(source)
    animation = tracks(source)
    bind_differences = {
        name: float(np.max(np.abs(source_nodes[name][1] - matrix)))
        for name, (parent, matrix) in nodes.items()
        if name in source_nodes
    }
    for registration in ("original_root", "saddle_translation", "saddle_full_frame"):
        frames = []
        saddle_path = []
        for frame in range(samples + 1):
            world = pose(nodes, animation, frame / samples)
            registration_matrix = np.eye(4)
            if registration == "saddle_translation":
                registration_matrix[:3, 3] = initial["prop_saddle"][:3, 3] - world["prop_saddle"][:3, 3]
            elif registration == "saddle_full_frame":
                registration_matrix = initial["prop_saddle"] @ np.linalg.inv(world["prop_saddle"])
            transform = np.asarray([registration_matrix @ world[name] @ inverse[index]
                                    for index, name in enumerate(names)])
            native = np.einsum("bij,pj,pb->pi", transform, homogeneous, weights)[:, :3]
            frames.append(fitted(native, 0))
            saddle = registration_matrix @ world["prop_saddle"]
            saddle_path.append(fitted(saddle[:3, 3][None, :], 0)[0].tolist())
        frames = np.asarray(frames)
        hooves = {}
        for name in ("Horse_Hoof_R", "Horse_Hoof_L", "Horse_Hoof_back_R", "Horse_Hoof_back_L"):
            selected = np.flatnonzero((weights[:, names.index(name)] > .35) & (rest[:, 1] < .11))
            if len(selected) < 3:
                raise ValueError((name, len(selected)))
            moving = frames[:, selected]
            sole = np.min(moving[:, :, 1], axis=1)
            # Track a fixed low central point, a toe and a heel separately.
            sole_indices = selected[rest[selected, 1] < rest[selected, 1].min() + .035]
            middle = sole_indices[np.argmin(np.linalg.norm(rest[sole_indices] - rest[sole_indices].mean(axis=0), axis=1))]
            toe = sole_indices[np.argmax(rest[sole_indices, 2])]
            heel = sole_indices[np.argmin(rest[sole_indices, 2])]
            track = frames[:, [middle, toe, heel]]
            support = (sole[:-1] < .042) & (sole[1:] < .042)
            step = np.diff(track[:, 0, 2]) * samples
            planted = support & (step < -.05)
            values = -step[planted]
            hooves[name] = {
                "vertices": len(selected), "fixed_points": [int(middle), int(toe), int(heel)],
                "minimum_y": float(sole.min()), "maximum_y": float(sole.max()),
                "support_fraction": float(support.mean()),
                "negative_support_samples": int(planted.sum()),
                "metres_per_cycle_median": float(np.median(values)) if len(values) else None,
                "metres_per_cycle_std": float(np.std(values)) if len(values) else None,
                "sole_y": sole.tolist(), "track": track.tolist(),
            }
        row = {"clip": clip_name, "registration": registration,
               "source_bind_max_difference": max(bind_differences.values()),
               "source_bind_differences": {key: value for key, value in bind_differences.items() if value > .001},
               "saddle_path": saddle_path, "hooves": hooves}
        reports.append(row)
        concise = {key: value for key, value in row.items() if key not in ("saddle_path", "hooves")}
        concise["hooves"] = {key: {field: value for field, value in data.items() if field not in ("track", "sole_y")}
                            for key, data in hooves.items()}
        print("AUTHORED_HORSE_CONTACT", json.dumps(concise), flush=True)
out = Path("reports/remount")
out.mkdir(parents=True, exist_ok=True)
(out / "native-contact-audit.json").write_text(json.dumps(reports, indent=2) + "\n")
