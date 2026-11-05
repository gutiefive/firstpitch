extends SceneTree
var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func fund(g: Node) -> void:
	var s := ShiftSession.new()
	s.start("full")
	s.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
	s.advance(1)
	g.shift.career.claim(s.attempt_id, s.get_result())
	s.free()


func place_marker(g: Node, offset: float, angle: float, along: float = 16) -> void:
	for action in ["forward", "back", "left", "right", "brake"]:
		Input.action_release(action)
	g.chalk.reset_state()
	g.chalk_marker.set_occupied(true)
	g.pushing_chalk = true
	g.player.set_seated(true)
	var direction: Vector2 = g.chalk.line_direction(1)
	var across := Vector2(-direction.y, direction.x)
	var point: Vector2 = g.layout.plate_position + direction * along + across * offset
	g.chalk_marker.position = Vector3(point.x, 0.06, point.y)
	g.chalk_marker.rotation.y = -PI / 4 + angle
	g.chalk_marker.speed = 0
	g.chalk_marker.velocity = Vector3.ZERO
	g.chalk_marker.gate_open = true
	g.chalk_marker.last_nozzle = g.chalk_marker.nozzle.global_position
	await frames(8)


func run() -> void:
	var path := "user://test-equipment-career.dat"
	DirAccess.remove_absolute(path)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = path
	g.settings_save_path = "user://test-equipment-settings.cfg"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	root.add_child(g)
	await frames(15)
	check(
		(
			g.mower.drag.working_width == 2.8
			and not g.chalk_marker.guide_wheel_owned
			and not g.chalk_marker.guide_visual.visible
		),
		"new career retains original equipment behavior"
	)
	check(
		(
			g.shift.overlay.career_panel.shop.wide_drag.disabled
			and g.shift.overlay.career_panel.shop.guide_wheel.disabled
		),
		"new shop upgrades display rank locks"
	)
	g.infield.paint(Vector3(10, 0, -10), Vector3.FORWARD, g.mower.drag.working_width, 1.2)
	var standard_cells: int = g.infield.prepared_count
	var store := FieldSave.new()
	var old_field := store.capture(g, g.shift.session)
	await place_marker(g, 0.25, deg_to_rad(-8))
	Input.action_press("forward")
	await frames(120)
	Input.action_release("forward")
	var standard_error: float = g.chalk.distance_to_guide(g.chalk_marker.nozzle.global_position)
	check(
		not g.chalk_marker.guide_active and standard_error > 0.65,
		"unowned guide wheel never changes standard cart steering"
	)
	fund(g)
	check(
		(
			g.shift.career.balance == 450
			and not g.shift.career.purchase("wide_drag")
			and not g.shift.career.purchase("guide_wheel")
		),
		"sufficient wallet alone cannot bypass Field Hand unlock"
	)
	var forged: Dictionary = g.shift.career.data.duplicate(true)
	forged.upgrades.append("wide_drag")
	check(
		not g.shift.career.validate(forged), "ledger validation rejects affordable but rank-locked equipment"
	)
	fund(g)
	check(
		g.shift.career.upgrade_unlocked("wide_drag") and g.shift.career.upgrade_unlocked("guide_wheel"),
		"500 lifetime credits unlock both equipment choices"
	)
	var wallet: int = g.shift.career.balance
	g.shift.career.path = "user://missing-equipment-directory/career.dat"
	check(
		(
			not g.shift.career.purchase("guide_wheel")
			and g.shift.career.balance == wallet
			and not g.chalk_marker.guide_wheel_owned
		),
		"failed equipment write leaves wallet and physical gear untouched"
	)
	g.shift.career.path = path
	check(
		g.shift.career.purchase("wide_drag") and g.shift.career.balance == 500,
		"wide drag purchases once for 400 credits"
	)
	check(
		(
			is_equal_approx(g.mower.drag.working_width, 3.5)
			and g.mower.drag.frame.scale.x == 1.25
			and g.tool_bay.parked_drag.frame.scale.x == 1.25
		),
		"mounted and parked drag visuals match upgraded working width"
	)
	g.infield.reset_state()
	g.infield.paint(Vector3(10, 0, -10), Vector3.FORWARD, g.mower.drag.working_width, 1.2)
	check(g.infield.prepared_count > standard_cells, "wider drag prepares more actual valid dirt cells")
	g.shift.apply_upgrades()
	g.shift.apply_upgrades()
	check(
		g.mower.drag.working_width == 3.5 and g.mower.drag.frame.scale.x == 1.25,
		"reapplying purchases cannot stack width multipliers"
	)
	check(
		(
			g.shift.career.purchase("guide_wheel")
			and g.shift.career.balance == 150
			and g.chalk_marker.guide_visual.visible
		),
		"guide wheel purchase adds visible gear and spends 350 credits"
	)
	check(
		not g.shift.career.purchase("guide_wheel") and not g.shift.career.purchase("wide_drag"),
		"owned equipment cannot charge again"
	)
	check(
		g.shift.career.rank_title() == "Field Hand" and g.shift.career.upgrade_unlocked("guide_wheel"),
		"spending below unlock threshold never removes earned equipment access"
	)
	await place_marker(g, 0.25, deg_to_rad(-8))
	var before: int = g.chalk.covered_count
	await frames(8)
	check(
		not g.chalk_marker.guide_active and g.chalk.covered_count == before,
		"stationary cart has no automatic steering or paint credit"
	)
	Input.action_press("forward")
	await frames(120)
	var guided_error: float = g.chalk.distance_to_guide(g.chalk_marker.nozzle.global_position)
	check(
		g.chalk_marker.guide_active and guided_error < 0.11 and guided_error < standard_error,
		"actual forward pushing converges onto the foul guide"
	)
	check(
		g.chalk.covered_count > 0 and g.chalk.offguide_metres > 0,
		"assisted chalk earns actual on-guide coverage while early off-guide marks still cost quality"
	)
	check(g.mode_label.text.contains("GUIDE WHEEL"), "HUD reports active assistance")
	Input.action_press("brake")
	await frames(2)
	check(not g.chalk_marker.guide_active, "braking immediately suspends steering assistance")
	Input.action_release("brake")
	Input.action_press("left", 0.05)
	await frames(6)
	check(not g.chalk_marker.guide_active, "even light manual steering overrides the guide wheel immediately")
	Input.action_release("forward")
	Input.action_release("left")
	await place_marker(g, 0, 0)
	g.chalk_marker.gate_open = false
	Input.action_press("forward")
	await frames(45)
	check(
		not g.chalk_marker.guide_active and g.chalk.covered_count == 0,
		"closed gate disables assistance and never paints"
	)
	await place_marker(g, 0, 0)
	Input.action_press("back")
	await frames(45)
	check(
		not g.chalk_marker.guide_active and g.chalk.covered_count == 0,
		"reverse motion never receives steering help or chalk credit"
	)
	await place_marker(g, 1.5, 0)
	Input.action_press("forward")
	await frames(45)
	check(
		not g.chalk_marker.guide_active and is_equal_approx(g.chalk_marker.rotation.y, -PI / 4),
		"distant cart is never pulled or snapped onto a guide"
	)
	await place_marker(g, 0, PI / 2)
	Input.action_press("forward")
	await frames(10)
	check(not g.chalk_marker.guide_active, "crossing a foul line at a steep angle remains manual")
	await place_marker(g, 0, 0, g.chalk.line_end + 2)
	Input.action_press("forward")
	await frames(12)
	check(
		not g.chalk_marker.guide_active and g.chalk.covered_count == 0,
		"beyond the guide endpoint there is no assisted steering or line credit"
	)
	await place_marker(g, 0.2, PI)
	Input.action_press("forward")
	await frames(100)
	check(
		(
			g.chalk_marker.guide_active
			and g.chalk.distance_to_guide(g.chalk_marker.nozzle.global_position) < 0.11
		),
		"guide wheel works in either forward travel direction along a foul line"
	)
	Input.action_release("forward")
	check(
		(
			store.restore(g, g.shift, old_field)
			and g.mower.drag.working_width == 3.5
			and g.chalk_marker.guide_wheel_owned
		),
		"loading pre-purchase field state keeps owned equipment"
	)
	check(
		not g.chalk_marker.guide_active and g.chalk_marker.guide_visual.visible,
		"parked cart keeps its upgrade without steering while unoccupied"
	)
	g.queue_free()
	await create_timer(0.15).timeout
	g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = path
	g.tutorial_enabled = false
	g.autosave_enabled = false
	root.add_child(g)
	await frames(5)
	check(
		(
			g.shift.career.balance == 150
			and g.mower.drag.working_width == 3.5
			and g.chalk_marker.guide_wheel_owned
		),
		"career restart restores both gear purchases and exact wallet"
	)
	g.shift.start_shift("training")
	check(
		g.mower.drag.working_width == 3.5 and g.chalk_marker.guide_visual.visible,
		"fresh shifts retain all purchased equipment"
	)
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test-equipment-settings.cfg")
	print("Equipment upgrades: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
