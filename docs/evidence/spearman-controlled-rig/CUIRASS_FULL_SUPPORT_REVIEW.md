# Complete cuirass/shoulder support iterations, all art rejected

Whole-layer source preserves the new full sewn sleeves, waist and leg cloth.
New cuirass has a continuous neck/armhole bearing rim, contoured shoulder bridges
and fitted upper lamellae, not only a collection of floating chest rectangles.
All changes are independently editable; no stable cache or Battle code changed.

Actual whole-body raised-arm Blender reviews:
- 5: bearing opening produced an excessively exposed leather bib. Rejected.
- 6: fitted upper coverage removes the bare bib but does not fix shoulder shape.
- 7: old world-axis shoulder projection has no corresponding source sleeve
  surface at some points. Guard rejects it rather than snapping to other body.
- 8: actual source upper-arm frame fitting succeeds in neutral, but arbitrary
  two-bone blending visibly pulls parts away under raised arms. Rejected.
- 9: full original cloth cage binding removes that extra pull, while actual
  coverage still sits too far down the upper arm and exposes the shoulder cap.
  Thus full-cage binding is not visual acceptance or an armor rigidity proof.
- 10: extension toward neck encounters missing source-arm radial intersection.
  Exact guard failure preserved, no fallback or weakened threshold used.

Next need is a genuinely contiguous shoulder/neck pattern with real seam and
support placement, not another microhole/detail pass or parameter search on the
old arch. No new runtime cache is justified by these failed images. Old945b
cache, full163 head and experimental field interface remain unchanged.

Current articulated_cuirass.py reproduces failed10. Historical wrappers in
rejected/ retain7–9. Render outputs remain in character-diagnostics/sintel-guardian/
articulated-cuirass5..10. Failed5/6/8 editable blends were losslessly compressed;
exact streaming decompression SHA verified before removing duplicates, recovery
commands and hashes in own-failed-masters-recovery.json. No original master or
other thread's files were removed.
