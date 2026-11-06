class_name OpeningGates
extends CanvasLayer
var game: Node3D
var active := false
var elapsed := 0.0
var presentations := 0
var view: SubViewport
var camera: Camera3D
var heading: Label
var detail: Label
var moment: Label
var pa_caption: Label
var timeline: ProgressBar
var playback_paused := false
var playback_speed := 1.0
var controls: HFlowContainer
var pause_button: Button
var speed_button: Button
var next_button: Button
var results_button: Button
var walk_button: Button
var chapter_label: Label
var clock_label: Label
var gates: Array[Node3D] = []
var cheer: AudioStreamPlayer
var latch: AudioStreamPlayer
const DURATION := 47.0
const G = preload("res://scripts/gameplay/geometry.gd")


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = SubViewport.new()
	view.size = Vector2i(1280, 720)
	view.world_3d = game.get_world_3d()
	view.gui_disable_input = true
	view.audio_listener_enable_3d = false
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(view)
	camera = Camera3D.new()
	camera.fov = 58
	camera.cull_mask &= ~FirstPersonView.VIEW_LAYER
	view.add_child(camera)
	camera.current = true
	var picture := TextureRect.new()
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.texture = view.get_texture()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	var top := PanelContainer.new()
	top.theme = GameUI.theme()
	top.position = Vector2(24, 24)
	top.custom_minimum_size.x = 380
	top.add_theme_stylebox_override("panel", GameUI.box(GameUI.BG, 12))
	add_child(top)
	var top_stack := VBoxContainer.new()
	top.add_child(top_stack)
	chapter_label = GameUI.label(top_stack, "", 12, GameUI.ACCENT)
	clock_label = GameUI.label(top_stack, "", 13)
	var band := PanelContainer.new()
	band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -155
	band.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = GameUI.BG
	style.set_content_margin_all(24)
	band.add_theme_stylebox_override("panel", style)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(stack)
	heading = Label.new()
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 28)
	heading.modulate = GameUI.ACCENT
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(heading)
	detail = Label.new()
	detail.add_theme_font_size_override("font_size", 15)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(detail)
	moment = GameUI.label(stack, "", 14, GameUI.TEXT)
	pa_caption = GameUI.label(stack, "", 12, GameUI.MUTED)
	timeline = GameUI.meter(stack)
	timeline.theme = GameUI.theme()
	controls = HFlowContainer.new()
	controls.theme = GameUI.theme()
	controls.mouse_filter = Control.MOUSE_FILTER_STOP
	controls.add_theme_constant_override("h_separation", 8)
	controls.add_theme_constant_override("v_separation", 6)
	stack.add_child(controls)
	pause_button = GameUI.button(controls, "Pause · Space / X")
	speed_button = GameUI.button(controls, "Speed 1× · Y")
	next_button = GameUI.button(controls, "Next moment · N / RB")
	walk_button = GameUI.button(controls, "Walk park · V / RS")
	walk_button.custom_minimum_size.x = 185
	walk_button.focus_mode = Control.FOCUS_NONE
	walk_button.pressed.connect(walk_park)
	results_button = GameUI.button(controls, "Results · Enter / A", true)
	for button in [pause_button, speed_button, next_button, results_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.x = 210 if button == next_button else 185
	pause_button.pressed.connect(toggle_pause)
	speed_button.pressed.connect(cycle_speed)
	next_button.pressed.connect(next_moment)
	results_button.pressed.connect(finish)
	for id in ["crowd_cheer", "gate_open"]:
		var player := AudioStreamPlayer.new()
		player.stream = game.audio.stream(id)
		player.bus = "GroundsAmbience" if id == "crowd_cheer" else "GroundsEffects"
		player.volume_db = -8 if id == "crowd_cheer" else -13
		add_child(player)
		if id == "crowd_cheer":
			cheer = player
		else:
			latch = player
	var root := Node3D.new()
	root.name = "ArrivalGateLeaves"
	game.stadium.add_child(root)
	for side in [-1, 1]:
		var hinge := Node3D.new()
		hinge.position = Vector3(side * 8, 0, 33)
		root.add_child(hinge)
		for y in [0.25, 1.35]:
			G.tube(hinge, Vector3(0, y, 0), Vector3(-side * 4.6, y, 0), 0.04, Color("526159"))
		for i in range(14):
			var x: float = -side * (0.1 + i * 0.34)
			G.tube(hinge, Vector3(x, 0.25, 0), Vector3(x, 1.35, 0), 0.018, Color("526159"))
		gates.append(hinge)
	set_gate_fraction(1)
	visible = false


func set_gate_fraction(value: float) -> void:
	for i in range(gates.size()):
		gates[i].rotation.y = (-1 if i == 0 else 1) * PI * 0.5 * value


func present(receipt: Dictionary) -> void:
	game.club.atmosphere.begin(int(receipt.game))
	elapsed = (
		game.club.live.visit_time / LiveMatchday.LENGTH * DURATION
		if game.club.live != null and game.club.live.active
		else 0.0
	)
	playback_paused = false
	playback_speed = 1
	cheer.stream_paused = false
	latch.stream_paused = false
	pause_button.text = "Pause · Space / X"
	speed_button.text = "Speed 1× · Y"
	if game.club.live == null or not game.club.live.active:
		game.club.matchday.begin(receipt)
	active = true
	visible = true
	presentations += 1
	heading.text = "OPEN THE GATES" if int(receipt.game) % 6 != 0 else "HOME FINALE · SEASON COMPLETE"
	detail.text = (
		"%d supporters · %d seats · Your prep made this possible." % [receipt.attendance, receipt.capacity]
	)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	set_gate_fraction(0)
	cheer.play()
	latch.play()
	update_view(elapsed / DURATION)


func update_view(fraction: float) -> void:
	var seconds := fraction * DURATION
	var park: MatchdayPark = game.club.matchday
	park.set_time(seconds)
	if seconds < 7:
		heading.text = (
			"HOME FINALE · SEASON COMPLETE"
			if int(park.receipt.get("game", 1)) % 6 == 0
			else "MATCHDAY · THE GATES ARE OPEN"
		)
		camera.position = Vector3(10, 4.5, 42).lerp(Vector3(7, 3.5, 35), seconds / 7)
		camera.look_at(Vector3(3, 1.1, 29))
		moment.text = park.story_lines[0] if not park.story_lines.is_empty() else "Welcome to Cedar Grove."
	elif seconds < 13:
		heading.text = "MATCHDAY · A PARK FULL OF LIFE"
		var buildings: Array = game.shift.career.club.buildings
		if "snack_shack" in buildings or "grill_stand" in buildings:
			var id := "snack_shack" if "snack_shack" in buildings else "grill_stand"
			camera.position = game.club.world.concession_point(
				id, Vector3(-7, 3.7, -7.5).lerp(Vector3(-5, 2.8, -6.5), (seconds - 7) / 6)
			)
			camera.look_at(game.club.world.concession_point(id, Vector3(0, 1.4, -1.8)))
		else:
			camera.position = Vector3(-24, 3.5, 12).lerp(Vector3(-27, 2.8, 13), (seconds - 7) / 6)
			camera.look_at(Vector3(-7, 1.4, 24))
		moment.text = park.story_lines[2]
	elif seconds < 40:
		heading.text = (
			"OWLS %d  ·  %s %d  /  INNING %d"
			% [park.home_runs, String(park.fixture.opponent).to_upper(), park.away_runs, park.inning]
		)
		var t := (seconds - 13) / 27
		camera.position = Vector3(27, 19, 18).lerp(Vector3(-17, 15, 12), t)
		camera.look_at(Vector3(0, 0, -22))
		moment.text = (
			"Condensed game · Pitch, contact, runners and the crowd. Your prep and gate earnings are "
			+ "already settled."
		)
	else:
		heading.text = "FINAL · OWLS %d  /  VISITORS %d" % [park.home_runs, park.away_runs]
		camera.position = Vector3(-3, 3, 28)
		camera.look_at(Vector3(-7, 1.4, 24))
		var index := mini(park.story_lines.size() - 1, 1 + int((seconds - 40) / 2.4))
		moment.text = park.story_lines[index]
	chapter_label.text = (
		"MATCHDAY  /  "
		+ {
			"arrivals": "1 OF 4 · ARRIVALS",
			"concourse": "2 OF 4 · AROUND THE PARK",
			"game": "3 OF 4 · THE GAME",
			"stories": "4 OF 4 · TOWN VOICES"
		}[park.stage]
	)
	clock_label.text = (
		"%s / 0:47  ·  %s"
		% [
			ShiftSession.clock_text(seconds),
			"PAUSED" if playback_paused else "%d× speed" % int(playback_speed)
		]
	)
	pa_caption.text = "PA · " + game.club.atmosphere.caption
	timeline.value = fraction * 100
	set_gate_fraction(1 - pow(1 - minf(1, seconds / 3), 3))


func _process(delta: float) -> void:
	if not active or playback_paused:
		return
	elapsed += delta * playback_speed
	update_view(clampf(elapsed / DURATION, 0, 1))
	if elapsed >= DURATION:
		finish()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouse and controls.get_global_rect().has_point(event.position):
		return
	if (
		(event is InputEventKey and event.pressed and event.physical_keycode == KEY_V)
		or (
			event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_STICK
		)
	):
		walk_park()
		get_viewport().set_input_as_handled()
		return
	if (
		(event is InputEventKey and event.pressed and event.physical_keycode == KEY_SPACE)
		or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X)
	):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if (
		(event is InputEventKey and event.pressed and event.physical_keycode == KEY_Y)
		or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y)
	):
		cycle_speed()
		get_viewport().set_input_as_handled()
		return
	if (
		(event is InputEventKey and event.pressed and event.physical_keycode == KEY_N)
		or (
			event is InputEventJoypadButton
			and event.pressed
			and event.button_index == JOY_BUTTON_RIGHT_SHOULDER
		)
	):
		next_moment()
		get_viewport().set_input_as_handled()
		return
	if (
		event.is_action_pressed("ui_accept")
		or event.is_action_pressed("ui_cancel")
		or event.is_action_pressed("cursor_menu")
		or event.is_action_pressed("shift_board")
	):
		finish()
	# The covered recap must not respond to navigation or pointer events underneath.
	get_viewport().set_input_as_handled()


func finish() -> void:
	if game.club.live != null and game.club.live.active and game.club.live.viewing:
		game.club.live.end_visit(false)
	game.club.atmosphere.end()
	active = false
	playback_paused = false
	cheer.stream_paused = false
	latch.stream_paused = false
	visible = false
	if game.club.matchday != null:
		game.club.matchday.complete()
	set_gate_fraction(1)
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	cheer.stop()
	latch.stop()
	if game.shift.overlay.modal.visible:
		game.shift.overlay.focus_current()


func toggle_pause() -> void:
	if not active:
		return
	playback_paused = not playback_paused
	cheer.stream_paused = playback_paused
	latch.stream_paused = playback_paused
	pause_button.text = "Play · Space / X" if playback_paused else "Pause · Space / X"
	update_view(elapsed / DURATION)


func cycle_speed() -> void:
	if not active:
		return
	playback_speed = 2.0 if playback_speed == 1 else 1.0
	speed_button.text = "Speed %d× · Y" % int(playback_speed)
	update_view(elapsed / DURATION)


func next_moment() -> void:
	if not active:
		return
	for mark in [7.0, 13.0, 40.0]:
		if elapsed < mark - 0.01:
			elapsed = mark
			update_view(elapsed / DURATION)
			return
	finish()


func walk_park() -> void:
	if not active:
		return
	active = false
	visible = false
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	cheer.stop()
	latch.stop()
	set_gate_fraction(1)
	game.club.live.start(elapsed)
