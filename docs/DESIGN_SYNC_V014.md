# v0.14 design synchronization provenance

Read-only canonical main: `b32de2c1d6c08297d4550b36c02ea4ba6b5bb625`.
Verified on 2026-11-11 UTC via the connected GitHub read API.
No remote reference or file was changed. Local base: `e64a398a4b7c0f01abfac50decd516ea57c0ba3a`.

## Verified upstream blobs

- `docs/CENTURY_WAR_ERA_CAMPAIGN_V0_1.md`: `e22c29766e4f339024c3785147b2506c302db9a4`
- `docs/PRODUCT_DECISIONS.md`: `9f1fe065c82022abd5252787bf24c788ca8c9ddf`
- `docs/SIMULATION_CONTRACTS.md`: `5dfd3cd2278aa45f4f810ab25e84341608b6b5b1`
- `docs/DOT_HANDOFF_FINAL.md`: `eaccfdd45540b11c24d810f81f7fea1bbe27aab9`
- `docs/FINAL_GAME_DESIGN_SPEC.md`: `11f77e406fc2d13710f15326d5b2e8a3bc6149f4`
- `docs/ACCEPTANCE_MATRIX.md`: `4442ba3c2809bfb330fe33de296b1433d4efc649`
- `docs/FINAL_VISION_ACCEPTANCE.md`: `207a488a39406c20c2d052c07163dcacec8d6401`
- `docs/NARRATIVE_ART_DIRECTION.md`: `35db168943eddcc551b2a1da607901523418d2f7`
- `docs/DELIVERY_PLAN.md`: `a20a3b0b0935edcb8b86bca117f834dc048379b0`
- `docs/PROJECT_STATUS.md`: `6bc1013993e86354e573a434117493f1750f8df1`

All fetched UTF-8 bytes were checked using Git blob SHA1 framing before integration.
Canonical design bytes are exact except ACCEPTANCE_MATRIX retains its existing
World8 implementation-evidence appendix. Upstream PROJECT_STATUS was read as a
historical design handoff, not copied over the newer local runtime/evidence record.
README keeps all existing launch instructions and adds only a design link.

## Extension boundary, not an empty framework

Future era pressure, political institutions/capital logistics, technology domains,
foreign polities and crisis history require their own typed, explicitly migrated
save version and causal event validation. No empty world fields are added now.
The existing seconds clock, independent inventories, bounded lives, immutable battle
profiles and per-battle snapshots remain authoritative. E0–E7 reachability is a future
acceptance target, not a claim of implementation. Core story remains owner-authored.
