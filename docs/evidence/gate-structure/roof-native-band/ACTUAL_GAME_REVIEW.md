# Actual Godot roof isolation review

Run 43633060845, source e7ae92de469b3a263a110646ca55f4acdc4e71b3, artifact 14128673474. Four actual 2560×1440, internal-scale-1 frames share tick 135 and snapshot SHA71262f36c7bfe3cffed4e80e1ca4b498f87f7bc796db92aabd406bbd47056f44. Original model SHA9590b664efb4316d1374c79f517d4f52e6b1a17d5a04a5eaa220fd4a021f4692; native-band experiment SHA5bd4a741c9bf5bc49c6a49764b186e5b9950ab168ce25456d562c6d6f6e4a865.

Personally inspected original-lit and native-band-lit: the previous broad black brush-like streaks and interrupted central tile rows substantially disappear with native tile-period reconstruction. Uniform roof channels and native hip corners remain. Also personally inspected native-band normal diagnostic: regular continuous normal bands now match the tile geometry. This supports a real geometry/normal phase correction, not exposure or disabling shadows. The material has no image texture, and prior shadow-off baseline still had the defect. Do not assert this eliminates every shading issue.

This is a close diagnostic camera, NOT the normal gameplay visual acceptance. Overall architecture remains ART_FAIL: untextured giant masonry, incomplete arch-shoulder-to-gallery load path and detached upper timber floor, unfinished unified stone/wood materials. The native roof band is an opt-in input for the next complete gate assembly, not a standalone approved release.

Failure retained: initial run43631852727 produced no graphics because editable .blend under assets was scanned by Godot without configured importer and interrupted other asset imports. Source directories now have .gdignore; explicit import-log errors are fatal. The successful rerun did not suppress those failures. Actual logs scanned without SCRIPT/SHADER/ERROR.
