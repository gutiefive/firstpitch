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

Try `deck_width`, `resolution`, `update_frequency`, `field_origin`, and `field_size`. Keep the exported outfield radius and diamond exclusions matched to the stadium geometry. Shader colors are in `shaders/grass.gdshader`. A future layout resource should hold both stadium dimensions and scoring boundaries as their shared source of truth.


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

Try `working_width` and `working_depth` on the drag, `dragging_speed` on the tractor, the bay's `service_radius`, and the dirt grid resolution/update frequency. The mask exclusions currently match Cedar Grove's dimensions; keep them aligned with any future stadium layout changes. The next architectural step for multiple stadiums is a shared field-layout resource rather than duplicated dimensions.


## M4: Chalking as a separate walking tool

`ChalkMarker` is a small CharacterBody3D with its own speed, collision, steering, brake, gate, wheels, and pushing character visual. Main transfers control to whichever nearby piece of equipment is closest, hiding the ordinary walking character while that tool's operator visual is active. The shared side-exit query checks space before restoring walking. The marker's collision footprint includes its handle/operator space; it is an arcade push tool rather than a rigidbody handcart.

The R action is contextual: it lifts/lowers an occupied tractor's drag or toggles the occupied chalk marker's gate. Each actor reads WASD only while occupied. Leaving the marker closes the gate. The controller records only forward, grounded travel while the gate is open; closing or reopening resets its stroke anchor, so a closed-gate move does not create a connecting stripe later. Wall-contact handling also checks actual horizontal displacement, because a floor recovery contact can hide a wall slide report and leave a tiny requested speed behind.

`ChalkSystem` draws the stroke where the nozzle actually travels. Small ribbons follow the park's known surface heights. New geometry is queued and committed at most 10 times per second in batches of 128 strokes. Finished mesh batches stay in the scene for the session. No broad field material swap or per-sample node is required. Repeated passes can add visual geometry, but they cannot increase already-earned coverage.

The foul-line objective uses two one-dimensional sets of approximately quarter-meter sections. For each swept nozzle segment, the system tests nearby section centers against the chalk footprint. The bases/plate are protected and excluded. Left and right counts have separate denominators. Off-guide chalk is drawn, but it cannot mark a target section that its footprint did not reach. The gold dashed guides themselves start with zero coverage.

Main remembers the selected task when you leave a tool. Returning to the tractor or changing its attachment restores its mowing/dragging objective. The HUD shows all five percentages and a left/right breakdown while chalking. Completion uses exact tracked counts rather than a rounded percentage, so nearly finished work cannot prematurely declare the park ready.

Try `push_speed`, `steering_rate`, and `stroke_spacing` on the marker; `chalk_width`, line bounds, `section_length`, and `update_frequency` on the chalk system. Surface-height projection currently describes Cedar Grove's fixed geometry. A future shared field-layout resource should supply these heights and exclusions for multiple parks. Unlimited chalk, no erase/undo, and no session save/load are deliberate prototype limits, not quality or supply mechanics.


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

Try `patch_positions`, `patch_radius`, and `hits_required` on the mound scene, or `working_reach`, `stroke_duration`, and `contact_time` on the rack scene. Keep contact time shorter than total stroke duration. Patch disks should remain on the plateau and away from the pitching rubber. If you move the mound, update the stadium geometry, repair scene, and surface-height data together until a shared layout resource replaces those duplicated dimensions.


## M5: Shift lifecycle and clean restarts

`ShiftSession` owns practice/active/finished state, profile quotas, elapsed time, proportional scoring, and deep-copied results. It consumes raw task percentages plus exact full-count flags; rounded HUD text cannot complete a full goal. Each job is worth 20 points. An incomplete attempt is capped at 99.9; completion wins if goals are reached on the deadline frame.

`ShiftDirector` collects the five existing models, advances the active clock, and coordinates fresh starts. Each model exposes `reset_state()` to clear both accounting and visible work. Reset also stows hand tools, cancels windups, clears chalk meshes, parks vehicles, raises/closes attachments, and restores the player/camera. Active attempts cannot be reset through a fresh-start request.

`ShiftOverlay` processes while the SceneTree is paused. Opening the board cancels an unfinished tamp and releases held tool actions; closing releases them again so a GUI click cannot become a spray or strike. The previous mouse mode is restored. Results are snapshots: later practice may change the field but cannot revise the last score. Profile durations and goals live in `ShiftSession.PROFILES`; no save data or quality simulation is implied by the score.
