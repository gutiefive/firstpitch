extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func idle(count: int) -> void:
	for i in range(count):
		await process_frame


func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
	await idle(3)


func click(button: Button) -> void:
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await idle(4)
		parent = parent.get_parent()
	assert(Rect2(Vector2.ZERO, root.size).has_point(button.get_global_rect().get_center()))
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		Input.parse_input_event(event)
	await idle(4)


func capture(path: String) -> void:
	await idle(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var g = load("res://scenes/main/main.tscn").instantiate()
	g.career_save_path = "user://test-inspection-visual-career.dat"
	g.tutorial_enabled = false
	g.autosave_enabled = false
	root.add_child(g)
	await frames(15)
	g.shift.wear.bootstrap(g, "full")
	g.shift.wear.apply(g, 43, 0.55)
	g.grass.mow_segment(Vector3(0, 0, -60), Vector3(0, 0, -50), Vector3.FORWARD)
	g.grass._process(0.2)
	var camera := Camera3D.new()
	g.add_child(camera)
	camera.current = true
	camera.fov = 55
	camera.far = 500
	camera.position = Vector3(18, 26, -35)
	camera.look_at(Vector3(0, 0, -55))
	await key(KEY_V)
	assert(g.inspection.enabled)
	await capture("/tmp/firstpitch-inspection-grass.png")
	g.moisture.fill_valid(0.8)
	var water: PackedFloat32Array = g.moisture.snapshot_moisture()
	for index in g.infield.work_indices():
		if g.infield.cell_world(index % g.infield.resolution.x, index / g.infield.resolution.x).x < 0:
			water[index] = 0.2
	g.moisture.replace_moisture(water)
	g.infield.paint(Vector3(10, 0, -10), Vector3.FORWARD, 6, 3)
	g.infield.refresh_texture()
	g.moisture.spray_at(Vector3(14, 0, -14), 5)
	g.moisture.refresh_texture()
	camera.position = Vector3(18, 10, 2)
	camera.look_at(Vector3(9, 0, -10))
	await key(KEY_BRACKETRIGHT)
	await capture("/tmp/firstpitch-inspection-dirt.png")
	await key(KEY_BRACKETRIGHT)
	var honest := true
	for i in range(g.chalk.covered.size()):
		var pose: Transform3D = g.inspection.chalk_markers.multimesh.get_instance_transform(i)
		var shown := absf(pose.basis.determinant()) > 0.5
		honest = honest and (shown == (g.chalk.valid[i] == 1 and g.chalk.covered[i] == 0))
	assert(honest, "Only valid missing chalk sections are visible on the actual renderer")
	await capture("/tmp/firstpitch-inspection-chalk.png")
	await key(KEY_BRACKETRIGHT)
	await capture("/tmp/firstpitch-inspection-water.png")
	await key(KEY_BRACKETRIGHT)
	camera.position = Vector3(4, 6, -12)
	camera.look_at(g.mound.global_position)
	while g.mound.hits[0] < g.mound.hits_required:
		g.mound.apply_tamp(0)
	await frames(12)
	assert(g.inspection.missing_markers == 5)
	await capture("/tmp/firstpitch-inspection-mound.png")
	await key(KEY_TAB)
	await click(g.shift.overlay.controls_button)
	await capture("/tmp/firstpitch-inspection-controls.png")
	print(
		(
			"Inspection visuals: all five views rendered; actual missing-section transforms checked; "
			+ "native controls passed"
		)
	)
	g.shift.close_board()
	g.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute("user://test-inspection-visual-career.dat")
	quit()
