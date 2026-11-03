extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
func idle(count: int) -> void:
 for i in range(count):
  await process_frame
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var prefs := SoundPreferences.new()
 prefs.path = "user://test-sound.cfg"
 DirAccess.remove_absolute(prefs.path)
 prefs.load_settings()
 check(prefs.levels == SoundPreferences.DEFAULTS and not prefs.muted,"missing settings use conservative defaults")
 prefs.set_level("effects",0.23)
 prefs.set_muted(true)
 var restored := SoundPreferences.new()
 restored.path = prefs.path
 restored.load_settings()
 check(restored.levels.effects == 0.23 and restored.muted,"volume and mute persist between preference instances")
 check(AudioServer.is_bus_mute(0),"mute reaches the real master bus")
 restored.set_muted(false)
 restored.set_level("master",0)
 check(AudioServer.is_bus_mute(0),"zero master is fully silent")
 restored.set_level("master",0.7)
 restored.set_level("ambience",0)
 check(not AudioServer.is_bus_mute(0) and AudioServer.is_bus_mute(AudioServer.get_bus_index("GroundsAmbience")),"ambience can be silenced independently")
 check(not restored.set_level("bogus",1) and not restored.set_level("effects",NAN),"unknown and nonfinite settings are rejected")
 var config := ConfigFile.new()
 config.set_value("sound","master",99)
 config.set_value("sound","effects","bad")
 config.set_value("sound","ambience",-1)
 config.set_value("sound","muted","bad")
 config.save(prefs.path)
 restored.load_settings()
 check(restored.levels.master == 1 and restored.levels.effects == SoundPreferences.DEFAULTS.effects and restored.levels.ambience == 0 and not restored.muted,"bad settings fall back safely and numeric levels clamp")
 restored.path = "user://no-such-directory/sound.cfg"
 check(not restored.persist() and not restored.error.is_empty(),"settings write failures are visible")
 DirAccess.remove_absolute(prefs.path)
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-test_audio-career.dat"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await frames(45)
 g.audio.settings.path = "user://test-sound-scene.cfg"
 check(g.audio.loops.wind.playing and g.audio.loops.birds.playing,"park ambience runs in free practice")
 check(not g.audio.loops.engine.playing and not g.audio.loops.hose.playing,"idle equipment is silent")
 var bus_count := AudioServer.bus_count
 g.audio.settings.apply()
 check(AudioServer.bus_count == bus_count,"reapplying settings does not duplicate buses")
 var sound: AudioStreamWAV = g.audio.loops.engine.stream
 check(sound.loop_mode == AudioStreamWAV.LOOP_FORWARD and sound.loop_end > sound.loop_begin and sound.data.size() > 0,"engine uses a nonempty bounded PCM loop")
 g.player.global_position = g.mower.global_position+Vector3(2.4,0,0)
 g.interact()
 await frames(4)
 check(g.audio.loops.engine.playing and g.audio.targets.engine,"entering the actual mower starts its engine")
 var idle_pitch: float = g.audio.loops.engine.pitch_scale
 Input.action_press("forward")
 await frames(45)
 Input.action_release("forward")
 check(g.audio.loops.engine.pitch_scale > idle_pitch,"real acceleration raises engine pitch")
 g.shift.open_board()
 await idle(5)
 check(g.audio.loops.engine.stream_paused and g.audio.loops.wind.stream_paused,"shift board pauses spatial tools and ambience")
 g.shift.overlay.sound_button.pressed.emit()
 check(g.shift.overlay.sound_screen.visible and not g.shift.overlay.board_scroll.visible and paused,"sound screen keeps the game paused")
 g.shift.overlay.sound_panel.sliders.effects.value = 31
 check(is_equal_approx(g.audio.settings.levels.effects,0.31),"settings slider updates effects bus")
 g.shift.overlay.sound_panel.preview_button.pressed.emit()
 await idle(2)
 check(g.audio.preview.playing and not g.audio.preview.stream_paused,"preview can play while world is paused")
 g.shift.overlay.sound_panel.mute.button_pressed = true
 check(AudioServer.is_bus_mute(0),"mute checkbox silences all buses including preview")
 g.shift.overlay.sound_panel.mute.button_pressed = false
 g.shift.overlay.sound_panel.back_button.pressed.emit()
 check(not g.shift.overlay.sound_screen.visible and paused,"back returns to the paused board")
 g.shift.close_board()
 await frames(4)
 check(not g.audio.loops.engine.stream_paused,"resume restores tool audio playback")
 await frames(100)
 g.interact()
 await frames(30)
 check(not g.audio.loops.engine.playing,"leaving the stopped mower fades out its engine")
 var heard_step := false
 Input.action_press("forward")
 for i in range(40):
  await frames(1)
  heard_step = heard_step or g.audio.step.playing
 Input.action_release("forward")
 check(heard_step,"actual grounded walking produces distance-timed footsteps")
 g.mound.apply_tamp(0)
 await frames(2)
 check(not g.audio.tamp.playing,"model resets or injected repair counts do not fake a hand-tool impact")
 # Only the hand controller's accepted-impact signal owns this positional sound.
 g.tamper.impact.emit(g.mound.patch_world(0))
 await frames(2)
 check(g.audio.tamp.playing and g.audio.tamp.global_position == g.mound.patch_world(0),"accepted-impact event plays at the mound patch")
 g.shift.open_board()
 g.shift.session.start("training")
 g.shift.session.end_early()
 await idle(2)
 check(g.audio.preview.playing,"shift result chime survives automatic result pause")
 g.shift.close_board()
 DirAccess.remove_absolute(g.audio.settings.path)
 g.audio.reset_tools()
 check(not g.audio.tamp.playing and not g.audio.loops.engine.playing,"fresh field clears old tool sound tails")
 g.queue_free()
 await create_timer(0.1).timeout
 print("Audio: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
