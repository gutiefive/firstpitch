# Verification record

Engine: Godot **4.6.3.stable.official.7d41c59c4**, Linux cloud environment.

## Executed

- Headless editor import and script registration. Initial type-inference error in dismount position fixed; later import and scene launch passed. Sandboxed editor socket warnings are infrastructure restrictions, not script parse failures; the final editor check runs outside that socket restriction.
- Headless main scene launch for 180 frames.
- `test_mowing.gd`: 14 assertions covering coordinate mapping, valid grass, dirt/mound and warning-track exclusion, diagonal sweep, broad deck footprint, outside-footprint preservation, unique overlap accounting, percentage and mower occupancy/exit guards.
- `test_gameplay.gd`: physics-loop integration covering grounded player/mower, entering, accelerating, real cutting while driving, moving exit guard, stopping/exiting, session persistence, safe grounded exit, reverse steering, and stopping at a shed wall (13 assertions).
- `test_visual.gd`: graphical scripted main-scene run under Xorg dummy and Mesa llvmpipe OpenGL Compatibility. Inspected captures of spawn, a turning mowing pass, and the stadium overview. Cut paths and HUD progression were visible. The final scripted pass cut 839 unique cells (1.37%). Final captures are in `docs/screenshots/`. Field-sector backface and depth-flicker issues found during visual inspection were corrected using two-sided annular warning-track geometry, removing redundant underlying field layers, and increasing the camera near plane. The overview capture shows the corrected field before mowing; the driving capture shows the scripted cut. The virtual display reports unsupported V-Sync; this does not affect the accounting checks.

## Not established

This was scripted graphical validation, not a human keyboard/mouse playtest. Native Windows execution, Forward+ graphics on a hardware GPU, sustained frame-rate targets, and a full 100% field mow were not tested. No Windows export template or executable is included.

## Manual acceptance checklist

1. Import project.godot in Godot 4.6.3 or newer stable 4.x and press F5.
2. Walk, sprint, jump, orbit and zoom near the shed. Check that camera obstruction behaves comfortably.
3. Approach mower, press E, drive forward, reverse, turn and brake. Confirm that E refuses a moving exit.
4. Cross fair grass horizontally and diagonally. Check visible deck-width stripes, persistent overlap, and increasing percentage.
5. Drive over dirt and warning track. Percentage must remain unchanged.
6. Stop, exit, walk around the cut path, re-enter and continue. Try exiting near obstacles.
7. Check Forward+ lighting and frame rate on the target Windows GPU. Tune visuals and steering before adding M4.
