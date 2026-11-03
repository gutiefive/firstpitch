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
 g.career_save_path = "user://test-contracts-visual-career.dat"
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await frames(30)
 await key(KEY_TAB)
 await click(g.shift.overlay.contracts_button)
 assert(paused and g.shift.overlay.contracts_screen.visible)
 assert(g.shift.overlay.contracts_panel.buttons.infield_turnaround.disabled)
 await capture("/tmp/firstpitch-contracts-locked.png")
 await click(g.shift.overlay.contracts_panel.buttons.mound_callout)
 assert(not paused and g.shift.session.profile_id == "mound_callout")
 await capture("/tmp/firstpitch-contract-mound-active.png")
 g.player.global_position = g.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 await key(KEY_G)
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.near = 0.3
 camera.far = 500
 camera.fov = 55
 g.tamper.camera = camera
 for index in range(g.mound.hits.size()):
  var point: Vector3 = g.mound.patch_world(index)
  g.player.global_position = point+Vector3(-0.75,0.1,0.65)
  camera.position = point+Vector3(2.5,3.5,4.4)
  camera.look_at(point)
  await frames(20)
  for hit in range(g.mound.hits_required):
   var event := InputEventMouseButton.new()
   event.button_index = MOUSE_BUTTON_LEFT
   event.pressed = true
   g._input(event)
   await frames(45)
 assert(paused and g.shift.session.phase == ShiftSession.Phase.FINISHED)
 assert(g.shift.overlay.heading.text == "CONTRACT COMPLETE" and g.shift.career.balance == 40)
 assert(g.grass.cut_count == 0 and g.infield.prepared_count == 0 and g.moisture.wet_count == 0)
 await capture("/tmp/firstpitch-contract-complete.png")
 await click(g.shift.overlay.contracts_button)
 # Completion fixtures only fund the rank-unlock branch; mound earnings above are real.
 for profile in ["full","training"]:
  var seed := ShiftSession.new()
  seed.start(profile)
  seed.set_progress([100,100,100,100,100],[true,true,true,true,true])
  seed.advance(1)
  g.shift.career.claim(seed.attempt_id,seed.get_result())
  seed.free()
  if profile == "full":
   assert(g.shift.career.earned == 490 and g.shift.overlay.contracts_panel.buttons.infield_turnaround.disabled)
 assert(not g.shift.overlay.contracts_panel.buttons.infield_turnaround.disabled)
 await capture("/tmp/firstpitch-contracts-unlocked.png")
 await click(g.shift.overlay.contracts_panel.buttons.infield_turnaround)
 assert(not paused and g.shift.session.jobs_required() == 2)
 await capture("/tmp/firstpitch-contract-infield-active.png")
 await key(KEY_TAB)
 await click(g.shift.overlay.contracts_button)
 assert(g.shift.overlay.contracts_panel.buttons.quick_mow.disabled)
 await key(KEY_ESCAPE)
 assert(paused and not g.shift.overlay.contracts_screen.visible)
 await key(KEY_TAB)
 assert(not paused)
 g.shift.session.advance(g.shift.session.duration_seconds)
 assert(paused and g.shift.session.get_result().reason == "time_up")
 print("Contracts graphical: native board/start, 18 real impacts -> completed mound +40 cr, 490/640 rank boundary, infield checklist, pause/escape/timeout passed")
 DirAccess.remove_absolute(g.career_save_path)
 g.shift.close_board()
 g.queue_free()
 await create_timer(0.15).timeout
 quit()
