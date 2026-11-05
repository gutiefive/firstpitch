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


func run() -> void:
	var s := ShiftSession.new()
	s.start("full")
	s.configure_work([0, 50, 100, 0, 10], [100, 100, 100, 100, 20], "game_day", 5)
	s.set_counts([0, 75, 100, 0, 15], [false, false, true, false, false])
	check(
		s.values == PackedFloat64Array([0, 50, 100, 0, 50]),
		"repair progress subtracts baseline and treats no-needed-work as complete"
	)
	s.set_progress([100, 100, 100, 100, 100], [true, true, true, true, false])
	check(
		s.coverage_score() == 99.9 and s.jobs_completed() == 4,
		"100-percent goals retain exact-completion guard"
	)
	check(
		s.set_quality([1, 0.75, 0.7, 0.75, 1]) and is_equal_approx(s.quality_multiplier(), 0.84),
		"requested-job quality averages penalties within bounds"
	)
	check(
		s.score() == 83.9 and "off-guide" in s.quality_tip(),
		"final score multiplies coverage and points to largest loss"
	)
	check(
		not s.set_quality([1, NAN, 1, 1, 1]) and not s.set_quality([1, 1, 1, 1, 0.9]),
		"invalid quality and mound penalties are rejected"
	)
	s.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
	s.advance(0)
	check(s.phase == ShiftSession.Phase.FINISHED, "quality penalties never block exact coverage completion")
	check(
		CareerProfile.valid_result(s.get_result()) and CareerProfile.payout(s.get_result()) == 402,
		"quality-adjusted completed score validates and pays with completion bonus"
	)
	s.free()
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-quality-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	var point := Vector3(10, 0, -10)
	g.moisture.spray_at(point, 5)
	g.shift.collect_progress()
	check(g.shift.session.job_quality[3] < 1, "overwatering independently reduces water quality")
	check(
		g.moisture.puddle_at(point) and g.moisture.overwatered_count > 0,
		"soaking creates timed puddles and overwatering history"
	)
	g.infield.drag_segment(point, point, Vector3.FORWARD, 2, 1)
	check(g.infield.prepared_count == 0 and g.infield.blocked_puddles, "puddles block drag preparation")
	g.moisture.advance_drying(13)
	check(
		not g.moisture.puddle_at(point) and g.moisture.overwatered_count > 0,
		"puddles dry while retaining quality penalty history"
	)
	g.moisture.fill_valid(0.8)
	g.infield.drag_segment(point, point, Vector3.FORWARD, 2, 1)
	check(
		g.infield.prepared_count > 0 and g.infield.rut_count > 0 and g.infield.wet_dragging,
		"wet nonpuddled dragging earns coverage but leaves ruts"
	)
	g.shift.collect_progress()
	check(g.shift.session.job_quality[1] < 1, "ruts reduce dirt quality")
	var store := FieldSave.new()
	var rut_save := store.capture(g, g.shift.session)
	check(
		store.restore(g, g.shift, rut_save) and store.capture(g, g.shift.session) == rut_save,
		"rut flags and quality round trip exactly"
	)
	g.moisture.fill_valid(0.7)
	g.infield.drag_segment(point, point, Vector3.FORWARD, 2, 1)
	check(g.infield.rut_count == 0, "a dry drag pass repairs ruts without duplicate coverage")
	g.chalk.paint_segment(Vector3(10, 0, -14), Vector3(12, 0, -14))
	check(g.chalk.offguide_metres > 1.9, "off-guide visible chalk records wasted metres")
	g.shift.collect_progress()
	check(g.shift.session.job_quality[2] < 1, "off-guide metres reduce chalk quality")
	g.grass.paint(Vector3(0, 0, -60), Vector3.FORWARD)
	g.shift.collect_progress()
	check(
		g.grass.stripe_samples >= 20 and g.shift.session.mowing_bonus > 0,
		"consistent neighbouring cut headings earn a modest stripe bonus"
	)
	var matching_bonus: float = g.shift.session.mowing_bonus
	g.grass.reset_state()
	g.grass.paint(Vector3(0, 0, -60), Vector3.FORWARD)
	g.grass.paint(Vector3(1.5, 0, -60), Vector3.RIGHT)
	g.shift.collect_progress()
	check(
		g.shift.session.mowing_bonus < matching_bonus, "crossed cut headings reduce stripe consistency bonus"
	)
	# Hand-built pre-quality career ledger: no new result fields at all.
	var legacy_result := {
		"profile_id": "full",
		"title": "Full park prep",
		"reason": "completed",
		"score": 100.0,
		"jobs_completed": 5,
		"values": [100.0, 100.0, 100.0, 100.0, 100.0],
		"goals": [100.0, 100.0, 100.0, 100.0, 100.0],
		"met": [true, true, true, true, true],
		"elapsed_seconds": 30.0,
		"remaining_seconds": 1770.0,
		"duration_seconds": 1800.0
	}
	var ledger := {
		"version": 1,
		"records": [{"id": "0123456789abcdef0123456789abcdef", "result": legacy_result}],
		"upgrades": PackedStringArray()
	}
	var career := CareerProfile.new()
	career.path = "user://test-legacy-quality-career.dat"
	var bytes := var_to_bytes(ledger)
	var file := FileAccess.open(career.path, FileAccess.WRITE)
	file.store_buffer("FPCREW01".to_ascii_buffer())
	file.store_buffer(store.digest(bytes))
	file.store_buffer(bytes)
	file.close()
	check(
		career.load_profile() and career.balance == 450 and career.earned == 450,
		"hand-built v1 career loads old score and payout unchanged"
	)
	check(
		(
			career.claim("0123456789abcdef0123456789abcdef", legacy_result).status == "recorded"
			and career.balance == 450
		),
		"legacy paid attempt remains protected against duplicate payout"
	)
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute("user://test-quality-career.dat")
	DirAccess.remove_absolute(career.path)
	print("Quality: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
