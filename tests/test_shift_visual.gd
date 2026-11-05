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
	game.career_save_path = "user://test-test_shift_visual-career.dat"
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
	await capture("/tmp/firstpitch-shift-results.png")
	await button_click(game.shift.overlay.full_button)
	await idle_frames(5)
	if (
		paused
		or game.mound.work_done != game.shift.session.starting_counts[CrewJob.MOUND]
		or game.grass.cut_count != 0
		or game.shift.session.profile_id != "full"
	):
		push_error("Native fresh shift did not reset the world")
		quit(1)
		return
	await capture("/tmp/firstpitch-shift-restart.png")
	# Fast-forward only the deadline branch; this is not a 30-minute playthrough.
	game.shift.session.advance(game.shift.session.remaining_seconds + 1)
	await capture("/tmp/firstpitch-shift-time-up.png")
	if game.shift.session.get_result()["reason"] != "time_up":
		push_error("Graphical timeout result did not appear")
		quit(1)
		return
	await button_click(game.shift.overlay.close_button)
	await idle_frames(5)
	if paused:
		push_error("Native practice return did not unpause")
		quit(1)
		return
	print(
		(
			"Graphical shift: native Tab/start/resume/end/restart verified; real mowing + 18 mound "
			+ "impacts; score "
		),
		result["score"],
		"; deadline branch fast-forwarded"
	)
	quit()
