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
