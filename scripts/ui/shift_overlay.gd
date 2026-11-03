class_name ShiftOverlay
extends CanvasLayer
signal close_requested
signal start_requested(profile: String)
signal end_requested
var session: ShiftSession
var modal: Control
var status_panel: PanelContainer
var status_title: Label
var status_clock: Label
var status_rows: Array[Label] = []
var heading: Label
var description: Label
var score_label: Label
var board_rows: Array[Label] = []
var training_button: Button
var full_button: Button
var end_button: Button
var close_button: Button
const GOLD := Color("e1bb67")
const CREAM := Color("f4ecd8")

func label(text: String,size: int,color: Color = CREAM) -> Label:
 var node := Label.new()
 node.text = text
 node.add_theme_font_size_override("font_size",size)
 node.add_theme_color_override("font_color",color)
 return node

func style(color: Color) -> StyleBoxFlat:
 var value := StyleBoxFlat.new()
 value.bg_color = color
 value.corner_radius_top_left = 10
 value.corner_radius_top_right = 10
 value.corner_radius_bottom_left = 10
 value.corner_radius_bottom_right = 10
 value.content_margin_left = 22
 value.content_margin_right = 22
 value.content_margin_top = 16
 value.content_margin_bottom = 16
 return value

func button(text: String) -> Button:
 var node := Button.new()
 node.text = text
 node.custom_minimum_size.y = 38
 node.add_theme_font_size_override("font_size",16)
 node.add_theme_color_override("font_color",CREAM)
 node.add_theme_stylebox_override("normal",style(Color("365d57")))
 node.add_theme_stylebox_override("hover",style(Color("49766a")))
 node.add_theme_stylebox_override("pressed",style(Color("25453e")))
 return node

func _ready() -> void:
 layer = 10
 var panel := PanelContainer.new()
 status_panel = panel
 panel.custom_minimum_size = Vector2(306,0)
 panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 panel.offset_left = -330
 panel.offset_right = -24
 panel.offset_top = 90
 panel.add_theme_stylebox_override("panel",style(Color(0.055,0.14,0.14,0.94)))
 add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",6)
 panel.add_child(stack)
 status_title = label("FREE PRACTICE",16,GOLD)
 stack.add_child(status_title)
 status_clock = label("TAB  Shift board / pause",13)
 stack.add_child(status_clock)
 for i in range(5):
  var row := label("",12)
  status_rows.append(row)
  stack.add_child(row)
 modal = Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var shade := ColorRect.new()
 shade.color = Color(0.015,0.04,0.035,0.8)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(center)
 var card := PanelContainer.new()
 card.custom_minimum_size = Vector2(720,0)
 card.add_theme_stylebox_override("panel",style(Color("173c39")))
 center.add_child(card)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 card.add_child(content)
 heading = label("SHIFT BOARD",28,GOLD)
 content.add_child(heading)
 description = label("",14)
 content.add_child(description)
 score_label = label("",22,GOLD)
 content.add_child(score_label)
 for i in range(5):
  var row := label("",16)
  board_rows.append(row)
  content.add_child(row)
 var scoring := label("Each job is worth 20 points, proportional to its shift goal.",13,Color("adc7b7"))
 content.add_child(scoring)
 var warning := label("Starting fresh resets field work and returns equipment to the workshop.",13,GOLD)
 content.add_child(warning)
 var profiles := HBoxContainer.new()
 profiles.add_theme_constant_override("separation",12)
 content.add_child(profiles)
 training_button = button("Fresh training · 15 min")
 full_button = button("Fresh full prep · 30 min")
 training_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 full_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 profiles.add_child(training_button)
 profiles.add_child(full_button)
 training_button.pressed.connect(func(): start_requested.emit("training"))
 full_button.pressed.connect(func(): start_requested.emit("full"))
 content.add_child(label("Training goals: mow 25%, drag/chalk/water 50%, mound 100%.",13,Color("adc7b7")))
 content.add_child(label("Full prep goals: 100% of every job. TAB pauses the world and clock.",13,Color("adc7b7")))
 end_button = button("End shift now")
 content.add_child(end_button)
 end_button.pressed.connect(func(): end_requested.emit())
 close_button = button("Return to practice")
 content.add_child(close_button)
 close_button.pressed.connect(func(): close_requested.emit())
 modal.visible = false
 session.changed.connect(refresh)
 refresh()

func _input(event: InputEvent) -> void:
 if modal.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_TAB,KEY_ESCAPE]:
  close_requested.emit()
  get_viewport().set_input_as_handled()

func refresh() -> void:
 var active := session.phase == ShiftSession.Phase.ACTIVE
 var result := session.get_result()
 var finished := session.phase == ShiftSession.Phase.FINISHED and not result.is_empty()
 status_title.text = session.title().to_upper() if active else "FREE PRACTICE"
 status_clock.text = "%s  /  %d of 5 goals · TAB pauses" % [ShiftSession.clock_text(session.remaining_seconds),session.jobs_completed()] if active else "TAB  Shift board / last result"
 if active and session.remaining_seconds <= 60:
  status_clock.modulate = Color("efbb8e")
 else:
  status_clock.modulate = Color.WHITE
 for i in range(5):
  status_rows[i].visible = active
  status_rows[i].text = "%s %s  %.1f / %.0f%%" % ["✓" if session.goal_met(i) else "·",ShiftSession.JOB_NAMES[i],session.values[i],session.goals()[i]]
 heading.text = "SHIFT BOARD"
 description.text = "Free practice. Choose a fresh shift when you are ready."
 score_label.visible = active or finished
 score_label.text = ""
 var values: Array = Array(session.values)
 var targets := session.goals()
 var met := []
 for i in range(5):
  met.append(session.goal_met(i))
 if active:
  heading.text = session.title().to_upper()
  description.text = "PAUSED — World and shift clock stopped."
  score_label.text = "%s left  /  %.1f points  /  %d of 5 goals" % [ShiftSession.clock_text(session.remaining_seconds),session.score(),session.jobs_completed()]
 elif finished:
  values = result["values"]
  targets = result["goals"]
  met = result["met"]
  if result["reason"] == "completed":
   heading.text = "TRAINING COMPLETE" if result["profile_id"] == "training" else "PARK READY"
  else:
   heading.text = "TIME’S UP" if result["reason"] == "time_up" else "SHIFT ENDED"
  description.text = "%s · Last shift result · Active time %s" % [result["title"],ShiftSession.clock_text(result["elapsed_seconds"])]
  score_label.text = "%.1f / 100 points  /  %d of 5 goals" % [result["score"],result["jobs_completed"]]
 for i in range(5):
  board_rows[i].text = "%s  %s     %.1f%% / %.0f%% goal" % ["✓" if met[i] else "·",ShiftSession.JOB_NAMES[i],values[i],targets[i]]
  board_rows[i].modulate = Color("a5d2b9") if met[i] else Color.WHITE
 training_button.disabled = active
 full_button.disabled = active
 end_button.visible = active
 close_button.text = "Resume shift" if active else "Continue practicing"
 status_panel.reset_size()
