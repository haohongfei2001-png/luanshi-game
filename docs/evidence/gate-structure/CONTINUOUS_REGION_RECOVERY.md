# Continuous region recovery, internal only
Base remote 97742b1a6376e2deb46cf52a426043c041840100 failed before GUI because recorder source was omitted. No new images existed from that run.

This explicit patch was validated in a clean worktree of that exact remote, not a mixed local development base. Added recorder, curator and Python dependency sources. Complete import, entry parse, actual 20v20 tick135 new-region setup, source closure and three Python evidence tests passed. Terrain source frozen from f9461d2da3f4144c27381928d5835764d6fa1fc1. Opt-in LUANSHI_AUTHORED_LANDFORM=1 applies to the whole process; default OFF contract passed.

42 terrain tiles with 42 matching collision shapes replace support rectangles, rectangular water and the 17x24m safe-core patch. Max tested route interpolation error 0.01694m. Three PBR scene roundtrips verified 137214 vertices and full 2048px texture mipmaps/tangents. Woodland is rebuilt against the same Ground, not reused at old heights. No old-terrain before image is claimed equivalent.

Static QHD/UHD use identical simulation state and frozen shader TIME. Size22 is the historical technical fixture, not current owner camera/art acceptance. Current characters and foliage remain internal unaccepted assets. Source-hashed tree/bush recipes support cache verification; successful derivatives are preserved before GUI and bounded at120MiB per artifact group, with byte-exact recovery metadata. The slow Sprite ground bake is no longer run.

Actual GUI images and traversal are NOT_RUN at this commit preparation. CI records their real outcome, missing actions and elapsed time without converting sampling FPS into game performance. No M5 test or art acceptance claimed. Existing gameplay, candidate versions and main are unchanged.

Run 43627524170 stopped at official Blender archive HTTP403 before any new baking/GUI. Published official RWTH mirror fallback retains exact 4.3.2 SHA256 and source ZIP member verification; mirror requests independently returned normal206 XZ header. No artwork or engine version changed. All missing derivative entries remain explicit in the failure recovery manifest.
