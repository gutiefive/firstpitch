extends SceneTree
var failures := 0


func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error(message)
		failures += 1


func press_key(game: Node, key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game = load("res://scenes/main/main.tscn").instantiate()
	game.career_save_path = "user://test-test_chalk_gameplay-career.dat"
	game.tutorial_enabled = false
	game.autosave_enabled = false
	DirAccess.remove_absolute(game.career_save_path)
	root.add_child(game)
	for i in range(60):
		await physics_frame
	check(game.chalk_marker.is_on_floor(), "chalk marker settles on terrain")
	game.player.global_position = game.chalk_marker.global_position + Vector3(1.3, 0, 0)
	press_key(game, KEY_E)
	check(
		game.pushing_chalk and game.player.seated and game.chalk_marker.occupied,
		"E transfers control to nearby chalk marker"
	)
	check(not game.driving and not game.mower.occupied, "tractor stays inactive while pushing marker")
	check(not game.chalk_marker.gate_open, "marker starts with gate closed")
	check(game.hud.objective_label.text == "Chalk both foul lines", "HUD selects chalk objective")
	check(not game.swap_work_tool(), "cannot swap tractor equipment while pushing marker")
	var direction: Vector2 = game.chalk.line_direction(1)
	game.chalk_marker.global_position = Vector3(direction.x * 8, 0.05, direction.y * 8)
	game.chalk_marker.rotation.y = -PI / 4
	game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
	Input.action_press("forward")
	for i in range(60):
		await physics_frame
	check(
		game.chalk.covered_count == 0 and game.chalk.pending.is_empty(),
		"closed gate makes no chalk or progress"
	)
	press_key(game, KEY_R)
	check(game.chalk_marker.gate_open, "R opens chalk gate")
	for i in range(120):
		await physics_frame
	check(game.chalk.covered_count > 10, "pushing on a foul line earns actual coverage")
	check(game.audio.loops.chalk.playing, "actual forward open-gate chalking plays cart sound")
	check(game.progress.value > 0, "chalk coverage reaches HUD")
	check(
		game.grass.cut_count == 0 and game.infield.prepared_count == 0,
		"chalking does not progress other tasks"
	)
	press_key(game, KEY_E)
	check(game.pushing_chalk, "cannot leave a moving chalk marker")
	press_key(game, KEY_R)
	var count: int = game.chalk.covered_count
	var gap_start := (
		Vector2(game.chalk_marker.nozzle.global_position.x, game.chalk_marker.nozzle.global_position.z)
		. dot(direction)
	)
	for i in range(60):
		await physics_frame
	check(game.chalk.covered_count == count, "closing gate stops progress during travel")
	var gap_end := (
		Vector2(game.chalk_marker.nozzle.global_position.x, game.chalk_marker.nozzle.global_position.z)
		. dot(direction)
	)
	press_key(game, KEY_R)
	for i in range(60):
		await physics_frame
	var gap_index := floori(((gap_start + gap_end) * 0.5 - game.chalk.line_start) / game.chalk.segment_step)
	check(
		game.chalk.covered[game.chalk.sections_per_line + gap_index] == 0,
		"reopening gate does not bridge the unpainted gap"
	)
	Input.action_release("forward")
	Input.action_press("brake")
	for i in range(60):
		await physics_frame
	Input.action_release("brake")
	count = game.chalk.covered_count
	press_key(game, KEY_E)
	check(not game.pushing_chalk and not game.player.seated, "stopped marker exit restores walking")
	check(not game.chalk_marker.gate_open, "leaving closes chalk gate")
	check(game.chalk.covered_count == count, "chalk coverage persists after leaving")
	# Reverse over untouched left-line sections to prove no accidental credit.
	direction = game.chalk.line_direction(0)
	game.chalk_marker.global_position = Vector3(direction.x * 15, 0.05, direction.y * 15)
	game.chalk_marker.rotation.y = PI / 4
	game.player.global_position = game.chalk_marker.global_position + Vector3(1.3, 0, 0)
	press_key(game, KEY_E)
	press_key(game, KEY_R)
	Input.action_press("back")
	for i in range(60):
		await physics_frame
	Input.action_release("back")
	check(
		game.chalk.covered_count == count and game.chalk.line_counts[0] == 0,
		"reverse on untouched guide does not paint"
	)
	for i in range(60):
		await physics_frame
	check(game.chalk.covered_count == count, "open gate while stationary cannot inflate progress")
	# The marker must stop at real stadium collision.
	game.chalk_marker.global_position = Vector3(31, 0.05, -11)
	game.chalk_marker.rotation.y = -PI / 2
	game.chalk_marker.speed = 0
	game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
	Input.action_press("forward")
	for i in range(180):
		await physics_frame
	Input.action_release("forward")
	check(game.chalk_marker.global_position.x < 34, "chalk marker cannot pass through workshop wall")
	check(game.chalk_marker.can_exit(), "wall contact stops marker")
	press_key(game, KEY_E)
	game.player.global_position = game.mower.global_position + Vector3(2.4, 0, 0)
	press_key(game, KEY_E)
	check(
		game.driving and not game.pushing_chalk and not game.chalk_marker.occupied,
		"tractor can be used again without control conflict"
	)
	check(game.hud.objective_label.text == "Mow the outfield", "returning to tractor restores its objective")
	check(game.chalk.covered_count == count, "changing tools preserves chalk coverage")
	# Exercise the completion boundary without claiming an end-to-end full-field playtest.
	game.mound.work_done = game.mound.total_work
	game.grass.cut_count = game.grass.total - 1
	game.infield.prepared_count = game.infield.total
	game.chalk.covered_count = game.chalk.valid_count
	game.moisture.wet_count = game.moisture.total
	game.update_progress(0)
	check(
		not game.hud.objective_label.text.begins_with("PARK READY"),
		"one remaining grass cell prevents park completion"
	)
	check(game.percent_label.text != "COMPLETE", "rounded percentage cannot prematurely complete a task")
	game.grass.cut_count = game.grass.total
	game.update_progress(0)
	check(
		game.hud.objective_label.text.begins_with("PARK READY"),
		"park completion requires all five full task counts"
	)
	print("Chalk gameplay failures: ", failures)
	game.queue_free()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
