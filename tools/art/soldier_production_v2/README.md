# Production-v2 complete natural character (WIP, not accepted)

Current entry `fit_full_coat.py` reads the complete editable professional recut
coat and official natural MakeHuman adult source. It uses actual posed source
joint landmarks, transfers the entire cloth UV mesh to the natural body, and
transfers all source skin influences by nearest-triangle barycentric weights.
It never modifies either input. New output is an editable `.blend` derivative.

This is **not a finished soldier or a game-tested asset**. First fit had exposed
underarm/torso and was rejected by direct Blender shape inspection. Fit02 tests
corrected torso/sleeve blending. Neither fit is art acceptance. Material baking,
runtime LOD, silhouette refinement, clothing penetration over all actions,
armor treatment, hands/weapon, and new-world Godot evidence remain outstanding.
Do not return to floating barrel chest plate construction. Original source rig,
UV/material detail can be preserved independently while runtime derivatives
are altered to match the owner's complete natural spearman direction.

Rig contract: `MH163`; available clips Idle_Loop, Walk_Loop, Jog_Fwd_Loop,
Sprint_Loop, Hit_Chest, Hit_Head, Death01, Sword_Idle, Sword_Attack. Ordinary
spear is NOT yet among these clips. Runtime worker owns its separate MH163
spear derivative. Target format is shared skinned GLB with complete UV/material
maps and OpenGL +Y tangent normals, not per-pose geometry JSON.

Licenses remain those of sources: Sintel professional coat CC BY 3.0 (see
`../sintel_guard/NOTICE.md`), MakeHuman official core CC0, source garments per
existing source notices. AI approved reference is project-authorized AI work,
not an external CC0 asset. Never publish the rejected conflicting Viking sources.
