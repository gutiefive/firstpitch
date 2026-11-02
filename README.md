# First Pitch: Grounds Crew

A native Godot 3D baseball groundskeeping prototype. Walk through a small ballpark, enter a riding mower, and cut persistent stripes into the outfield. Built with GDScript and procedural meshes; no plugins or downloaded art are required.

![The playable ballpark](docs/screenshots/stadium.png)

## Open and play

Tested with **Godot 4.6.3 stable**, the installed stable 4.x version. Import `project.godot` into Godot, open `scenes/main/main.tscn`, and press **F6**, or press **F5** to run the project. The project defaults to **Forward+** for a desktop GPU. Windows PC is the intended platform; a Windows executable has not been exported or tested.

```sh
godot --editor --path .
godot --path .
```

If your graphics device cannot run Forward+, use Godot's Compatibility renderer (or launch with `--rendering-method gl_compatibility`). That override was used for software-rendered graphical checks in the cloud; it does not change the saved desktop renderer.

## Controls

| Action | Input |
| --- | --- |
| Walk / steer and drive mower | WASD |
| Sprint on foot | Shift |
| Jump on foot / brake mower | Space |
| Enter nearby mower / exit when stopped | E |
| Orbit third-person camera | Mouse |
| Zoom camera | Mouse wheel |
| Release or recapture cursor | Escape |

Spawn beside the equipment shed. The mower is ahead and to the left in world space, on the paved equipment pad. Approach until **Press E to enter mower** appears. Drive across the foul line onto grass. Cutting starts automatically while driving. Dirt does not contribute to the percentage. Repeated passes count only once. Exit after stopping; your cut pattern stays for this session.

## Implemented M1–M3

- 27.43 m basepaths, dirt diamond, mound, bases, foul lines, grass outfield, warning track, padded outfield wall, dugouts, bleachers, scoreboard, light towers, shed, and mower parking.
- Collidable ground, buildings, stands, and outfield fence; daylight and shadows.
- Visible groundskeeper, walking, sprinting, jumping, orbit/zoom camera with spring-arm collision.
- Arcade CharacterBody3D mower: acceleration, reverse, speed-dependent steering, braking, rotating wheels, steering animation, protected exit placement.
- Spatial 450 × 330 grass-state image. Swept 2.4 m cutting footprint, overlap-safe unique-cell percentage, dirt exclusion, directional cut color, dirty-only updates capped at 10 Hz.
- HUD with mode, objective, contextual controls, percentage, and progress bar.

## Project map

Start with `scenes/main/main.tscn` and `scripts/gameplay/game.gd` for scene composition and interactions. Then inspect `scripts/vehicles/mower.gd` and `scripts/mowing/grass.gd` for driving and cutting. `scripts/gameplay/stadium.gd` creates the ballpark using shared helpers in `geometry.gd`. The player, mower, and grass mask have separate reusable scenes. Open `scenes/environment/grass.tscn` to tune the exported grass settings. Prototype geometry is generated on scene startup; expand the running scene in the editor's **Remote** tree to inspect generated nodes.

See [learning notes](docs/LEARNING_NOTES.md), [roadmap](docs/ROADMAP.md), and [verification](docs/VERIFICATION.md).

## Automated checks

Run from the project directory:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_mowing.gd
godot --headless --path . --script tests/test_gameplay.gd
godot --headless --path . --quit-after 180
```

On restricted Linux machines set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` to writable directories before launching. No such adjustment is normally needed on Windows.

For a graphical smoke run on a desktop or virtual display:

```sh
godot --path . --rendering-method gl_compatibility --script tests/test_visual.gd
```

The graphical test captures three images under `/tmp/firstpitch-*.png` (Linux only). It automates a driving pass; normal play uses the main scene, not this test script.

## Current limitations

- Prototype primitive art and generated scene content; no artist-authored assets, rigged animations, stadium crowds, career, or infield tools.
- Cut grass uses color/texture variation, not shorter geometric blades. No cross-session mask save/load yet.
- Cutting audio has a named `CuttingAudioHook` AudioStreamPlayer3D on the mower, with no sound assigned.
- Flat terrain and arcade handling; no suspension. The player hides consistently while seated. The infield is visually raised slightly but the continuous ground collider remains flat.
- Only the outfield wall is a perimeter barrier; this is an explorable prototype, not a fully enclosed stadium. Dugouts are solid exterior placeholders.
- Forward+ GPU visuals, native Windows behavior, controller support, and hardware performance remain unverified.
- Field bounds and mask resolution are configurable; changing the stadium layout also requires matching the mowing area's exported exclusion settings. There is no layout-authoring UI yet.
