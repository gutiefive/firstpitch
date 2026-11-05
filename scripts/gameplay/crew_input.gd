class_name CrewInput
extends Node
signal device_changed
var game: Node
var last_input_device := "keyboard"
const ACTIONS := [
	"forward",
	"back",
	"left",
	"right",
	"sprint",
	"jump",
	"interact",
	"brake",
	"swap_tool",
	"lift_drag",
	"water_tool",
	"mound_tool",
	"spray_water",
	"tamp_mound",
	"shift_board",
	"cursor_menu",
	"tutorial_skip",
	"inspect_field",
	"previous_job",
	"next_job"
]
const PAD_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_DPAD_UP: "D-pad Up",
	JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_DPAD_LEFT: "D-pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad Right"
}


static func add_event(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


static func configure_input() -> void:
	var keys := {
		"forward": KEY_W,
		"back": KEY_S,
		"left": KEY_A,
		"right": KEY_D,
		"sprint": KEY_SHIFT,
		"jump": KEY_SPACE,
		"interact": KEY_E,
		"brake": KEY_SPACE,
		"swap_tool": KEY_Q,
		"lift_drag": KEY_R,
		"water_tool": KEY_F,
		"mound_tool": KEY_G,
		"shift_board": KEY_TAB,
		"cursor_menu": KEY_ESCAPE,
		"tutorial_skip": KEY_F8,
		"inspect_field": KEY_V,
		"previous_job": KEY_BRACKETLEFT,
		"next_job": KEY_BRACKETRIGHT
	}
	for action in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		add_event(action, event)
	for action in ["spray_water", "tamp_mound"]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		add_event(action, event)
	var buttons := {
		"jump": JOY_BUTTON_A,
		"brake": JOY_BUTTON_A,
		"interact": JOY_BUTTON_X,
		"swap_tool": JOY_BUTTON_Y,
		"lift_drag": JOY_BUTTON_B,
		"water_tool": JOY_BUTTON_LEFT_SHOULDER,
		"mound_tool": JOY_BUTTON_RIGHT_SHOULDER,
		"shift_board": JOY_BUTTON_START,
		"cursor_menu": JOY_BUTTON_BACK,
		"sprint": JOY_BUTTON_LEFT_STICK,
		"tutorial_skip": JOY_BUTTON_DPAD_UP,
		"inspect_field": JOY_BUTTON_RIGHT_STICK,
		"previous_job": JOY_BUTTON_DPAD_LEFT,
		"next_job": JOY_BUTTON_DPAD_RIGHT,
		"ui_accept": JOY_BUTTON_A,
		"ui_cancel": JOY_BUTTON_B
	}
	for action in buttons:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		add_event(action, event)
	var axes := {
		"left": [JOY_AXIS_LEFT_X, -1.0],
		"right": [JOY_AXIS_LEFT_X, 1.0],
		"forward": [JOY_AXIS_LEFT_Y, -1.0],
		"back": [JOY_AXIS_LEFT_Y, 1.0],
		"look_left": [JOY_AXIS_RIGHT_X, -1.0],
		"look_right": [JOY_AXIS_RIGHT_X, 1.0],
		"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
		"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
		"spray_water": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
		"tamp_mound": [JOY_AXIS_TRIGGER_RIGHT, 1.0]
	}
	for action in axes:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = axes[action][0]
		event.axis_value = axes[action][1]
		add_event(action, event)
		InputMap.action_set_deadzone(action, 0.2)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var device := last_input_device
	if event is InputEventJoypadButton and event.pressed:
		device = "pad"
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.2:
		device = "pad"
	elif event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		device = "keyboard"
	elif event is InputEventMouseMotion and event.relative.length_squared() > 1:
		device = "keyboard"
	if device != last_input_device:
		last_input_device = device
		device_changed.emit()


func aim_allowed() -> bool:
	return (
		not get_tree().paused
		and (last_input_device == "pad" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	)


func binding_text(action: String) -> String:
	var names := PackedStringArray()
	if action == "move":
		for direction in ["forward", "left", "back", "right"]:
			var text := binding_text(direction)
			if text not in names:
				names.append(text)
		return " / ".join(names)
	for event in InputMap.action_get_events(action):
		var value := ""
		if last_input_device == "pad":
			if event is InputEventJoypadButton:
				value = PAD_NAMES.get(event.button_index, event.as_text())
			elif event is InputEventJoypadMotion:
				value = (
					"RT"
					if event.axis == JOY_AXIS_TRIGGER_RIGHT
					else ("Left stick" if event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] else "Right stick")
				)
		elif event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode else event.keycode
			value = {KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]"}.get(code, OS.get_keycode_string(code))
		elif event is InputEventMouseButton:
			value = "LMB" if event.button_index == MOUSE_BUTTON_LEFT else event.as_text()
		if not value.is_empty() and value not in names:
			names.append(value)
	return " / ".join(names)


func _process(delta: float) -> void:
	if get_tree().paused or last_input_device != "pad":
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.2)
	game.yaw -= look.x * game.settings.pad_sensitivity * delta
	game.pitch = clampf(game.pitch - look.y * game.settings.pad_sensitivity * delta, -1.1, 0.1)


static func focus_screen(screen: Control) -> void:
	var controls: Array[Control] = []
	for node in screen.find_children("*", "Control", true, false):
		if (
			(node is BaseButton or node is Slider)
			and node.is_visible_in_tree()
			and not (node is BaseButton and node.disabled)
		):
			node.focus_mode = Control.FOCUS_ALL
			controls.append(node)
	if controls.is_empty():
		return
	for i in range(controls.size()):
		var control := controls[i]
		control.focus_previous = control.get_path_to(controls[(i - 1 + controls.size()) % controls.size()])
		control.focus_next = control.get_path_to(controls[(i + 1) % controls.size()])
		control.focus_neighbor_top = control.focus_previous
		control.focus_neighbor_bottom = control.focus_next
		control.focus_neighbor_left = control.focus_previous
		control.focus_neighbor_right = control.focus_next
	# Prefer the nearest control in each direction; the ordered chain is a wrap fallback.
	for control in controls:
		var origin := control.get_global_rect().get_center()
		for side in [
			[Vector2.UP, "focus_neighbor_top"],
			[Vector2.DOWN, "focus_neighbor_bottom"],
			[Vector2.LEFT, "focus_neighbor_left"],
			[Vector2.RIGHT, "focus_neighbor_right"]
		]:
			var best: Control
			var distance := INF
			var direction: Vector2 = side[0]
			for other in controls:
				var offset := other.get_global_rect().get_center() - origin
				var forward := offset.dot(direction)
				if forward <= 1:
					continue
				var across := absf(offset.cross(direction))
				var score := forward + across * 3
				if score < distance:
					distance = score
					best = other
			if best != null:
				control.set(side[1], control.get_path_to(best))
	controls[0].grab_focus()
