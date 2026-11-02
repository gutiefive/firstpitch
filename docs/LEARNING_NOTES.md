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
