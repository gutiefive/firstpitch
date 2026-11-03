extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
func idle(count: int) -> void:
 for i in range(count):
  await process_frame
func key(code: Key) -> void:
 for pressed in [true,false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.physical_keycode = code
  event.pressed = pressed
  Input.parse_input_event(event)
 await idle(3)
func click(button: Button) -> void:
 var parent := button.get_parent()
 while parent != null:
  if parent is ScrollContainer:
   parent.ensure_control_visible(button)
   await idle(4)
  parent = parent.get_parent()
 assert(Rect2(Vector2.ZERO,root.size).has_point(button.get_global_rect().get_center()))
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = button.get_global_rect().get_center()
  event.pressed = pressed
  Input.parse_input_event(event)
 await idle(4)
func capture(path: String) -> void:
 await idle(4)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func scene() -> Node:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-onboarding-visual-career.dat"
 g.settings_save_path = "user://test-onboarding-visual-settings.cfg"
 g.autosave_save_path = "user://test-onboarding-visual-auto.dat"
 root.add_child(g)
 return g
func pad(code: JoyButton) -> void:
 for pressed in [true,false]:
  var event := InputEventJoypadButton.new()
  event.button_index = code
  event.pressed = pressed
  Input.parse_input_event(event)
  await idle(3)
func run() -> void:
 var paths := ["user://test-onboarding-visual-career.dat","user://test-onboarding-visual-settings.cfg","user://test-onboarding-visual-auto.dat"]
 for path in paths:
  DirAccess.remove_absolute(path)
 var g := scene()
 await frames(20)
 assert(g.tutorial.can_run())
 await capture("/tmp/firstpitch-tutorial-first-run.png")
 await key(KEY_F8)
 assert(not g.tutorial.active and g.settings.tutorial_done)
 await key(KEY_TAB)
 await click(g.shift.overlay.controls_button)
 assert(g.shift.overlay.controls_screen.visible)
 await pad(JOY_BUTTON_DPAD_DOWN)
 assert(g.input_device.last_input_device == "pad")
 await capture("/tmp/firstpitch-controller-controls.png")
 await pad(JOY_BUTTON_B)
 await click(g.shift.overlay.replay_button)
 assert(g.tutorial.active and not paused)
 await capture("/tmp/firstpitch-tutorial-replay.png")
 await key(KEY_F8)
 await key(KEY_TAB)
 await click(g.shift.overlay.contracts_button)
 await click(g.shift.overlay.contracts_panel.buttons.mound_callout)
 # Partial-work fixture for the resume screen; real tool impacts are tested separately.
 for i in range(3):
  g.mound.apply_tamp(0)
 g.shift.session.advance(43)
 g.shift.open_board()
 g.autosave.since_write = 1
 g.autosave.write_now()
 var elapsed: float = g.shift.session.elapsed_seconds
 g.shift.close_board()
 g.queue_free()
 await create_timer(0.2).timeout
 g = scene()
 await idle(8)
 assert(paused and g.shift.overlay.resume_card.visible)
 await capture("/tmp/firstpitch-resume-card.png")
 await click(g.shift.overlay.resume_button)
 assert(paused and g.shift.session.phase == ShiftSession.Phase.ACTIVE)
 assert(g.shift.session.elapsed_seconds == elapsed and g.mound.work_done == 3)
 await capture("/tmp/firstpitch-resumed-session.png")
 print("Onboarding visuals: first launch, native skip/replay, pad Controls/back, persisted paused resume verified")
 g.shift.close_board()
 g.queue_free()
 await create_timer(0.15).timeout
 for path in paths:
  DirAccess.remove_absolute(path)
 quit()
