# Genuine World8 appraisal-entry fixture

`world8-camp-before-appraisal.save.json` was produced by the unmodified source
`78c7853` in an isolated archive, with official Godot 4.6.3. This is a local
source reference, not a claim that this commit is published. Its authoritative
WorldSim, YouthCareer, CourierOrders, CampaignStore, CampaignSchema, value codec
and combat driver are unchanged from `72e08db`, whose tree is represented by
public source [`95a33fd`](https://github.com/haohongfei2001-png/luanshi-game/commit/95a33fd4e9ee65f54c40b0dce1b9964212bd7ddd).
It was not produced by the new appraisal implementation and has no appraisal events.

SHA256: `1599220e8efdde1d0c0a5f5cc17376473c4b38a0bebbf7ed7b9eb7865ead0da0`.

Synthetic seed 184; forced/homeland youth; arrange courier, march, wait one hour,
reply comply; genuine first battle victory using the existing public-input
`youth_combat_driver`; return to camp; keep evidence; accept appointment.
Encoded by the original `CampaignStore.encode_campaign` after its own validation.
No personal data or external service credentials. The new reader must preserve
all exact world fields, values, provenance, resources, clock and battle identities.

Reproduce using the original public source in a separate checkout:

1. Archive or check out `95a33fd4e9ee65f54c40b0dce1b9964212bd7ddd` without modifying it.
2. Import that checkout with official Godot 4.6.3 (`--headless --editor --import`).
3. Run `godot --headless --path <original-checkout> --script <absolute-path-to-generate_world8_camp.gd> -- <absolute-output-file>`.
4. Compare the SHA256 above. The generator is stored beside this fixture and uses
   the original checkout's `res://` modules, never the new appraisal modules.

The generated state is deterministic and contains a synthetic campaign only.
