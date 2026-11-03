extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
 checks += 1
 if ok:
  print("PASS: ",message)
 else:
  failures += 1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func frames(n: int) -> void:
 for i in range(n):
  await physics_frame
func button(code: JoyButton,pressed: bool = true) -> void:
 var event := InputEventJoypadButton.new()
 event.device = 0
 event.button_index = code
 event.pressed = pressed
 Input.parse_input_event(event)
 await process_frame
func axis(code: JoyAxis,value: float) -> void:
 var event := InputEventJoypadMotion.new()
 event.device = 0
 event.axis = code
 event.axis_value = value
 Input.parse_input_event(event)
 await process_frame
func tap(code: JoyButton) -> void:
 await button(code)
 await button(code,false)
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-controller-career.dat"
 g.settings_save_path = "user://test-controller-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 root.add_child(g)
 await frames(20)
 var events := InputMap.action_get_events("interact").size()
 g.configure_input()
 check(InputMap.action_get_events("interact").size() == events,"reconfiguring input does not duplicate bindings")
 var mapping := {JOY_BUTTON_X:"interact",JOY_BUTTON_Y:"swap_tool",JOY_BUTTON_B:"lift_drag",JOY_BUTTON_LEFT_SHOULDER:"water_tool",JOY_BUTTON_RIGHT_SHOULDER:"mound_tool",JOY_BUTTON_START:"shift_board",JOY_BUTTON_BACK:"cursor_menu",JOY_BUTTON_A:"jump"}
 for code in mapping:
  var event := InputEventJoypadButton.new()
  event.device = 2
  event.button_index = code
  event.pressed = true
  check(event.is_action_pressed(mapping[code]),"nonzero-device joypad button maps to "+mapping[code])
 await axis(JOY_AXIS_LEFT_Y,-0.1)
 check(not Input.is_action_pressed("forward"),"left-stick deadzone filters drift")
 var from: Vector3 = g.player.position
 await axis(JOY_AXIS_LEFT_Y,-1)
 await frames(20)
 await axis(JOY_AXIS_LEFT_Y,0)
 check(g.player.position.distance_to(from) > 0.5 and g.input_device.last_input_device == "pad","injected left stick moves real player and selects pad prompts")
 var yaw: float = g.yaw
 await axis(JOY_AXIS_RIGHT_X,0.1)
 await frames(4)
 check(is_equal_approx(g.yaw,yaw),"right-stick deadzone filters camera drift")
 await axis(JOY_AXIS_RIGHT_X,1)
 await frames(10)
 await axis(JOY_AXIS_RIGHT_X,0)
 check(g.yaw < yaw and g.binding_text("interact") == "X" and g.binding_text("spray_water") == "RT","right-stick look and pad glyphs follow active device")
 g.player.global_position = g.mower.global_position+Vector3(2.4,0.05,0)
 await tap(JOY_BUTTON_Y)
 check(g.mower.active_tool == RidingMower.WorkTool.DRAG,"Y performs real bay tool swap")
 await tap(JOY_BUTTON_X)
 check(g.driving,"X enters tractor")
 await tap(JOY_BUTTON_B)
 check(g.mower.drag.lowered,"B lowers stationary drag")
 await button(JOY_BUTTON_A)
 check(Input.is_action_pressed("brake"),"A shares jump and brake action")
 await button(JOY_BUTTON_A,false)
 await tap(JOY_BUTTON_X)
 check(not g.driving,"X exits stationary tractor")
 g.player.global_position = g.watering.station_position+Vector3(-1.5,0.05,1.5)
 await tap(JOY_BUTTON_LEFT_SHOULDER)
 check(g.watering.equipped,"LB equips real hose")
 g.inspection.set_enabled(true)
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.position = Vector3(8,4,-3)
 camera.look_at(Vector3(10,0,-10))
 g.watering.camera = camera
 g.player.global_position = Vector3(8,0.05,-7)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 await frames(20)
 await axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await frames(100)
 check(g.watering.spraying and g.moisture.wet_count > 0 and g.watering.cursor_is_captured(),"RT waters real dirt with free mouse cursor when pad is active")
 await axis(JOY_AXIS_TRIGGER_RIGHT,0)
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(8,0)
 Input.parse_input_event(motion)
 await axis(JOY_AXIS_TRIGGER_RIGHT,1)
 Input.parse_input_event(motion)
 await frames(3)
 check(g.input_device.last_input_device == "keyboard" and not g.watering.spraying,"returning to mouse with free cursor stops spraying")
 await axis(JOY_AXIS_TRIGGER_RIGHT,0)
 await tap(JOY_BUTTON_LEFT_SHOULDER)
 g.player.global_position = g.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 await tap(JOY_BUTTON_RIGHT_SHOULDER)
 check(g.tamper.equipped,"RB equips real tamper")
 var point: Vector3 = g.mound.patch_world(0)
 g.player.global_position = point+Vector3(-0.75,0.1,0.65)
 camera.position = point+Vector3(2.5,3.5,4.4)
 camera.look_at(point)
 g.tamper.camera = camera
 await frames(20)
 await axis(JOY_AXIS_TRIGGER_RIGHT,1)
 await frames(45)
 await axis(JOY_AXIS_TRIGGER_RIGHT,0)
 check(g.mound.hits[0] == 1 and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"RT performs accepted timed tamp with free cursor")
 await tap(JOY_BUTTON_START)
 check(paused and g.shift.overlay.modal.visible and root.gui_get_focus_owner() != null,"Start opens paused board with focus")
 var overlay: ShiftOverlay = g.shift.overlay
 overlay.controls_button.grab_focus()
 await tap(JOY_BUTTON_A)
 check(overlay.controls_screen.visible and overlay.controls_panel.sensitivity.has_focus(),"A opens Controls and focuses first interactive control")
 check(overlay.controls_panel.rows.interact.text.contains("X"),"Controls screen reads current InputMap bindings")
 var sensitivity: float = g.settings.pad_sensitivity
 Input.action_press("ui_right")
 await process_frame
 Input.action_release("ui_right")
 overlay.controls_panel.sensitivity.value += 0.1
 check(g.settings.pad_sensitivity > sensitivity,"controller sensitivity is adjustable")
 var settings := CrewSettings.new()
 settings.path = g.settings_save_path
 settings.load_settings()
 check(is_equal_approx(settings.pad_sensitivity,g.settings.pad_sensitivity),"controller sensitivity persists")
 await tap(JOY_BUTTON_B)
 check(overlay.board_scroll.visible and not overlay.controls_screen.visible,"B returns from Controls")
 overlay.contracts_button.grab_focus()
 await tap(JOY_BUTTON_A)
 check(overlay.contracts_screen.visible and overlay.contracts_panel.buttons.quick_mow.has_focus(),"Contracts opens with first available offer focused")
 await tap(JOY_BUTTON_BACK)
 check(overlay.board_scroll.visible and paused,"Back returns from submenu without resuming world")
 await tap(JOY_BUTTON_B)
 check(not paused and not overlay.modal.visible,"B closes main board")
 check(not g.prompt.text.contains("LMB") and not g.prompt.text.contains("G stow"),"live prompts use pad binding names")
 var remapped := InputEventKey.new()
 remapped.physical_keycode = KEY_T
 remapped.keycode = KEY_T
 remapped.pressed = true
 InputMap.action_erase_events("interact")
 InputMap.action_add_event("interact",remapped)
 Input.parse_input_event(remapped)
 await process_frame
 overlay.controls_panel.refresh()
 check(g.binding_text("interact") == "T" and overlay.controls_panel.rows.interact.text.contains("T") and g.chalk_marker_sign.text.contains("T USE"),"remapping InputMap updates helper, Controls and world prompts")
 g.queue_free()
 await create_timer(0.15).timeout
 for path in ["user://test-controller-career.dat","user://test-controller-settings.cfg"]:
  DirAccess.remove_absolute(path)
 print("Controller input: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
