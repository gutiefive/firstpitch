class_name GameUI
extends RefCounted
const BG := Color("0c151c")
const SURFACE := Color("15252f")
const RAISED := Color("203641")
const LINE := Color("304a57")
const TEXT := Color("edf4f3")
const MUTED := Color("94acb8")
const ACCENT := Color("76d8bd")
const GOLD := Color("d8b778")
static var shared: Theme


static func box(color: Color = SURFACE, margin: int = 20, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.set_border_width_all(1)
	style.border_color = LINE
	return style


static func theme() -> Theme:
	if shared != null:
		return shared
	shared = Theme.new()
	shared.default_font_size = 15
	shared.set_color("font_color", "Label", TEXT)
	shared.set_stylebox("panel", "PanelContainer", box())
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var surface := box(RAISED if state == "normal" else Color("2a4855"), 12, 6)
		surface.content_margin_left = 16
		surface.content_margin_right = 16
		if state == "disabled":
			surface.bg_color = Color("172731")
			surface.border_color = Color("233b46")
		elif state == "focus":
			surface.bg_color = Color(0, 0, 0, 0)
			surface.border_color = ACCENT
			surface.set_border_width_all(2)
		elif state == "pressed":
			surface.bg_color = Color("335a60")
			surface.border_color = ACCENT
		shared.set_stylebox(state, "Button", surface)
	shared.set_color("font_color", "Button", TEXT)
	shared.set_color("font_hover_color", "Button", ACCENT)
	shared.set_color("font_pressed_color", "Button", TEXT)
	shared.set_color("font_focus_color", "Button", TEXT)
	shared.set_color("font_disabled_color", "Button", Color("68818e"))
	shared.set_constant("h_separation", "Button", 10)
	shared.set_constant("icon_max_width", "Button", 18)
	var track := box(Color("263d49"), 0, 3)
	track.set_border_width_all(0)
	var fill := box(ACCENT, 0, 3)
	fill.set_border_width_all(0)
	shared.set_stylebox("background", "ProgressBar", track)
	shared.set_stylebox("fill", "ProgressBar", fill)
	shared.set_stylebox("scroll", "VScrollBar", box(BG, 0, 3))
	shared.set_stylebox("grabber", "VScrollBar", box(Color("3c5967"), 0, 3))
	shared.set_stylebox("grabber_highlight", "VScrollBar", box(Color("5b7d89"), 0, 3))
	shared.set_stylebox("grabber_pressed", "VScrollBar", box(ACCENT, 0, 3))
	var slider_track := box(Color("263d49"), 3, 3)
	var slider_fill := box(ACCENT, 3, 3)
	shared.set_stylebox("slider", "HSlider", slider_track)
	shared.set_stylebox("grabber_area", "HSlider", slider_fill)
	shared.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	return shared


static func label(parent: Node, value: String, size: int = 14, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(node)
	return node


static func button(parent: Node, value: String, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 44
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if primary:
		var normal := box(ACCENT, 12, 6)
		normal.border_color = ACCENT
		node.add_theme_stylebox_override("normal", normal)
		node.add_theme_color_override("font_color", BG)
		node.add_theme_color_override("font_hover_color", BG)
		node.add_theme_color_override("font_focus_color", BG)
		node.add_theme_color_override("font_pressed_color", BG)
		node.add_theme_stylebox_override("hover", box(Color("9ae6cf"), 12, 6))
		node.add_theme_stylebox_override("pressed", box(Color("59b59e"), 12, 6))
	parent.add_child(node)
	return node


static func card(parent: Node, title: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", box(Color("1b2e39"), 18))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	if not title.is_empty():
		label(content, title, 12, MUTED)
	return content


static func width(control: Control, preferred: float = 900) -> void:
	control.custom_minimum_size.x = minf(preferred, maxf(600, control.get_viewport_rect().size.x - 280))


static func meter(parent: Node) -> ProgressBar:
	var node := ProgressBar.new()
	node.custom_minimum_size.y = 5
	node.show_percentage = false
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func funding(balance: int, cost: int) -> String:
	return (
		"Ready to buy · %d cr left afterward" % (balance - cost)
		if balance >= cost
		else "Save %d more cr · %d / %d cr" % [cost - balance, balance, cost]
	)
