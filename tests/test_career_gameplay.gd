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


func frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var path := "user://test-career-gameplay.dat"
	DirAccess.remove_absolute(path)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = path
	g.tutorial_enabled = false
	g.autosave_enabled = false
	root.add_child(g)
	await frames(5)
	check(
		g.shift.career.balance == 0 and g.grass.deck_width == 2.4,
		"scene begins with standard equipment and a new career"
	)
	g.grass.paint(Vector3(0, 0, -60), Vector3.FORWARD)
	var standard_cut: int = g.grass.cut_count
	g.moisture.spray_at(Vector3(10, 0, -10), 0.1)
	var standard_dose: float = g.moisture.moisture_at(Vector3(10, 0, -10))
	g.shift.collect_progress()
	check(g.shift.career.data.records.is_empty(), "free practice does not create earnings")
	g.shift.open_board()
	g.shift.start_shift("training")
	var attempt: String = g.shift.session.attempt_id
	g.mound.apply_tamp(0)
	g.shift.collect_progress()
	g.shift.save_store.path = "user://test-career-field.dat"
	var wrote: bool = g.shift.save_store.write(g, g.shift.session)
	var saved: Dictionary = g.shift.save_store.read(g)
	check(wrote and saved.session.attempt_id == attempt, "disk field save preserves active attempt identity")
	g.shift.end_shift()
	var paid: int = g.shift.career.balance
	check(
		paid > 0 and g.shift.career.data.records.size() == 1 and paused,
		"actual partial mound work pays when shift ends"
	)
	check(
		g.shift.overlay.career_reward.visible and g.shift.overlay.career_reward.text.begins_with("Earned"),
		"results show the committed payout"
	)
	check(
		g.shift.save_store.restore(g, g.shift, saved) and g.shift.session.attempt_id == attempt,
		"restoring a field preserves its attempt identity"
	)
	g.shift.end_shift()
	check(
		(
			g.shift.career.balance == paid
			and g.shift.career.data.records.size() == 1
			and g.shift.career_message.begins_with("Already recorded")
		),
		"finishing the same saved attempt twice cannot pay twice"
	)
	var legacy := saved.duplicate(true)
	legacy.session.erase("attempt_id")
	check(
		g.shift.save_store.restore(g, g.shift, legacy),
		"older field saves without attempt IDs remain loadable"
	)
	var legacy_id: String = g.shift.session.attempt_id
	g.shift.save_store.restore(g, g.shift, legacy)
	check(
		CareerProfile.valid_id(legacy_id) and g.shift.session.attempt_id == legacy_id,
		"older saves receive a stable repeatable identity"
	)
	# Seed two honest-format completed-result fixtures to exercise the shop without a full park run.
	for i in range(2):
		var s := ShiftSession.new()
		s.start("full")
		s.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
		s.advance(10)
		g.shift.career.claim(s.attempt_id, s.get_result())
		s.free()
	g.shift.overlay.career_button.pressed.emit()
	check(g.shift.overlay.career_screen.visible and paused, "career screen opens without resuming the shift")
	g.shift.overlay.career_panel.shop.wide_deck.pressed.emit()
	check(
		g.shift.career.owns("wide_deck") and g.grass.deck_width == 3 and g.mower.deck.scale.x == 1.25,
		"deck purchase changes actual footprint and visible deck"
	)
	g.shift.overlay.career_panel.shop.hose_nozzle.pressed.emit()
	check(
		g.shift.career.owns("hose_nozzle") and is_equal_approx(g.moisture.application_rate, 1.0),
		"nozzle purchase changes actual exposure rate"
	)
	g.grass.reset_state()
	g.grass.paint(Vector3(0, 0, -60), Vector3.FORWARD)
	check(g.grass.cut_count > standard_cut, "upgraded deck actually cuts more valid cells per pass")
	g.moisture.reset_state()
	g.moisture.spray_at(Vector3(10, 0, -10), 0.1)
	check(
		is_equal_approx(g.moisture.moisture_at(Vector3(10, 0, -10)), standard_dose * 1.25),
		"upgraded nozzle actually delivers 25 percent more moisture"
	)
	g.shift.save_store.restore(g, g.shift, saved)
	check(
		g.grass.deck_width == 3 and is_equal_approx(g.moisture.application_rate, 1.0),
		"loading an old field snapshot cannot roll back owned upgrades"
	)
	var balance: int = g.shift.career.balance
	check(
		g.shift.career.rank_title() == "Field Hand" and g.shift.career.earned >= 900,
		"career rank uses lifetime rewards after purchases"
	)
	g.shift.close_board()
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
			g.shift.career.balance == balance
			and g.grass.deck_width == 3
			and is_equal_approx(g.moisture.application_rate, 1.0)
		),
		"a recreated game restores career balance and purchased equipment"
	)
	g.shift.open_board()
	g.shift.start_shift("training")
	check(
		g.shift.session.attempt_id != attempt and g.grass.deck_width == 3,
		"fresh shifts get new identities and keep purchased upgrades"
	)
	g.shift.close_board()
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute("user://test-career-field.dat")
	print("Career gameplay: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
