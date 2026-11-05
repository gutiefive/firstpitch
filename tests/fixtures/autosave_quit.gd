extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-quit-career.dat"
	g.settings_save_path = "user://test-quit-settings.cfg"
	g.autosave_save_path = "user://test-quit-autosave.dat"
	g.tutorial_enabled = false
	DirAccess.remove_absolute(g.autosave_save_path)
	root.add_child(g)
	await process_frame
	g.shift.start_shift("mound_callout")
	g.mound.apply_tamp(0)
	g.shift.session.advance(23)
	g.autosave.since_write = 0
	g.autosave.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
# Production autosave processing owns the write and process exit.
