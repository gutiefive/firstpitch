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


func complete(g: Node) -> void:
	g.grass.prepare_all()
	g.infield.prepare_all()
	g.moisture.fill_valid(0.8)
	g.chalk.prepare_all()
	g.mound.prepare_all()
	g.shift.collect_progress()
	g.shift.session.advance(0)


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if name == "recap":
		root.get_child(0).club.opening.finish()
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/firstpitch-loop-%s.png" % name)


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://game-day-gameplay-career.dat"
	g.settings_save_path = "user://game-day-gameplay-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	var c: CareerProfile = g.shift.career
	g.club.join()
	check(
		g.club.prepare() and g.shift.session.profile_id == "home_game",
		"first home prep retains familiar opener"
	)
	complete(g)
	check(g.club.host() and c.balance == 244, "opener still pays 160 wages plus 84 gate")
	check(
		g.shift.overlay.club_panel.recap_continue.has_focus(),
		"postgame controller focus lands beside the recap"
	)
	check(
		(
			paused
			and g.shift.overlay.club_screen.visible
			and g.shift.overlay.club_panel.receipt.text.contains("already received")
		),
		"hosting opens consolidated recap with wage accounting"
	)
	check(
		g.shift.overlay.club_panel.investment.text.contains("Next tool:"),
		"recap shows next investment progress"
	)
	check(
		not g.hud.condition_label.visible,
		"postgame practice clears the active condition HUD even while paused"
	)
	g.club.opening.finish()
	for pressed in [true, false]:
		var accept := InputEventJoypadButton.new()
		accept.device = 7
		accept.button_index = JOY_BUTTON_A
		accept.pressed = pressed
		Input.parse_input_event(accept)
		for i in range(2):
			await process_frame
	check(
		(
			g.shift.overlay.club_panel.prep_button.has_focus()
			and g.shift.session.phase == ShiftSession.Phase.PRACTICE
		),
		"native controller Continue focuses next prep without starting it"
	)
	check(g.club.prepare() and g.shift.session.profile_id == "home_hot", "second date starts hot-day prep")
	check(
		g.shift.session.goals()[3] == 90 and g.moisture.wet_count == 0,
		"hot afternoon starts dry and requires more watering"
	)
	for i in range(3):
		await process_frame
	check(
		g.hud.condition_label.visible and g.hud.condition_label.text.contains("Controlled watering"),
		"active HUD shows conditions and manager priority"
	)
	await capture("hot")
	var store := FieldSave.new()
	store.path = "user://game-day-rain-field.dat"
	var hot := store.capture(g, g.shift.session)
	check(store.validate(hot, g), "hot condition and work baselines produce valid field save")
	complete(g)
	var before: int = c.balance
	check(
		g.club.host() and c.balance > before + 35 and c.club.last.priority_bonus == 35,
		"successful hot prep pays manager bonus with gate income"
	)
	await capture("recap")
	var balance: int = c.balance
	var last: Dictionary = c.club.last.duplicate(true)
	check(
		store.restore(g, g.shift, hot) and g.shift.session.profile_id == "home_hot",
		"old hot field restores its original condition profile"
	)
	complete(g)
	check(
		c.balance == balance and c.club.last == last and not g.club.host(),
		"rewound paid condition cannot duplicate wages, gate or bonus"
	)
	g.shift.enter_practice()
	check(g.club.prepare() and g.shift.session.profile_id == "home_rain", "third date starts rain recovery")
	check(
		(
			g.shift.session.goals()[3] == 0
			and g.moisture.active_puddles.size() > 0
			and g.moisture.overwatered_count == 0
		),
		"rain creates draining puddles without player-overwatering penalty"
	)
	var rain := store.capture(g, g.shift.session)
	check(store.validate(rain, g), "rain puddles and frozen baselines save strictly")
	check(
		store.write(g, g.shift.session) and store.read(g).session.profile == "home_rain",
		"rain conditions and timers survive a real field-file round trip"
	)
	var injected := rain.duplicate(true)
	injected.session.profile = "home_hot"
	check(not store.validate(injected, g), "natural-rain puddle exception cannot be used by other profiles")
	await capture("rain-start")
	var point := Vector3(10, 0, -10)
	g.infield.drag_segment(point, point + Vector3(0, 0, -1), Vector3.FORWARD, 2, 0.6)
	check(g.infield.blocked_puddles, "standing water blocks the drag until the rain drains")
	check(
		store.restore(g, g.shift, rain) and g.moisture.active_puddles.size() > 0,
		"rain reload preserves standing water rather than regenerating conditions"
	)
	g.moisture.advance_drying(13)
	check(
		g.moisture.active_puddles.is_empty() and g.moisture.moisture_at(point) <= 0.75,
		"rain drains to workable moisture after its timer"
	)
	g.infield.drag_segment(point, point + Vector3(0, 0, -1), Vector3.FORWARD, 2, 0.6)
	check(g.infield.rut_count == 0, "waiting out rain allows clean dragging")
	await capture("rain")
	complete(g)
	check(g.club.host() and c.club.last.priority_bonus == 40, "clean rain recovery earns its priority bonus")
	check(
		(
			g.club.prepare()
			and g.shift.session.profile_id == "home_double"
			and g.shift.session.duration_seconds == 900
		),
		"fourth date has doubleheader wear and shorter clock"
	)
	check(
		g.shift.session.goals()[1] == 75 and g.shift.session.goals()[4] == 100,
		"doubleheader emphasizes dirt and mound repairs"
	)
	check(not g.club.prepare() and not g.club.host(), "active conditions retain start and host guards")
	complete(g)
	check(g.club.host() and c.club.last.priority_bonus == 50, "on-time doubleheader earns its manager bonus")
	check(
		(
			g.shift.overlay.club_panel.receipt.text.contains("MET")
			and g.shift.overlay.club_panel.receipt.text.contains("supporters")
		),
		"postgame recap combines priority outcome and fan growth"
	)
	var restored := CareerProfile.new()
	restored.path = c.path
	restored.load_profile()
	check(
		restored.club == c.club and restored.balance == c.balance,
		"relaunch retains condition receipts, bonuses and budget"
	)
	var total := 0
	for record in c.data.records:
		total += CareerProfile.payout(record.result)
	for receipt in c.club.hosted.values():
		total += int(receipt.net) + int(receipt.get("priority_bonus", 0))
	check(total == c.balance, "total wages plus gate and manager bonuses reconcile to wallet")
	DirAccess.remove_absolute(c.path)
	DirAccess.remove_absolute(store.path)
	paused = false
	g.queue_free()
	await process_frame
	print("Game-day gameplay: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
