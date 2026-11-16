"""Pure CPU reference for the bounded 27B projective-texture experiment.

This verifies mapping mathematics, not scene reconstruction or art quality.
No third-party dependencies, files, engine, network, or production imports.
"""
from math import isfinite


def capture_uv(clip):
    """Godot GL-compatible clip coordinates to top-left image coordinates.

    The caller must exclude points outside/behind the capture frustum. A single
    image has no information there; this helper never invents hidden surfaces.
    """
    if len(clip) != 4 or not all(isfinite(x) for x in clip) or clip[3] <= 0:
        raise ValueError("finite clip vector with positive w required")
    return (clip[0] / clip[3] * 0.5 + 0.5,
            clip[1] / clip[3] * -0.5 + 0.5)


def perspective_interpolate(values, screen_barycentric, current_clip_w):
    """Reference raster varying interpolation under the CURRENT view.

    Pass capture clip vec4 values as varyings, not already-divided source UVs.
    After interpolation, divide source xy by source w via capture_uv(). This
    retains the source camera while the current camera may move independently.
    """
    if len(values) != 3 or len(screen_barycentric) != 3 or len(current_clip_w) != 3:
        raise ValueError("one triangle required")
    width = len(values[0])
    if width == 0 or any(len(v) != width for v in values):
        raise ValueError("equal nonempty varying vectors required")
    if any(not isfinite(w) or w <= 0 for w in current_clip_w):
        raise ValueError("positive finite current-view w required")
    if any(not isfinite(x) or x < 0 for x in screen_barycentric):
        raise ValueError("inside-triangle barycentric coordinates required")
    if abs(sum(screen_barycentric) - 1.0) > 1e-9:
        raise ValueError("barycentric coordinates must sum to one")
    weights = [b / w for b, w in zip(screen_barycentric, current_clip_w)]
    denominator = sum(weights)
    return tuple(sum(weight * value[k] for weight, value in zip(weights, values))
                 / denominator for k in range(width))


def transform(matrix, vector):
    if len(matrix) != 4 or len(vector) != 4 or any(len(row) != 4 for row in matrix):
        raise ValueError("4x4 row-major matrix and vec4 required")
    return tuple(sum(a * b for a, b in zip(row, vector)) for row in matrix)
