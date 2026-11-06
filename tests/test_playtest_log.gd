extends SceneTree
var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func rows(path: String) -> Array:
	var out := []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return out
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == PlaytestLog.HEADER.size():
			out.append(Array(row))
	file.close()
	return out


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://playtest-test-career.dat"
	g.settings_save_path = "user://playtest-test-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	root.add_child(g)
	await process_frame
	var logbook: PlaytestLog = g.shift.playtest
	logbook.path = "user://playtest-test.csv"
	check(not logbook.enabled, "local timing log is off by default")
	g.shift.start_shift("mound_callout")
	g.shift.end_shift()
	check(not FileAccess.file_exists(logbook.path), "disabled logging creates no files")
	logbook.enabled = true
	g.shift.start_shift("mound_callout")
	var id: String = g.shift.session.attempt_id
	g.shift.session.advance(5)
	g.mound.prepare_all()
	g.shift.collect_progress()
	g.shift.session.advance(1)
	var output := rows(logbook.path)
	check(
		output.size() == 2 and output[0] == PlaytestLog.HEADER,
		"one finished shift appends one row with the fixed columns"
	)
	check(
		output[1][1] == "mound_callout" and output[1][2] == "completed" and float(output[1][3]) == 6,
		"CSV preserves profile, end reason and actual elapsed time"
	)
	check(
		float(output[1][8]) == 5 and output[1][4] == "" and output[1][5] == "",
		"first observed goal time is retained; unrequested jobs stay blank"
	)
	check(
		float(output[1][9]) == 100 and int(output[1][10]) == 40 and output[1][11] == id,
		"CSV score and paid credits match the real settled shift"
	)
	check(
		logbook.record(g.shift.session, 40) and rows(logbook.path).size() == 2,
		"same finished attempt cannot produce duplicate rows"
	)
	var restart := PlaytestLog.new()
	restart.enabled = true
	restart.path = logbook.path
	check(
		restart.record(g.shift.session, 40) and rows(logbook.path).size() == 2,
		"duplicate protection survives logger recreation"
	)
	g.shift.start_shift("training")
	g.shift.session.advance(7)
	g.shift.end_shift()
	output = rows(logbook.path)
	check(
		output.size() == 3 and output[2][2] == "ended_early" and output[2][4] == "",
		"unfinished goals have no invented completion time"
	)
	var saved: Dictionary = g.shift.career.data.duplicate(true)
	logbook.path = "user://missing-playtest-directory/log.csv"
	logbook.loaded_path = ""
	g.shift.start_shift("mound_callout")
	g.shift.end_shift()
	check(
		(
			not logbook.error.is_empty()
			and g.shift.career.healthy
			and g.shift.career.data.records.size() == saved.records.size() + 1
		),
		"optional log failure does not block normal once-only settlement"
	)
	paused = false
	g.queue_free()
	await process_frame
	print("Playtest log: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
