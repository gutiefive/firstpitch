# Verification record

Engine: Godot **4.6.3.stable.official.7d41c59c4**, Linux cloud environment.

## Visual milestone: Cedar Grove Ballpark

This pass preserves M1–M3 mechanics and adds a warm teal/cream/gold art direction, a decorative infield island, textured dirt, open dugouts, covered seating, a detailed workshop, local sponsor signs, a larger scoreboard, concourse props, and a surrounding tree line. The mower and character visuals now live separately from their controllers. The player has a procedural walk cycle and the mower shows a seated driver. The HUD is separate from game coordination.

## Executed

- Headless editor import and script registration completed without parse errors. The final import ran outside the sandbox's editor-socket restriction.
- Headless main scene launch for 180 frames passed.
- `test_mowing.gd`: **14 passed assertions**, covering coordinate mapping, valid grass, dirt/mound and warning-track exclusion, diagonal sweep, broad deck footprint, outside-footprint preservation, unique overlap accounting, percentage, occupancy, and exit guards.
- `test_gameplay.gd`: **13 passed assertions**, covering grounded player/mower, entering, accelerating, real cutting while driving, moving exit guard, stopping/exiting, session persistence, safe grounded exit, reverse steering, and stopping at the workshop wall.
- `test_visual.gd`: scripted graphical run under Xorg dummy and Mesa llvmpipe OpenGL Compatibility, with 4× MSAA. Inspected spawn, turning mowing pass, overview, workshop, grandstand, and mower detail captures. The driving pass still cut **839 unique cells (1.37%)**. Grass tufts disappear where the mask is cut, and the HUD uses the same tracked-cell percentage.
- Visual inspection corrected excessive workshop trim, sign readability, dark grass-tuft shading, and the seated arm/leg orientation. The warning track and infield do not require overlapping broad field layers.
- Repeated seat meshes use MultiMesh batches; 28,000 sparse grass tufts share one MultiMesh and the existing state texture. Solid color materials are shared. These are structural performance improvements, not a measured frame-rate guarantee.

The virtual display reports unsupported V-Sync; it does not affect the logic checks. Screenshots in `docs/screenshots/` are actual software-rendered game captures, not concept art. `test_visual.gd` can regenerate the six Linux captures in `/tmp/firstpitch-*.png`.

## M4: First infield drag tool

The first M4 slice adds a visible service rack, Q equipment swapping on foot beside a stopped tractor near the bay, R lift/lower controls, a 4 m/s working speed, and a mask-driven dirt-preparation objective. Mowing and dirt progress persist independently within the running session. The condition material is bound to the existing diamond and home-area meshes, avoiding overlapping dirt geometry.

- Existing mowing and tractor suites: **27 assertions passed** after M4 integration.
- `test_infield.gd`: **16 assertions passed** for coordinate mapping, workable basepaths, protected lawn/mound/bases/plate/track, oriented rectangular width and depth, diagonal sweeps, overlap-safe accounting, non-dirt exclusion, and percentage math.
- `test_drag_gameplay.gd`: **22 assertions passed** for Q/R key handling, bay-only tool swapping, rack/deck state, objective selection, raised/moving guards, actual forward preparation, working-speed limit, task separation on untouched grass, raising while moving, reverse travel over untouched dirt, exiting, persistence, and returning to mowing.
- Total: **65 passing assertions**, with no failed or skipped assertions.
- `test_drag_visual.gd`: scripted graphical comparison of the same basepath before and after a controlled forward pass. The pass prepared **807 cells (6.40%)** while mowing remained **0.00%**. Inspected the tool bay and lowered drag up close; a fine-grooved, lighter strip follows the mesh attachment. Captures are `tool-bay.png`, `dirt-before.png`, `dirt-after.png`, and `dragging.png` under `docs/screenshots/`.

The dragging graphical test explicitly repositions the tractor at a basepath start for a repeatable comparison. It is not a human-driven route from the workshop. The attachment follows tractor heading rigidly and has no independent trailer collision or suspension. Lowered reverse travel does not prepare dirt. Chalk, bases, and the pitcher/batter work areas are not erased or repaired by this first tool.

## M4: Pushable chalk marker

A separate pushable cart adds E interaction, WASD pushing/steering, Space braking, and an R-operated chalk gate. The operator walks behind the handle. Its footprint collides with the park, exit requires stopping and a free side position, and leaving closes the gate. The tractor remains inactive while pushing. The completed white foul lines are now replaced by dashed gold guides until the player paints them; batter-box decorations remain fixed.

- `test_chalk.gd`: **23 assertions passed**, including empty guide state, both sides, protected base/plate targets, off-guide visible strokes without credit, no stationary paint, diagonal coverage, overlap, parallel error, beyond-end rejection, travel direction, guide distance, complete left/right coverage, exact 100%, persistence, and mesh batching.
- `test_chalk_gameplay.gd`: **27 assertions passed**, including physical-key E/R routing, occupied states, task HUD, closed/open gate behavior, true line coverage, other-task isolation, moving exit guard, closing/reopening without bridging gaps, stopped exit, reverse on untouched guide, idle no-score, wall collision, returning to the tractor, session persistence, and exact completion-count boundaries.
- Existing mowing/dragging suites: **65 assertions passed** after integration. Total: **115 passing assertions** across six suites.
- `test_chalk_visual.gd`: graphical marker, before/after line, close pushing view, and a separate parallel off-guide stroke. The controlled pass painted **39 target sections**, giving **4.83% total / 9.65% right-line coverage**, with left-line, mowing, and dirt progress unchanged. The off-guide stroke remained visible and did not increase coverage. Captures are the five `chalk*.png` files in `docs/screenshots/`.
- Visual inspection confirmed the character's pushing pose, visible white trail, unfinished gold guide ahead, and off-guide feedback. The wall test exposed residual requested speed during a floor-recovery contact even when horizontal travel was zero; the controller now clears speed using actual displacement as well as slide normals, and the failing exit/control-transition checks then passed.

Default targets contain 404 valid sections per side (808 total), after base exclusions. The score uses the continuous nozzle stroke against section centers; repeated passes cannot increase covered sections. Geometry stays at the actual stroke position, including mistakes. Painting is batched in groups of 128 strokes and flushed at most 10 times per second. It does not replace an entire line or field material.

The graphical script repositions the cart for controlled comparisons; it is not a human-driven workshop-to-foul-pole route. Unit checks prove full target completion mathematically. The readiness boundary uses injected counts; no end-to-end 100% park playthrough was performed. Chalk supply is unlimited, strokes are not erased by other tools, and task state is still session-only.

## M4: On-foot hose watering

The water station adds F pickup/stow, held-left-click spray, a center reticle and footprint ring, a held nozzle/arm pose, a curved visual hose, and a batched droplet stream. Camera aim, nozzle line of sight, grounded player state, a 65 m station reach, and a 12 m nozzle reach gate spraying. The existing dirt-validity map protects grass, lawn, mound, bases, and plate/batter area. Entering either vehicle/tool stows the hose before transferring controls.

- `test_moisture.gd`: **17 assertions passed** covering dry initialization, zero exposure, damp versus sufficiently soaked cells, equivalent elapsed-time doses, footprint width, protected/out-of-bounds areas, base-pad protection, saturation, overlap-safe completion, percentage math, independent dragging state, and dirty-only publication.
- `test_watering_gameplay.gd`: **21 assertions passed** covering physical-key F routing, walking while equipped, task HUD, real camera/ground rays and spray action, other-task isolation, cursor release, both reach limits, wall obstruction and recovery, tractor/chalk-marker auto-stow, blocked vehicle-mode spraying, remote stow, persistence, and completion-count boundaries.
- Existing six suites: **115 assertions passed** after watering integration. Total: **153 passing assertions** across eight suites.
- `test_watering_visual.gd`: actual software-rendered station, before/after dirt, live spray, and overview captures. A controlled three-second exposure watered **256 cells (2.03%)**. A prepared strip and chalk stroke were seeded for the comparison; their tracked counts and visible patterns remained intact. The test also released the real graphical cursor with Escape while the spray action was held and verified spraying stopped without extra exposure.
- The headless dummy display ignores requested cursor capture. The headless integration test injects that OS state only; the production default and graphical test use the actual cursor mode. This preserves the no-spray-while-cursor-free guard rather than disabling it to make tests pass.

Captures are `water-station.png`, `water-before.png`, `watering.png`, `water-after.png`, and `wet-dirt.png` in `docs/screenshots/`. The test teleports the player and seeds drag/chalk state for repeatable comparison; it is not an end-to-end human preparation run. Moisture remains session-only, without drying or quality penalties. The hose has no physical collision, tension, or obstacle routing.

## M4: Mound repair

A G-operated tamper rack adds an on-foot timed-impact task. The mound has a shallow frustum mesh and matching convex collider. Six worn clay patches each need three distinct accepted strikes; partial compaction settles the visual clumps and a finished patch blends into the original clay. The HUD shows repaired patches and the current patch's hit count. Hand tools are mutually exclusive and stow on vehicle/marker entry.

- `test_mound.gd`: **16 assertions passed** for initial layout/work totals, world-to-patch lookup, rubber/off-mound exclusions, invalid indices, accepted and partial strokes, material/clump updates, full repair, no repeat farming, independent patches, exact 100%, and accepted-work signals.
- `test_tamping_gameplay.gd`: **29 assertions passed** for rack pickup, walking up the slope, standing on the mound, aiming, windup/contact timing, spam rejection, three-stroke repair, HUD, task isolation, cursor guard, looking away, movement, distance, obstruction, cancelled stow, hose/tamper mutual exclusion, vehicle stow, persistence, and five-task completion boundaries.
- Existing eight suites: **153 assertions passed** after integration. Total: **198 passing assertions** across ten suites.
- `test_tamping_visual.gd`: repaired **all six patches with eighteen valid strokes (100%)** in the actual graphical scene. Inspected the rack, worn mound, live stroke, one repaired patch, and fully repaired mound. The test also released the real cursor during a windup and confirmed no repair was credited. Other task counters remained zero.
- Visual inspection found the old long completion label crowded its caption. The completed-task label is now compact, the caption says task progress, and finished-mound feedback no longer tells the player to find more worn clay.

Captures are `tamper-rack.png`, `mound-before.png`, `tamping.png`, `mound-patch-repaired.png`, and `mound-after.png` in `docs/screenshots/`. The graphical test teleports between patches for controlled aim and does not constitute a human workshop-to-mound route or a complete all-five-task park playthrough. The headless controller test separately proves that walking climbs the slope. Patch wear/compaction is visual and logical; impacts do not deform the collider, consume clay, or affect the other masks. Motion is procedural, without hand-contact IK.

## Not established

This was scripted graphical validation, not a human keyboard/mouse playtest. Native Windows execution of these updates, Forward+ appearance on a hardware GPU, sustained frame-rate targets, and a full 100% field mow were not tested here. The user confirmed the original version's mechanics in a local playtest; that does not establish validation of this update. No Windows export template or executable is included.

The art is still generated prototype geometry. The uncut tufts are sparse, not a dense lawn simulation. They shrink away beyond 38 m and cast no shadows. Set `tuft_count` to zero for a cheaper visual configuration without changing scoring. The infield lawn is decorative and excluded from the outfield objective.

## Manual acceptance checklist

1. Pull `main`, import project.godot in Godot 4.6.3 or newer stable 4.x, and press F5.
2. Walk, sprint, jump, orbit and zoom near the workshop. Check the walk cycle and camera obstruction.
3. Approach the mower, press E, drive forward, reverse, turn and brake. Check that the seated driver appears and E refuses a moving exit.
4. Cross fair grass horizontally and diagonally. Check deck-width stripes, disappearing tufts, persistent overlap, and increasing percentage.
5. Drive over dirt, the decorative infield lawn, and warning track. Percentage must remain unchanged.
6. Stop, exit, walk around the cut path, re-enter and continue. Try exiting near obstacles.
7. Check the workshop, open dugouts, signs, scoreboard, stands, and tree line at player height.
8. Near the parked tractor, press Q on foot to equip the drag. Confirm the unused deck appears on the bay rack.
9. Enter, drive to a basepath, stop, and press R to lower. Drive forward and check the visible smooth strip and dirt percentage. The outfield percentage must stay unchanged.
10. Raise the drag while moving, then stop, lower it, and reverse over new rough dirt. Progress must not increase. Grass, bases, plate/batter area, and the mound must not count.
11. Stop, exit, and inspect the path. Return to the workshop, swap back to mowing with Q, and confirm both progress values remain.
12. Walk to the chalk marker on the workshop pad and press E. Check that the walking player hides and the pushing operator appears, with no tractor control conflict.
13. Follow a dashed gold guide with WASD. R opens/closes the chalk gate; check that only open-gate forward motion paints and credits the correct line. Close the gate while repositioning and confirm there is no connecting stripe when reopening it.
14. Make a parallel off-guide stroke on a new patch: it must remain visible without increasing line coverage. Repeated passes, reversing, and idling must not inflate completion.
15. Stop, leave, use the tractor again, and return to the marker. Check that all five percentages and the chalk trails persist. Test marker braking and exit near the workshop wall.
16. Approach the water station on foot and press F. Aim at dirt and hold LMB: the patch must darken over time, then count only sufficiently wet cells. Watch the aim-point moisture and blue reticle.
17. Release the cursor with Escape while holding LMB. Spray must stop. Recapture, test grass/protected areas, targets beyond the 12 m spray reach, and walking beyond the 65 m hose reach.
18. Test spray obstruction at a wall, then enter the tractor or chalk marker while holding the hose. It must stow, with no water progress during vehicle control. Stow manually with F away from the station and confirm moisture persists.
19. Approach the repair rack and press G. Walk up the mound, aim a dark patch, stop, and click LMB. Confirm the stroke has a windup and only credits work at contact. Three separate strikes should flatten that patch and turn its target ring blue.
20. Try holding/spamming clicks, moving or looking away before impact, stowing during windup, releasing the cursor, and clicking from too far away or behind an obstacle. None should create free repair work.
21. Swap between hose and tamper, then enter the tractor or chalk marker. Check automatic stow and persistent repair progress. Repair all six patches and check that this completes only the mound task while other work remains.
22. Check Forward+ appearance and performance on the target Windows GPU during the next desktop playtest.


## M5: Timed shifts and results

- All ten existing headless suites passed again: **198 assertions**.
- `test_shift_session.gd`: **25 assertions passed** for profile/start guards, quotas, proportional scores, exact full-completion flags, invalid progress, clock boundaries, early finish, frozen results, and restarts.
- `test_shift_gameplay.gd`: **32 assertions passed** for the real scene's practice/pause/resume/reset lifecycle, all five models and their visuals, actor clock pause, hand-tool cancellation, click isolation, result snapshots, timeout, and completion. Total: **255 passing headless assertions**.
- `test_shift_visual.gd`: real Tab input and native GUI mouse clicks started, paused, resumed, ended, and restarted attempts. Actual mower movement plus eighteen timed mound impacts produced **20.4 points / one completed goal**. The test teleports between repair patches for repeatability. Timeout is fast-forwarded; the full-completion headless fixture supplies synthetic full counts. No full 15/30-minute human route has been validated.
- Inspected active checklist and results captures at 1280×720: text and buttons fit. Seven software-rendered captures are stored as `shift-*.png` in `docs/screenshots/`.

The board pauses the world and shift clock; Escape outside it only releases the cursor. Windows Forward+ appearance/performance and challenge timing balance remain unverified.


## M5: Save and resume

- All twelve prior headless suites passed again: **255 assertions**.
- `test_field_save.gd`: **28 assertions passed** for missing saves, mixed real work, slot replacement, exact direction/visual data, independent counters, partial moisture/patches, on/off-guide chalk rebuilding, paused active clocks, parked equipment, version/layout mismatch, invalid data, immutable results after later practice, checksum/truncation rejection, practice/timeout/completion snapshots, and write failures. Total: **283 passing headless assertions**. The completed-result branch uses synthetic full progress; mixed-work restoration uses the actual field models.
- `test_save_visual.gd`: native mouse-button clicks saved an active five-job scene, then loaded it into a completely recreated main scene. Verified all five counters, the exact paused elapsed time, Resume advancing the clock, and early-end results. Inspected 1280×720 board, loaded-state, and results captures under Xorg/Mesa OpenGL Compatibility (`save-*.png`). The load warning remains visible alongside the status message; all controls fit the viewport, with scrolling available for smaller windows.

No Windows executable or Windows filesystem replacement behavior was tested. The automated graphical run recreates the scene in one process; a human close/relaunch check remains part of desktop testing. Saves are manual and local, with one slot and no migration or sync. Check on desktop: save mid-shift, close, reopen, load from Tab, verify patterns/clock, then resume. A fresh shift should preserve the previous disk slot until Save is clicked.


## Sound feedback and preferences

- Prior **283 assertions** passed with the audio layer installed. Four existing real-controller checks additionally verify audible-player activation during forward dragging, open-gate chalking, reachable spraying, and an accepted timed tamp.
- `test_audio.gd`: **27 assertions passed** covering safe defaults, preference persistence, actual bus mute/zero levels, channel independence, invalid settings/write errors, ambience, idle tools, bus reuse, PCM loop bounds, actual mower entry/acceleration/exit, pause/resume, sliders, preview during pause, mute checkbox, screen navigation, grounded footsteps, impact/result events, and reset cleanup. Total: **314 passing headless assertions**. Scene fixtures free players and allow the mixer to release playback references before quitting.
- All nine source WAV files checked for nonzero output, bounded peaks (maximum 0.428), and quiet endpoints. `test_sound_visual.gd` used native clicks and slider key input, checked mute, Escape and Tab navigation, and recorded the real Godot mixer preview while the world was paused. The resulting stereo recording was nonempty with peak 0.0434. Inspected `sound-settings.png` and `sound-board.png` at 1280×720; every board and sound control fits.
- Headless editor import and 180-frame main startup passed. These validate routing, state and generated PCM, not a human listening assessment. No Windows output-device or headphone/speaker mix check has been performed. Sound remains synthetic prototype material, without music, crowds, surface-specific footsteps, or acoustic occlusion.


## Connected field and dugouts

- All previous **314 headless assertions** passed after the enclosure changes.
- `test_field_layout.gd`: **20 assertions passed** for field-facing orientation, foul-territory placement, both front-corner openings, actual walking into each dugout, rear walls, foul-side collision, backstop collision, equipment-gate clearance, both unobstructed foul lines, actual mower travel through the gate, and retained scored areas. Total: **334 passing headless assertions**.
- `test_field_layout_visual.gd`: captured the full field, an overhead infield layout, both dugout fronts and the equipment entrance. Inspected the actual 1280×720 OpenGL Compatibility captures: dugouts now face the playing surface, fence wings meet their ends, side fences return to the outfield, and the workshop entrance remains open. Captures are `field-layout.png`, `dugout-layout.png`, `visitor-dugout.png`, `home-dugout.png`, and `field-access.png` under `docs/screenshots/`.

The tall backstop and side fences have collision; the workshop gate is intentionally open. Chain-link appearance is a cutout shader, not individually modeled wires. Existing field masks and saves keep their layout; this does not add playable baseball simulation. Windows Forward+ rendering remains unverified. An intermittent audio playback-resource warning appeared on one save-test shutdown; all assertions passed and the ordinary main-scene smoke launch remains clean.
