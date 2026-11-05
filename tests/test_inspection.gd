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


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func pad(code: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-inspection-career.dat"
	g.settings_save_path = "user://test-inspection-settings.cfg"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	DirAccess.remove_absolute(g.career_save_path)
	root.add_child(g)
	for i in range(5):
		await physics_frame
	var inspection: CrewInspection = g.inspection
	var store := FieldSave.new()
	var before := store.capture(g, g.shift.session)
	check(
		not inspection.enabled and not inspection.is_processing() and not g.hud.inspection_panel.visible,
		"inspection starts off with no idle processing"
	)
	await key(KEY_V)
	check(
		inspection.enabled and g.grass.surface_material.get_shader_parameter("inspection_enabled") == true,
		"V enables grass inspection shader"
	)
	check(
		not g.grass.tufts.visible and g.hud.inspection_legend.text.contains("uncut"),
		"grass inspection exposes its scored mask beneath tufts with a legend"
	)
	await key(KEY_BRACKETRIGHT)
	check(
		g.selected_task == 1 and g.infield.surface_material.get_shader_parameter("inspection_job") == 1,
		"next-job key selects dirt inspection"
	)
	check(
		g.grass.tufts.visible and not g.grass.surface_material.get_shader_parameter("inspection_enabled"),
		"switching jobs restores normal grass display"
	)
	await key(KEY_BRACKETRIGHT)
	check(
		(
			g.selected_task == 2
			and inspection.chalk_markers.visible
			and inspection.missing_markers == g.chalk.valid_count
		),
		"chalk inspection marks every valid missing section"
	)
	check(not g.chalk.guides.visible, "normal dashed guides hide so completed sections cannot appear missing")
	var count := inspection.missing_markers
	var nodes: int = g.get_child_count()
	var direction: Vector2 = g.chalk.line_direction(0)
	g.chalk.paint_segment(g.layout.point3(direction * 5), g.layout.point3(direction * 8))
	g.chalk._process(0.2)
	inspection._process(0.11)
	check(
		inspection.missing_markers == count - g.chalk.covered_count and inspection.missing_markers < count,
		"real chalk work removes its missing-section markers"
	)
	check(
		g.get_child_count() == nodes, "chalking updates a fixed marker batch without adding per-section nodes"
	)
	await key(KEY_BRACKETRIGHT)
	check(
		g.selected_task == 3 and g.infield.surface_material.get_shader_parameter("inspection_job") == 3,
		"water inspection selects the moisture overlay"
	)
	check(
		g.moisture.watered_image.get_pixel(0, 0).r == 0,
		"protected dry cells begin outside qualified-water highlights"
	)
	check(
		g.infield.surface_material.get_shader_parameter("watered_mask") == g.moisture.watered_texture,
		"water inspection samples exact qualified flags instead of rounded moisture colors"
	)
	var values: PackedFloat32Array = g.moisture.snapshot_moisture()
	var cell: int = g.infield.work_indices()[0]
	values[cell] = g.moisture.target_moisture - 0.0001
	g.moisture.replace_moisture(values)
	var below: float = (
		g.moisture.watered_image.get_pixel(cell % g.infield.resolution.x, cell / g.infield.resolution.x).r
	)
	values[cell] = g.moisture.target_moisture + 0.0001
	g.moisture.replace_moisture(values)
	check(
		(
			below == 0
			and (
				(
					g
					. moisture
					. watered_image
					. get_pixel(cell % g.infield.resolution.x, cell / g.infield.resolution.x)
					. r
				)
				== 1
			)
		),
		"water highlight respects both sides of target despite identical rounded moisture colors"
	)
	g.moisture.spray_at(Vector3(10, 0, -10), 5)
	g.moisture.refresh_texture()
	inspection._process(0.11)
	check(
		g.hud.inspection_legend.text.contains(str(g.moisture.total - g.moisture.wet_count)),
		"water legend updates from real qualified-cell counts"
	)
	await key(KEY_BRACKETRIGHT)
	check(
		g.selected_task == 4 and inspection.missing_markers == 6 and inspection.mound_markers.visible,
		"mound inspection shows all six unfinished patches"
	)
	g.mound.apply_tamp(0)
	inspection._process(0.11)
	check(inspection.missing_markers == 6, "one impact does not hide an unfinished mound patch")
	g.mound.apply_tamp(0)
	g.mound.apply_tamp(0)
	inspection._process(0.11)
	check(inspection.missing_markers == 5, "completed mound patch loses its inspection disc")
	var refreshes := inspection.refreshes
	for i in range(3):
		await process_frame
	check(
		not inspection.is_processing() and inspection.refreshes == refreshes,
		"unchanged inspection performs no repeated marker rebuilds"
	)
	await key(KEY_BRACKETRIGHT)
	check(g.selected_task == 0, "job cycling wraps to mowing")
	await key(KEY_BRACKETLEFT)
	check(g.selected_task == 4, "previous-job key wraps backwards")
	await pad(JOY_BUTTON_RIGHT_STICK)
	check(
		(
			not inspection.enabled
			and not inspection.chalk_markers.visible
			and not inspection.mound_markers.visible
			and g.chalk.guides.visible
		),
		"RS disables inspection and restores regular guides"
	)
	await pad(JOY_BUTTON_DPAD_LEFT)
	check(
		g.selected_task == 3 and g.input_device.last_input_device == "pad",
		"pad D-pad cycles jobs through normal event routing"
	)
	await pad(JOY_BUTTON_RIGHT_STICK)
	check(
		(
			inspection.enabled
			and g.hud.inspection_controls.text.contains("RS")
			and g.hud.inspection_controls.text.contains("D-pad")
		),
		"inspection legend follows pad binding names"
	)
	var snapshot := store.capture(g, g.shift.session)
	inspection.set_enabled(false)
	inspection.set_enabled(true)
	check(
		store.capture(g, g.shift.session) == snapshot,
		"inspection toggles do not change any saved field or scoring state"
	)
	g.shift.open_board()
	await pad(JOY_BUTTON_RIGHT_STICK)
	check(inspection.enabled, "inspection input cannot toggle through a paused menu")
	g.shift.close_board()
	check(
		g.shift.start_shift("mound_callout") and not inspection.enabled,
		"starting a paid attempt clears the temporary view"
	)
	inspection.set_enabled(true)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check(
		g.selected_task == 4 and inspection.available_jobs() == [4],
		"paid job cycling includes only requested contract work"
	)
	g.shift.open_board()
	inspection.set_enabled(true)
	var saved := store.capture(g, g.shift.session)
	check(
		store.restore(g, g.shift, saved) and not inspection.enabled and g.chalk.guides.visible,
		"field restore parks equipment and clears inspection without saving presentation"
	)
	g.shift.end_shift()
	g.shift.close_board()
	check(
		inspection.available_jobs() == [0, 1, 2, 3, 4],
		"free practice after a result can inspect all five jobs"
	)
	g.shift.enter_practice()
	check(
		store.capture(g, g.shift.session).grass == before.grass,
		"inspection leaves the original fresh-state mask intact after reset"
	)
	g.queue_free()
	await create_timer(0.15).timeout
	for path in ["user://test-inspection-career.dat", "user://test-inspection-settings.cfg"]:
		DirAccess.remove_absolute(path)
	print("Inspection: ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)
