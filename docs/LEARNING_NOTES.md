# Learn the prototype

## Scenes and nodes

A node does one job: a mesh draws, a collision shape defines contact, a camera views, and a CharacterBody3D moves under scripted collision rules. A scene saves a reusable group of nodes. Main loads the stadium, groundskeeper, and mower scenes, then connects them. Their scripts generate the prototype meshes in `_ready()`, so the source scenes stay small. The editor's Remote scene tree shows those generated nodes while playing. A later art pass can replace the generated visuals with authored child scenes without replacing the controllers.

## Player and camera

`player.gd` reads the movement vector and rotates it by the camera's horizontal angle. This makes W move toward the view instead of a fixed compass direction. Gravity and jumping change vertical velocity. `move_and_slide()` handles contacts with terrain and walls. `game.gd` smoothly interpolates the camera pivot toward the active actor. A SpringArm3D retracts the camera against buildings; the player and mower are excluded so they cannot push their own camera forward.

Experiment with `walk_speed`, `sprint_speed`, camera distance limits, and camera follow smoothing. The input actions are registered in `configure_input()` to keep the native project self-contained.

## Interaction and signals

Main owns the switch between walking and driving. The mower can be entered within 3.5 m. Entering hides the player and disables its collision and movement. Exiting is allowed only below 0.5 m/s; a physics shape query checks each side before restoring the player. This prevents two controllers from responding to the same keys at once.

Signals announce events without requiring one component to know every listener. `completion_changed` tells the HUD a new percentage is ready. `occupied_changed` is available for future seat animation or audio listeners. Input-driven control changes stay in main; mower steering and grass accounting remain separate.

## Mower physics

`mower.gd` uses CharacterBody3D rather than a simulated suspension vehicle. It gradually moves signed speed toward a target, turns according to speed, calculates horizontal velocity from its forward direction, and calls `move_and_slide()`. Negative speed reverses both travel and steering response. Wall contacts stop its drive speed. Wheels animate around their axles; the steering wheel reflects turn input.

Try the exported `max_speed`, `reverse_speed`, `acceleration`, `braking`, and `steering_rate` values. Avoid changing the rigidbody physics settings: this mower is deliberately not a RigidBody3D.

## Grass mask

`grass.gd` maps world X/Z into a bounded texture grid. Each cell has a validity flag and a cut flag. Validity follows the fair-territory wedge inside the warning track, excluding the dirt diamond and home area. The score denominator is the number of valid cells, not the texture size.

The deck paints a circular footprint with a 2.4 m diameter. Sampling along each movement segment closes gaps between physics frames, including diagonal travel. A cell increments the score only on its first cut. The RGBA texture uses red for cut state, green for direction shading, and alpha for grass validity. The shader discards invalid cells so the dirt beneath remains visible.

The mask is modest (450 × 330). A dirty flag batches full uploads to at most 10 Hz; idle grass uploads nothing. This is simpler than a partial-update rendering pipeline and has predictable small upload size. CPU footprint work only visits a local bounding box around the cutting deck. There is one grass surface and one MultiMesh batch for the sparse uncut tufts, not a node per blade. Session state stays in the same grass node when you leave the mower.

Try `deck_width`, the scene resolution override, and `update_frequency`. Mask origin/size and geometry now come from `FieldLayout`; zero resolution selects its default. Shader colors are in `shaders/grass.gdshader`. The shared geometry/scoring source of truth is implemented, as described below.


## The visual pass

Appearance is now separated further from controls. `CrewVisual` builds both the standing groundskeeper and a seated pose. Walking rotates the four limb pivots using a sine wave; there is no animation rig or skeleton. `MowerVisual` builds the tractor details and returns the deck, wheel, steering, and driver references to the controller. Driving physics still own movement; the visual class owns appearance.

`ParkProps` groups the workshop, dugouts, stands, scoreboard, light towers, benches, and trees. Each group has its own origin, so details can be designed in local coordinates. Repeated seats use MultiMesh: many transforms reference one mesh and material, keeping the render batches small. Color materials are cached and shared, so treat returned standard materials as immutable. Use a separate material when a prop needs custom settings.

The grass tuft shader reads the same mask as the ground. A freshly cut cell hides its blades instead of relying on the vehicle to delete individual objects. All 28,000 tufts are deterministic and live in one batch. Set `tuft_count` to zero on the grass scene to disable this visual layer for slower hardware; the score and flat cut stripes still work. Shadows are disabled on these tiny blades to avoid flicker and excessive rendering cost.

Try the colors and dimensions in `ParkProps`, the visual proportions in `MowerVisual`, the sky/sun settings in `stadium.gd`, and the color gradients in the grass shaders. The infield grass island is deliberately decorative and remains excluded from the outfield mowing objective.


## M4: Dirt, attachments, and task selection

`InfieldSurface` follows the mowing mask's broad idea without inheriting its circular cutting footprint. It builds a 250 × 265 grid for dirt basepaths and the work area around home plate. The decorative lawn, bases, mound, and batter/plate area are invalid cells. Red stores prepared state, green/blue store drag heading, and alpha stores validity. Each valid cell increments progress just once. Uploads happen only when dirty, at most 10 times per second.

The dirt shader is applied directly to the stadium's existing diamond and home-area meshes. World X/Z maps those meshes into the state texture. This avoids a second dirt plane fighting for depth with the stadium surface. Protected cells retain their dirt appearance, rough cells have clumpy variation, and prepared cells show a lighter finish with subtle heading-aligned grooves. Texture variation changes appearance; the terrain stays physically flat.

`DragAttachment` draws the frame, grid, and tow bars. Its lowered visual follows the existing shallow dirt heights. It has no independent rigidbody or collision shape. The tractor owns movement, and each physics step sends the rear attachment's travel segment to `InfieldSurface`. The footprint is an oriented rectangle rather than a circle. Sampling along that segment closes gaps between frames. Reverse and raised travel do not prepare dirt. Turning uses the current heading for each short sweep; there is no independently articulating trailer.

`ToolBay` checks the tractor's distance from the workshop rack. Main also checks that the player is on foot, nearby, and that the tractor is stopped before allowing Q to change tools. `RidingMower.set_tool()` changes the visuals and emits `tool_changed`. Main uses that signal to update the rack and objective. R raises a working drag immediately, but lowering requires a stopped, occupied tractor. Each task keeps its own state while the other tool is equipped.

Try `working_width` and `working_depth` on the drag, `dragging_speed` on the tractor, the bay's `service_radius`, and the dirt grid resolution/update frequency. The next architectural step for multiple stadiums is now done: `FieldLayout` supplies shared dimensions and mask exclusions rather than duplicated coordinates.


## M4: Chalking as a separate walking tool

`ChalkMarker` is a small CharacterBody3D with its own speed, collision, steering, brake, gate, wheels, and pushing character visual. Main transfers control to whichever nearby piece of equipment is closest, hiding the ordinary walking character while that tool's operator visual is active. The shared side-exit query checks space before restoring walking. The marker's collision footprint includes its handle/operator space; it is an arcade push tool rather than a rigidbody handcart.

The R action is contextual: it lifts/lowers an occupied tractor's drag or toggles the occupied chalk marker's gate. Each actor reads WASD only while occupied. Leaving the marker closes the gate. The controller records only forward, grounded travel while the gate is open; closing or reopening resets its stroke anchor, so a closed-gate move does not create a connecting stripe later. Wall-contact handling also checks actual horizontal displacement, because a floor recovery contact can hide a wall slide report and leave a tiny requested speed behind.

`ChalkSystem` draws the stroke where the nozzle actually travels. Small ribbons follow the park's known surface heights. New geometry is queued and committed at most 10 times per second in batches of 128 strokes. Finished mesh batches stay in the scene for the session. No broad field material swap or per-sample node is required. Repeated passes can add visual geometry, but they cannot increase already-earned coverage.

The foul-line objective uses two one-dimensional sets of approximately quarter-meter sections. For each swept nozzle segment, the system tests nearby section centers against the chalk footprint. The bases/plate are protected and excluded. Left and right counts have separate denominators. Off-guide chalk is drawn, but it cannot mark a target section that its footprint did not reach. The gold dashed guides themselves start with zero coverage.

Main remembers the selected task when you leave a tool. Returning to the tractor or changing its attachment restores its mowing/dragging objective. The HUD shows all five percentages and a left/right breakdown while chalking. Completion uses exact tracked counts rather than a rounded percentage, so nearly finished work cannot prematurely declare the park ready.

Try `push_speed`, `steering_rate`, and `stroke_spacing` on the marker; `chalk_width`, `section_length`, and `update_frequency` on the chalk system. Line bounds, surface heights and exclusions now come from the shared layout resource. Unlimited chalk and no erase/undo remain prototype limits. Manual saves now preserve chalk through a stroke archive; they do not add quality or supply mechanics.


## M4: Water exposure and the on-foot hose

`DirtMoisture` uses the same valid dirt cells as `InfieldSurface`, but keeps its own floating-point moisture array and qualified-cell flags. Each physics step adds application rate × elapsed time × distance falloff inside a circular footprint. A cell contributes once after reaching the target moisture. Values saturate at one. The model has no drying or overwatering penalties, so qualifying progress persists for the session.

A small R8 texture carries moisture to the existing dirt material. Dirty changes upload at most 10 times per second; idle data is not re-uploaded. The shader multiplies the dirt color by a moisture-dependent darkening factor and reduces roughness. It does not replace the dragging mask or the separate chalk meshes, so those systems retain their patterns and counts.

`WateringTool` owns the station, held nozzle, hose mesh, droplets, ground-ring indicator, and camera aiming. It rays through the center reticle into the physics world, then separately checks the path from the nozzle to the target. This prevents the third-person camera from watering around a wall that blocks the character's hand. Pickup range, hose reach, nozzle reach, grounded player state, equipment state, and cursor capture all gate spraying. Entering another tool stows the hose before transferring control.

The droplet stream is one MultiMesh with 36 instances. The hose is one small tube mesh rebuilt only when its endpoint moves and at no more than 10 Hz. It follows a curved ground route using the park's existing surface-height query. This is a visual approximation: it does not route around obstacles, simulate tension, constrain walking, or consume water. Reach limits prevent watering beyond the station's working range even though the character may walk farther away.

Desktop play reads the actual cursor mode. Godot's headless dummy display always reports a visible cursor, so the logic test supplies a capture-state adapter for this one OS detail. The graphical test uses the real cursor mode and verifies Escape blocks spraying while the spray action remains held. Camera rays, collision queries, walking, doses, progress, and equipment transitions still run through the real scene in the headless integration test.

Try the moisture scene's `spray_radius`, `application_rate`, `target_moisture`, and `update_frequency`, plus the station scene's `pickup_distance`, `hose_reach`, and `spray_reach`. A lower target or higher application rate makes the job faster. Larger radii cover more area but still respect protected dirt cells. Mound repair remains a separate future task rather than silently including the mound in the dirt-watering objective.


## M4: Mound patches and timed impacts

`MoundSurface` tracks six explicit repair patches rather than a large grass/dirt mask. Each patch has an integer hit count, a small material, and a few visual clay clumps. Three accepted strokes fill its compaction state. Each impact increments work once, updates only that patch's shader uniform, and shrinks its clumps; a finished patch cannot earn extra work. The shared base-color noise makes the finished patch blend back into the mound.

`TampingTool` separates a requested click, a windup, the contact instant, and recovery. Left-click input is queued to the physics loop. At contact, the controller rechecks that the player is grounded and stationary, still aims at the same patch, remains in reach, has an unobstructed hand-to-patch path, and has a captured cursor. Only then can `MoundSurface.apply_tamp()` run. Looking away or moving during windup therefore cannot repair a remote target. Click spam cannot queue additional strokes while busy. Escape, stowing, or entering equipment cancels an unfinished swing.

The visual tamper follows a simple windup/contact/recovery path, with arm posing and one small instanced clay-dust effect. This is not inverse kinematics or a skeletal animation. The physical mound itself is a convex frustum: a 2.8 m base radius, 2.2 m plateau radius, and 0.36 m height. The gentle edge is walkable with the existing CharacterBody3D controller. The shared surface-height query was updated so hose and chalk visuals follow that slope too.

Main makes the hose and tamper mutually exclusive and stows either before handing control to a vehicle or marker. The fifth objective uses actual accepted-impact counts. Whole-park readiness requires full counts from all five tasks; the rounded percentage text is not used as the completion rule.

Try `mound_patches` and `mound_patch_radius` on the layout, `hits_required` on the mound scene, or `working_reach`, `stroke_duration`, and `contact_time` on the rack scene. Keep contact time shorter than total stroke duration. Patch disks should remain on the plateau and away from the pitching rubber. Mound position, shape and projected height now share the same layout.


## M5: Shift lifecycle and clean restarts

`ShiftSession` owns practice/active/finished state, profile quotas, elapsed time, proportional scoring, and deep-copied results. It consumes raw task percentages plus exact full-count flags; rounded HUD text cannot complete a full goal. Each job is worth 20 points. An incomplete attempt is capped at 99.9; completion wins if goals are reached on the deadline frame.

`ShiftDirector` collects the five existing models, advances the active clock, and coordinates fresh starts. Each model exposes `reset_state()` to clear both accounting and visible work. Reset also stows hand tools, cancels windups, clears chalk meshes, parks vehicles, raises/closes attachments, and restores the player/camera. Active attempts cannot be reset through a fresh-start request.

`ShiftOverlay` processes while the SceneTree is paused. Opening the board cancels an unfinished tamp and releases held tool actions; closing releases them again so a GUI click cannot become a spray or strike. The previous mouse mode is restored. Results are snapshots: later practice may change the field but cannot revise the last score. Profile durations and goals live in `ShiftSession.PROFILES`; quality simulation is not implied by the score.


## M5: Manual field persistence

`FieldSave` captures raw RGBA mask bytes for mowing and dragging so direction shading survives, full floating-point moisture for partially soaked cells, chalk coverage plus a small quad archive, and per-patch mound hits. It rebuilds counters from those arrays rather than trusting saved totals. Chalk keeps the same mesh batching; the archive additionally retains completed batches and strokes awaiting upload. Loading recreates those meshes, including off-guide marks.

The resource-free Variant payload has a format version, a SHA-256 layout signature, and a checksum header. Reads are bounded to 32 MiB and use object-disabled decoding. Layout, dimensions, protected cells, numeric ranges, stroke geometry, session clocks, and reconstructed result scores are validated before calling `reset_field()`. Temporary-file writes are flushed and renamed over the slot, keeping the old slot if replacement fails. This guards accidental corruption; it is not an anti-cheat format.

`ShiftDirector` connects the board's explicit save/load buttons. Loading stows tools and parks equipment using the existing reset lifecycle, then restores field state and session data. The world stays paused until the player resumes. Positions, motion, camera angle, hand-tool animations, and held inputs are deliberately not serialized. Save files live under Godot's `user://`, never in the project directory. There is one manual slot, no autosave, no automatic startup load, and no cloud sync. The recorded Cedar Grove v1 field now has an explicit v2 migration.


## Sound: Separate presentation from accepted work

`GroundsAudio` reads the existing controllers for the engine, hose, drag, and chalk loops. Pitch follows actual mower speed. Short volume ramps avoid hard starts/stops. World players inherit pausing; the results/preview player explicitly processes during pause. Footsteps accumulate horizontal distance only for a grounded walking player and discard teleport-sized jumps. Fresh starts and loads stop old tool tails.

The hand tamper emits `impact(point)` only after `MoundSurface.apply_tamp()` accepts the controller's timed contact. Audio listens to that event, rather than watching the mound counter: loading hits, resetting, missed strokes, and repeated strikes cannot generate fake impact feedback. Other model accounting is unchanged. Positional effects attenuate with distance, but do not yet model walls or acoustic occlusion.

`SoundPreferences` owns two effects/ambience buses feeding Master, clamps finite numeric settings, restores safe defaults for malformed fields, and persists a separate small ConfigFile. Zero levels use bus mute for true silence. Failed writes report that the live change could not be saved. `SoundPanel` is a separate screen inside the paused overlay so controls do not crowd the checklist. The waveform generator uses deterministic standard-library synthesis, mono 16-bit PCM at 22,050 Hz, with quiet loop joins and bounded amplitude; no downloaded recordings or runtime synthesis dependency is required.


## Field enclosure and dugout orientation

The diamond points toward negative Z, with foul lines at X = ±(-Z). `ParkProps.dugout()` now places each dugout along its side's boundary direction and rotates its local +Z opening toward the diamond. Walls and the roof sit on the foul side; the front rail leaves walk-in gaps at both corners. Floors stay nearly flush so the walking controller needs no new step-climbing behavior.

`Stadium.build_foul_boundary()` joins the backstop, dugout wings, side fencing and returns to the existing foul-pole/outfield-wall junctions. The first-base side has a broad open equipment gate around the existing pad. Fence visuals use one alpha-discard quad per run with UVs measured in meters, plus posts and rails; separate thin box colliders block traversal. The shader draws holes but the collision intentionally remains a continuous fence. Gate leaves lie outside the driving corridor.

The work grids, task exclusions, equipment spawn points and save layout signature are unchanged. This pass changes enclosure geometry, not field dimensions or job quotas. Outside walkways are decorative surfaces rather than additional scored dirt.


## Static field reference markings

`FieldMarkings` keeps the fixed plate, batter's boxes, coaching boxes and on-deck circles separate from `ChalkSystem` and its playable foul-line strokes. Dimensions use meters converted from inches/feet. Coaching boxes use the foul-line direction and outward normal; both rectangles stay in foul territory. On-deck circles sit inside the foul-side fence, away from dugout walk-in openings.

The home plate is a flat five-sided triangle mesh rather than a regular five-sided cylinder. Its rectangular front faces the pitcher and its point faces the backstop. A slightly larger dark underlay outlines it. On-deck paint uses a flat annulus rather than a raised torus. These surfaces need Godot's clockwise front-face winding as viewed from above; vertex normals alone do not prevent back-face culling. None of these details adds collision or enters the saved task masks.


## Career: Durable rewards and useful purchases

`CareerProfile` keeps an append-only attempt ledger and owned upgrade IDs. Wallet balance, lifetime earnings, rank, completion count and personal bests are derived from validated frozen results and purchase costs, rather than trusting saved totals. Training pays floor(score) plus 50 for completion; full prep pays floor(3 × score) plus 150. Ending early or timing out still pays for measured work. Zero-work attempts are recorded with zero pay. Free practice never emits a finished shift.

A cryptographically random 128-bit attempt ID is assigned by `ShiftSession.start()`. `FieldSave` adds it as an optional field without invalidating old version-one saves. Older snapshots receive a stable hash-based identity on restore. Finishing the same ID again returns the original receipt without improving or duplicating its payout, even if a rewound playthrough later earns a higher score. Loaded finished results do not automatically claim rewards; the career retry action can settle an unpaid current result.

The career file has its own bounded, checksummed, resource-free payload. A complete candidate ledger is validated, flushed to a temporary file, and renamed before in-memory money, purchases or upgrade effects change. Failed writes leave confirmed progress untouched. Corrupt files are kept and block further financial changes; the UI exposes reload/retry. This is local save integrity, not an anti-cheat or multi-process synchronization system.

`ShiftDirector` owns the career and applies upgrade multipliers from captured scene defaults. The wide deck scales its visible mesh and spare deck and raises the actual grass footprint by 25%; the nozzle raises moisture application rate by 25%. Effects are derived from the current career after startup and purchases, so loading field work cannot revert them. Fresh shifts reset task state while retaining owned equipment. Scene fixtures override the exported `career_save_path` before `_ready()` to isolate synthetic results from the player's profile.

`CareerPanel` is another paused screen within the board, with scroll fallback for small windows. Lifetime earnings drive four crew ranks independently of spending. The recent list shows the latest five attempts; the prototype retains at most 2,000 to bound decoding and validation. More parks, contracts, migration and expanded progression remain future work.


## Focused contracts and requested-job scoring

`ShiftSession.PROFILES` now describes training, full prep and three contracts with duration, five fixed task slots, pay per score point, completion bonus and optional minimum lifetime earnings. Zero goals mean an unrequested job: it does not satisfy a goal, contribute points or appear on the active/result checklist. `jobs_required()` counts positive targets. Score divides 100 points equally among those jobs, keeping the original five-job profiles at 20 points each. Exact full-task flags still gate 100% goals; completion takes priority on the deadline frame.

`ContractsPanel` shows the selected jobs, deadline, maximum total payout including bonus, personal best and rank requirement. Starting routes through `ShiftDirector.start_shift()`, which rejects active, unknown or rank-locked requests before resetting the field. The first requested job is selected for the HUD. Earning 500 lifetime credits unlocks the two-job infield contract regardless of wallet spending. Offers are fixed and repeatable rather than scheduled online jobs.

Career payout now reads each profile's rate/bonus; training and full-prep terms remain unchanged. Derived best scores initialize for every profile. Field-save and career-result validation use the requested-job count rather than assuming five completed jobs. Result dictionaries and field layout remain compatible with earlier saves. Frozen result goal counts come from the snapshot, not later practice progress. Whole-park readiness continues using all five original exact field counters.


## Part 1: Shared FieldLayout resource — completed

`FieldLayout` is a Resource, with Cedar Grove's explicit configuration in `resources/layouts/cedar_grove.tres`. Main assigns the same resource to stadium, surfaces, markings, tools and equipment before `add_child()`, because construction happens in `_ready()`. Mask origins/sizes are resource-backed read-only properties; scene resolution remains a tuning override, with zero selecting the resource default. Moisture shares its infield surface's bounds. No new per-cell nodes or idle layout-processing loop was added. Existing packed arrays, state textures, dirty flags and upload throttling remain in place.

Base coordinates derive from `basepath_length / sqrt(2)`, with a 27.432 m (90 ft) baseline, rather than separately rounded axis coordinates. The drawn diamond and island give canonical outer/inner distances of `31 / sqrt(2)` and `22 / sqrt(2)`. Both scoring and height queries now use those edges. Previously independent rounded thresholds differed; removing those differences adds 124 grass cells and 138 dirt cells, with no previously valid cells removed. Chalk sections and mound work totals are unchanged. Height projection also uses the actual island/concourse top surfaces, eliminating their half-millimeter rounding discrepancies.

The geometry correction necessarily changes the saved layout signature. FieldSave now writes v2. Its only legacy migration recognizes the captured pre-refactor Cedar Grove v1 signature and the current canonical v2 signature. Immutable v1 validity arrays are bundled as a compressed native Resource, so old protected cells are still validated against the old rules. All old work and direction pixels remain intact; added cells are visible, rough/uncut and dry. Attempt IDs, clock, chalk strokes, mound hits and frozen results are preserved. Pre-career snapshots without an ID receive the original v1 fallback hash before migration, preserving the identity used for payout replay protection. Unknown v1 layouts and work that was invalid under the original masks are rejected before mutation. The compressed original save fixture was generated by main at commit `4ff75db`, not reconstructed using new geometry.

To configure a second park:

1. Duplicate `resources/layouts/cedar_grove.tres` to a new `.tres`.
2. Edit its dimensions, radii, mask bounds/resolutions, mound patches and equipment/structure placements together in the Inspector. Keep valid areas inside their mask bounds and equipment approaches clear.
3. Assign the new resource to the main scene's `layout` property (or to `game.layout` before adding the scene). Main propagates it before construction. Do not mutate the shared Cedar Grove resource at runtime.
4. Check the generated park and run the layout/resource tests. A different mask signature intentionally cannot load a Cedar Grove slot without an explicit migration. This configures a park; it does not add a career park-selection screen.

Game-day wear, quality penalties, tutorial, autosave and controller support belong to later parts and were not implemented in this refactor.

## Part 2: Game-day wear and finish quality

`FieldWear` uses a seeded RNG and layout-derived traffic regions. Its cached topology is built once when the director is ready; applying wear uses public packed-state snapshot/replace/recount APIs rather than writing surface arrays. It removes existing preparation, dries/recounts moisture, trims chalk quads and rebuilds coverage, removes mound hits and regrows grass. No per-cell nodes were added. Grass, dirt and chalk stop processing when clean; moisture processes only while dirty or drying active puddles. Dirty texture updates are capped at 10 Hz. Bulk start/load operations refresh immediately once.

Fresh training/mowing/mound jobs preserve the original blank reset. Full prep and infield jobs wear the current state. A wholly blank park first receives prepared dirt, 0.8 moisture, full chalk and repaired mound before wear; an already worked park never receives this bootstrap. This makes the first game day readable while preserving later work. The attempt ID's SHA-256 first unsigned 32 bits supply the wear seed. Loading restores the generated state directly; it never reapplies wear.

Each session stores five starting counts and totals. Repair progress is `(current-starting)/(total-starting)`; no work needed is complete. Exact full counts still gate 100% goals. Resetting counts after starting would invalidate that baseline, so normal model edits preserve unique flags. The separate whole-park HUD still shows absolute coverage.

All balance settings are in `ShiftSession.PROFILES`, with inherited `quality` and `wear_rules` defaults on training. Full prep wears at 0.55, Between-games at 0.45 and Doubleheader at 0.85. Heavy/light dirt and chalk probabilities are 0.85/0.12 times intensity. Moisture loses `0.7 × intensity`; initial host moisture is 0.8. Traffic radii are base 2.2 m, batter 4.5 m, holes 3 m, lanes 1.8 m. Chalk hotspots extend 8 m from home and 3 m from first/third. Mound rear loss weighs 0.55 versus front 1.0, with random loss fraction 0.65–1.

Quality begins at one. Chalk loses 0.005 per off-guide metre, bounded at 0.7. Water and drag each lose up to 0.25 proportional to overwatered/rutted cells against new qualified work. Puddles begin at 0.95, block dragging for 12 seconds, then dry to 0.7. Dragging above 0.75 leaves ruts; a later dry drag clears them. Puddle history remains penalized for the attempt even after drying. Neighbour cut headings within 0.15 of the stripe channel match; after 20 comparisons, a consistency bonus of up to 0.03 enters the requested-job quality sum. The average across requested jobs is clamped to 0.7–1.0. Mowing has no penalty, mound stays neutral, and no quality loss blocks completion. At five jobs the maximum stripe recovery is 0.6 percentage points of multiplier; it only offsets other losses because the multiplier cannot exceed one.

Results freeze coverage, aggregate quality, per-job quality, mowing bonus and the largest-loss tip. Career pay uses the final coverage-times-quality score. Result validation reconstructs the entire result, including score and tip, rather than trusting supplied multipliers. Results with no quality fields use the original schema and neutral multiplier, preserving every historical payout.

FieldSave v3 adds seed, baselines, puddle timers/history, ruts, wasted chalk metres and stripe statistics. Validation checks packed types, valid masks, timer/moisture consistency, rut/prepared consistency, plausible stripe counts and archived stroke length. V1 geometry migration and current-layout v2 saves receive fresh baselines and disabled quality for the legacy attempt; old frozen results stay byte-for-value unchanged. New starts enable quality again.

Doubleheader turnaround unlocks at 1,500 lifetime credits. It requests drag/water 75% and chalk/mound 100% within 480 seconds, paying 2 credits per final score point plus 100 completion credits (300 maximum). This and the loss weights need human playtesting: wet-before-drag routes now cost quality, chalk scuffs can make a 100% touch-up slow, and the eight-minute contract may be demanding. Repeated game days on a poorly repaired park deliberately retain that accumulated damage. Part 3 remains pending review.

## Part 3: Guide, autosave and controller support

`CrewTutorial` owns a seven-step sequence: noticeboard approach, actual mowing after boarding, forward lowered dragging, a real guide chalk section, target-moisture watering, three accepted impacts on one mound patch, and opening then closing the planning board. Steps compare actual model counts with an entry baseline and check the appropriate occupied/equipped state. Partial clay hits cannot satisfy the patch step. Checkpoint/completion live in `CrewSettings` (`user://settings.cfg`), alongside pad sensitivity; ConfigFile loading checks types and ranges. Skip and completion mark the guide done and call `ShiftDirector.enter_practice()`, which reuses the existing equipment/surface resets. Replay explicitly starts fresh practice. Career and manual snapshots are untouched. A paid attempt suspends tutorial checks and prevents tutorial cleanup from wiping its work.

The HUD guide reuses `game.prompt.text` for contextual help, including stop-before-lowering and tool blockers; it does not implement another copy of that decision tree. A primitive ring/pole and billboard label identify the current target, moving from equipment to work area as the player equips it. First-run/replay camera heading faces the noticeboard. The tutorial processes while the board is paused so it can observe the final open/close step; paid-attempt and pending-resume guards keep it inactive elsewhere.

`CrewAutosave` owns `user://field-autosave.dat` through a separate FieldSave instance. It queues start, finish, board and window-close triggers, and listens to all five completion signals to mark work dirty. During an unpaused active attempt it checks a 60-second interval; idle intervals do not write. Off-guide chalk now publishes a dirty signal even when guide coverage does not change, because its visible geometry and quality penalty must survive autosave. All writes run from normal process timing, at most once per second. Overlapping triggers coalesce into one current-state snapshot. The quit notification disables automatic acceptance, pauses the world and waits out any remaining write cooldown before exiting. A separate Godot-process test verifies this path actually commits and exits.

Startup validates the autosave before offering an active or unpaid finished attempt. The recovery candidate is held without applying it; it blocks replacement writes/starts until Resume or Start fresh resolves the choice. Resume uses FieldSave.restore, parks equipment and remains paused. Finished recovery calls the existing career claim function; repeated recovery cannot duplicate pay. Start fresh enters clean practice. Corrupt snapshots are renamed to `field-autosave.bad` and leave a one-line notice. A prior `.bad` backup is replaced by the latest corrupt snapshot. Autosave uses the unchanged v3 field format and its checksummed atomic write/rename path. Manual Save/Load remain independent.

A full-field capture, strict validation, serialization and atomic write measured roughly 110–140 ms in the managed Linux fixture (individual runs vary). No background thread touches Godot images or scene nodes. This preserves validation and scene safety, but synchronous saves can cause a brief frame hitch. Normal-close saves are guaranteed only while the process/filesystem can complete a write; a forced kill relies on the most recent completed snapshot. Paid-attempt dirty intervals bound ordinary crash loss to about a minute.

`CrewInput` owns action registration, device tracking, right-stick look and glyph text. Joypad bindings accept all device indices. Keyboard/mouse bindings remain, with left stick movement, right stick look, A jump/brake/confirm, X interact, Y swap, B drag/gate/back, LB hose, RB tamper, RT spray/tamp, Start board and Back cursor/menu back. LS sprints; D-pad navigates menus, and D-pad Up skips the guide during practice. Sticks use a 0.2 deadzone. Camera sensitivity defaults to 2.2 rad/s with a saved 0.5–5 range; mouse look keeps its original coefficient. Input setup is idempotent so recreating scenes cannot accumulate duplicate bindings.

`binding_text(action)` reads InputMap, including grouped movement, and supplies live prompts, world signs, tutorial hints and Controls rows. Controls is generated from those same actions; moving a binding changes its displayed name. `aim_allowed()` permits pad operation with a free cursor while retaining mouse recapture and paused-world protections. Existing tool capture-query seams now use this adapter. Menus select the first available interactive control, use geometric directional neighbours with wrap fallbacks, and support A confirmation and B/Back return. Controls and recovery fit at 1280×720; longer boards retain scroll fallback. `game.gd` only wires the systems and retains its existing interaction/prompt decisions.

Tests set dedicated career/settings/autosave paths. Older gameplay fixtures disable tutorial and autosave explicitly so synthetic work never becomes a startup recovery or resets underneath a test. Physical controller mapping/layouts, trigger calibration, stick feel/disconnect behavior and native Windows close/storage/export behavior still need real devices and Windows. The headless suite injects joypad events into Godot's normal Input pipeline; it does not establish hardware compatibility.


## Field inspection and job cycling

`CrewInspection` is a view adapter over the existing five work models. V / right-stick click toggles it; [ / ] and D-pad Left / Right cycle all jobs in practice and positive-goal jobs during an active attempt. Normal tool selection still changes the selected HUD job. A live legend reports absolute field counts, not the session's repair-baseline percentage. A rutted cell remains prepared for coverage but receives the orange quality warning.

Grass and dirt use inspection uniforms on their existing state shaders. Grass tufts hide only for grass inspection so they cannot conceal unfinished cells; they return when the view changes. Unfinished cells are gold, completed cells teal, ruts orange and puddles blue. Inspection colors use emission with zero diffuse/specular response so sunlight does not wash them into fluorescent yellow. Protected dirt, bases, plate, grass boundaries and mound exclusions retain their original masks.

Water inspection samples a separate R8 qualified-cell texture, maintained beside the existing moisture image during spray, recount, puddle expiry and reset. The rounded/interpolated moisture color cannot determine completion exactly near a threshold: two float moisture values on opposite sides of the target can quantize to the same R8 color. The new binary texture mirrors `watered` flags and shares the existing dirty upload cadence. Saves still store the original float moisture; restore recounts both flags and their display. No save version or layout signature changes.

Missing chalk and mound patches use two fixed MultiMesh batches. Chalk poses are cached from layout-backed valid sections and ground heights; covered or protected sections receive zero-scale transforms. Regular dashed guides hide during chalk inspection so they cannot be mistaken for missing work. Mound discs disappear only after all required impacts. Neither batch creates colliders or per-cell nodes, so tool raycasts and physics remain unchanged.

The adapter sleeps when disabled and after each refresh. Completion signals wake a dirty refresh, capped at 10 Hz; changing jobs or toggling the view refreshes immediately. There is no idle per-frame field scan. Resetting/parking equipment clears inspection, including start, field restore and guide cleanup. Snapshot tests confirm that toggling changes no field bytes, quality state, result or career data. View preferences are deliberately not persisted.

The headless renderer does not retain queryable MultiMesh transforms. Headless tests cover counts, fixed batches and state changes; the graphical fixture verifies every chalk transform against valid/uncovered flags on the actual renderer. All five overlays were rendered and inspected under OpenGL Compatibility. Physical pad usability, color-vision accessibility, Forward+ hardware performance and Windows remain to be evaluated.


## Equipment progression: wide drag and chalk guide wheel

The permanent shop now has four upgrades. `wide_drag` costs 400 credits and `guide_wheel` costs 350; both require 500 lifetime credits (Field Hand). `CareerProfile.upgrade_unlocked()` uses lifetime earnings rather than the current wallet. Candidate-ledger validation also derives lifetime earnings from validated results before checking upgrade requirements and costs. A forged affordable purchase below the rank threshold is rejected. Failed writes retain both wallet and existing gear. Old upgrade prices, result formats and payouts are unchanged, so legacy career files need no migration and keep exact balances.

The director captures the standard drag width before applying ownership. The wide mat uses a 1.25 multiplier (2.8 → 3.5 m). `DragAttachment.set_working_width()` sets the real preparation footprint and scales the existing frame against the width at mesh construction; mounted and parked mats both update. Reapplying ownership uses scene defaults and cannot stack multipliers. Tow-bar endpoints follow the scaled frame. Depth, travel speed, protected cells, puddle blocking and rut rules stay unchanged. Field slots store work rather than gear, so an old field load cannot roll back a career purchase.

The chalk marker builds one hidden guide-wheel visual at construction and exposes it only when owned. Assistance runs only while occupied, on the floor, moving forward above the existing paint threshold, with the gate open and no manual steering/braking. It uses the actual nozzle position and layout-backed foul-line endpoints. Within 0.65 m and 30° of a guide, it aims 2.5 m ahead along the closest travel direction and rotates heading at no more than 0.65 rad/s. Both outward and homeward forward pushing work; reverse motion does not. Off-range, steep crossings and past-endpoint travel stay manual. Any deliberate turn input overrides the correction.

Assistance never teleports the cart, changes its collision body, snaps paint onto a guide or grants coverage directly. The existing movement/collision and actual nozzle-stroke pipeline remain responsible for progress. Initial off-guide corrections still record wasted metres and quality penalties. The HUD adds GUIDE WHEEL to its existing chalk feedback, preserving the off-guide warning. The wheel is automatic when its conditions are met, with no additional key or controller mapping. All its main tuning lives in `CareerProfile.UPGRADES.guide_wheel`.

Tests compare actual assisted/unassisted travel from the same offset/heading, show increased valid dirt coverage with the wider mat, and verify rank locks, single charges, failed-write rollback, nonstacking visuals/footprints, old-field restore and career restart. These prices and the capture/correction settings are prototype balance values. Human controller feel, handling around bases/obstacles and longer routes still need playtesting; the guide wheel intentionally provides no obstacle avoidance or automatic gate control.

## Minor-league club story and stadium economy

The story is an opt-in career layer for the fictional Cedar Grove Owls. Existing sandbox careers remain unchanged until the player accepts the groundskeeper job from Clubhouse. `ClubProgress` contains the economy and manager chapters; `ClubDirector` owns scene transitions; `ClubStadium` owns purchased construction and crowd presentation. Main only wires them up. Mara Vale's five chapter prompts follow hosting the opener, growing demand, seating, concessions, covered stands and continuing toward a full 480-seat park. Snack-first investment is allowed even though the manager's suggested order starts with seating.

Enrollment changes unowned tools to a 1.8 m deck, 2.2 m drag and 0.55 watering rate. The director still captures the original scene defaults before applying ownership, so purchased gear retains its full 3.0 m deck / 3.5 m mat / 1.0 hose targets without compounding multipliers. Owned equipment and previous money are carried over. A dedicated `home_game` profile uses a 1,200-second game-day attempt with 0.35 wear, goals [15,50,100,50,100], one credit per final score point and 60 completion credits. Its result is HOME GAME PREPARED, not a claim that partial grass coverage is the whole park's readiness.

The player is assigned priority work; volunteers finish routine passes only when the player explicitly hosts the completed home date. Hosting first commits the financial settlement, then enters practice, parks actors and uses public surface APIs to prepare the rest of the park. New `MowingGrass.prepare_all()` sets only valid cells and resets stripe statistics. Volunteer work never runs during an active attempt and cannot generate extra coverage pay. Starting home prep finishes an unfinished practice guide before its paid attempt starts, avoiding guide checks against later volunteer work. Old training/contracts continue working as side income.

A finished home-prep wage is paid through the existing immutable attempt record. The club's pending date is derived from completed home records since enrollment, excluding already hosted IDs. The next home prep is blocked until that date is hosted; switching to other work cannot erase the pending reward. An ended-early or timed-out prep can earn normal partial wages but cannot host. Hosting reads the career's originally recorded result, so reloading a field and improving its score cannot improve an already paid attempt's fan/revenue settlement. Autosave recovery now also offers paid-but-unhosted home prep. Resuming still uses the once-only claim path; a hosted date is not offered again.

Club careers use career payload version 2 inside the existing checksummed atomic file. Version 1 stays valid and keeps all prior earnings and purchases. Enrollment stores record/tool prefix counts plus an empty event list; no historical wages receive retroactive attendance or profit. Each subsequent club event stores only type, ID and current record/tool counts. Game events reference validated completed home-prep IDs; construction events reference known projects. Replay enforces monotonic bounded prefixes, unique home settlements, fan/prerequisite locks and sufficient funds at each construction point. There are no saved fan totals or gate-money amounts for a modified payload to override. Final budget is base prep/contract wages + replayed club net income − tool spending − stadium spending. Net club income contributes to lifetime rank earnings; spending never removes rank progress.

The economy starts at 48 supporters and 120 seats. Attendance is the smaller of capacity and `floor(fans * (0.65 + 0.35 * final_score / 100))`. Tickets begin at 4 credits; costs are 60 plus one per attendee. Net income is nonnegative ticket/food proceeds minus those costs. Supporter growth is `8 + floor(score * 0.12)` plus amenities, capped at 10,000 total. A clean first date pays 160 prep credits and 84 net gate credits, grows support by 20 and draws 48 attendees. Money does not produce fans while idle; quality home dates do.

Community bleachers cost 600 at 90 supporters and add 120 seats. The snack shack costs 450 at 75 supporters and adds one credit per attendee plus three supporters per date. The covered grandstand costs 1,400 at 200 supporters after both earlier projects; it adds 240 seats, one ticket credit and five supporters per date. Capacity therefore grows 120 → 240 → 480. Forecasts and receipts use the same replay rules as committed money. These constants form the version-2 economy: future price/rule changes need a versioned migration rather than silently repricing old events.

`ClubStadium` replaces the two sandbox grandstands only after enrollment, disabling their hidden collision shapes. It builds exactly 60 seats per bank: two starter banks, four after bleachers, eight under roofs after the grandstand. The snack shack appears as a separate physical building. Supporter bodies/heads use a few MultiMesh batches, capped by last attendance and seats, rather than a scene node per person. A signature of active state, buildings and last attendance avoids rebuilding geometry on ordinary tool purchases or wage changes. New construction parks actors to prevent the player being left inside a newly spawned building; work masks remain intact. Construction sits behind home/outside the work masks, so all old field signatures and migrations remain valid.

This is a playable story/economy foundation, not a baseball match engine. Home dates are summaries and spectators are static placeholders representing the last crowd. There are no simulated wins, player AI, promotion leagues, day/night schedule or real construction wait yet. Human checklist timing, tool-versus-stadium price balance, long-session pacing and richer story events remain the next design work.

### Home schedule

`ClubSchedule` derives fixture order from committed game events, not wage records or dictionary ordering. Optional targets use the original frozen result's score and elapsed time. Pending prep, side contracts and duplicate hosting cannot advance the calendar. Reviews show the just-completed season until the next hosting. This presentation layer adds no save fields and leaves version-2 economic replay unchanged; existing games receive retrospective target reviews, never new money.

### Stadium amenities expansion

Added three immutable project IDs to the existing version-2 event ledger. Existing project prices and economics stay unchanged; a new benefit enters replay only after its build event, so old receipts never gain retroactive income. The event bound now allows 2,000 records plus the number of available projects. The Clubhouse derives prerequisite names from each project rather than assuming all projects need the original seating/concessions pair. Scoreboard tiers replace the stock board visually and disable its old colliders. New buildings stay outside the playing field and add no seats; capacity remains 480. Video-board caching includes supporters so its display updates after hosting without rebuilding during every HUD refresh.

### Silent hose regression

Watering previously coupled visible droplets to `apply_spray()` succeeding at a camera-picked ground target. An equipped hose could receive a real mouse press but show no stream when aim missed reachable ground. Separate nozzle effects from moisture application: captured input on foot and within hose length emits a range-limited stream, clipped by physical obstacles; the original ground/range/obstruction checks still control soil changes. The tutorial also omitted the required chalk-cart release. Its watering instruction and marker now depend on current equipment, and its status shows live feedback and local moisture. The tutorial regression uses the production spring-arm camera for watering rather than a replacement test camera.

### Four-pass art workflow

Review the same camera views between silhouette, material, lighting and detail passes. `tools/capture_art_review.gd` uses an isolated fixture career and explicitly restores its review camera after construction resets the game camera. `ParkGeometry` now caches chamfer meshes, canopy variants and surface materials; chamfers replace visual meshes while existing box colliders retain exact dimensions. Smooth character and tree geometry is visual only. Shared procedural shaders use the project's explicit linear-color convention; an intermediate unconverted material pass was visibly washed out in Compatibility and was corrected. Coverage/inspection shader branches and saved masks remain unchanged. Forward+ was attempted but the host fell back to Compatibility because Vulkan surface support is unavailable.

### Close-up refinements

Cached seat-shell meshes reuse MultiMesh transforms and preserve 120/240/480 capacity. Decorative rails and serving displays add no gameplay collision changes. Crowd clothing selection now varies within banks, avoiding the old modulo-four/interleaved-bank pattern that made an entire bank one color. Crowd facial/hair/leg details remain batched under one group rather than creating supporter scenes. Knee pivots live beneath existing leg roots; the public limb ordering and hand-tool pose branches remain intact. The art capture tool freezes only the fixture player's physics while recording a walking pose, then restores it.

### Entrance and surroundings

`ParkArrival` keeps the decorative entrance and distant landscape separate from the field/work systems. Existing box collisions, field geometry resources and masks are retained; new decorations add no physics bodies. The rolling landscape begins beyond the outfield fence/tree line. A shared paving shader uses world-space slab joints with derivative antialiasing and restrained per-slab variation. The art-review fixture now walks the real player through the right-hand entrance approach and asserts forward clearance before recording the actual orbit camera.

### Field presentation versus work state

The grass surface binds the same texture twice: nearest sampling for exact validity/inspection, linear sampling for visual coverage edges. CPU counts and saved masks are untouched. Uncut tufts retain one MultiMesh and mask-based disappearance, with bent blade geometry and explicit renderer-aware unshaded color to avoid black backlit spikes. Mound overlays use irregular alpha edges and fade with compaction; the underlying visual mesh rounds the shoulder while the original convex collider and node transforms remain intact. Gold guide fading is a presentation shader over existing transforms, not a change to scoring, protection or steering assistance.

### Condition profiles, cash priorities and recap

`GameDay` owns three new immutable profile IDs and their bonus rules. Existing `home_game` definitions and old result economics are untouched. The first home date stays the opener; later dates rotate conditions by hosted-game count. Profiles carry goals, duration and wear tuning, so existing strict result reconstruction and field snapshots freeze the condition without adding save fields. Rain adds threshold-qualified puddles and timers before repair baselines; its natural puddles may have zero player-overwatering marks. `FieldSave.quality_state_ok` permits that combination only for `home_rain`; the old invariant remains for every other profile. Player spraying still records overwatering normally.

Cash is derived from frozen recorded result quality/score/time during strict game-event replay. It is added separately from gate profit to club income, and therefore to the shared budget and lifetime earnings. New receipt bonus fields are derived, never accepted from serialized events. A failed write, duplicate host, improved replay or field rewind cannot pay again. Future tuning should use new profile/rule IDs rather than repricing committed results.

New-condition season targets use the same priority outcome as cash; legacy home-game results retain their original schedule targets. Recaps explicitly mark wages as already received, show actual request requirements/results, and use the current wallet for upgrade progress. HUD condition visibility responds to phase signals, including paused postgame transitions. Recap scrolling waits for text wrapping and controller focus to settle before aligning its heading.

### Progression, stadium life and ownership

Starter handling can be tuned without touching result reconstruction or ledger economics: drag 2.4 m and water rate 0.65 retain the original purchased targets and prices. `audit_club_balance.gd` uses validated results and existing forecasts to compare spending orders, not an approximation of currency rules.

`OpeningGates` presents only after successful settlement. Its shared-world SubViewport has an independent camera, disabled audio listener and disabled rendering outside the short presentation. The real world stays paused; Enter/A/click or cancel consumes the skip input before the underlying recap. Decorative gate leaves have no new collision. Programmatic prep/build finishes the effect, and startup never replays it. `StadiumLife` uses existing ambience buses, distance attenuation and pause controls; active prep hides spectator batches and suppresses their sounds.

`ClubOwnership` reconstructs season closing states from event prefixes, including tool ownership at those points. Its objective order is fixed, not whatever future projects get appended to the catalog. Reviews/objectives are derived from the career ledger, with no new cash, fields or migration. Director caches the report on career changes rather than replaying seasons every progress frame. The following finale evaluates the previous objective using its frozen closing state; later investment cannot rewrite that evaluation.

## Modern UI pass

- Navigation belongs outside each scrolling page. Moving the existing destination buttons into a persistent rail preserves their signals while allowing direct screen switching; every destination first hides its siblings.
- Clubhouse sections share the existing career/session model and purchase guards. Results is selected before assigning focus after hosting. Continue sits above the report so it is visible without scrolling and returns to Matchday with preparation focused.
- Build focus links after layout as well as immediately. Godot's container positions settle after visibility changes; rail-to-content links must use the active page and exclude hidden/disabled controls. Resume offers disable every rail button.
- Use one shared Theme and original outline SVG icons; preserve public HUD fields for tool/tutorial controllers. Noninteractive HUD controls ignore mouse input so panels cannot intercept watering.
- The UI capture test disables covered world rendering beneath opaque menus to speed software rendering, then restores it for the live HUD capture. Menu widgets, native click routing and injected D-pad events still run through Godot itself. Headless tests emit button signals because Godot's headless display does not route these pointer events.
