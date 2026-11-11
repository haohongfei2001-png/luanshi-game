# Genuine World7 migration fixtures

Captured using Godot 4.6.3 from the public source commit
`049fecc66bd4da84ca533cb4dbd403d4bae88733` in a separate source archive,
not by deleting new World8 fields. `tools/capture_world7_fixtures.gd` records
an existing youth at camp and an actual running youth battle at 0.03125 seconds.
The old source's campaign store produced these untouched save bytes.

World8 adds empty physical transport records. Active old battles retain their
historical immediate signal model until settlement; new encounters use local
signals. Existing youth origin, named soldiers, time, condition, random state,
resources and receipts are not reinitialized. These source fixtures are never
rewritten during load tests.
