extends SceneTree
var checks := 0
var failures := 0
const CAREER := "user://test-autosave-career.dat"
const AUTO := "user://test-autosave-field.dat"
const MANUAL := "user://test-autosave-manual.dat"


func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func scene() -> Node:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = CAREER
	g.settings_save_path = "user://test-autosave-settings.cfg"
	g.autosave_save_path = AUTO
	g.tutorial_enabled = false
	root.add_child(g)
	g.autosave.set_process(false)
	return g


func dispose(g: Node) -> void:
	paused = false
	g.queue_free()
	await create_timer(0.12).timeout


func run() -> void:
	for path in [CAREER, AUTO, MANUAL, AUTO.get_basename() + ".bad"]:
		DirAccess.remove_absolute(path)
	var file := FileAccess.open(MANUAL, FileAccess.WRITE)
	file.store_string("manual slot sentinel")
	file.close()
	var g := scene()
	await process_frame
	g.shift.save_store.path = MANUAL
	check(g.shift.start_shift("mound_callout") and g.autosave.pending, "attempt start queues autosave")
	g.autosave.advance(0)
	check(g.autosave.writes == 1 and FileAccess.file_exists(AUTO), "start trigger writes separate autosave")
	g.mound.apply_tamp(0)
	g.shift.collect_progress()
	g.shift.session.advance(17)
	g.autosave.advance(59)
	check(
		g.autosave.writes == 1 and g.autosave.dirty,
		"surface signal marks dirty without an early interval save"
	)
	g.autosave.advance(1)
	check(g.autosave.writes == 2 and not g.autosave.dirty, "60-second dirty interval saves once")
	g.autosave.advance(60)
	check(g.autosave.writes == 2, "idle interval does not save")
	g.chalk.paint_segment(Vector3(10, 0, -14), Vector3(12, 0, -14))
	g.chalk._process(0.2)
	check(g.autosave.dirty, "off-guide-only chalk signals unsaved visual and quality work")
	g.autosave.since_write = 0
	g.shift.open_board()
	g.autosave.advance(0.9)
	check(g.autosave.writes == 2 and g.autosave.pending, "board trigger obeys one-second write limit")
	g.autosave.advance(0.11)
	check(
		g.autosave.writes == 3 and g.shift.overlay.autosave_footer.text.begins_with("Autosaved "),
		"board save publishes timestamp footer"
	)
	check(
		FileAccess.get_file_as_string(MANUAL) == "manual slot sentinel",
		"autosave never overwrites manual slot"
	)
	var elapsed: float = g.shift.session.elapsed_seconds
	var id: String = g.shift.session.attempt_id
	await dispose(g)
	g = scene()
	await process_frame
	check(
		(
			paused
			and g.shift.overlay.resume_card.visible
			and g.shift.session.phase == ShiftSession.Phase.PRACTICE
		),
		"launch offers active autosave without applying it before choice"
	)
	var rail_locked := true
	for control in g.shift.overlay.navigation.get_children():
		if control is Button:
			rail_locked = rail_locked and control.disabled
	check(
		rail_locked and g.shift.overlay.resume_button.has_focus(),
		"recovery locks every navigation shortcut and focuses Resume"
	)
	check(
		(
			g.shift.overlay.resume_summary.text.contains("Mound callout")
			and g.shift.overlay.resume_summary.text.contains("left")
		),
		"resume card describes title, remaining clock and progress"
	)
	check(
		not g.shift.start_shift("training") and not g.autosave.pending,
		"unresolved resume protects backup from replacement starts and board writes"
	)
	check(
		g.autosave.resume() and paused and g.shift.session.attempt_id == id,
		"resume restores original attempt and leaves world paused"
	)
	check(
		(
			g.shift.session.elapsed_seconds == elapsed
			and g.mound.work_done == 1
			and g.player.position == g.layout.player_spawn
		),
		"resume preserves clock and work while parking equipment"
	)
	g.autosave.since_write = 1
	g.autosave.advance(0)
	g.autosave.start_fresh()
	check(
		(
			g.shift.session.phase == ShiftSession.Phase.PRACTICE
			and g.mound.work_done == 0
			and g.autosave.candidate.is_empty()
		),
		"Start fresh clears resumed field through existing reset path"
	)
	g.shift.close_board()
	g.shift.start_shift("mound_callout")
	g.mound.apply_tamp(0)
	g.shift.collect_progress()
	# Failed career write creates the unpaid finished-attempt recovery scenario.
	g.shift.career.path = "user://missing-autosave-directory/career.dat"
	g.shift.end_shift()
	g.autosave.advance(1.1)
	check(
		(
			g.shift.session.phase == ShiftSession.Phase.FINISHED
			and g.autosave.store.read(g).session.phase == ShiftSession.Phase.FINISHED
		),
		"finish trigger saves even when reward write fails"
	)
	var unpaid: Dictionary = g.autosave.store.read(g)
	await dispose(g)
	g = scene()
	await process_frame
	check(paused and not g.autosave.candidate.is_empty(), "unpaid finished autosave offers recovery")
	check(
		g.autosave.resume() and g.shift.career.balance == 1,
		"resuming unpaid result claims its original proportional pay"
	)
	g.autosave.candidate = unpaid
	check(
		g.autosave.resume() and g.shift.career.balance == 1 and g.shift.career.data.records.size() == 1,
		"resuming same finished attempt twice pays once"
	)
	g.autosave.candidate = unpaid
	var before := FileAccess.get_file_as_bytes(AUTO)
	g.autosave.request()
	g.autosave.advance(2)
	check(
		FileAccess.get_file_as_bytes(AUTO) == before,
		"opening a pending recovery never overwrites its snapshot"
	)
	g.autosave.candidate.clear()
	g.autosave.since_write = 0
	g.autosave.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(
		g.autosave.quitting and g.autosave.pending and paused,
		"window-close notification queues save before quit"
	)
	# Keep this test process alive while exercising the production pending-write path.
	g.autosave.quitting = false
	g.autosave.advance(1.1)
	check(
		not g.autosave.pending and g.autosave.store.read(g).session.attempt_id == g.shift.session.attempt_id,
		"queued quit snapshot commits through rate-limited write path"
	)
	# Full-field fixture for measured snapshot/validation/atomic-write cost.
	g.shift.enter_practice()
	g.shift.wear.bootstrap(g, "full")
	g.grass.cut = g.grass.valid.duplicate()
	g.grass.cut_count = g.grass.total
	for i in range(g.grass.valid.size()):
		if g.grass.valid[i] == 1:
			g.grass.image.set_pixel(i % g.grass.resolution.x, i / g.grass.resolution.x, Color(1, 0.5, 0.5, 1))
	g.autosave.since_write = 1
	check(g.autosave.write_now(), "full-field state autosaves successfully")
	print("FULL_FIELD_AUTOSAVE_MS=", g.autosave.last_ms)
	await dispose(g)
	# Irrecoverable fixture: no valid redundant autosave may remain.
	DirAccess.remove_absolute(AUTO + ".bak")
	DirAccess.remove_absolute(AUTO + ".tmp")
	file = FileAccess.open(AUTO, FileAccess.WRITE)
	file.store_string("damaged autosave")
	file.close()
	g = scene()
	await process_frame
	check(
		(
			not paused
			and FileAccess.file_exists(AUTO.get_basename() + ".bad")
			and not FileAccess.file_exists(AUTO)
		),
		"corrupt autosave is quarantined without blocking startup"
	)
	check(
		g.shift.overlay.autosave_footer.text.contains("damaged"), "corrupt autosave leaves a one-line notice"
	)
	var output := []
	var exit_code := OS.execute(
		OS.get_executable_path(),
		[
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"--script",
			"res://tests/fixtures/autosave_quit.gd"
		],
		output,
		true
	)
	var quit_store := FieldSave.new()
	quit_store.path = "user://test-quit-autosave.dat"
	var quit_data := quit_store.read(g)
	check(
		(
			exit_code == 0
			and not quit_data.is_empty()
			and quit_data.session.phase == ShiftSession.Phase.ACTIVE
			and quit_data.session.elapsed >= 23
			and quit_data.hits[0] == 1
		),
		"separate window-close process saves clock/work before actually exiting"
	)
	for path in [quit_store.path, "user://test-quit-career.dat", "user://test-quit-settings.cfg"]:
		DirAccess.remove_absolute(path)
	await dispose(g)
	for path in [CAREER, AUTO, MANUAL, AUTO.get_basename() + ".bad"]:
		DirAccess.remove_absolute(path)
	print("Autosave: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
