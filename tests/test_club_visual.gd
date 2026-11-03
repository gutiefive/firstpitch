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
func complete_prep(g: Node) -> void:
 g.grass.prepare_all()
 g.infield.prepare_all()
 g.moisture.fill_valid(0.8)
 g.chalk.prepare_all()
 g.mound.prepare_all()
 g.shift.collect_progress()
 g.shift.session.advance(0)
func finish_date(g: Node) -> void:
 g.club.prepare()
 complete_prep(g)
 g.club.host()
func fund(g: Node) -> void:
 var s := ShiftSession.new()
 s.start("full")
 s.set_progress([100,100,100,100,100],[true,true,true,true,true])
 s.advance(1)
 g.shift.career.claim(s.attempt_id,s.get_result())
 s.free()
func park_view(g: Node,camera: Camera3D,path: String) -> void:
 g.shift.close_board()
 g.hud.visible = false
 g.shift.overlay.visible = false
 camera.current = true
 camera.position = Vector3(42,30,45)
 camera.look_at(Vector3(4,0,10))
 await capture(path)
 g.hud.visible = true
 g.shift.overlay.visible = true
func open_club(g: Node) -> void:
 if not g.shift.overlay.modal.visible:
  await key(KEY_TAB)
 await click(g.shift.overlay.club_button)
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-club-visual-career.dat"
 g.settings_save_path = "user://test-club-visual-settings.cfg"
 g.tutorial_enabled = false
 g.autosave_enabled = false
 DirAccess.remove_absolute(g.career_save_path)
 root.add_child(g)
 await frames(15)
 await open_club(g)
 await capture("/tmp/firstpitch-club-offer.png")
 await click(g.shift.overlay.club_panel.join_button)
 assert(g.shift.career.club_started() and g.grass.deck_width == 1.8 and g.club.world.seat_count == 120)
 await capture("/tmp/firstpitch-club-chapter-one.png")
 var camera := Camera3D.new()
 g.add_child(camera)
 camera.far = 500
 camera.fov = 55
 await park_view(g,camera,"/tmp/firstpitch-club-starter.png")
 await open_club(g)
 await click(g.shift.overlay.club_panel.prep_button)
 assert(g.shift.session.profile_id == "home_game" and not paused)
 # Completed surface fixtures drive the story path; this is not a human full-prep run.
 complete_prep(g)
 await open_club(g)
 assert(not g.shift.overlay.club_panel.host_button.disabled)
 await click(g.shift.overlay.club_panel.host_button)
 assert(g.shift.career.balance == 244 and g.club.world.crowd_count == 48)
 await capture("/tmp/firstpitch-club-first-game.png")
 await park_view(g,camera,"/tmp/firstpitch-club-first-crowd.png")
 for i in range(2):
  finish_date(g)
 # Side-work fixtures provide additional construction and workshop capital.
 fund(g)
 fund(g)
 await open_club(g)
 await click(g.shift.overlay.club_panel.projects.bleachers)
 assert(g.club.world.seat_count == 240)
 await click(g.shift.overlay.club_panel.projects.snack_shack)
 assert(g.club.world.structures.has_node("OwlsSnackShack"))
 await park_view(g,camera,"/tmp/firstpitch-club-expanded.png")
 while g.shift.career.club.fans < 200:
  finish_date(g)
 await open_club(g)
 await click(g.shift.overlay.club_panel.projects.grandstand)
 assert(g.club.world.seat_count == 480)
 await click(g.shift.overlay.club_panel.workshop_button)
 assert(g.shift.overlay.career_screen.visible)
 for id in ["wide_deck","hose_nozzle","wide_drag","guide_wheel"]:
  await click(g.shift.overlay.career_panel.shop[id])
 assert(g.grass.deck_width == 3.0 and g.mower.drag.working_width == 3.5 and g.moisture.application_rate == 1.0)
 finish_date(g)
 await open_club(g)
 assert(g.shift.career.club.last.net > 84 and g.shift.overlay.club_panel.chapter.text.contains("Chapter 5"))
 await capture("/tmp/firstpitch-club-grown-story.png")
 await park_view(g,camera,"/tmp/firstpitch-club-grown-stadium.png")
 g.hud.visible = false
 g.shift.overlay.visible = false
 camera.current = true
 camera.position = Vector3(14,4.8,8)
 camera.look_at(Vector3(7,1.4,11.5))
 await capture("/tmp/firstpitch-club-supporters.png")
 print("Club visuals: native enrollment, home prep/hosting, projects, workshop and 120-to-480-seat stadium growth passed")
 g.queue_free()
 await create_timer(0.15).timeout
 DirAccess.remove_absolute("user://test-club-visual-career.dat")
 DirAccess.remove_absolute("user://test-club-visual-settings.cfg")
 quit()
