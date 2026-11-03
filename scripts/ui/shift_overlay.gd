class_name ShiftOverlay
extends CanvasLayer
signal close_requested
signal start_requested(profile: String)
signal save_requested
signal load_requested
signal end_requested
var contracts_screen: ScrollContainer
var contracts_panel: ContractsPanel
var contracts_button: Button
var scoring_label: Label
var director: ShiftDirector
var career_screen: ScrollContainer
var career_panel: CareerPanel
var career_button: Button
var career_reward: Label
var session: ShiftSession
var modal: Control
var status_panel: PanelContainer
var status_title: Label
var status_clock: Label
var status_rows: Array[Label] = []
var heading: Label
var description: Label
var quality_label: Label
var quality_tip: Label
var start_warning: Label
var score_label: Label
var board_rows: Array[Label] = []
var training_button: Button
var full_button: Button
var end_button: Button
var close_button: Button
var save_button: Button
var load_button: Button
var save_message: Label
var board_scroll: ScrollContainer
var sound_screen: CenterContainer
var sound_panel: SoundPanel
var sound_button: Button
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
 var colors := {"normal":"365d57","hover":"49766a","pressed":"25453e"}
 for state in colors:
  var box := style(Color(colors[state]))
  box.content_margin_top = 8
  box.content_margin_bottom = 8
  node.add_theme_stylebox_override(state,box)
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
 var scroll := ScrollContainer.new()
 board_scroll = scroll
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(scroll)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var card := PanelContainer.new()
 card.custom_minimum_size = Vector2(720,0)
 card.add_theme_stylebox_override("panel",style(Color("173c39")))
 center.add_child(card)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",6)
 card.add_child(content)
 heading = label("SHIFT BOARD",28,GOLD)
 content.add_child(heading)
 description = label("",14)
 content.add_child(description)
 score_label = label("",22,GOLD)
 content.add_child(score_label)
 quality_label = label("",13,Color("adc7b7"))
 content.add_child(quality_label)
 quality_tip = label("",13,GOLD)
 quality_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(quality_tip)
 career_reward = label("",13,GOLD)
 career_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(career_reward)
 for i in range(5):
  var row := label("",16)
  board_rows.append(row)
  content.add_child(row)
 scoring_label = label("",13,Color("adc7b7"))
 content.add_child(scoring_label)
 start_warning = label("",13,GOLD)
 start_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(start_warning)
 var profiles := HBoxContainer.new()
 profiles.add_theme_constant_override("separation",12)
 content.add_child(profiles)
 training_button = button("Fresh training · 15 min")
 full_button = button("Game-day prep · 30 min")
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
 var saves := HBoxContainer.new()
 content.add_child(saves)
 save_button = button("Save field + shift")
 load_button = button("Load saved field + shift")
 for item in [save_button,load_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  saves.add_child(item)
 save_button.pressed.connect(func(): save_requested.emit())
 load_button.pressed.connect(func(): load_requested.emit())
 content.add_child(label("One slot. Loading replaces current work and parks equipment.",12,GOLD))
 save_message = label("Save manually before closing the game.",12,Color("adc7b7"))
 content.add_child(save_message)
 var menus := HBoxContainer.new()
 content.add_child(menus)
 contracts_button = button("Contracts")
 career_button = button("Crew career")
 sound_button = button("Sound settings")
 for item in [contracts_button,career_button,sound_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  menus.add_child(item)
 close_button = button("Return to practice")
 content.add_child(close_button)
 close_button.pressed.connect(func(): close_requested.emit())
 modal.visible = false
 attach_career()
 attach_contracts()
 session.changed.connect(refresh)
 refresh()

func attach_career() -> void:
 career_screen = ScrollContainer.new()
 career_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(career_screen)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 career_screen.add_child(center)
 career_panel = CareerPanel.new()
 career_panel.director = director
 center.add_child(career_panel)
 career_panel.back_requested.connect(show_board)
 career_button.pressed.connect(func():
  board_scroll.visible = false
  career_screen.visible = true
  career_panel.refresh()
  career_panel.back_button.grab_focus())
 director.career.changed.connect(refresh)
 career_screen.visible = false

func attach_contracts() -> void:
 contracts_screen = ScrollContainer.new()
 contracts_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(contracts_screen)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 contracts_screen.add_child(center)
 contracts_panel = ContractsPanel.new()
 contracts_panel.director = director
 center.add_child(contracts_panel)
 contracts_panel.back_requested.connect(show_board)
 contracts_button.pressed.connect(func():
  board_scroll.visible = false
  contracts_screen.visible = true
  contracts_panel.refresh()
  contracts_panel.back_button.grab_focus())
 contracts_screen.visible = false

func attach_audio(audio: GroundsAudio) -> void:
 sound_screen = CenterContainer.new()
 sound_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(sound_screen)
 sound_panel = SoundPanel.new()
 sound_panel.audio = audio
 sound_screen.add_child(sound_panel)
 sound_panel.back_requested.connect(show_board)
 sound_button.pressed.connect(func():
  board_scroll.visible = false
  sound_screen.visible = true
  sound_panel.sliders.master.grab_focus())
 sound_screen.visible = false

func show_board() -> void:
 if sound_screen != null:
  sound_screen.visible = false
 if career_screen != null:
  career_screen.visible = false
 if contracts_screen != null:
  contracts_screen.visible = false
 board_scroll.visible = true

func _input(event: InputEvent) -> void:
 if modal.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_TAB,KEY_ESCAPE]:
  if event.keycode == KEY_ESCAPE and ((sound_screen != null and sound_screen.visible) or (career_screen != null and career_screen.visible) or (contracts_screen != null and contracts_screen.visible)):
   show_board()
  else:
   close_requested.emit()
  get_viewport().set_input_as_handled()

func refresh() -> void:
 if career_button != null:
  career_button.text = "Crew career · %d cr" % director.career.balance
 career_reward.text = director.career_message
 career_reward.visible = not director.career_message.is_empty()
 var active := session.phase == ShiftSession.Phase.ACTIVE
 var result := session.get_result()
 var finished := session.phase == ShiftSession.Phase.FINISHED and not result.is_empty()
 status_title.text = session.title().to_upper() if active else "FREE PRACTICE"
 start_warning.text = "Training starts fresh. Game-day prep wears the current park. Both park equipment."
 quality_label.visible = active or finished
 quality_tip.visible = active or finished
 var goal_count := "%d of %d %s" % [int(result.jobs_completed) if finished else session.jobs_completed(),session.jobs_required(),"goal" if session.jobs_required() == 1 else "goals"]
 scoring_label.text = "Each listed job is worth %.0f points, proportional to its goal." % (100.0/maxi(session.jobs_required(),1))
 status_clock.text = "%s  /  %s · TAB pauses" % [ShiftSession.clock_text(session.remaining_seconds),goal_count] if active else "TAB  Shift board / last result"
 if active and session.remaining_seconds <= 60:
  status_clock.modulate = Color("efbb8e")
 else:
  status_clock.modulate = Color.WHITE
 for i in range(5):
  status_rows[i].visible = active and session.goals()[i] > 0
  status_rows[i].text = "%s %s  %.1f / %.0f%%" % ["✓" if session.goal_met(i) else "·",ShiftSession.JOB_NAMES[i],session.values[i],session.goals()[i]]
 heading.text = "SHIFT BOARD"
 description.text = "Free practice. Choose training or a game-day preparation shift."
 score_label.visible = active or finished
 score_label.text = ""
 var values: Array = Array(session.values)
 var targets := session.goals()
 var met := []
 for i in range(5):
  met.append(session.goal_met(i))
 if active:
  heading.text = session.title().to_upper()
  description.text = "PAUSED — World and shift clock stopped."+ (" Goals track repairs since game day." if session.start_mode == "game_day" else "")
  score_label.text = "%s left  /  %.1f points  /  %s" % [ShiftSession.clock_text(session.remaining_seconds),session.score(),goal_count]
 elif finished:
  values = result["values"]
  targets = result["goals"]
  met = result["met"]
  if result["reason"] == "completed":
   heading.text = "CONTRACT COMPLETE" if ShiftSession.PROFILES[result.profile_id].get("contract",false) else ("TRAINING COMPLETE" if result["profile_id"] == "training" else "PARK READY")
  else:
   heading.text = "TIME’S UP" if result["reason"] == "time_up" else "SHIFT ENDED"
  description.text = "%s · Last shift result · Active time %s" % [result["title"],ShiftSession.clock_text(result["elapsed_seconds"])]
  score_label.text = "%.1f / 100 points  /  %s" % [result["score"],goal_count]
 var qualities: Array = result.get("job_quality",[1.0,1.0,1.0,1.0,1.0]) if finished else Array(session.job_quality)
 var multiplier: float = result.get("quality",1.0) if finished else session.quality_multiplier()
 var coverage: float = result.get("coverage_score",result.get("score",0)) if finished else session.coverage_score()
 quality_label.text = "Coverage %.1f / 100 · Finish quality %.1f%%" % [coverage,multiplier*100]
 quality_tip.text = result.get("quality_tip","Legacy result: finish quality is neutral.") if finished else session.quality_tip()
 for i in range(5):
  board_rows[i].visible = targets[i] > 0
  board_rows[i].text = "%s  %s     %.1f%% / %.0f%% goal" % ["✓" if met[i] else "·",ShiftSession.JOB_NAMES[i],values[i],targets[i]]+ (" · Quality %.0f%%" % (float(qualities[i])*100) if i != 4 else " · Quality —")
  board_rows[i].modulate = Color("a5d2b9") if met[i] else Color.WHITE
 training_button.disabled = active
 full_button.disabled = active
 end_button.visible = active
 close_button.text = "Resume shift" if active else "Continue practicing"
 status_panel.reset_size()
