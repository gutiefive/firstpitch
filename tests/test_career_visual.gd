# Graphical shift flow using real engine key/button events and real tool work.
extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func idle_frames(count: int) -> void:
	for i in range(count):
		await process_frame


func key(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)


func button_click(button: Button) -> void:
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await idle_frames(4)
		parent = parent.get_parent()
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)


func tool_click(game: Node) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game._input(event)


func capture(path: String) -> void:
	await idle_frames(4)
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not save capture: " + path)
		quit(1)


func run() -> void:
	var game = load("res://scenes/main/main.tscn").instantiate()
	game.career_save_path = "user://test-career-visual.dat"
	game.tutorial_enabled = false
	game.autosave_enabled = false
	DirAccess.remove_absolute(game.career_save_path)
	root.add_child(game)
	await frames(45)
	await capture("/tmp/firstpitch-shift-practice.png")
	key(KEY_TAB)
	await idle_frames(5)
	if not paused or not game.shift.overlay.modal.visible:
		push_error("Native Tab did not open shift board")
		quit(1)
		return
	await capture("/tmp/firstpitch-shift-board.png")
	await button_click(game.shift.overlay.training_button)
	await idle_frames(5)
	if paused or game.shift.session.phase != ShiftSession.Phase.ACTIVE:
		push_error("Native training button did not start shift")
		quit(1)
		return
	await frames(30)
	await capture("/tmp/firstpitch-shift-active.png")
	game.player.global_position = game.mower.global_position + Vector3(2.4, 0, 0)
	game.interact()
	Input.action_press("forward")
	await frames(180)
	Input.action_release("forward")
	await frames(75)
	key(KEY_TAB)
	await idle_frames(5)
	var remaining: float = game.shift.session.remaining_seconds
	await idle_frames(20)
	if game.shift.session.remaining_seconds != remaining:
		push_error("Graphical pause did not stop clock")
		quit(1)
		return
	await capture("/tmp/firstpitch-shift-paused.png")
	await button_click(game.shift.overlay.close_button)
	await idle_frames(5)
	if paused:
		push_error("Native resume button did not resume")
		quit(1)
		return
	game.interact()
	game.player.global_position = game.tamper.rack_position + Vector3(-1.2, 0.05, 1.2)
	key(KEY_G)
	await frames(3)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current = true
	camera.near = 0.3
	camera.far = 500
	camera.fov = 55
	game.tamper.camera = camera
	for index in range(game.mound.hits.size()):
		var point: Vector3 = game.mound.patch_world(index)
		game.player.global_position = point + Vector3(-0.75, 0.1, 0.65)
		camera.position = point + Vector3(2.5, 3.5, 4.4)
		camera.look_at(point)
		await frames(20)
		for hit in range(game.mound.hits_required):
			tool_click(game)
			await frames(45)
	if game.mound.repaired_count != 6 or game.grass.cut_count <= 0:
		push_error("Real tool work did not reach shift model")
		quit(1)
		return
	key(KEY_TAB)
	await idle_frames(5)
	await button_click(game.shift.overlay.end_button)
	await idle_frames(5)
	var result: Dictionary = game.shift.session.get_result()
	if not paused or result.is_empty() or result["jobs_completed"] != 1 or result["score"] <= 20:
		push_error("Graphical early finish did not preserve earned work")
		quit(1)
		return
	await capture("/tmp/firstpitch-career-results.png")
	# Two completed fixtures fund native purchases; the first payout above is real tool work.
	for i in range(2):
		var seed := ShiftSession.new()
		seed.start("full")
		seed.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
		seed.advance(10)
		game.shift.career.claim(seed.attempt_id, seed.get_result())
		seed.free()
	await button_click(game.shift.overlay.career_button)
	await idle_frames(5)
	assert(paused and game.shift.overlay.career_screen.visible)
	await capture("/tmp/firstpitch-career-shop.png")
	await button_click(game.shift.overlay.career_panel.shop.wide_deck)
	await idle_frames(5)
	assert(game.shift.career.owns("wide_deck") and game.grass.deck_width == 3)
	await button_click(game.shift.overlay.career_panel.shop.hose_nozzle)
	await idle_frames(5)
	assert(game.shift.career.owns("hose_nozzle") and is_equal_approx(game.moisture.application_rate, 1.0))
	await capture("/tmp/firstpitch-career-owned.png")
	key(KEY_ESCAPE)
	await idle_frames(3)
	assert(paused and not game.shift.overlay.career_screen.visible)
	await button_click(game.shift.overlay.full_button)
	await idle_frames(4)
	assert(not paused and game.grass.deck_width == 3)
	game.set_process(false)
	camera.current = true
	camera.position = game.mower.global_position + Vector3(4, 2.8, -5)
	camera.look_at(game.mower.global_position + Vector3.UP * 0.8)
	await capture("/tmp/firstpitch-career-deck.png")
	print(
		"Career graphical: real mowing + 18 impacts paid ",
		floori(result.score),
		" cr; fixture-funded native upgrades, rank, results, Escape, fresh shift verified"
	)
	DirAccess.remove_absolute(game.career_save_path)
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
