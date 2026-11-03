extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func idle(count: int) -> void:
 for i in range(count):
  await process_frame
func click(button: Button) -> void:
 var point := button.get_global_rect().get_center()
 assert(Rect2(Vector2.ZERO,root.size).has_point(point),"Save controls must fit viewport")
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.position = point
  event.pressed = pressed
  Input.parse_input_event(event)
 await idle(4)
func capture(path: String) -> void:
 await idle(4)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-test_save_visual-career.dat"
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 for i in range(30):
  await physics_frame
 g.shift.save_store.path = "user://visual-save-test.dat"
 g.shift.open_board()
 await idle(3)
 await click(g.shift.overlay.training_button)
 assert(not paused and g.shift.session.phase == ShiftSession.Phase.ACTIVE)
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 g.infield.paint(Vector3(10,0,-10),Vector3.RIGHT,2.8,1.2)
 g.moisture.spray_at(Vector3(10,0,-10),2)
 g.chalk.paint_segment(Vector3(5,0,-5),Vector3(8,0,-8))
 g.mound.apply_tamp(0)
 g.shift.open_board()
 await idle(5)
 await click(g.shift.overlay.save_button)
 assert(g.shift.overlay.save_message.text.begins_with("Saved snapshot"))
 var before: Dictionary = g.shift.save_store.capture(g,g.shift.session)
 await capture("/tmp/firstpitch-save-board.png")
 # Recreate the entire scene: the file is the only source of the old field state.
 g.queue_free()
 await idle(2)
 g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-test_save_visual-career.dat"
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 g.shift.save_store.path = "user://visual-save-test.dat"
 g.shift.open_board()
 await idle(5)
 assert(g.grass.cut_count == 0)
 await click(g.shift.overlay.load_button)
 assert(g.shift.overlay.save_message.text.begins_with("Loaded."))
 assert(paused and g.grass.cut_count > 0 and g.infield.prepared_count > 0 and g.moisture.wet_count > 0 and g.chalk.covered_count > 0 and g.mound.work_done == 1)
 assert(g.shift.session.phase == ShiftSession.Phase.ACTIVE and g.shift.session.elapsed_seconds == before.session.elapsed)
 await capture("/tmp/firstpitch-save-loaded.png")
 await click(g.shift.overlay.close_button)
 assert(not paused)
 for i in range(10):
  await physics_frame
 assert(g.shift.session.elapsed_seconds > before.session.elapsed)
 g.shift.open_board()
 await click(g.shift.overlay.end_button)
 await capture("/tmp/firstpitch-save-results.png")
 DirAccess.remove_absolute(g.shift.save_store.path)
 print("Graphical save/load: native buttons, scene recreation, five jobs, paused clock, resume, results passed")
 paused = false
 g.queue_free()
 await idle(2)
 quit()
