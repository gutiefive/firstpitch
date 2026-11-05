extends SceneTree
const Cases = preload("res://tests/fixtures/hud_cases.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://hud-text-career.dat"
	g.settings_save_path = "user://hud-text-settings.cfg"
	g.autosave_enabled = false
	g.tutorial_enabled = false
	root.add_child(g)
	await process_frame
	var rows: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/hud_text_before.json")
	)
	var failures := 0
	var checks := 0
	for row in rows:
		g.input_device.last_input_device = row.device
		g.input_device.device_changed.emit()
		Cases.apply(g, row.config)
		g._process(0)
		checks += 2
		if g.mode_label.text != row.mode:
			failures += 1
			push_error("Mode changed: " + row.config.name + " / " + row.device)
		if g.prompt.text != row.prompt:
			failures += 1
			push_error("Prompt changed: " + row.config.name + " / " + row.device)
	var cached: Dictionary = g.binding_format
	g._process(0)
	checks += 1
	if not is_same(cached, g.binding_format):
		failures += 1
		push_error("Bindings rebuilt without a device change")
	g.input_device.last_input_device = "keyboard"
	g.input_device.device_changed.emit()
	checks += 1
	if is_same(cached, g.binding_format) or g.binding_format.look != "mouse":
		failures += 1
		push_error("Bindings did not rebuild on device change")
	checks += 1
	if CrewJob.ALL != [0, 1, 2, 3, 4]:
		failures += 1
		push_error("Serialized job indices changed")
	g.queue_free()
	await process_frame
	print("HUD text: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
