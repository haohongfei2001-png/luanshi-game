"""Dependency-free reference for27F same-source-sample plane-depth validation.

This is an original mathematical reference, not image-based reconstruction,
physical material generation, hidden-surface recovery or visual acceptance.
"""
from math import floor, isfinite, sqrt


def _vec(v, count):
    if len(v) != count or not all(isfinite(x) for x in v):
        raise ValueError("finite vector of required size")
    return tuple(v)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def source_sample_center(uv, size=(1672, 941)):
    """Nearest RF texel centre; return None outside the half-open capture."""
    uv = _vec(uv, 2)
    if len(size) != 2 or any(type(x) is not int or x <= 0 for x in size):
        raise ValueError("two positive integer capture dimensions")
    if any(x < 0 or x >= 1 for x in uv):
        return None
    return tuple((floor(x * n) + .5) / n for x, n in zip(uv, size))


def capture_ray(uv, basis_x, basis_y, basis_z, tan_half_fov, aspect):
    """Unnormalised -Z camera ray; its parameter is positive view depth."""
    u, v = _vec(uv, 2)
    x, y, z = (_vec(b, 3) for b in (basis_x, basis_y, basis_z))
    if not all(isfinite(a) and a > 0 for a in (tan_half_fov, aspect)):
        raise ValueError("finite positive projection parameters")
    return tuple(x[i] * (2 * u - 1) * aspect * tan_half_fov
                 + y[i] * (1 - 2 * v) * tan_half_fov - z[i]
                 for i in range(3))


def plane_from_triangle(vertices):
    if len(vertices) != 3:
        raise ValueError("three vertices required")
    a, b, c = (_vec(v, 3) for v in vertices)
    u, v = tuple(b[i] - a[i] for i in range(3)), tuple(c[i] - a[i] for i in range(3))
    n = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
    length = sqrt(dot(n, n))
    if length <= 1e-12:
        raise ValueError("nondegenerate triangle required")
    n = tuple(x / length for x in n)
    return (*n, -dot(n, a))


def plane_depth(origin, ray, plane):
    origin, ray, plane = _vec(origin, 3), _vec(ray, 3), _vec(plane, 4)
    denominator = dot(plane[:3], ray)
    if abs(denominator) <= 1e-8:
        return None
    depth = -(dot(plane[:3], origin) + plane[3]) / denominator
    return depth if depth > 0 else None
