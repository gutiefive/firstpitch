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


func remove_copies(path: String) -> void:
	for suffix in ["", ".tmp", ".bak", ".recover", ".bak.stage"]:
		DirAccess.remove_absolute(path + suffix)


func corrupt(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("damaged sentinel")
	file.close()


func run() -> void:
	var career := CareerProfile.new()
	career.path = "user://recovery-career.dat"
	remove_copies(career.path)
	career.load_profile()
	var shift := ShiftSession.new()
	shift.start("full")
	shift.set_progress([100, 100, 100, 100, 100], [true, true, true, true, true])
	shift.advance(0)
	var result := shift.get_result()
	check(career.claim(shift.attempt_id, result).status == "awarded", "normal career save")
	var snapshot := career.data.duplicate(true)
	DirAccess.rename_absolute(career.path, career.path + ".tmp")
	check(
		career.load_profile() and career.data == snapshot and career.error.contains("recovered"),
		"career recovers missing main from valid tmp"
	)
	DirAccess.copy_absolute(career.path, career.path + ".bak")
	corrupt(career.path)
	check(
		career.load_profile() and career.data == snapshot and career.error.contains("recovered"),
		"career recovers corrupt main from valid backup"
	)
	for suffix in ["", ".tmp", ".bak"]:
		corrupt(career.path + suffix)
	var sentinel := FileAccess.get_file_as_bytes(career.path)
	check(
		not career.load_profile() and not career.healthy and career.data == snapshot,
		"all corrupt career copies preserve memory and block changes"
	)
	check(
		not career.commit(snapshot) and FileAccess.get_file_as_bytes(career.path) == sentinel,
		"corrupt career copies are never overwritten"
	)
	DirAccess.remove_absolute(career.path)
	check(
		not career.load_profile() and not career.healthy,
		"missing main with damaged recovery copies cannot create a fresh career"
	)
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://recovery-scene-career.dat"
	g.settings_save_path = "user://recovery-settings.cfg"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	root.add_child(g)
	await process_frame
	var field := FieldSave.new()
	field.path = "user://recovery-field.dat"
	remove_copies(field.path)
	g.shift.start_shift("mound_callout")
	check(field.write(g, g.shift.session), "normal field save")
	var captured := field.capture(g, g.shift.session)
	DirAccess.rename_absolute(field.path, field.path + ".tmp")
	check(
		field.read(g) == captured and field.error.contains("recovered"),
		"field recovers missing main from tmp"
	)
	DirAccess.copy_absolute(field.path, field.path + ".bak")
	corrupt(field.path)
	check(
		field.read(g) == captured and field.error.contains("recovered"),
		"field recovers corrupt main from backup"
	)
	# A checksummed but invalid candidate must not outrank the valid backup.
	var file := FileAccess.open(field.path + ".tmp", FileAccess.WRITE)
	var bytes := var_to_bytes({"version": 3})
	file.store_buffer("FPGCSAVE".to_ascii_buffer())
	file.store_buffer(SaveRecovery.digest(bytes))
	file.store_buffer(bytes)
	file.close()
	corrupt(field.path)
	check(
		field.read(g) == captured, "full validation rejects checksummed invalid tmp before recovering backup"
	)
	for suffix in ["", ".tmp", ".bak"]:
		corrupt(field.path + suffix)
	check(
		field.read(g).is_empty() and not field.write(g, g.shift.session),
		"invalid field copies block replacement"
	)
	for suffix in ["", ".tmp", ".bak"]:
		check(
			FileAccess.get_file_as_string(field.path + suffix) == "damaged sentinel",
			"damaged field artifact retained"
		)
	remove_copies(field.path)
	field.write(g, g.shift.session)
	DirAccess.rename_absolute(field.path, field.path + ".tmp")
	g.autosave.store.path = field.path
	g.autosave.probe()
	check(
		not g.autosave.candidate.is_empty() and g.autosave.notice.contains("recovered"),
		"autosave probes recovery files even when main is absent"
	)
	g.autosave.candidate.clear()
	for suffix in ["", ".tmp", ".bak"]:
		corrupt(field.path + suffix)
	g.autosave.probe()
	check(
		g.autosave.candidate.is_empty() and not SaveRecovery.exists(field.path),
		"truly damaged autosave copies are quarantined"
	)
	check(
		(
			FileAccess.file_exists(field.path.get_basename() + ".bad")
			and FileAccess.file_exists(field.path.get_basename() + ".bad.tmp")
			and FileAccess.file_exists(field.path.get_basename() + ".bad.bak")
		),
		"quarantine retains all three damaged artifacts"
	)
	paused = false
	shift.free()
	g.queue_free()
	await process_frame
	remove_copies(career.path)
	remove_copies(field.path)
	print("Save recovery: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
