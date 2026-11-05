extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://profile-career.dat"
	g.settings_save_path = "user://profile-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	root.add_child(g)
	await process_frame
	g.grass.prepare_all()
	g.infield.prepare_all()
	g.moisture.fill_valid(0.8)
	g.chalk.prepare_all()
	g.mound.prepare_all()
	var store := FieldSave.new()
	store.path = "user://profile-field.dat"
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(store.path + suffix)
	var fast := "fast" in OS.get_cmdline_user_args()
	var samples := []
	for i in range(7):
		var started := Time.get_ticks_usec()
		var ok: bool = (
			store.call("write", g, g.shift.session, true) if fast else store.write(g, g.shift.session)
		)
		if not ok:
			push_error(store.error)
			quit(1)
			return
		var row := store.last_timings.duplicate()
		row.total_ms = (Time.get_ticks_usec() - started) / 1000.0
		if i > 0:
			samples.append(row)
	print("AUTOSAVE_PROFILE ", JSON.stringify({"fast": fast, "samples": samples}))
	g.queue_free()
	await process_frame
	quit()
