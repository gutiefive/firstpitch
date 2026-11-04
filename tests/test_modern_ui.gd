extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func idle(n: int = 2) -> void:
 for i in range(n):
  await process_frame
func check(ok: bool,message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
 else:
  print("PASS: ",message)
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless":
  return
 await idle()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-ui-"+name+".png")
func click(control: Control) -> void:
 if DisplayServer.get_name() == "headless":
  control.pressed.emit()
  await idle()
  return
 var parent := control.get_parent()
 while parent != null:
  if parent is ScrollContainer:
   parent.ensure_control_visible(control)
  parent = parent.get_parent()
 await idle()
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = control.get_global_rect().get_center()
  event.pressed = pressed
  Input.parse_input_event(event)
 await idle()
func pad(code: JoyButton) -> void:
 for pressed in [true,false]:
  var event := InputEventJoypadButton.new()
  event.device = 7
  event.button_index = code
  event.pressed = pressed
  Input.parse_input_event(event)
  await process_frame
 await idle()
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-modern-ui-career.dat"
 g.settings_save_path = "user://test-modern-ui-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await idle(20)
 var ui = g.shift.overlay
 var club = ui.club_panel
 g.shift.open_board()
 # Opaque menus do not need the covered world during software-rendered UI checks.
 root.disable_3d = true
 await idle()
 await capture("operations")
 await click(ui.primary_action)
 check(ui.club_screen.visible and club.selected_section == "matchday","career action opens Matchday")
 await click(club.join_button)
 check(g.shift.career.club_started(),"native enrollment still starts club career")
 await capture("matchday")
 for key in ["stadium","results","season","matchday"]:
  await click(club.tabs[key])
  var visible_sections := 0
  for section in club.sections.values():
   if section.visible:
    visible_sections += 1
  check(club.selected_section == key and visible_sections == 1,"tab shows only "+key)
 await click(club.tabs.stadium)
 await capture("stadium")
 await click(ui.career_button)
 check(ui.career_screen.visible and not ui.club_screen.visible,"rail switches directly from Clubhouse to Workshop")
 await capture("workshop")
 await click(ui.contracts_button)
 check(ui.contracts_screen.visible and not ui.career_screen.visible,"rail opens contract cards")
 await capture("contracts")
 await click(ui.sound_button)
 check(ui.sound_screen.visible and not ui.contracts_screen.visible,"rail opens audio preferences")
 await capture("audio")
 await click(ui.controls_button)
 check(ui.controls_screen.visible and not ui.career_screen.visible,"rail switches directly to Controls")
 await capture("controls")
 await click(ui.home_button)
 check(not ui.controls_screen.visible,"Operations returns from submenu")
 await click(ui.club_button)
 ui.club_button.grab_focus()
 await pad(JOY_BUTTON_DPAD_RIGHT)
 check(club.tabs.matchday.has_focus(),"D-pad crosses from rail into Clubhouse tabs")
 await pad(JOY_BUTTON_DPAD_LEFT)
 check(ui.club_button.has_focus(),"D-pad returns from content to selected rail item")
 for dimensions in [Vector2i(1024,768),Vector2i(1600,900),Vector2i(1280,720)]:
  root.size = dimensions
  await idle(10)
  await click(ui.club_button)
  await click(club.tabs.stadium)
  var rail: Rect2 = ui.nav_panel.get_global_rect()
  var panel: Rect2 = club.get_global_rect()
  check(rail.end.x <= panel.position.x and panel.end.x <= dimensions.x,"navigation and content fit width "+str(dimensions.x))
  await capture("stadium-"+str(dimensions.x))
 await click(club.tabs.matchday)
 await click(club.prep_button)
 check(not paused and g.shift.session.phase == ShiftSession.Phase.ACTIVE,"Matchday preparation returns to live field")
 root.disable_3d = false
 await capture("hud")
 root.disable_3d = true
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
 g.shift.open_board()
 await click(ui.club_button)
 await click(club.host_button)
 g.club.opening.finish()
 await idle()
 check(club.selected_section == "results" and club.recap_continue.has_focus(),"hosting opens Results with Continue focused")
 await capture("results")
 await click(club.recap_continue)
 check(club.selected_section == "matchday" and club.prep_button.has_focus(),"Continue returns to next date with prep focused")
 g.queue_free()
 await idle(3)
 DirAccess.remove_absolute("user://test-modern-ui-career.dat")
 DirAccess.remove_absolute("user://test-modern-ui-settings.cfg")
 print("Modern UI: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
