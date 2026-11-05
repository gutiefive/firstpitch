class_name ControlsPanel
extends PanelContainer
signal back_requested
var game: Node
var rows: Dictionary = {}
var sensitivity: HSlider
var value_label: Label
var back_button: Button
var device_label: Label


func _ready() -> void:
	theme = GameUI.theme()
	GameUI.width(self, 740)
	add_theme_stylebox_override("panel", GameUI.box(GameUI.SURFACE, 24))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	GameUI.label(content, "Controls & camera", 28)
	device_label = GameUI.label(content, "", 12, GameUI.ACCENT)
	GameUI.label(
		content,
		"Bindings follow your active input device. Open the board any time to pause your shift.",
		13,
		GameUI.MUTED
	)
	var groups := HBoxContainer.new()
	groups.add_theme_constant_override("separation", 12)
	content.add_child(groups)
	var movement := GameUI.card(groups, "MOVEMENT & MENUS")
	var equipment := GameUI.card(groups, "EQUIPMENT & FIELD")
	movement.add_theme_constant_override("separation", 4)
	equipment.add_theme_constant_override("separation", 4)
	for action in ["move"] + CrewInput.ACTIONS.slice(4) + ["look_left"]:
		var parent := (
			movement
			if (
				action
				in [
					"move",
					"sprint",
					"jump",
					"interact",
					"brake",
					"shift_board",
					"cursor_menu",
					"tutorial_skip",
					"look_left"
				]
			)
			else equipment
		)
		var row := GameUI.label(parent, "", 13)
		rows[action] = row
	var camera := GameUI.card(content, "CONTROLLER CAMERA")
	content.move_child(camera.get_parent(), 3)
	GameUI.label(camera, "Look sensitivity", 18)
	GameUI.label(
		camera, "Adjust how quickly the right stick turns the camera. Saves automatically.", 12, GameUI.MUTED
	)
	sensitivity = HSlider.new()
	sensitivity.min_value = 0.5
	sensitivity.max_value = 5
	sensitivity.step = 0.1
	sensitivity.value = game.settings.pad_sensitivity
	sensitivity.custom_minimum_size.y = 28
	camera.add_child(sensitivity)
	value_label = Label.new()
	camera.add_child(value_label)
	sensitivity.value_changed.connect(
		func(amount: float):
			game.settings.pad_sensitivity = amount
			game.settings.save()
			refresh()
	)
	back_button = Button.new()
	back_button.text = "Back to shift board"
	back_button.custom_minimum_size.y = 38
	back_button.pressed.connect(func(): back_requested.emit())
	content.add_child(back_button)
	game.input_device.device_changed.connect(refresh)
	refresh()


func refresh() -> void:
	device_label.text = (
		"ACTIVE INPUT  /  "
		+ ("CONTROLLER" if game.input_device.last_input_device == "pad" else "KEYBOARD & MOUSE")
	)
	for action in rows:
		var bindings: String = game.binding_text(action)
		rows[action].text = (
			"%s   ·   %s"
			% [
				"Camera" if action == "look_left" else String(action).replace("_", " ").capitalize(),
				bindings if not bindings.is_empty() else "Mouse orbit"
			]
		)
	value_label.text = "%.1f rad/s · %s" % [game.settings.pad_sensitivity, game.settings.error]
