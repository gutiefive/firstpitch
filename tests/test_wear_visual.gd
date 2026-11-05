extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in range(count):
		await physics_frame


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


func click(button: Button) -> void:
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await idle(4)
		parent = parent.get_parent()
	assert(Rect2(Vector2.ZERO, root.size).has_point(button.get_global_rect().get_center()))
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		Input.parse_input_event(event)
	await idle(4)


func capture(path: String) -> void:
	await idle(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-wear-visual-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	await frames(20)
	await key(KEY_TAB)
	await click(g.shift.overlay.full_button)
	assert(g.shift.session.start_mode == "game_day" and not paused)
	g.hud.visible = false
	g.shift.overlay.visible = false
	var camera := Camera3D.new()
	g.add_child(camera)
	camera.current = true
	camera.far = 500
	camera.position = Vector3(0, 60, 20)
	camera.look_at(Vector3(0, 0, -18))
	await capture("/tmp/firstpitch-wear-field.png")
	# Surface API fixtures expose puddles/ruts and a deliberate off-guide mistake.
	var p := Vector3(10, 0, -10)
	g.moisture.spray_at(p, 5)
	g.moisture.fill_valid(0.8)
	g.infield.drag_segment(p, p, Vector3.FORWARD, 4, 2)
	g.moisture.spray_at(Vector3(14, 0, -14), 5)
	g.chalk.paint_segment(Vector3(10, 0, -14), Vector3(18, 0, -14))
	g.infield.refresh_texture()
	g.moisture.refresh_texture()
	g.chalk.flush_visuals()
	camera.fov = 50
	camera.position = Vector3(15, 3, -7)
	camera.look_at(Vector3(12, 0, -12))
	await capture("/tmp/firstpitch-wear-puddles-ruts.png")
	g.hud.visible = true
	g.shift.overlay.visible = true
	await key(KEY_TAB)
	await click(g.shift.overlay.end_button)
	assert(paused and g.shift.session.get_result().quality < 1)
	await capture("/tmp/firstpitch-wear-results.png")
	await click(g.shift.overlay.contracts_button)
	await capture("/tmp/firstpitch-doubleheader-locked.png")
	g.shift.overlay.contracts_screen.ensure_control_visible(g.shift.overlay.contracts_panel.back_button)
	await idle(4)
	await click(g.shift.overlay.contracts_panel.back_button)
	assert(g.shift.overlay.board_scroll.visible)
	assert(g.shift.overlay.contracts_panel.buttons.doubleheader.disabled)
	print(
		(
			"Wear visuals: native game-day start/end, worn field, surface quality fixtures and Crew "
			+ "Lead card captured"
		)
	)
	g.shift.close_board()
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute("user://test-wear-visual-career.dat")
	quit()
