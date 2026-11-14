"""Deterministic axes for authored material projection, not a mesh deformation.
The pinned local/CI FBX import has ~2.2e-6 differences at 45-degree normals.
Within 1e-5 of the maximum use the lowest axis, rather than let float noise
rotate a whole wood-grain UV island by 90 degrees. Distinct normals retain
normal dominant-axis projection. The source UV channel is never changed.
"""
import math

def dominant_axis(values, tolerance=1e-5):
    if len(values)!=3 or tolerance<0 or not math.isfinite(tolerance):
        raise ValueError('Three finite axis values and a nonnegative tolerance required')
    values=tuple(abs(float(x)) for x in values)
    if not all(math.isfinite(x) for x in values) or max(values)==0:
        raise ValueError('A finite nonzero axis vector is required')
    largest=max(values)
    return next(i for i,v in enumerate(values) if largest-v<=tolerance)
