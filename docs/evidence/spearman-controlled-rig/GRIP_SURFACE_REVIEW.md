# Actual evaluated grip review, rejected

Original grip3 whole evaluated hand has 38,346 surface vertices. 1,372 vertices
penetrate the actual 14mm radius finite shaft by more than 1mm; worst radial
penetration is 13.370mm. Wrist-target accuracy was not a valid grip test.

A bounded original-author finger-control sweep changed driver control scaleY
(not mesh or bone lengths). Uniform .80 with unchanged wrist reduced >1mm
penetrating vertices to 13 and worst penetration to 1.269mm, retaining 447
vertices within 2mm of the shaft. Zero-penetration/zero-contact variants were
rejected immediately. These surface-point metrics are not triangle collision
proof, pressure or natural grip acceptance.

Actual full-body Blender render of .80 was personally reviewed: fingers are
open/clawlike, loosely supporting the shaft rather than naturally enclosing it.
REJECTED. Not merged into rebuild.sh or the active cache source. Need separate
finger joint profiles and thumb opposition using original controls, followed by
full-body visual review and actual motion. No global hand scaling or concealed
contact is acceptable.

Reproduce original metrics with grip_surface_contact.py and bounded alternatives
with grip_control_sweep.py, passing grip-study3/soldier-grip-editable.blend.
Diagnostic image: character-diagnostics/sintel-guardian/grip-curl4/
whole-grip-BLENDER-NOT-GAME.png. Candidate reproduction is spearman_grip_study.py
with only its finger control scaleY .65 changed to .80, on carrier-layered8 source.
This local image is Blender, not Godot, and the local layered8 source predates the
final eye-alpha restoration. Do not identify it as current hosted source geometry.
