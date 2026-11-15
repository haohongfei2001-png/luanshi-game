# HF08 exact historical geometry fixture

This file is the exact approved historical HF08 terrain-query JSON, losslessly XZ-compressed. It is retained for reproducible build, navigation, save and CPU-regression tests. It is **not** a new map or art candidate. HF08's actual whole-game image was rejected; see `docs/DOT_PRODUCTION_V2_RECOVERY_20261115.md` on the recovery branch.

## Exact identity

- File: `hf08-mother-manifest.json.xz`
- XZ bytes: `225624`
- XZ SHA256: `0782f2d260c09d461450922952ab157fc8a0e47a5c05f7aff074a5490a801fee`
- Git blob: `751b585adccb480300078cff3df79204c14bca8c`
- Original JSON bytes: `1287052`
- Original JSON SHA256: `28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`
- Topology SHA256 inside the original: `0b1d24868d11505f3e980a8eb456df7e55035203490b1d1df8384ba5622bd140`

The exact approved payload contains support triangles, solids, portals, deployment/retreat/goals and asset-source URI/hash provenance. It does not contain the complete visual GLB, textures, source assets, movie or an installation package. Source URI entries identify historical inputs; they are not a promise that every referenced asset is publicly retrievable. Do not substitute this geometry for a new map's identity or use it as authorization to publish other data.

## Verify and materialize without overwriting

Run from repository root with Python's standard library:

```bash
python3 - <<'PY'
import hashlib, json, lzma
from pathlib import Path
p = Path('tests/map_runtime/fixtures/hf08-mother-manifest.json.xz')
compressed = p.read_bytes()
assert len(compressed) == 225624
assert hashlib.sha256(compressed).hexdigest() == '0782f2d260c09d461450922952ab157fc8a0e47a5c05f7aff074a5490a801fee'
raw = lzma.decompress(compressed)
assert len(raw) == 1287052
assert hashlib.sha256(raw).hexdigest() == '28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753'
data = json.loads(raw)
assert data['topology_sha256'] == '0b1d24868d11505f3e980a8eb456df7e55035203490b1d1df8384ba5622bd140'
print('PASS exact historical HF08 geometry:', len(data['surfaces']), 'surfaces,', len(data['solids']), 'solids')
# Optional fresh local output. Existing files are never overwritten.
# with Path('hf08-mother-manifest.local.json').open('xb') as out: out.write(raw)
PY
```

No CI workflow, default game change, main/PR67 merge, graphics/performance claim or new art acceptance accompanies this fixture-only checkpoint. The separate opt-in exact-query implementation is public at commit `936849f60f67a57c85f0a832f12736699c97e9c8`; its documented runner accepts a verified raw manifest path. Build/test execution must be reported separately from successful fixture publication.
