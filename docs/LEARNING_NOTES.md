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

The mask is modest (450 × 330). A dirty flag batches full uploads to at most 10 Hz; idle grass uploads nothing. This is simpler than a partial-update rendering pipeline and has predictable small upload size. CPU footprint work only visits a local bounding box around the cutting deck. There is one grass surface, not a node per blade. Session state stays in the same grass node when you leave the mower.

Try `deck_width`, `resolution`, `update_frequency`, `field_origin`, and `field_size`. Keep the exported outfield radius and diamond exclusions matched to the stadium geometry. Shader colors are in `shaders/grass.gdshader`. A future layout resource should hold both stadium dimensions and scoring boundaries as their shared source of truth.
