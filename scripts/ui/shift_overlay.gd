class_name ShiftOverlay
extends CanvasLayer
signal close_requested
signal start_requested(profile: String)
signal save_requested
signal load_requested
signal end_requested
var navigation: VBoxContainer
var nav_panel: PanelContainer
var nav_wallet: Label
var home_button: Button
var primary_action: Button
var primary_caption: Label
var career_hero: VBoxContainer
var club_screen: ScrollContainer
var club_panel: ClubPanel
var club_button: Button
var controls_screen: ScrollContainer
var controls_panel: ControlsPanel
var controls_button: Button
var replay_button: Button
var autosave_footer: Label
var resume_card: VBoxContainer
var resume_summary: Label
var resume_button: Button
var fresh_button: Button
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
var board_content: VBoxContainer
var board_scroll: ScrollContainer
var sound_screen: CenterContainer
var sound_panel: SoundPanel
var sound_button: Button
const GOLD := GameUI.ACCENT
const CREAM := GameUI.TEXT

func label(text: String,size: int,color: Color = CREAM) -> Label:
 var node := Label.new()
 node.text = text
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.add_theme_font_size_override("font_size",size)
 node.add_theme_color_override("font_color",color)
 return node

func style(_color: Color) -> StyleBoxFlat:
 return GameUI.box(GameUI.SURFACE,22)

func button(text: String) -> Button:
 var node := Button.new()
 node.text = text
 node.custom_minimum_size.y = 44
 node.add_theme_font_size_override("font_size",15)
 node.clip_text = true
 node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 return node

func _ready() -> void:
 layer = 10
 var panel := PanelContainer.new()
 status_panel = panel
 panel.theme = GameUI.theme()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.custom_minimum_size = Vector2(306,0)
 panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 panel.offset_left = -330
 panel.offset_right = -24
 panel.offset_top = 90
 panel.add_theme_stylebox_override("panel",style(Color(0.055,0.14,0.14,0.94)))
 add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",6)
 stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
 modal.theme = GameUI.theme()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var shade := ColorRect.new()
 shade.color = GameUI.BG
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
 card.custom_minimum_size = Vector2(860,0)
 card.add_theme_stylebox_override("panel",style(Color("173c39")))
 center.add_child(card)
 var content := VBoxContainer.new()
 board_content = content
 content.add_theme_constant_override("separation",6)
 card.add_child(content)
 heading = label("OPERATIONS",28,GOLD)
 content.add_child(heading)
 resume_card = VBoxContainer.new()
 content.add_child(resume_card)
 resume_summary = label("",15,GOLD)
 resume_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 resume_card.add_child(resume_summary)
 resume_button = button("Resume last session")
 fresh_button = button("Start fresh · return to practice")
 resume_card.add_child(resume_button)
 resume_card.add_child(fresh_button)
 resume_button.pressed.connect(func(): director.game.autosave.resume())
 fresh_button.pressed.connect(func(): director.game.autosave.start_fresh())
 resume_card.visible = false
 description = label("",14)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 content.add_child(description)
 career_hero = GameUI.card(content,"YOUR CLUB CAREER")
 primary_caption = GameUI.label(career_hero,"",20)
 primary_action = GameUI.button(career_hero,"Continue your club career",true)
 primary_action.pressed.connect(func():
  if club_button != null:
   club_button.pressed.emit()
   club_panel.show_section("matchday"))
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
 var training := GameUI.card(profiles,"PRACTICE YOUR ROUTINE")
 GameUI.label(training,"Crew training",21)
 GameUI.label(training,"15 minutes · Fresh field\nMow 25%, drag/chalk/water 50%, repair the mound.",13,GameUI.MUTED)
 training_button = GameUI.button(training,"Start training")
 var full := GameUI.card(profiles,"TAKE ON THE WHOLE PARK")
 GameUI.label(full,"Full-park prep",21)
 GameUI.label(full,"30 minutes · Game-day wear\nPrepare every task to 100%. Earn credit for partial work.",13,GameUI.MUTED)
 full_button = GameUI.button(full,"Start full prep")
 training_button.pressed.connect(func(): start_requested.emit("training"))
 full_button.pressed.connect(func(): start_requested.emit("full"))
 end_button = button("End shift now")
 content.add_child(end_button)
 end_button.pressed.connect(func():
  if director.game.club != null and director.game.club.live != null and director.game.club.live.active:
   director.game.club.live.end_visit()
  else:
   end_requested.emit())
 var save_card := GameUI.card(content,"MANUAL FIELD SLOT")
 GameUI.label(save_card,"Keep a field checkpoint",18)
 GameUI.label(save_card,"One manual slot, separate from autosave. Loading replaces current field work and parks equipment; your career stays saved.",12,GameUI.MUTED)
 var saves := HBoxContainer.new()
 saves.add_theme_constant_override("separation",8)
 save_card.add_child(saves)
 save_button = button("Save checkpoint")
 load_button = button("Load checkpoint")
 for item in [save_button,load_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  saves.add_child(item)
 save_button.pressed.connect(func(): save_requested.emit())
 load_button.pressed.connect(func(): load_requested.emit())
 save_message = GameUI.label(save_card,"Manual slot is separate from autosave.",12,GameUI.MUTED)
 autosave_footer = label("Autosave ready",12,Color("adc7b7"))
 content.add_child(autosave_footer)
 var menus := HBoxContainer.new()
 content.add_child(menus)
 contracts_button = button("Contracts")
 career_button = button("Crew career")
 sound_button = button("Audio")
 for item in [contracts_button,career_button,sound_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  menus.add_child(item)
 var help := HBoxContainer.new()
 content.add_child(help)
 controls_button = button("Controls")
 replay_button = button("Tutorial")
 replay_button.tooltip_text = "Starts a fresh practice field. Career and manual slot are kept."
 for item in [controls_button,replay_button]:
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  help.add_child(item)
 replay_button.pressed.connect(func(): director.game.tutorial.replay())
 close_button = button("Return to practice")
 content.add_child(close_button)
 close_button.pressed.connect(func(): close_requested.emit())
 modal.visible = false
 attach_career()
 attach_contracts()
 attach_controls()
 build_navigation()
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
  show_board()
  board_scroll.visible = false
  career_screen.visible = true
  career_panel.refresh()
  focus_current())
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
  show_board()
  board_scroll.visible = false
  contracts_screen.visible = true
  contracts_panel.refresh()
  focus_current())
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
  show_board()
  board_scroll.visible = false
  sound_screen.visible = true
  focus_current())
 sound_screen.visible = false
 fit_screens()

func show_board() -> void:
 if club_screen != null:
  club_screen.visible = false
 if controls_screen != null:
  controls_screen.visible = false
 if sound_screen != null:
  sound_screen.visible = false
 if career_screen != null:
  career_screen.visible = false
 if contracts_screen != null:
  contracts_screen.visible = false
 board_scroll.visible = true
 focus_current()

func _input(event: InputEvent) -> void:
 if not modal.visible or (event is InputEventKey and event.echo):
  return
 if event.is_action_pressed("shift_board"):
  if resume_card.visible:
   return
  close_requested.emit()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("cursor_menu") or event.is_action_pressed("ui_cancel"):
  if not board_scroll.visible:
   show_board()
  elif not resume_card.visible:
   close_requested.emit()
  get_viewport().set_input_as_handled()

func refresh() -> void:
 var offered := resume_card.visible
 var visiting: bool = director.game.club != null and director.game.club.live != null and director.game.club.live.active
 if navigation != null:
  for node in navigation.get_children():
   if node is Button:
    node.disabled = offered
  nav_wallet.text = "%d cr available\n%s" % [director.career.balance,director.career.rank_title()]
  primary_caption.text = "Pick up where your crew left off" if director.career.club_started() else "Build a club worth coming back to"
  primary_action.text = "Review prepared home game" if not String(director.career.club.pending).is_empty() else ("Continue club career" if director.career.club_started() else "Start your club career")
 for child in board_content.get_children():
  child.visible = true
 resume_card.visible = offered
 if career_button != null:
  career_button.text = "Workshop" if director.career.club_started() else "Career"
 if club_button != null:
  club_button.disabled = offered
  club_button.text = "Clubhouse"
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
 status_clock.text = "%s  /  %s · %s pauses" % [ShiftSession.clock_text(session.remaining_seconds),goal_count,director.game.binding_text("shift_board")] if active else "%s  Shift board / last result" % director.game.binding_text("shift_board")
 if active and session.remaining_seconds <= 60:
  status_clock.modulate = Color("efbb8e")
 else:
  status_clock.modulate = Color.WHITE
 for i in range(5):
  status_rows[i].visible = active and session.goals()[i] > 0
  status_rows[i].text = "%s %s  %.1f / %.0f%%" % ["✓" if session.goal_met(i) else "·",ShiftSession.JOB_NAMES[i],session.values[i],session.goals()[i]]
 heading.text = "OPERATIONS"
 description.text = "Free practice. Visit Clubhouse to take the Owls groundskeeper job." if not director.career.club_started() else "Between home games. Clubhouse has your next story objective."
 if visiting:
  description.text = "Live matchday paused. Return to the park, or end the visit before paid prep, construction or manual checkpoints."
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
   heading.text = "HOME GAME PREPARED" if ShiftSession.PROFILES[result.profile_id].get("club",false) else ("CONTRACT COMPLETE" if ShiftSession.PROFILES[result.profile_id].get("contract",false) else ("TRAINING COMPLETE" if result["profile_id"] == "training" else "PARK READY"))
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
  board_rows[i].visible = (active or finished) and targets[i] > 0
  board_rows[i].text = "%s  %s     %.1f%% / %.0f%% goal" % ["✓" if met[i] else "·",ShiftSession.JOB_NAMES[i],values[i],targets[i]]+ (" · Quality %.0f%%" % (float(qualities[i])*100) if i != 4 else " · Quality —")
  board_rows[i].modulate = Color("a5d2b9") if met[i] else Color.WHITE
 replay_button.disabled = active or offered or visiting
 close_button.disabled = offered
 load_button.disabled = offered or visiting
 save_button.disabled = offered or visiting
 contracts_button.disabled = offered
 training_button.disabled = active or offered or visiting
 full_button.disabled = active or offered or visiting
 end_button.visible = active or visiting
 end_button.text = "End visit and view Results" if visiting else "End shift now"
 close_button.text = "Return to matchday" if visiting else ("Resume" if active else "Return to field")
 scoring_label.visible = active or finished
 career_hero.get_parent().visible = not active
 status_panel.reset_size()
 if offered:
  for child in board_content.get_children():
   child.visible = child in [heading,resume_card,description,autosave_footer]
  heading.text = "RESUME LAST SESSION"
  description.text = "Restore field work and park equipment at the workshop. The world stays paused."

func attach_controls() -> void:
 controls_screen = ScrollContainer.new()
 controls_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(controls_screen)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 controls_screen.add_child(center)
 controls_panel = ControlsPanel.new()
 controls_panel.game = director.game
 center.add_child(controls_panel)
 controls_panel.back_requested.connect(show_board)
 controls_screen.visible = false
 controls_button.pressed.connect(func():
  show_board()
  board_scroll.visible = false
  controls_screen.visible = true
  controls_panel.refresh()
  focus_current())
func focus_current() -> void:
 if navigation != null:
  CrewInput.focus_screen(navigation)
 if not is_inside_tree() or not modal.visible:
  return
 var screen: Control = board_scroll
 for candidate in [club_screen,controls_screen,career_screen,contracts_screen,sound_screen]:
  if candidate != null and candidate.visible:
   screen = candidate
 CrewInput.focus_screen(screen)
 if screen == club_screen:
  club_panel.preferred_focus().grab_focus()
 wire_navigation(screen)
 call_deferred("wire_navigation",screen)
 if resume_card.visible and screen == board_scroll:
  resume_button.grab_focus()
func show_resume(data: Dictionary) -> void:
 resume_card.visible = true
 var s: Dictionary = data.session
 var check := ShiftSession.new()
 check.profile_id = s.profile
 check.configure_work(Array(s.starting_counts),Array(s.work_totals),s.start_mode,s.wear_seed)
 var counts := [0,0,0,0,0]
 for i in range(data.grass.size()/4):
  counts[0] += int(data.grass[i*4] == 255)
 for i in range(data.dirt.size()/4):
  counts[1] += int(data.dirt[i*4] == 255)
  counts[3] += int(data.moisture[i] >= director.game.moisture.target_moisture)
 for value in data.chalk:
  counts[2] += value
 for value in data.hits:
  counts[4] += value
 var complete := []
 for i in range(5):
  complete.append(counts[i] == check.work_totals[i])
 check.set_counts(counts,complete)
 var coverage: float = s.result.get("coverage_score",s.result.get("score",check.coverage_score())) if s.phase == ShiftSession.Phase.FINISHED else check.coverage_score()
 resume_summary.text = "%s · %s left · %.1f%% goal coverage" % [check.title(),ShiftSession.clock_text(ShiftSession.PROFILES[s.profile].duration-s.elapsed),coverage]
 check.free()
 refresh()
 focus_current()

func attach_club(club: ClubDirector) -> void:
 club_button = button("Clubhouse")
 club_button.add_theme_color_override("font_color",GOLD)
 club_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls_button.get_parent().add_child(club_button)
 controls_button.get_parent().move_child(club_button,3)
 club_button.icon = preload("res://assets/ui/club.svg")
 club_button.toggle_mode = true
 club_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
 club_button.add_theme_font_size_override("font_size",13)
 club_screen = ScrollContainer.new()
 club_screen.follow_focus = true
 club_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal.add_child(club_screen)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 club_screen.add_child(center)
 club_panel = ClubPanel.new()
 club_panel.director = club
 center.add_child(club_panel)
 club_panel.back_requested.connect(show_board)
 club_screen.visible = false
 fit_screens()
 club_button.pressed.connect(func():
  show_board()
  board_scroll.visible = false
  club_screen.visible = true
  club_panel.show_section("matchday")
  club_panel.refresh()
  focus_current())

func build_navigation() -> void:
 nav_panel = PanelContainer.new()
 nav_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
 nav_panel.offset_left = 24
 nav_panel.offset_right = 200
 nav_panel.offset_top = 24
 nav_panel.offset_bottom = -24
 nav_panel.add_theme_stylebox_override("panel",GameUI.box(GameUI.BG,12))
 modal.add_child(nav_panel)
 navigation = VBoxContainer.new()
 navigation.add_theme_constant_override("separation",8)
 nav_panel.add_child(navigation)
 GameUI.label(navigation,"FIRST\nPITCH",27,GameUI.TEXT)
 GameUI.label(navigation,"GROUNDS CREW",10,GameUI.ACCENT)
 home_button = GameUI.button(navigation,"Operations")
 home_button.toggle_mode = true
 home_button.icon = preload("res://assets/ui/home.svg")
 home_button.pressed.connect(show_board)
 for pair in [[career_button,"workshop"],[contracts_button,"contracts"],[sound_button,"sound"],[controls_button,"controls"],[replay_button,"help"],[close_button,"exit"]]:
  var node: Button = pair[0]
  node.reparent(navigation)
  node.icon = load("res://assets/ui/"+String(pair[1])+".svg")
  node.alignment = HORIZONTAL_ALIGNMENT_LEFT
  node.add_theme_font_size_override("font_size",13)
  node.toggle_mode = node != replay_button and node != close_button
  node.custom_minimum_size.y = 42
 nav_wallet = GameUI.label(navigation,"",12,GameUI.MUTED)
 nav_wallet.size_flags_vertical = Control.SIZE_EXPAND_FILL
 nav_wallet.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
 GameUI.label(navigation,"B / Esc  Back\nTab  Return to field",11,GameUI.MUTED)
 get_viewport().size_changed.connect(fit_screens)
 fit_screens()
func fit_screens() -> void:
 for pane in [board_scroll,career_screen,contracts_screen,controls_screen,sound_screen,club_screen]:
  if pane != null:
   pane.offset_left = 224
   pane.offset_top = 24
   pane.offset_right = -24
   pane.offset_bottom = -24
   if pane is ScrollContainer:
    pane.follow_focus = true
 for pair in [[career_panel,860],[contracts_panel,860],[controls_panel,740],[sound_panel,660]]:
  if pair[0] != null:
   GameUI.width(pair[0],pair[1])
 if board_scroll != null:
  var card: Control = board_content.get_parent()
  GameUI.width(card,860)
func menu_controls(screen: Control) -> Array[Control]:
 var result: Array[Control] = []
 for node in screen.find_children("*","Control",true,false):
  if (node is BaseButton or node is Slider) and node.is_visible_in_tree() and not (node is BaseButton and node.disabled):
   result.append(node)
 return result
func wire_navigation(screen: Control) -> void:
 if navigation == null or resume_card.visible or not modal.visible:
  return
 var rail := menu_controls(navigation)
 var content := menu_controls(screen)
 if rail.is_empty() or content.is_empty():
  return
 var active: Button = home_button
 if screen == club_screen:
  active = club_button
 elif screen == career_screen:
  active = career_button
 elif screen == contracts_screen:
  active = contracts_button
 elif screen == controls_screen:
  active = controls_button
 elif screen == sound_screen:
  active = sound_button
 for node in rail:
  if node is Button and node.toggle_mode:
   node.set_pressed_no_signal(node == active)
  node.focus_neighbor_right = node.get_path_to(content[0])
 for node in content:
  if node.get_global_rect().get_center().x < screen.get_global_rect().get_center().x:
   node.focus_neighbor_left = node.get_path_to(active)
 rail[-1].focus_next = rail[-1].get_path_to(content[0])
 content[0].focus_previous = content[0].get_path_to(rail[-1])
 content[-1].focus_next = content[-1].get_path_to(rail[0])
 rail[0].focus_previous = rail[0].get_path_to(content[-1])
