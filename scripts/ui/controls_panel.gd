class_name ControlsPanel
extends PanelContainer
signal back_requested
var game: Node
var rows: Dictionary = {}
var sensitivity: HSlider
var value_label: Label
var back_button: Button
func _ready() -> void:
 theme = GameUI.theme()
 GameUI.width(self,740)
 var box := StyleBoxFlat.new()
 box.bg_color = Color("15252f")
 box.set_corner_radius_all(10)
 box.set_content_margin_all(20)
 add_theme_stylebox_override("panel",box)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",5)
 add_child(content)
 var title := Label.new()
 title.text = "CONTROLS"
 title.add_theme_font_size_override("font_size",26)
 title.modulate = Color("76d8bd")
 content.add_child(title)
 for action in ["move"]+CrewInput.ACTIONS.slice(4)+["look_left"]:
  var row := Label.new()
  content.add_child(row)
  rows[action] = row
 var caption := Label.new()
 caption.text = "Controller camera sensitivity · saved automatically"
 content.add_child(caption)
 sensitivity = HSlider.new()
 sensitivity.min_value = 0.5
 sensitivity.max_value = 5
 sensitivity.step = 0.1
 sensitivity.value = game.settings.pad_sensitivity
 content.add_child(sensitivity)
 value_label = Label.new()
 content.add_child(value_label)
 sensitivity.value_changed.connect(func(amount: float):
  game.settings.pad_sensitivity = amount
  game.settings.save()
  refresh())
 back_button = Button.new()
 back_button.text = "Back to shift board"
 back_button.custom_minimum_size.y = 38
 back_button.pressed.connect(func(): back_requested.emit())
 content.add_child(back_button)
 game.input_device.device_changed.connect(refresh)
 refresh()
func refresh() -> void:
 for action in rows:
  var bindings: String = game.binding_text(action)
  rows[action].text = "%s   ·   %s" % [("Camera" if action == "look_left" else String(action).replace("_"," ").capitalize()),bindings if not bindings.is_empty() else "Mouse orbit"]
 value_label.text = "%.1f rad/s · %s" % [game.settings.pad_sensitivity,game.settings.error]
