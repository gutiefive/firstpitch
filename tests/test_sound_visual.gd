extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func idle(count: int) -> void:
	for i in range(count):
		await process_frame


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
	await idle(3)


func click(control: Control) -> void:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			await idle(4)
		parent = parent.get_parent()
	var point := control.get_global_rect().get_center()
	assert(Rect2(Vector2.ZERO, root.size).has_point(point))
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
	await idle(4)


func capture(path: String) -> void:
	await idle(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-test_sound_visual-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	for i in range(30):
		await physics_frame
	g.audio.settings.path = "user://visual-sound-test.cfg"
	await key(KEY_TAB)
	await click(g.shift.overlay.sound_button)
	assert(paused and g.shift.overlay.sound_screen.visible)
	var original: float = g.audio.settings.levels.master
	g.shift.overlay.sound_panel.sliders.master.grab_focus()
	await key(KEY_LEFT)
	assert(g.audio.settings.levels.master < original)
	await click(g.shift.overlay.sound_panel.mute)
	assert(g.audio.settings.muted and AudioServer.is_bus_mute(0))
	await click(g.shift.overlay.sound_panel.mute)
	assert(not g.audio.settings.muted)
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	await click(g.shift.overlay.sound_panel.preview_button)
	assert(g.audio.preview.playing)
	await create_timer(1.1, true, false, true).timeout
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	assert(recording != null and recording.data.size() > 1000)
	recording.save_to_wav("/tmp/firstpitch-sound-preview.wav")
	AudioServer.remove_bus_effect(0, 0)
	await capture("/tmp/firstpitch-sound-settings.png")
	await key(KEY_ESCAPE)
	assert(paused and not g.shift.overlay.sound_screen.visible)
	await click(g.shift.overlay.training_button)
	assert(not paused)
	await key(KEY_TAB)
	await capture("/tmp/firstpitch-sound-board.png")
	await click(g.shift.overlay.sound_button)
	await key(KEY_TAB)
	assert(not paused and not g.shift.overlay.sound_screen.visible)
	DirAccess.remove_absolute(g.audio.settings.path)
	print("Graphical sound: native screen, slider keys, mute, recorded mixer preview, Escape/Tab passed")
	g.queue_free()
	await create_timer(0.15).timeout
	quit()
