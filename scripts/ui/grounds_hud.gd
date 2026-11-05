class_name GroundsHUD
extends CanvasLayer
const CREAM := GameUI.TEXT
const GOLD := GameUI.ACCENT
var park_label: Label
var condition_label: Label
var mode_label: Label
var prompt: Label
var percent_label: Label
var progress: ProgressBar
var objective_label: Label
var summary_label: Label
var detail_label: Label
var reticle: Label
var reminder: Label
var tutorial_panel: PanelContainer
var tutorial_title: Label
var tutorial_instruction: Label
var tutorial_reason: Label
var tutorial_skip: Button
var inspection_panel: PanelContainer
var inspection_title: Label
var inspection_legend: Label
var inspection_controls: Label
var condition_panel: PanelContainer
var task_panel: PanelContainer


func text_label(text: String, size: int, color: Color = CREAM) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func panel_style(color: Color) -> StyleBoxFlat:
	return GameUI.box(color, 16)


func hud_panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.theme = GameUI.theme()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", GameUI.box(Color(0.045, 0.08, 0.11, 0.91), 16))
	add_child(node)
	return node


func _ready() -> void:
	task_panel = hud_panel()
	task_panel.position = Vector2(24, 24)
	task_panel.custom_minimum_size.x = 300
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 7)
	task_panel.add_child(stack)
	park_label = text_label("CEDAR GROVE / MORNING PREP", 11, GameUI.MUTED)
	stack.add_child(park_label)
	objective_label = text_label("Mow the outfield", 18)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 268
	stack.add_child(objective_label)
	percent_label = text_label("0.00%", 28, GOLD)
	stack.add_child(percent_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(268, 5)
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(progress)
	summary_label = text_label("", 10, GameUI.MUTED)
	stack.add_child(summary_label)
	detail_label = text_label("", 11, GameUI.MUTED)
	stack.add_child(detail_label)
	mode_label = text_label("ON FOOT", 11, GameUI.ACCENT)
	stack.add_child(mode_label)
	condition_panel = hud_panel()
	condition_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	condition_panel.offset_left = 24
	condition_panel.offset_right = 424
	condition_panel.offset_top = -230
	condition_panel.offset_bottom = -88
	condition_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	condition_label = text_label("", 12, GameUI.TEXT)
	condition_label.custom_minimum_size.x = 360
	condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition_panel.add_child(condition_label)
	condition_label.visible = false
	condition_panel.visible = false
	var bottom := hud_panel()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -61
	bottom.offset_bottom = -20
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.add_theme_stylebox_override("panel", GameUI.box(Color(0.045, 0.08, 0.11, 0.88), 10, 6))
	prompt = text_label("", 13)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(prompt)
	reticle = text_label("+", 22)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.offset_left = -10
	reticle.offset_right = 10
	reticle.offset_top = -15
	reticle.offset_bottom = 15
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle.add_theme_color_override("font_shadow_color", GameUI.BG)
	reticle.add_theme_constant_override("shadow_outline_size", 3)
	reticle.visible = false
	add_child(reticle)
	reminder = text_label("", 11, GameUI.TEXT)
	reminder.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	reminder.offset_left = -360
	reminder.offset_right = -24
	reminder.offset_top = 24
	reminder.offset_bottom = 70
	reminder.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reminder.add_theme_color_override("font_shadow_color", GameUI.BG)
	reminder.add_theme_constant_override("shadow_outline_size", 3)
	add_child(reminder)
	tutorial_panel = hud_panel()
	tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	tutorial_panel.offset_left = 24
	tutorial_panel.offset_right = 424
	tutorial_panel.offset_top = -260
	tutorial_panel.offset_bottom = -88
	tutorial_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var guide := VBoxContainer.new()
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.add_theme_constant_override("separation", 8)
	tutorial_panel.add_child(guide)
	tutorial_title = text_label("CREW GUIDE", 13, GameUI.ACCENT)
	tutorial_instruction = text_label("", 14)
	tutorial_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_reason = text_label("", 12, GameUI.MUTED)
	tutorial_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for item in [tutorial_title, tutorial_instruction, tutorial_reason]:
		guide.add_child(item)
	tutorial_skip = Button.new()
	tutorial_skip.text = "Skip guide"
	tutorial_skip.pressed.connect(func(): get_parent().tutorial.finish())
	guide.add_child(tutorial_skip)
	tutorial_panel.visible = false
	inspection_panel = hud_panel()
	inspection_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	inspection_panel.offset_left = -350
	inspection_panel.offset_right = -24
	inspection_panel.offset_top = -250
	inspection_panel.offset_bottom = -88
	inspection_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var inspection := VBoxContainer.new()
	inspection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspection.add_theme_constant_override("separation", 8)
	inspection_panel.add_child(inspection)
	inspection_title = text_label("FIELD INSPECTION", 13, GameUI.ACCENT)
	inspection_legend = text_label("", 13)
	inspection_legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspection_controls = text_label("", 11, GameUI.MUTED)
	inspection_controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for item in [inspection_title, inspection_legend, inspection_controls]:
		inspection.add_child(item)
	inspection_panel.visible = false


func _process(_delta: float) -> void:
	condition_panel.visible = condition_label.visible and not tutorial_panel.visible
