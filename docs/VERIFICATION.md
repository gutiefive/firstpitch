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


## Plate, coaching boxes and on-deck areas

- Targeted existing suites passed: **20 field-layout**, **28 chalk gameplay**, and **28 save/load assertions** (**76 checks**). Actual dugout entry, gate driving, foul-line task progress, independent counts and persisted visuals remain intact.
- Extended `test_field_layout_visual.gd` with overhead home-area, close plate and coaching-box captures. Inspected the rendered plate point toward the backstop, two correctly spaced batter's boxes, paired on-deck circles, and coaching rectangles between foul lines and dugouts. Corrected flat-mesh winding after the first rendering exposed back-face culling; the final plate and rings are visible from above.
- New captures: `home-area.png`, `home-plate.png`, and `coach-box.png`. The geometry is static and has no collision or scoring effect. Existing field masks, save format and job quotas are unchanged. Windows Forward+ remains unverified.


## First career loop: Rewards, ranks and upgrades

- All **334 prior headless assertions** passed after integrating career persistence and isolated test profiles.
- `test_career.gd`: **26 assertions passed** for new profiles, partial/zero/complete payouts, invalid results and IDs, immutable receipts, duplicate/rewound attempts, ranks and personal bests, upgrade costs/ownership, rank retention after spending, disk restoration, invalid ledgers, failed purchase/reward writes, safe retry and corruption handling.
- `test_career_gameplay.gd`: **18 assertions passed** for practice without pay, active IDs through a real disk field save, real partial mound work paying at finish, visible receipts, repeat-load payout prevention, legacy snapshots, paused shop access, actual wider cutting and 25% faster moisture, visual deck scale, upgrades surviving field load/new scenes, and fresh attempt IDs. Shop funding uses two synthetic completed-result fixtures; it is not a human full-park run. Total: **378 passing headless assertions**.
- `test_career_visual.gd`: native Tab/start/end/career/shop input, actual mower movement and eighteen timed mound impacts produced 20.4 points and **20 credits**. Two explicitly seeded completed results funded the native upgrade purchases. Inspected reward, shop, owned-upgrade and widened-deck captures at 1280×720. Escape returned to the paused board; a fresh shift retained upgrades. No 15/30-minute end-to-end human shift or economy balance assessment was performed.

Career data is separate from field saves and is automatically committed on rewards/purchases. Test fixtures use dedicated career paths so fabricated results cannot affect player data. Existing intermittent audio-resource warnings on process teardown remain unrelated to the career assertions. Windows filesystem replacement behavior and Forward+ visuals remain unverified.


## Focused preparation contracts

- All **378 prior headless assertions** passed with contract profiles installed.
- `test_contracts.gd`: **30 assertions passed** covering zero-target exclusion, proportional one-/two-job scores, exact mound completion, deadline completion priority, per-contract partial/bonus payouts, unrelated-work timeout, rank locks before reset, paused native-screen wiring, active-attempt guards, actual contract field saves and IDs, repeated-load payout prevention, accepted mound model work, contract versus park-ready labels, filtered goal totals, frozen counts after practice, separate bests, rank unlocks retained after spending, correct initial HUD selection, and persisted contract history. Total: **408 passing headless assertions**.
- `test_contracts_visual.gd`: native Tab/Contracts/start buttons selected a mound callout; eighteen actual timed hand-tool impacts automatically completed it and committed **40 credits**, with other job counters still zero. Completion fixtures then exercised the lock boundary: **490 lifetime credits remained locked; 640 unlocked** the infield card. Verified the two-job infield checklist, active-contract replacement guards, Escape/Tab pause navigation, and a fast-forwarded timeout. Inspected 1280×720 contract-board and completion captures; controls and text fit.

Captures are `contracts-locked.png`, `contract-mound-active.png`, `contract-complete.png`, `contracts-unlocked.png`, and `contract-infield-active.png`. Rank-funding and infield timeout are synthetic branches; no full human mowing/infield contract route, pay-balance assessment, or Windows Forward+ run was performed. Existing audio teardown warnings remain intermittent and do not affect assertions.


## Part 1 — Shared FieldLayout resource

Baseline recorded from unmodified main at `4ff75db` before edits. Helpers and masks now use the geometry actually drawn: outer edge `31 / sqrt(2) = 21.9203102168` instead of separately rounded `21.92` / `21.921`; inner edge `22 / sqrt(2) = 15.5563491861` instead of `15.6` / `15.556`. Base axes derive from `27.432 / sqrt(2) = 19.3973532215`, replacing the old rounded coordinates. The grass exclusion now follows that same outer edge.

| Tracked area | Before | After | Change |
| --- | ---: | ---: | ---: |
| Grass cells | 61,445 | 61,568 | +124 |
| Dirt cells | 12,618 | 12,756 | +138 |
| Moisture cells | 12,618 | 12,756 | +138 (same dirt mask) |
| Chalk sections | 808 | 808 | 0 |
| Mound impacts | 18 | 18 | 0 |

No previously valid cells were removed. No existing assertion changed its expected gameplay outcome; six tests now obtain sample coordinates from the resource. Island and concourse height projection uses the actual drawn top surfaces, removing half-millimeter rounding differences.

The v1 layout hash is hard-coded in the regression test:
`4b93508a852f996a404526525630f7fcb6b2271cd10d8adedd4c9f2364fd70b5`.
Canonical v2 hash:
`7b9130bdf3d3ece6fd0bdc711a4028ad8613ebebabf58008a3603857720664bd`.

Because valid cells changed, FieldSave.VERSION was bumped to **2**. A real checksummed v1 slot captured before the refactor is committed as `tests/fixtures/cedar_grove_v1.dat.gz`; the test loads it through the migration, checks all old direction pixels and counts, preserves its attempt ID and paused clock (including the original fallback ID for pre-career saves), initializes new cells unworked/dry, and writes/reads the migrated v2 slot. Original validity arrays are bundled in `resources/layouts/cedar_grove_v1_masks.res`. Migration rejects unknown layouts and originally invalid work rather than weakening validation. Tests use dedicated `user://test-*` files and isolated XDG roots, never player saves.

All README headless suites plus the new resource suite ran successfully:

| Suite | Passed assertions |
| --- | ---: |
| `test_mowing.gd` | 14 |
| `test_gameplay.gd` | 13 |
| `test_infield.gd` | 16 |
| `test_drag_gameplay.gd` | 23 |
| `test_chalk.gd` | 23 |
| `test_chalk_gameplay.gd` | 28 |
| `test_moisture.gd` | 17 |
| `test_watering_gameplay.gd` | 22 |
| `test_mound.gd` | 16 |
| `test_tamping_gameplay.gd` | 30 |
| `test_shift_session.gd` | 25 |
| `test_shift_gameplay.gd` | 32 |
| `test_field_save.gd` | 28 |
| `test_audio.gd` | 27 |
| `test_field_layout.gd` | 20 |
| `test_career.gd` | 26 |
| `test_career_gameplay.gd` | 18 |
| `test_contracts.gd` | 30 |
| `test_field_layout_resource.gd` | 37 |
| **Total** | **445** |

The new resource suite additionally covers base derivation, diamond/fair/basepath helpers, all requested ground-height surfaces, shared resource identity, baseline/corrected totals, legacy protection and pixel preservation, and an alternate resource reaching masks, mound, tools and actor spawns before `_ready()`. Altering a duplicated resource leaves Cedar Grove untouched.

Headless editor import and main startup passed. `test_field_layout_visual.gd` rendered field, dugouts, equipment access, home plate and reference markings under OpenGL Compatibility; inspected the overhead field capture after refactoring. A code-coordinate audit found the old copied coordinates only in layout definitions, not controllers, surfaces, shaders or test bodies. Runtime shader mappings are supplied explicitly from the resource-backed masks. Existing intermittent audio playback-resource warnings on process teardown remain; Windows/Forward+ validation is still outstanding. Parts 2 and 3 were not started.

## Part 2 — Game-day wear and finish quality

Added two headless suites and extended contracts/career regressions. All 21 headless suites pass **495 assertions**: the original 445, six contract checks, two career checks, 21 wear checks and 21 quality checks. Run with isolated `/tmp/firstpitch-part2` XDG roots and dedicated test save paths. Editor import and main-scene startup were also checked. Logs were inspected for script errors as well as exit codes.

`test_field_wear.gd` checks zero-intensity identity; seeded repeatability and variation; greater traffic-area damage; drying flag recount; matching chalk/stroke loss; grass/mound wear; current-state game-day baselines; attempt-derived seed; once-only reworking; worn, partly repaired, puddled disk round trip; seed/nonfinite-state rejection; and v2 fresh/neutral migration. Seeded wear measured approximately **23–25 ms** in the headless default-park fixture, below the 50 ms requirement. This measures wear application including state/visual rebuilding, with topology cached during scene construction. First blank-field preparation plus wear was about **58 ms** in the initial smoke check; that includes the separate host-park bootstrap.

`test_quality.gd` checks repair denominators and no-needed-work handling, exact 100% guards, multiplier arithmetic, largest-loss tips, invalid quality rejection, quality-independent completion, adjusted payouts, independent water/drag/chalk penalties, puddle blocking/drying/history, rut repair and state round trip, stripe consistency versus crossed directions, and a hand-built checksummed v1 career file paying the original 450 credits exactly once. Career regression rejects forged quality; contract regression covers Crew Lead lock/unlock, eight-minute four-goal doubleheader, saved baselines and 260-credit quality-adjusted completion.

The real pre-refactor v1 field fixture still loads with preserved pixels, counts, attempt ID and clock, then writes v3. The resource test's format-version assertions were updated from 2 to 3. The shift restart assertion now checks the worn current-field baseline instead of requiring an empty dirt reset; fresh-training assertions remain unchanged.

`test_wear_visual.gd` uses native board start/end controls under Linux Xorg/Mesa OpenGL Compatibility. Captures show the worn field, puddle/rut surface fixtures, result coverage/quality/tip and the locked Crew Lead card. These are scripted fixtures, not a human route or balance test. Results fit at 1280×720; the four-card contracts screen scrolls. Existing intermittent audio-resource teardown warnings remain. Windows, Forward+ hardware and full human deadline/pay balance remain unverified. Part 3 was not implemented.

## Part 3 — Onboarding, autosave and controller support

All 24 headless suites pass **582 assertions**: the Part 2 total of 495 plus 27 tutorial, 26 autosave and 34 controller assertions. All tests use isolated `/tmp/firstpitch-part3` XDG roots; new fixtures override settings/autosave/career paths. Existing gameplay fixtures explicitly disable guide/autosave side effects. Godot editor import, main-scene startup and whitespace checks passed. Logs were scanned for runtime/script errors in addition to checking process exit status.

- `test_tutorial.gd`: each of seven checks begins unfinished, then succeeds using actual walking, occupied-tractor mowing, bay tool swap and lowered forward drag, open-gate chalk movement, real spray and three timed hand-tool impacts. Confirms a blocked drag reuses the existing prompt, partial impacts do not finish a patch, board open requires a later close, paid attempts block tutorial checks/cleanup, replay works, completion/skip persist, checkpoints reload and cleanup clears all five jobs.
- `test_autosave.gd`: start/dirty-interval/board/finish/quit triggers; no idle saves; one-second coalescing; timestamp footer; off-guide-only dirty work; untouched manual sentinel; active recovery title/clock/progress/ID and parked equipment; unresolved candidate preservation; fresh reset; failed career write followed by unpaid-result recovery and twice-resumed single payout; corrupt-file quarantine/notice. A separate Godot process receives the actual close notification, waits for its rate-limited save, exits, and leaves its active clock and mound hit on disk. A full-field fixture measures capture, strict validation and atomic write; observed runs were approximately **113–141 ms**, so a short synchronous save hitch remains a limitation.
- `test_controller_input.gd`: idempotent bindings, requested button-to-action mappings on a nonzero device ID, stick drift deadzones, actual player movement and camera look, bay swap/tractor entry/drag control, LB/RB equipment, RT watering and accepted tamp with free cursor, mouse-switch spray stop, paused board focus, A/B/Back menu navigation, InputMap-generated Controls, saved sensitivity, pad prompts and remapped binding text/world signs.

`test_onboarding_visual.gd` ran through native keyboard/mouse skip and replay controls, pad Controls/back navigation, an autosaved partial mound-callout fixture, scene recreation, the paused startup resume card and exact restored clock/work. Inspected 1280×720 captures: `tutorial-first-run.png`, `controller-controls.png`, `resume-card.png` and the resumed board. Controls and its Back button fit; the recovery card shows only the pending choice. First tutorial view faces the noticeboard marker. Screenshots are committed in `docs/screenshots/`. The existing `test_save_visual.gd` also passed native manual save/load across scene recreation, preserving five jobs, paused clock, resume and results. Native click helpers now scroll controls into view on expanded boards.

Graphical checks used Linux Xorg/Mesa software OpenGL Compatibility. Tutorial headless tool work is real simulation; the graphical resume's partial mound work is an explicitly injected model fixture. No full human tutorial timing/usability session or 60-minute crash soak was performed. Physical controller enumeration/mappings/trigger calibration, disconnect/reconnect and stick feel remain unverified. Windows export, native window-close/filesystem behavior and Forward+ hardware remain unverified. Existing intermittent Godot audio playback-resource teardown warnings remain; no script errors or failed assertions remain in the verified runs.


## Field inspection and remaining-work visibility

All 25 headless suites pass **612 assertions**: the previous 582 plus 30 in `test_inspection.gd`. Tests use isolated `/tmp/firstpitch-inspection` XDG roots and dedicated career/settings paths. Editor import, main startup and whitespace checks pass; logs were inspected for script errors as well as exit codes.

The new suite checks native V/[ / ] and pad RS/D-pad controls, bidirectional wrap, requested-job filtering, normal tool/HUD selection, grass tuft restoration, dirt/water shader selection, exact water qualification at both sides of the target, fixed chalk batches, completed-section count removal, partial-versus-complete mound impacts, no idle rebuilds, device-aware legends, paused-input guards, unchanged full save snapshots across toggles, and clearing presentation on paid starts/field restore/reset. Existing layout hashes, v1/v2 save migrations, career payouts, tutorial cleanup, autosave recovery and controller suites remain passing. The controller regression now keeps inspection enabled while its actual hose spray and timed tamp are performed, confirming the overlays do not block aiming or impacts.

`test_inspection_visual.gd` rendered grass, drag, chalk, water and mound views using seeded wear and explicit surface-work fixtures. It verifies every actual-renderer chalk instance against valid and uncovered flags, confirms completion removes a mound marker, and opens Controls through native events. Inspected 1280×720 captures for legibility, completed/protected regions and correct gold/teal/orange/blue states. Screenshots for grass, dirt and chalk are committed. This is a controlled inspection fixture, not a full human contract route.

Graphics used Linux Xorg/Mesa OpenGL Compatibility. Physical pad testing, color-vision accessibility, Windows and Forward+ hardware performance remain unverified. The binary water mask adds one small texture upload to the existing moisture refresh; no idle per-cell updates or per-cell nodes were added. Existing occasional Godot audio-resource teardown warnings remain.


## Equipment progression — wide drag and chalk guide wheel

All 26 headless suites pass **642 assertions**: the previous 612 plus 30 in `test_equipment_upgrades.gd`. Fixtures use isolated `/tmp/firstpitch-equipment` XDG roots and dedicated career/settings files. Editor import, main startup and whitespace checks pass; logs were inspected for script errors and assertion failures.

The new suite covers unchanged standard gear; visible shop locks; wallet-versus-lifetime unlock rules; rejection of a forged affordable/rank-locked ledger; failed-write rollback; exact 400/350-credit purchases and once-only charges; mounted/parked mat dimensions; greater actual valid-cell preparation; nonstacking width effects; visible guide gear; no stationary credit; actual convergence versus an unassisted control from the same offset and heading; real on-guide coverage with off-guide penalties retained; HUD feedback; brake/light-steering overrides; closed gate, reverse, distance, angle and endpoint limits; both directions along a guide; old-field restore and recreated-career persistence. Existing legacy field/career, payout, tutorial, autosave, inspection and controller suites remain passing.

`test_equipment_visual.gd` uses native board/shop controls to show locked upgrades and buy both after two completed-result fixtures fund 900 lifetime credits. It then performs actual lowered forward dragging and actual open-gate chalking with assistance. Assertions check the upgraded width, wallet, real dirt/chalk progress and final nozzle distance within the 0.11 m guide-credit tolerance. Inspected 1280×720 shop, wide-drag and guide-wheel captures; the two-column shop fits at 1280×720 with all four choices and Back visible, retaining scroll fallback for smaller windows. Funding is synthetic; tool work uses real physics. Screenshots are committed in `docs/screenshots/`.

Graphics used Linux Xorg/Mesa OpenGL Compatibility. No human economy/long-route balance pass, native Windows run, Forward+ hardware test or physical-controller steering assessment was performed. Existing occasional audio-resource teardown warnings remain. Career remains version 1 and field slots version 3: new ownership IDs fit the existing ledger, with no old payouts or layout signatures changed.

## Minor-league club story — first playable loop

All 28 headless suites pass **715 assertions**: the previous 642 plus 35 club progression and 38 scene/gameplay checks. Runs use isolated `/tmp/firstpitch-club` XDG roots and named test career/settings/autosave slots. Editor import, main startup and whitespace checks pass; logs were checked for script errors as well as exit status.

`test_club_progress.gd` verifies opt-in enrollment and v1 balance/tool preservation; no retroactive gate pay; incomplete-prep rejection; durable pending games; deterministic first attendance/net/growth; atomic failed enrollment, settlement and construction; one-time wages and gate settlements; rejection of duplicate events, forged fan/money fields, invalid ledger prefixes and unmet project requirements; seating/amenity/covered-stand costs and economic effects; chapter progression; budget reconciliation; reload equality; quality affecting attendance/profit/growth; side-work money without extra fans; and rejection of improved ticket pay after a frozen prep result is rewound.

`test_club_gameplay.gd` checks the default sandbox remains unchanged, the job is accepted through injected controller confirmation, focus moves to the next action, starter gear has narrower/slower actual effects, 120 starter seats replace the legacy stands without ghost colliders, mask signatures stay fixed, the home profile uses real director/claim flow, active attempts block hosting/construction, practice-guide cleanup precedes paid work, finished paid prep resumes for its pending game, volunteers create no extra pay, first spectators appear in batches, game money buys better tools, unchanged crowd geometry is cached, real seating/snack/roof construction appears, all tiers preserve field compatibility, and relaunch/old-field load cannot roll back club money/buildings or duplicate settlement. Surface-completion fixtures exercise the progression path; they are not a human full-field route.

`test_club_visual.gd` uses native Clubhouse enrollment, prep/hosting, project and workshop controls. It renders the 120-seat starter park, the first crowd, added bleachers/snack shack, the covered 480-seat park, upgraded tools and later chapters. Eight completed surface fixtures and two side-pay fixtures fund this scripted tour; it is not a pacing/balance playthrough. Inspected 1280×720 UI and stadium/supporter captures; construction stays outside the field and the story/actions/project cards remain readable. Screenshots are committed in `docs/screenshots/`.

The existing 642 assertions still cover legacy career/field slots, exact masks, tool mechanics, finish quality, contracts, autosave, controller input and inspection. Club enrollment creates career v2; old v1 careers retain exact prior payouts and field saves remain v3 with unchanged layout signatures. Graphics used Linux Xorg/Mesa OpenGL Compatibility. Physical-controller feel, native Windows, Forward+ hardware, long-session economic balance and human home-prep timing remain unverified. Actual innings/baseball players, animated spectators and league results are not implemented; hosted games use explicit summaries. Existing occasional audio-resource teardown warnings remain.

### Home schedule verification

Added a 19-assertion schedule suite covering exact time boundaries, quality-dependent score targets, unfinished prep, pending dates, season rollover, reload equality, duplicate hosting and unchanged gate/wage accounting. Club gameplay also checks the actual Clubhouse opponent and review labels. Tests use isolated XDG directories. These fixtures verify the schedule and saved review; optional target difficulty still needs human playtesting. This pass does not claim graphical screenshot verification.

Result: 181 assertions passed across schedule, club progression/gameplay, career, autosave and controller suites. Godot 4.6.3 editor import and main-scene headless startup passed without script errors. Previous full-suite total was 715; this pass adds 20 assertions but does not claim a fresh full-suite run.

### Stadium expansion verification

138 headless assertions passed across stadium expansion (17), club progression (35), club gameplay (39), schedule (19) and career (28). The new suite exercises fan/budget/prerequisite guards, exact construction cost, failed-write rollback, duplicate purchases, frozen historical receipts, additive food/ticket/fan benefits, six-project reload equality, physical buildings, scoreboard replacement and unchanged capacity. Godot 4.6.3 Compatibility graphics also passed the 17 expansion assertions. Rendered screenshots were inspected for concession placement, video-board readability and the scrollable Clubhouse project grid. Screenshots: `screenshots/stadium-concessions.png` and `screenshots/stadium-video-board.png`. Full-park preparations and funds use test fixtures; this is not a human balance playthrough. The video display is static club messaging, not live baseball footage.

### Tutorial watering regression

Reproduced the silent-hose case with native left-mouse input and the real player camera: the original code failed the visible-spray assertion when aiming above nearby ground. After the fix, 142 assertions pass across hose feedback (9), tutorial (33), watering gameplay (22), moisture (17), controller input (34) and audio (27). The new suite covers input arrival, visible air spray without moisture credit, cursor release, normal player-camera dirt watering, mouse release, obstacle-clipped spray without watering through walls, and finite hose length. Tutorial checks cover the cart-release handoff and live moisture feedback. Test saves use isolated `/tmp/firstpitch-watering` XDG roots. The headless tests inject only cursor-capture availability; actual gameplay camera transforms are retained.

Godot Compatibility graphical playback also passed all 9 hose checks; inspected a rendered frame showing the held hose, droplet stream, ground ring and increased water coverage. Editor import passed without script errors. Physical-controller hardware and the user's own save were not available for this check.

### Four-pass visual revision

219 assertions passed across gameplay (13), watering gameplay (22), tutorial (33), equipment upgrades (30), club gameplay (39), stadium expansion (17), shared layout resource (37) and field save (28). Captured five recurring views across baseline, four passes and final refinement; inspected character/equipment, park, field and concession renders. Editor import and captures passed without script/shader errors. Committed final screenshots and the baseline crew comparison are linked in `ART_REVIEW.md`. No new mechanics or save format changes. The attempted Forward+ review cannot count as Forward+ verification: Vulkan `VK_KHR_surface` is missing and Godot falls back to OpenGL Compatibility. Hardware performance, native AO and Windows remain unverified.

### Close-up art refinement

154 targeted assertions passed: gameplay 13, tutorial 33, watering gameplay 22, equipment upgrades 30, club gameplay 39, stadium expansion 17. Reviewed Compatibility renders of the molded seats/rails, concession display/sign clearance, crew walking pose, tractor, field and expanded park. The existing club tests retain exact seat counts, batch-size guard, saved building restoration, equipment operation and field-layout compatibility. New screenshots: `refined-seating.png`, `refined-concession.png`, `refined-walking.png`. Visual fixture histories and isolated XDG paths were used. Native Forward+ and hardware performance are not newly verified.

### Entrance and surroundings visual pass

187 targeted assertions passed: gameplay 13, field layout 20, shared layout resource 37, field save 28, club gameplay 39, stadium expansion 17 and tutorial 33. Rendered entrance, concourse, field and expanded stadium views were reviewed in Godot 4.6.3 Compatibility. The capture helper additionally verifies a clear entrance approach using the real player controller and records its normal orbit camera. Saves/settings/cache use isolated `/tmp/firstpitch-arrival` XDG roots. New scenery is decorative, with existing collision footprints and scoring masks retained. Native Forward+ and Windows performance remain outside this verification.

### Field surface visual refinement

239 assertions passed across mowing (14), mound (16), tamping gameplay (30), chalk (23), chalk gameplay (28), inspection (30), field save (28), tutorial (33) and shared layout resource (37). Reviewed Compatibility captures of worn and repaired mound states, mowed versus uncut turf, contextual guides and the park. Mowing screenshots call the real mowing API on fixture lanes; they are not a human tool playthrough. Isolated XDG roots: `/tmp/firstpitch-field-art`. State masks, protected cells, repair targets, costs, scoring and original mound collision geometry are retained. Native Forward+ rendering and hardware performance remain unverified.

### Conditions, manager priorities and postgame recap

408 targeted assertions passed across 14 suites: new game-day rules/ledger (33), new gameplay (31), club progression (35), schedule (19), club gameplay (39), career (28), contracts (36), field save (28), autosave (26), quality (21), controller input (34), shift session (25), shift gameplay (32), field wear (21). The new suites cover deadline/quality boundaries, unchanged opener economics, atomic and duplicate settlement, missed-request replay, bonus injection rejection, exact wallet reconciliation, actual dry/wet/heavy-wear starts, puddle blocking/drainage, natural-rain save round trips, scoped validator exceptions, original condition restoration, recap focus, paused HUD clearing and relaunch persistence.

Compatibility graphical playback also passed the 31 gameplay checks. Inspected hot/rain briefing HUDs and the recap, corrected a clipped heading after text wrapping, and added actual request requirements/results. Completion fixtures use public surface APIs; this is not a full human playthrough or a balance certification. Tests use isolated `/tmp/firstpitch-loop` and `/tmp/firstpitch-loop-visual` XDG roots. No animated rain or continuous heat simulation is claimed. Native Forward+ and Windows remain unverified.

### Progression, stadium life and ownership payoff

513 assertions passed across 18 suites: ownership (19), stadium life (29), game-day rules (33), game-day gameplay (31), club progression (35), schedule (19), club gameplay (39), career (28), contracts (36), field save (28), autosave (26), quality (21), controller input (34), shift session (25), shift gameplay (32), field wear (21), audio (27) and equipment upgrades (30). New checks cover real starter/owned spray timing, failed/duplicate hosting, paused one-shots, native A skip without underlying UI activation, automatic finish, muted ambience routing, concession prerequisites, reactions, hidden prep spectators, exact season summaries, frozen objectives/deadlines, late purchases, capped endgame goals and scene relaunch without replay.

Balance audit covers six deterministic valid-result routes and is documented in `BALANCE_REVIEW.md`; it is not a human playthrough. The new 22,050 Hz mono PCM clips were checked for duration and bounded peaks (all under 0.24 amplitude); physical speaker/headphone mix review remains outstanding. Compatibility renders verify the independent opening camera and ownership recap. Isolated XDG roots: `/tmp/firstpitch-payoff` and `/tmp/firstpitch-payoff-visual`. Native Forward+ and Windows remain unverified.

## Modern UI and navigation

The UI now shares a navy/mint Theme and eight original outline SVG icons. Operations has a club-career entry action and a persistent destination rail. Clubhouse data is separated into Matchday, Stadium, Results and Season; equipment/contracts use cards. The field HUD separates task progress, shift goals, conditions, tutorial, inspection and interaction prompts. Existing career, result, field-save and tool controllers retain their public interfaces.

- `test_modern_ui.gd`: **19 checks passed** in an actual graphical Godot run. Native mouse events exercised enrollment, section tabs, direct destination switching, preparation, hosting and Continue. Injected device-7 D-pad events crossed between the rail and Clubhouse tabs in both directions. Layout checks and captures covered **1024×768, 1280×720 and 1600×900**. Continue is visible above the report and returns focus to the next prep action. Headless mode uses button signals because the dummy display does not route pointer clicks.
- **389 assertions passed** across controller input (34), game-day gameplay (31), club gameplay (39), autosave (27), tutorial (33), inspection (30), watering gameplay (22), equipment upgrades (30), contracts (36), stadium life (29), career gameplay (18), shift gameplay (32), and field save (28). Autosave now explicitly checks that recovery disables every rail shortcut and focuses Resume.
- Total for this pass: **408 passing checks**, no remaining script errors or failed assertions in the verified runs. Final headless editor import/registration and `git diff --check` passed.
- Inspected actual captures for Operations, Matchday, Stadium, Workshop, Contracts, Audio, Controls, Results and the live HUD. Selected `ui-*.png` captures are under `docs/screenshots/`. The UI script disables covered 3D rendering beneath the opaque menus for software-rendering efficiency and restores it for the HUD capture. Full prep is a surface-state fixture, not a human full-game playthrough.

Graphics used Linux Xorg dummy/Mesa llvmpipe OpenGL Compatibility. Unsupported virtual-display V-Sync and occasional existing ObjectDB teardown warnings remain. Physical controllers, native Windows and Forward+ hardware rendering remain unverified. No economy, reward, save-version or field-layout changes were made in this UI pass.

## UI refinement: purchase states and postgame disclosure

Equipment and stadium cards now show savings meters, explicit cash/rank/supporter/construction requirements, installed/built states, and remaining funds for affordable purchases. Equipment purchases show confirmation and restore usable controller focus. Results shows gate profit, manager bonus and fan growth as summary tiles; the full existing receipt expands on request, keeping the next action and investment easier to find.

- `test_modern_ui.gd`: **28 checks passed** headlessly and graphically, including native purchase/install and wallet reconciliation, exact lock reasons, postgame metrics, expandable wages and post-purchase focus, alongside the previous mouse/D-pad and three-size layout checks.
- Existing career gameplay (18), club gameplay (39), game-day gameplay (31), equipment upgrades (30) controller input (34) and autosave (27) passed: **207 distinct checks** across seven suites including modern UI. No script errors or failed assertions remained in the verified logs.
- Reviewed updated software-rendered Stadium, Workshop, purchase confirmation and Results screenshots. Linux Xorg/Mesa Compatibility verification retains the prior hardware and human playtesting limits. Economy and save formats are unchanged.

## UI refinement: Operations, controls and audio

Operations now separates training, full-park prep and manual field checkpoints into descriptive cards. Controls groups movement/menu and equipment/field bindings, displays the active input device, and places camera sensitivity above the reference. Audio has descriptive channel cards, larger slider targets and shared mint slider tracks.

- Modern UI: **36 checks passed**, with native graphical mouse/controller flows and additional controls/audio fit checks at 1024×768, 1280×720 and 1600×900. The camera slider is visible on entry; bindings still reflect the active InputMap. Headless layout assertions wait for container layout to settle.
- Controller input (34), shift gameplay (32), field save (28), autosave (27) and audio (27) passed: **184 distinct checks** across six suites including modern UI.
- Reviewed the actual Operations, Controls and Audio captures, updated under `docs/screenshots/ui-*.png`. Script import and whitespace validation passed. Linux software Compatibility graphics and the prior Windows/physical-pad/Forward+ verification limits still apply. No gameplay, economy or save-format changes.

## Living matchday: arrivals, staged game and town voices

A new MatchdayPark reconstructs representative moving supporters, concession routes/workers, six upgrade identity signs and named town voices from the existing career. The gates presentation now runs a skippable 47-second arrivals → concourse → nine-inning staged game → stories sequence. Baseball actors include fielders reacting to the ball, a swinging batter and an animated runner. Purchased scoreboards update with the displayed inning and score. Ordinary paused menus freeze walkers and quiet ambience; the matchday presentation advances decorative activity while tool/world gameplay remains paused. Returning to prep hides moving supporters and baseball actors.

- `test_matchday_park.gd`: **30 checks passed** headlessly and graphically. Coverage includes actual route displacement and limb animation, bounded agent population, booth routing, no NPC colliders, stage/inning progression, moving ball/runner, stable score at a repeated time, no financial side effects, skip cleanup, presentation/ordinary-pause audio, postgame movement, next-prep visibility, ledger-funded expansions, staff/queue unlocks, project-sensitive story lines, live scoreboard, readable Clubhouse voices, duplicate-host rejection and career reload compatibility.
- Regression checks passed: stadium life (29), game-day gameplay (31), club gameplay (39), modern UI (36), ownership (19), stadium expansion (17), autosave (27), controller input (34), audio (27). Total: **289 distinct checks** across ten suites including matchday park. No script errors or failed assertions remain in the verified logs.
- Actual captures reviewed for arrivals, baseball action, the serving side of the snack stand, and Eli's story moment. The visual suite uses completed-surface/side-job fixtures and explicit presentation times to review the park reproducibly. These are actual game renders, not concept art or a human full-season playthrough.

This is a first ambient matchday simulation: walkers use authored public-area routes and do not implement general navigation/collision avoidance, individual seat ownership or one NPC per ticket. At most 28 walking supporters supplement the existing batched seated crowd. The staged ball, runs and fielding are deterministic presentation rather than baseball physics or persistent league outcomes. Crowd reactions and concession sales do not create new economic transactions. Town dialogue is contextual ambient text and a Clubhouse record, without conversation choices. All objects are procedural/original; career/field save versions and layout signatures remain unchanged. Graphics used Linux Xorg/Mesa Compatibility; physical controllers, native Windows, Forward+ hardware, large-crowd performance and human playthrough balance remain unverified. Existing occasional ObjectDB teardown warnings remain.

## Matchday viewing, replay and Town UI

Matchday now has real mouse controls and keyboard/controller shortcuts for pause, speed, chapter stepping and returning to Results. A chapter/time badge and progress bar explain playback state. Pausing freezes decorative motion and ambience while gameplay stays paused. Outside clicks are absorbed. Results offers a guarded replay and the same deterministic final score as the simulation; Town has its own tab and Everyone/Mara/Eli/Leni filters.

- `test_matchday_ui.gd`: **25 checks passed** headlessly and graphically, covering actual mouse buttons, injected Space/Y/N and device-7 X/Y/RB/A inputs, pause freeze across clock/walkers/audio, 2× time, chapter jumps while paused, compact badge and 1024×768 button bounds, ignored outside clicks, recap focus, replay controls reset, exact ledger/wallet preservation, shared final score and speaker filtering.
- Regression suites passed: matchday park (30), stadium life (29), modern UI (36), game-day gameplay (31), club gameplay (39), autosave (27), controller input (34). **251 distinct checks** across eight suites including matchday UI. Final editor import and whitespace validation passed; no script errors or failed assertions remain in the verified logs.
- Inspected actual 1280×720 playback, 1024×768 controls, Results/replay and Town captures under Linux Xorg/Mesa Compatibility. Main-viewport 3D was disabled beneath opaque menus/presentation; the matchday SubViewport rendered the actual park normally. Full-prep setup uses surface fixtures. Existing occasional ObjectDB teardown warnings and prior physical-pad, Windows, Forward+ and human balance limits remain.

Replay explicitly reconstructs the latest presentation from the committed date; it is not a video recording, another hosted date, a new payout or a persistent league result. No save versions, financial rules, field layouts or input bindings for gameplay changed.

## Playable live matchday, fan routines and optional jobs

LiveMatchday adds a playable third-person visit sharing time with the matchday broadcast. The 47-second staged timeline stretches across a six-minute visit, with the final at roughly five minutes. Walk/broadcast transitions preserve the clock; ordinary menus freeze it. Visitors remain behind the active playing field, equipment stays stowed, and paid work/construction/manual checkpoints/tutorial replay are guarded until exit. The pause board provides an explicit End visit action.

Representative walkers reserve distinct actual seats, use public approaches, visit built concessions, react while seated, and head back through the gates after the final. Remaining batched spectators clear afterward. Explicit crowd metadata fixes duplicate-name batches missed by the old name-prefix visibility/removal logic. Soft yielding and bounded sidestepping avoid permanent aisle jams. Optional tasks implement held/stopped spill cleanup, a visible carried supply delivery at built concessions, and Eli following bounded player breadcrumbs to his section. Completion produces checks, thanks and a session service report, with no financial rewards or new save state.

- `test_live_matchday.gd`: **39 checks passed** headlessly and graphically. Coverage includes a real player-controller walk, shared-clock/pause behavior, RS broadcast switching and native Walk button, field boundary, conflicting work guards, held cleanup/no-work-while-moving, escort following, seated reactions, departure of every representative walker in the starter fixture, static-crowd clearing, unique reservations/exact represented attendance, concession unlock/pickup/destination delivery, return to sections, unchanged ledger/wallet, native pause-menu exit, broadcast exit focus, and aborting a carried delivery before a fresh visit.
- Fixture routine results: **11 of 16** moving supporters seated during play; **16 of 16** departed after the final with adequate simulated travel time. The concession fixture also returns supporters to sections. These are reproducible state/time fixtures, not measured human arrival or crowd-performance guarantees.
- Existing suites passed: matchday UI (25), matchday park (30), stadium life (29), modern UI (36), game-day gameplay (31), club gameplay (39), autosave (27), controller input (34), field save (28), contracts (36), shift gameplay (32). Total: **386 distinct checks** across twelve suites including live matchday.
- Reviewed actual cleanup-progress, live seating, final/departure and concession-job captures under Linux Xorg/Mesa Compatibility. The suite uses surface fixtures, teleports for job locations and explicit time advancement for deterministic routine checks; it separately exercises actual player movement and native UI/controller input. Script import and whitespace checks passed, with no script errors or failed assertions in the verified logs. Existing occasional ObjectDB teardown warnings remain.

Visits and optional jobs are transient; they do not persist across relaunch or grant additional credits/supporters. Seat entry/exit handoffs are decorative transitions, and soft spacing is not a general navigation mesh or physics crowd. NPCs have no colliders. The underlying baseball remains staged, with no physical ball adjudication or persistent league outcomes. Career/field save versions, payouts and layout signatures remain unchanged. Physical pads, Windows, Forward+ hardware, long-session crowd performance and human timing/balance remain unverified.

## Fan satisfaction, rotating events and matchday atmosphere

ParkSatisfaction combines a welcome baseline, the frozen paid prep result, visit-time seating/facilities, completed work and aggregate queue pressure into a capped 100-point/five-star review. Eligible visits reach the final and accumulate at least 30 on-foot seconds. Results offers an explicit once-per-hosted-ID service claim, worth at most 25 cr and 3 repeat supporters. Existing gate/prep/manager receipts remain unchanged; additional supporters influence later attendance demand. Service events rebuild from strict raw inputs and validated facility snapshots. Existing career v1/v2 files load unchanged; the first successful service claim atomically writes career v3. Manual field/autosave format stays v3.

One visit event rotates by hosted date and facilities: held litter cleanup, held rush service, or a visiting family needing directions. Rush completion lowers actual later customer waits. Supporter rigs now include upper/lower leg joints and bent-knee sitting, seated head movement and home-scoring cheers. PA captions with an existing chime announce match moments through the Ambience bus. Evening fixtures use an isolated dusk environment and four bounded floodlights, restoring the original sky/light resources on exit. Stadium rebuilds also refresh cached live scoreboard labels.

- `test_park_satisfaction.gd`: **45 checks passed** headlessly and graphically. Covers rating inputs/queue pressure, real job completions, one event per visit, explicit claim/focus/scroll, exact once-only credit/supporter changes, unchanged original receipts, repeat attendance demand, reloads, duplicate/tampered/unknown input rejection, frozen pending and saved facilities, v2→v3 migration and failed-save rollback/retry, day/night restoration, scoring/start PA captions/bus, all event types, actual rush wait reduction, and rebuilt scoreboard references. The eligible end-of-broadcast A input cannot automatically activate the newly focused claim.
- Other suites passed: live matchday (39), matchday UI (25), matchday park (30), stadium life (29), modern UI (36), game-day gameplay (31), club progress (35), club gameplay (39), ownership (19), career (28), autosave (27), field save (28), controller input (34), contracts (36), shift gameplay (32), stadium expansion (17), equipment upgrades (30), audio (27). Total: **587 distinct checks across nineteen suites**.
- Actual Linux Xorg/Mesa Compatibility captures reviewed for the visible review/claim, dusk/floodlit field and PA caption, concession event, and articulated seated crowd. The close-up crowd view uses a temporary review camera with the HUD hidden; other captures use the actual gameplay/presentation UI. Surface completions, explicit times, job-position teleports and ledger-funded side work are fixtures, not a human season playthrough. Script import and whitespace validation passed; no script errors or failed assertions remain in the verified logs. Existing occasional ObjectDB teardown warnings remain.

Unclaimed visit reports remain transient and must be claimed before moving to another hosted date or relaunching. Claimed reviews persist and cannot be replaced by replaying or later purchases. Career v3 is not readable by older game builds. These are prototype reward weights and aggregate queue metrics, with no human economy/long-session balance audit. PA uses text and a chime, not recorded speech; baseball and crowd navigation retain their prior staged/authored-path limits. Physical pads, Windows, Forward+ hardware and large-crowd performance remain unverified.

## Job feel, team identity and six-date season audit

- `test_season_polish.gd`: **30 checks passed**, including visible broom/cleanup pose, stationary arm motion, release cleanup, dedicated crate pose, six opponent identities, six settled reviews, legal tool/stadium purchases, nonnegative budgets, all event types, season ownership review, recurring-character finale text, exact v3 reload and full money reconciliation. Completed prep/service are explicit audit fixtures; no side-work income is injected.
- Existing live matchday (39), satisfaction (45), matchday UI (25), matchday park (30), stadium life (29), controller input (34), tutorial (33) and equipment upgrades (30) passed. **295 distinct checks across nine suites**.
- Reviewed actual software-rendered sweeping, carrying and Owls-uniform views. The uniform capture repositions only the review camera. Scripted season results and limitations are committed under `docs/audits/`. Prices, payout rules and save formats are unchanged.

The six-date graphical audit passed its assertions but Mesa Compatibility reported four texture-leak errors at renderer shutdown (349,524 bytes each); no script errors occurred. This teardown issue is not resolved by this pass. Physical controller feel, Windows/Forward+ rendering, measured human prep times, full-season fun and long-session resource behavior remain unverified.

## Ballpark expansion along the foul lines

Starter seats remain behind home plate; bleachers add one 60-seat section per line, and covered seating adds two further sections per line (480 seats total). The first-base wing starts farther out to preserve the workshop/equipment area. Concessions face the outer promenades. Shared sideline transforms drive seats, static/moving crowd orientation, section access, service destinations, staff, localized audio and presentation cameras. Upgrade descriptions now explain their locations. Prices, reward rules and save formats are unchanged.

- `test_ballpark_growth.gd`: 31 checks covering 120→240→480 physical seats, both lines/facing, unique transformed seat/access mappings, sampled full routes clearing solid buildings, native player movement from home concourse to both counters, delivery at the relocated counter, public-wing access and field exclusion, queue facing, localized sound/camera location, fans reaching all eight sections and departing, and exact career reload. Prep funding and fan travel timing are controlled fixtures; native movement uses accelerated simulation.
- Existing stadium expansion (17), live matchday (39), matchday park (30), satisfaction (45), stadium life (29), matchday UI (25), season polish (30) and club progression (35) suites passed: 281 distinct checks across nine suites. Field layout checks also passed.
- Linux Xorg/Mesa Compatibility renders review the starter, bleacher and covered stages plus a close concession view. Overview images use a temporary orthographic review camera. The final graphical run passed all 31 checks without script errors; this environment fell back from Vulkan to OpenGL 3 and dummy audio, so it does not validate hardware rendering or audible spatial placement. Human route pacing, Windows/Forward+ and physical-controller feel remain unverified. Earlier runs reported renderer texture leaks, and the headless growth run reported an ObjectDB shutdown warning; these remain unresolved and this pass is not a long-session resource audit.

## Ordered maintenance: baseline and Task 1

Branch: `maintenance/save-safety-career-v4`, based on `5fdbacf`. Every top-level `tests/test_*.gd` is launched headlessly with a separate writable XDG data/config/cache root per suite and stage. Exit status and logs are checked for both `ERROR:` and `SCRIPT ERROR:`; an exit of zero alone does not pass. Capture-only scripts have a 12-second timeout because headless RenderingServer never emits their awaited rendered frame; other scripts have 120 seconds. No assertions were relaxed.

Baseline: **42/58 suites passed**. Sixteen graphical capture suites timed out headlessly; some also reported pre-existing headless UI assertions: `test_club_visual`, `test_contracts_visual`, `test_equipment_visual`, `test_save_visual`, `test_sound_visual`, `test_wear_visual`. The other timed-out scripts were `test_career_visual`, `test_chalk_visual`, `test_drag_visual`, `test_field_layout_visual`, `test_inspection_visual`, `test_onboarding_visual`, `test_shift_visual`, `test_tamping_visual`, `test_visual`, `test_watering_visual`. These are baseline failures/unverified graphics, not passing headless tests. No regular headless suite failed. Stage logs are retained under `/tmp/firstpitch-maintenance/` during this workspace session.

Task 1 adds empty `docs/.gdignore` and removes 126 committed documentation import sidecars. Search of scripts, tests, tools, scenes, resources and project settings found no `res://docs` loads. Markdown/GitHub screenshot paths and source images are preserved. This prevents documentation imports and resource exports without changing gameplay.

Task 1 full rerun: **42/58 passed**, the same sixteen pre-existing graphical/headless limitations as baseline. No new failing headless suites. `git diff --check` passed.

### Task 2 — redundant checked save recovery

`SaveRecovery` shares the 8-byte magic/SHA-256/payload envelope, flush/error checks, backup preservation and replacement for career/manual/autosave files. Load order is main → `.tmp` → `.bak`, with full format/domain validation before acceptance. A recovery source remains intact until promotion succeeds; recovery is visible through career/manual/autosave notices. Missing main plus any damaged artifact blocks fresh-career creation. All-invalid manual/career slots refuse writes; truly damaged autosave artifacts retain the existing quarantine behavior, now for all three copies.

Full rerun: **43/59 passed**, with exactly the same sixteen baseline graphical/headless failures. New recovery suite: **17 checks passed**, including missing main/valid tmp, corrupt main/valid backup, checksummed-but-invalid tmp rejection, all-corrupt refusal/preservation, normal round trips and autosave recovery/quarantine. Existing corruption tests explicitly remove the newly introduced good backup to retain their original irrecoverable fixtures; their rejection assertions are unchanged. Linux replacement/recovery was tested; real Windows interruption, hardware power-loss durability and antivirus/file-lock behavior remain unverified. Redundant flushed copies address the documented Windows destination-delete gap; this is not a claim of atomic Windows rename.

### Task 3 — shadowing and unused names

The shared checksum helper already replaced CareerProfile's old `hash` local; FieldSave's digest local is now `context`. Godot's debug script-loading diagnostics found and drove renames for shadowed `sign`, `basis`, `position`, `seed`, `start`, `reference`, `ring`, `surface_material`, `size`, `owner`, `ready`, and `impact`, plus the unused style color parameter. References to renamed tool placards were updated. A fresh `--headless --debug` load of every `scripts/` script reports no shadowing/built-in/unused-variable or unused-parameter warnings. Existing integer-division notices are unrelated and unchanged.

Full fresh-root rerun: **43/59 passed**, with the same sixteen baseline graphical/headless failures. One earlier run hit the existing 50-ms seeded-wear timing assertion under overlapping test load; the clean full rerun passed it without changing the assertion. A test-harness retry initially reused old backup files; final runs use freshly cleared per-stage/per-suite roots. No save-format or gameplay-rule changes were made in this task.

### Task 4 — formatting only

All 117 GDScript files under `scripts/`, `tests/` (including fixtures), and `tools/` now use tabs. gdformat **4.5.0**, with its syntax/AST safety checks enabled and a 110-character target, successfully handles this project's Godot 4.6.3 syntax. Large profile/upgrade/project dictionaries now have separate key lines. Thirty-nine long string literals were wrapped as constant concatenations; the wrapping script asserted that every concatenation preserves the exact original literal contents. There are no lines over 200 characters, no space-indented code lines, and just one formatter-retained 131-character property-assignment line. No values, tests, branches, or algorithms were changed.

Full rerun: **43/59 passed**, the same sixteen baseline graphical/headless failures; all existing test assertions are unchanged in this commit. `git diff --check` passed. This task makes no new Windows or hardware-rendering claim.

### Task 5 — named jobs and extracted HUD text

`CrewJob` defines stable MOW/DRAG/CHALK/WATER/MOUND indices 0–4 and is used by selection, progress/quality arrays, inspection, tutorial baselines, result validation, and their tests. Coordinate, base and tutorial-step indices retain their distinct meanings. `HUDText.mode_text()`/`prompt_text()` own presentation decisions; the on-foot mode uses a plain match. Camera, reticle and tool behavior remain in game.gd. Binding formatting and reminder strings are built by the existing device-change refresh, rather than every frame.

Before extraction, 24 actual tool/proximity states were captured on both keyboard and controller. The committed reference JSON remains independent of the helper. `test_hud_text.gd`: **99 checks passed**, comparing all 48 exact mode/prompt pairs, binding-cache reuse/invalidation and saved enum values. Full rerun: **44/60 passed**, with the same sixteen baseline graphical/headless failures. No wording, physics, prices, goals or saved indices changed; real Windows/controller hardware remains unverified.

### Task 6 — measured autosave validation cost

Six warm full-field samples before/after optimization, on this Linux host (milliseconds, mean):

| Component | Before | After |
| --- | ---: | ---: |
| Main-thread capture, including layout signature | 1.092 | 1.013 |
| Strict validation of newly captured snapshot | 101.405 | 0.000 |
| `var_to_bytes` | 0.369 | 0.320 |
| SHA-256, including checked prior bytes | 10.726 | 11.738 |
| Prior-file domain validation | 101.179 | 0.000 |
| Prior payload decode | 1.055 | 0.000 |
| File read/backup/flush/replace and envelope overhead | 2.106 | 1.446 |
| Total | **218.122** | **14.638** |

Raw samples: `audits/autosave-profile.json`. Baseline's original autosave check measured 112.697 ms before Task 2 introduced redundant prior-file validation. `tools/profile_autosave.gd -- fast` reproduces the optimized live-capture benchmark; without `fast` it measures today's strict manual path, not the historical implementation.

Only production autosave opts into trusting a freshly captured live-model snapshot. Manual save validates fully. Every load and recovery still checks checksum and complete domain validity. The writer can recognize exactly matching previously checked/generated bytes by SHA-256 when preserving the prior main file; changed bytes and recovery candidates cannot use that shortcut. Hashing, flushed redundant backups and replacement are retained. Captures are owned byte/array snapshots. No thread was added: the measured improvement avoids validation work while preserving synchronous completion, non-overlapping writes and the existing quit-time contract. Larger chalk archives, slower Windows disks, antivirus and hardware frame pacing remain unmeasured.

Full rerun: **45/61 passed**, same sixteen baseline graphical/headless failures. New autosave-performance suite: **8 checks passed**, including valid optimized saves, strict rejection of freshly checksummed malformed data on load, strict manual rejection and synchronous completion. Existing separate-process quit/resume/once-only tests and all save-recovery tests passed.

### Task 7 — authoritative career v4 and frozen legacy migration

V4 saves current wallet/lifetime earnings, completed count, bests, upgrades, the complete required club state, pending/paid/hosted/serviced IDs, frozen receipts/service inputs/target outcomes, actual paid purchase costs, and compact season closing snapshots/objectives. Attempt results/pay and club events remain logs. New transactions update copied state and publish only after the shared checked write succeeds. History, recap, schedule and ownership UI use frozen wages/targets/receipts rather than recomputing historical economics. Structural validation checks types/ranges/known IDs/duplicates and state-log references without replaying prices, scoring or payout rules. See `CAREER_V4.md`.

Pre-v4 profiles, economics, service weights and result validation are frozen in `LegacyCareerRules`, `LegacyShiftSession`, and `LegacyParkSatisfaction`. `ClubProgress.legacy_replay()` traverses old events once while collecting season snapshots. Conversion reuses that validated context rather than replaying it again. The original bytes are kept as `<basename>.v3.bak`; a distinct timestamped name avoids overwriting a different pre-existing legacy backup. Failed backup/migration writes preserve files and block financial changes. `tools/audit_club_balance.gd` now exercises actual v4 transactions through a validation-preserving, file-free adapter; all six modeled routes retain their previous purchase dates.

Immutable pre-v4 fixtures were recorded at `8563cc1` before introducing v4. `test_career_v4.gd`: **76 checks passed**, including exact v1/v2/v3 wallet, earnings, rank, upgrades, bests, every club counter/receipt/pending/service field, schedule and ownership/season review; one legacy validation per migration; no legacy calls on subsequent v4 reload/commit; historical goal/pay/price differences; current rules for new work; structural rejection; and once-only payouts across real autosave restore/repeated resume. The original compressed v1 field fixture and field/autosave v1–v3 checks remain intact. The existing six-date route passes under v4.

Judgment call: raise the career envelope ceiling from 4 to **16 MiB**, without changing the 2,000-attempt limit or gameplay numbers. A valid maximum-length v3 fixture fits the old limit but expands to **4,493,248 payload bytes** under v4. It now migrates and reloads without truncation, replay or changed funds. This regression guards against rejecting legitimate full old careers solely because the new format stores more state.

Task 7 final full rerun: **46/62 passed**, the same sixteen baseline graphical/headless failures. All 76 v4 checks, the six-date route, old career/gameplay/equipment/club/season/save/autosave tests, and strict corruption/recovery checks passed. A debug load of every production script reports no new shadowing/built-in/unused-name warnings. `git diff --check` passed. Migration and recovery were tested on Linux; real Windows interrupted writes, Forward+ hardware, physical controllers and human progression timing remain unverified.

### Task 8 — optional local playtest timing log

`PlaytestLog` observes existing session changes and appends one CSV row per finished attempt when `-- --playtest-log` is passed. It records UTC/profile/end reason/elapsed, first observed per-job goal times, score, settlement pay and attempt ID. Default-off operation performs no log file I/O. Existing IDs are read to suppress duplicate rows after recreation; log failures remain independent of successful career settlement. A command-line opt-in was chosen from the requested alternatives, preserving the current settings UI. Already-met goals whose earlier timing was not observed on resume/enabling stay blank; no invented timestamps or save-format fields are introduced.

New `test_playtest_log.gd`: **10 checks passed** for default-off/no file, real finished shift/goal timing/score/payout, duplicate suppression in-process and after logger recreation, unfinished jobs, and non-blocking logging failure. Final full rerun: **47/63 passed**, the same sixteen pre-existing graphical/headless failures documented at baseline. All regular headless suites, migration/maximum-career checks, save recovery, strict loads, autosave quit/resume and the six-date audit passed. No gameplay or balance numbers were changed. Human timing sessions, real Windows filesystems, Forward+ hardware and physical controllers remain unverified.

## First-person gameplay conversion

Branch `feature/first-person` builds on the completed eight-commit maintenance branch. Gameplay now uses a direct 1.65 m standing eye, tractor-seat eye or chalk-handle eye, with FOV 78 and a close 0.045 m near plane. The old spring arm, orbit distance and wheel zoom are removed. Mouse/controller share ±1.35 rad look limits; equipment views follow turns while preserving free-look offset. There is no cosmetic bob or positional camera lag. Existing controls, physics, tool limits, balance and save formats remain unchanged.

The local character/driver/pusher casts shadows without obstructing the eye camera. Camera-specific gloves and held tool meshes are excluded from the optional broadcast viewport. Watering has a visible nozzle/grip, finer translucent droplets and a continuous obstacle-clipped visual stream; its tube and hose segments scale along their rotated local axis. Tamper rest orientation follows the eye when looking down while real impact checks remain unchanged. Sweeping and carried Owls crates have matching visible grips. Live/broadcast return, safe equipment exits and field/reset/load paths restore eye placement. Controls and README now describe look rather than orbit.

- `test_first_person.gd`: **29 checks passed headlessly and graphically**, using actual player cameras and native held actions for watering, timed tamping, moving mower-seat attachment, chalk coverage, both equipment exits, controller look bounds, no wheel orbit, visible in-frame grip projections, stream endpoints, sweeping/carrying and broadcast return. Gameplay and save compatibility checks passed. Work setup/teleports are explicit repeatable fixtures; the suite is not a human playthrough. Graphical simulation disables rendering between capture points for software-renderer efficiency; captures render the actual game normally.
- Full final rerun: **48/64 suites passed**, with exactly the same sixteen baseline headless-incompatible graphical scripts described in the maintenance baseline. All regular suites passed, including the 76-check v4 migration/maximum-career suite, the six-date route, strict saves, autosave/recovery/logging, all tools, tutorial, controller and stadium progression. The earlier 48/64 pre-refinement run also passed; the final run adds grip projection and exact stream endpoint coverage.
- Actual Linux Xorg/Mesa OpenGL Compatibility screenshots reviewed for walking, watering, tamping, mower driving, chalking, sweeping and carrying; committed as `docs/screenshots/fps-*.png`. The final graphical first-person run has no script/runtime errors; the virtual display warns that V-Sync changes are unsupported. Dummy audio does not verify audible output. Editor import and whitespace checks complete the verification. Prior historical teardown warnings remain documented, not declared resolved.

Human first-person comfort, sensitivity/FOV preference, Windows filesystem behavior, Forward+ hardware, physical controllers and long-session resource/performance behavior remain unverified. Optional matchday broadcasts intentionally remain spectator presentations; all player-controlled modes use first person.
