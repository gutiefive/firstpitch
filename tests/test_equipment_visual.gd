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
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-equipment-visual-career.dat"
 g.settings_save_path = "user://test-equipment-visual-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await frames(15)
 await key(KEY_TAB)
 await click(g.shift.overlay.career_button)
 assert(g.shift.overlay.career_panel.shop.wide_drag.disabled and g.shift.overlay.career_panel.shop.guide_wheel.disabled)
 g.shift.overlay.career_screen.scroll_vertical = 0
 await capture("/tmp/firstpitch-equipment-locked.png")
 # Honest-format completed-result fixtures fund the unlock/purchase branch only.
 for i in range(2):
  var s := ShiftSession.new()
  s.start("full")
  s.set_progress([100,100,100,100,100],[true,true,true,true,true])
  s.advance(1)
  g.shift.career.claim(s.attempt_id,s.get_result())
  s.free()
 await click(g.shift.overlay.career_panel.shop.wide_drag)
 await click(g.shift.overlay.career_panel.shop.guide_wheel)
 assert(g.shift.career.balance == 150 and g.mower.drag.working_width == 3.5 and g.chalk_marker.guide_wheel_owned)
 g.shift.overlay.career_screen.scroll_vertical = 0
 await capture("/tmp/firstpitch-equipment-owned.png")
 await key(KEY_ESCAPE)
 await key(KEY_ESCAPE)
 assert(not paused)
 g.player.global_position = g.mower.global_position+Vector3(2.4,0.1,0)
 await key(KEY_Q)
 assert(g.mower.active_tool == RidingMower.WorkTool.DRAG)
 await key(KEY_E)
 g.mower.global_position = Vector3(7,0.05,-7)
 g.mower.rotation.y = -PI/4
 g.mower.previous_drag = g.mower.drag.global_position
 await frames(8)
 await key(KEY_R)
 Input.action_press("forward")
 await frames(100)
 Input.action_release("forward")
 assert(g.infield.prepared_count > 0)
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.position = g.mower.drag.global_position+Vector3(-5,4,6)
 camera.look_at(g.mower.drag.global_position)
 await capture("/tmp/firstpitch-wide-drag.png")
 await frames(45)
 await key(KEY_E)
 assert(not g.driving)
 g.mower.position = g.layout.mower_spawn
 g.player.global_position = g.chalk_marker.global_position+Vector3(1.3,0.1,0)
 await key(KEY_E)
 assert(g.pushing_chalk and g.chalk_marker.guide_wheel_owned)
 var direction: Vector2 = g.chalk.line_direction(1)
 var across := Vector2(-direction.y,direction.x)
 var p: Vector2 = g.layout.plate_position+direction*16+across*0.25
 g.chalk_marker.position = Vector3(p.x,0.06,p.y)
 g.chalk_marker.rotation.y = -PI/4-deg_to_rad(8)
 g.chalk_marker.last_nozzle = g.chalk_marker.nozzle.global_position
 await frames(10)
 await key(KEY_R)
 assert(g.chalk_marker.gate_open)
 Input.action_press("forward")
 await frames(120)
 assert(g.chalk_marker.guide_active and g.chalk.covered_count > 0)
 assert(g.chalk.distance_to_guide(g.chalk_marker.nozzle.global_position) < 0.11)
 camera.position = g.chalk_marker.global_position+Vector3(3,3,5)
 camera.look_at(g.chalk_marker.global_position+Vector3.UP*0.5)
 await capture("/tmp/firstpitch-chalk-guide-wheel.png")
 Input.action_release("forward")
 print("Equipment visuals: native rank unlock/purchases, actual wide-drag work and guide-wheel chalking passed")
 g.queue_free()
 await create_timer(0.15).timeout
 DirAccess.remove_absolute("user://test-equipment-visual-career.dat")
 DirAccess.remove_absolute("user://test-equipment-visual-settings.cfg")
 quit()
