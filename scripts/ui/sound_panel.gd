class_name SoundPanel
extends PanelContainer
signal back_requested
var audio: GroundsAudio
var sliders: Dictionary = {}
var value_labels: Dictionary = {}
var mute: CheckButton
var message: Label
var preview_button: Button
var back_button: Button

func _ready() -> void:
 custom_minimum_size = Vector2(620,0)
 var box := StyleBoxFlat.new()
 box.bg_color = Color("173c39")
 box.set_corner_radius_all(10)
 box.content_margin_left = 24
 box.content_margin_right = 24
 box.content_margin_top = 24
 box.content_margin_bottom = 24
 add_theme_stylebox_override("panel",box)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",18)
 add_child(content)
 var title := Label.new()
 title.text = "SOUND SETTINGS"
 title.add_theme_font_size_override("font_size",28)
 title.modulate = Color("e1bb67")
 content.add_child(title)
 var hint := Label.new()
 hint.text = "World and clock stay paused. Changes save automatically."
 content.add_child(hint)
 for key in SoundPreferences.DEFAULTS:
  var row := HBoxContainer.new()
  content.add_child(row)
  var caption := Label.new()
  caption.text = key.capitalize()
  caption.custom_minimum_size.x = 100
  row.add_child(caption)
  var slider := HSlider.new()
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 1
  slider.value = audio.settings.levels[key]*100
  slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(slider)
  sliders[key] = slider
  var value := Label.new()
  value.custom_minimum_size.x = 50
  row.add_child(value)
  value_labels[key] = value
  slider.value_changed.connect(func(amount): audio.settings.set_level(key,amount/100.0))
 mute = CheckButton.new()
 mute.text = "Mute all sound"
 mute.button_pressed = audio.settings.muted
 mute.toggled.connect(audio.settings.set_muted)
 content.add_child(mute)
 preview_button = Button.new()
 preview_button.text = "Preview sound"
 preview_button.custom_minimum_size.y = 42
 preview_button.pressed.connect(func(): audio.preview.play())
 content.add_child(preview_button)
 message = Label.new()
 message.add_theme_font_size_override("font_size",13)
 content.add_child(message)
 back_button = Button.new()
 back_button.text = "Back to shift board"
 back_button.custom_minimum_size.y = 42
 back_button.pressed.connect(func(): back_requested.emit())
 content.add_child(back_button)
 audio.settings.changed.connect(refresh)
 refresh()

func refresh() -> void:
 for key in sliders:
  sliders[key].set_value_no_signal(audio.settings.levels[key]*100)
  value_labels[key].text = "%d%%" % roundi(audio.settings.levels[key]*100)
 mute.set_pressed_no_signal(audio.settings.muted)
 message.text = audio.settings.error if not audio.settings.error.is_empty() else "Local preferences apply to practice and every shift."
