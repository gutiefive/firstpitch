extends "res://tests/test_modern_ui.gd"


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await idle()


func run() -> void:
	root.size = Vector2i(1280, 720)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://matchday-ui-career.dat"
	g.settings_save_path = "user://matchday-ui-settings.cfg"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	await idle(12)
	var ui = g.shift.overlay
	var club = ui.club_panel
	var show: OpeningGates = g.club.opening
	var park: MatchdayPark = g.club.matchday
	root.disable_3d = true  # The presentation uses its own 3D viewport; menus are opaque.
	check(club.watch_button.disabled and not g.club.watch_last_game(), "unhosted games cannot be replayed")
	g.club.join()
	g.club.prepare()
	check(not g.club.can_watch(), "active prep prevents replay")
	g.grass.prepare_all()
	g.infield.prepare_all()
	g.moisture.fill_valid(0.8)
	g.chalk.prepare_all()
	g.mound.prepare_all()
	g.shift.collect_progress()
	g.shift.session.advance(0)
	g.club.host()
	show.set_process(false)
	await idle(4)
	var ledger: Dictionary = g.shift.career.data.duplicate(true)
	var money: int = g.shift.career.balance
	await click(show.pause_button)
	check(show.active and show.playback_paused, "native pause button controls presentation without exiting")
	var time := show.elapsed
	var position: Vector3 = park.agents[0].node.position
	show._process(2)
	park._process(0.1)
	g.club.life._process(0.1)
	check(
		show.elapsed == time and park.agents[0].node.position == position and not g.club.life.targets.crowd,
		"playback pause freezes clock, walkers and ambience"
	)
	await pad(JOY_BUTTON_X)
	check(not show.playback_paused, "controller X resumes playback")
	await key(KEY_SPACE)
	check(show.playback_paused and show.active, "keyboard Space pauses without triggering default accept")
	await key(KEY_SPACE)
	await key(KEY_Y)
	check(show.playback_speed == 2, "keyboard Y changes playback speed")
	await key(KEY_Y)
	await pad(JOY_BUTTON_Y)
	check(show.playback_speed == 2, "controller Y selects double speed")
	show._process(1)
	check(is_equal_approx(show.elapsed, time + 2), "double speed advances presentation clock twice as fast")
	await pad(JOY_BUTTON_RIGHT_SHOULDER)
	check(show.elapsed == 7 and park.stage == "concourse", "controller RB jumps to next chapter")
	await key(KEY_N)
	check(show.elapsed == 13 and park.stage == "game", "keyboard N reaches next chapter")
	await click(show.pause_button)
	check(
		(
			show.playback_paused
			and show.chapter_label.text.contains("THE GAME")
			and show.clock_label.text.contains("PAUSED")
		),
		"chapter and clock explain paused viewing state"
	)
	check(show.chapter_label.get_global_rect().size.y < 60, "chapter badge remains a compact readable label")
	for pressed in [true, false]:
		var pointer := InputEventMouseButton.new()
		pointer.position = Vector2(10, 10)
		pointer.button_index = MOUSE_BUTTON_LEFT
		pointer.pressed = pressed
		Input.parse_input_event(pointer)
		await process_frame
	check(show.active, "clicks outside playback controls cannot dismiss the show")
	await capture("watch-live")
	root.size = Vector2i(1024, 768)
	await idle(8)
	check(
		Rect2(Vector2.ZERO, Vector2(root.size)).encloses(show.controls.get_global_rect()),
		"playback controls fit smaller window"
	)
	await capture("watch-compact")
	root.size = Vector2i(1280, 720)
	await idle(5)
	await click(show.next_button)
	check(show.elapsed == 40 and park.inning == 9, "next chapter remains usable while paused")
	await click(show.results_button)
	check(
		not show.active and club.selected_section == "results" and paused,
		"Results button returns to recap without starting next date"
	)
	check(
		g.shift.career.data == ledger and g.shift.career.balance == money,
		"viewing controls never alter settled finances"
	)
	var final := MatchdayPark.score_for(1)
	check(
		(
			club.match_summary.text.contains("Owls %d" % final.x)
			and club.match_summary.text.contains("Mill Creek Foxes %d" % final.y)
		),
		"Results uses the same displayed final as the simulation"
	)
	await capture("watch-results")
	var count := show.presentations
	await click(club.watch_button)
	check(
		(
			show.active
			and show.presentations == count + 1
			and show.elapsed == 0
			and show.playback_speed == 1
			and not show.playback_paused
		),
		"explicit replay resets playback controls"
	)
	await pad(JOY_BUTTON_A)
	check(
		not show.active and club.selected_section == "results" and club.recap_continue.has_focus(),
		"A exits replay without activating covered Continue"
	)
	check(
		g.shift.career.data == ledger and g.shift.career.balance == money,
		"replay cannot pay or append a hosted game"
	)
	await click(club.tabs.town)
	check(
		club.selected_section == "town" and club.town_voices.text.contains("Leni"),
		"Town tab opens latest character updates"
	)
	await click(club.town_buttons.Leni)
	check(
		(
			club.town_filter == "Leni"
			and club.town_voices.text.begins_with("Leni")
			and not club.town_voices.text.contains("Mara")
		),
		"speaker selection filters town conversation"
	)
	await capture("watch-town")
	await click(club.town_buttons.All)
	check(
		club.town_voices.text.contains("Mara") and club.town_voices.text.contains("Eli"),
		"Everyone restores complete town updates"
	)
	g.queue_free()
	await idle(4)
	DirAccess.remove_absolute("user://matchday-ui-career.dat")
	DirAccess.remove_absolute("user://matchday-ui-settings.cfg")
	print("Matchday UI: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
