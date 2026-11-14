"""Explicit bounded capture scopes; no mode is a performance/art acceptance."""
MODES = ('baseline', 'camera-study', 'gate-context-study', 'destination-study')

def arguments(mode):
    if mode == 'camera-study':
        return ['--camera-study']
    if mode == 'destination-study':
        return ['--destination-study', '--road-section-study', '--author-oracle']
    if mode == 'gate-context-study':
        return ['--gate-context-study', '--road-section-study', '--author-oracle']
    if mode == 'baseline':
        return ['--wall-clock-action', '--traversal-review', '--shadow-diagnostic']
    raise ValueError('Unknown capture mode')

def capture_budget(mode):
    arguments(mode)
    # The verified old scene took 106 seconds with cold shaders and readback.
    # The complete road/gate + 224MB single actor gets a declared 240s bound,
    # not a relaxed FPS or quality gate. All stage/failure logs are preserved.
    return 120 if mode == 'camera-study' else 240
