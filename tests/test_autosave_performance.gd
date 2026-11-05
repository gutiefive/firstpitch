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


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://performance-career.dat"
	g.settings_save_path = "user://performance-settings.cfg"
	g.autosave_save_path = "user://performance-auto.dat"
	g.tutorial_enabled = false
	root.add_child(g)
	g.autosave.set_process(false)
	await process_frame
	var store: FieldSave = g.autosave.store
	g.grass.prepare_all()
	g.infield.prepare_all()
	g.moisture.fill_valid(0.8)
	g.chalk.prepare_all()
	g.mound.prepare_all()
	g.autosave.since_write = 1
	check(g.autosave.write_now(), "trusted live snapshot writes successfully")
	g.autosave.since_write = 1
	check(g.autosave.write_now(), "repeated snapshot preserves redundant checked backup")
	check(
		store.last_timings.trusted_capture and store.last_timings.validation_ms == 0,
		"autosave avoids repeated surface validation of trusted unchanged bytes"
	)
	check(not store.read(g).is_empty(), "optimized snapshot still passes strict load validation")
	var captured := store.capture(g, g.shift.session)
	var bad := captured.duplicate(true)
	bad.moisture[0] = NAN
	var bytes := var_to_bytes(bad)
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_buffer("FPGCSAVE".to_ascii_buffer())
	file.store_buffer(SaveRecovery.digest(bytes))
	file.store_buffer(bytes)
	file.close()
	DirAccess.remove_absolute(store.path + ".bak")
	check(store.read(g).is_empty(), "load does not trust a freshly checksummed but invalid snapshot")
	DirAccess.remove_absolute(store.path)
	var old: float = g.moisture.moisture[0]
	g.moisture.moisture[0] = NAN
	check(not store.write(g, g.shift.session), "manual saves retain full strict validation")
	g.moisture.moisture[0] = old
	check(
		store.write(g, g.shift.session) and not store.read(g).is_empty(),
		"manual validation and checked round trip remain available"
	)
	# Writes remain synchronous: return guarantees completion, and the existing quit fixture tests process exit.
	check(
		not FileAccess.file_exists(store.path + ".tmp"), "completed write leaves no in-flight temporary file"
	)
	paused = false
	g.queue_free()
	await process_frame
	print("Autosave performance: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
