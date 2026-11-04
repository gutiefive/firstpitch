# Prototype audio

Thirteen original synthetic effects generated for this project by
`tools/generate_audio.py`. No third-party recordings or external audio packages.
Run `python3 tools/generate_audio.py` from the repository root to regenerate them.
The game ships these WAV files and needs no Python at runtime.

Mono 16-bit PCM, 22,050 Hz. Engine, hose, drag, chalk, wind and birds loop via
GroundsAudio; step, tamp and shift are one-shots. Quiet loop endpoints reduce
clicks. Gain, distance attenuation and engine pitch are applied in Godot.
StadiumLife adds crowd/concession loops and occasional cheer reactions. OpeningGates plays crowd_cheer and gate_open one-shots while the board pauses the world. The cheer uses GroundsAmbience; the gate uses GroundsEffects.

These clips are prototype sound design; desktop listening and mix tuning remain.
