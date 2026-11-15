# Private v5 continuation in an existing Linux debug template

This follows the source-process save tests in `EXPERIMENTAL_MAP_V5_RESUME.md`.
The original measurement below used local checkpoint
`86ab3ae0da05abb12aa4dd33b5c391ccc226cddf`. That ID records historical provenance,
not a required public-clone dependency. The current tool defaults to `HEAD`,
immediately resolves it to an exact commit and freezes every dependency against
that revision before packing. An explicit `--frozen-commit` is also supported;
unknown revisions and modified dependencies fail closed. This source checkpoint
contains only code, tests and documentation. It does not change save semantics, enable a UI path, publish a map,
install/build an engine or trigger CI.

## Actual result

A private **2,091,412-byte** PCK boots normally through `res://main.tscn`, an inert
Node, from an empty working directory. The existing native Linux template runs
`--headless --main-pack`; it is **not** passed CLI `--script`.

The template reads the pre-existing512-per-side experimental disk slot generated
by the source test. No saved state is reconstructed from JSON and no replacement
slot is generated. It validates the exact packed HF08 source, rebuilds navigation,
loads the400tick typed checkpoint, then applies20 real continuation inputs.

**60 checks pass,0 failures.** Initial/full per-tick/final typed Save and passive
combat, order, projectile and RNG observations agree with the uninterrupted source
process oracle. Final state: tick420,1057 entities,512+512 ordinary soldiers,
570 attacks, hits[98,178], losses[51,21]. Final typed snapshot SHA256:

`79abb40a2acf1dc82cddd6a78e31b11f342463e16df11fa68c925ae8121aac29`

The experimental slot, legacy quick-save file and campaign sentinel retain their
original hashes. The working directory remains empty. The sentinel proves file
isolation only, not campaign/world settlement integration.

### Measured engine identity, not an inferred release mode

- Godot4.6.3 stable custom build, engine hash
  `35e80b3a8822a9df9be390814b62f44c0a9c69e8`.
- Executable SHA256:
  `16cd16ae2a2f7f5fd9ca18ba9f68a0ef0d043cdfbb3b51df2cec2183def26f5a`.
- `OS.is_debug_build() == true`.
- Features `template`, `template_debug`, `debug`, `linux`, `x86_64`, `single`:
  **true**.
- Features `editor`, `template_release`, `release`, `standalone`, `double`:
  **false**.
- `DisplayServer.get_name() == "headless"`.

This is a **template_debug CPU test**, not release-template, GPU rendering,
production/native visual PCK, M5, Controller UI adoption, art approval or realtime
performance evidence. HF08 art remains ART_FAIL. The observed8.29-second whole
process includes startup/configuration/loading; it is not a frame-rate result.

### Exact resources and negative cases

The pack contains22 frozen GDScript dependencies, the inert probe/scene/config,
the original1,287,052-byte HF08 source manifest and the original typed source
oracle. There is no GLB, texture, skeletal actor, graphical Controller or unrelated
scene. Every dependency is checked against the frozen Git commit before packing.

HF08 source SHA256:
`28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`.
Complete PCK SHA256:
`ec4b0d3de1bc2fb55a4942833a0eb69b81978d528107080d10d989460018d0e4`.

Two independently built missing-resource PCKs also boot through the inert scene:

- Missing `res://test_data/hf08-source.json`: explicit
  `REQUIRED_RESOURCE_MISSING`, status REFUSED, exit2.
- Missing `res://test_data/expected.bin`: explicit
  `REQUIRED_RESOURCE_MISSING`, status REFUSED, exit2.

Neither substitutes legacy terrain or silently continues. All initialization and
refusal checks execute outside GDScript assertions. Any engine/script error or
unexpected exit fails the outer runner. Each pack is capped at4MiB.

## Reproduce locally

The user-authorized source file and evidence directory must already be available
locally. This source-only branch includes no world manifest, PCK, typed save,
trajectory or private test report. Set `$GODOT_EDITOR` and `$GODOT_TEMPLATE` to
compatible executables that are already available locally; this tool does not
install them. No default gameplay or Controller/UI save entry is enabled.
The evidence directory is the previous512 source test output containing
`expected.bin` and its isolated `save5-xdg` tree. Do not publish the source or PCK.

```sh
python3 tools/test_packed_map_save.py \
  --editor "$GODOT_EDITOR" \
  --template "$GODOT_TEMPLATE" \
  --source "$HF08_SOURCE_JSON" \
  --source-evidence "$EXISTING_512_SOURCE_EVIDENCE" \
  --output "$PRIVATE_PACK_EVIDENCE"
```

The editor alone uses `--script` to call PCKPacker. The template uses the ordinary
main-scene route from an empty cwd. The runner records the exact commands, process
IDs, source/dependency/executable/PCK hashes, features and positive/negative
receipts in `summary.json`. No large-asset or new-template fallback is permitted.
