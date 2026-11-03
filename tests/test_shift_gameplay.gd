extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
func idle_frames(count: int) -> void:
 for i in range(count):
  await process_frame
func press_key(game: Node,key: Key) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = key
 event.keycode = key
 event.pressed = true
 game._unhandled_input(event)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 game.career_save_path = "user://test-test_shift_gameplay-career.dat"
 DirAccess.remove_absolute(game.career_save_path)
 root.add_child(game)
 await frames(60)
 check(game.shift.session.phase == ShiftSession.Phase.PRACTICE and not paused,"game begins as unrestricted free practice")
 game.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 game.infield.paint(Vector3(10,0,-10),Vector3.FORWARD,2.8,1.2)
 game.moisture.spray_at(Vector3(10,0,-10),3)
 var direction: Vector2 = game.chalk.line_direction(1)
 game.chalk.paint_segment(Vector3(direction.x*5,0,direction.y*5),Vector3(direction.x*8,0,direction.y*8))
 game.chalk.flush_visuals()
 game.mound.apply_tamp(0)
 var grass_count: int = game.grass.cut_count
 press_key(game,KEY_TAB)
 check(paused and game.shift.overlay.modal.visible,"Tab opens a board that pauses the world")
 check(game.grass.cut_count == grass_count and game.mound.work_done == 1,"opening board does not reset existing practice")
 game.shift.close_board()
 check(not paused and not game.shift.overlay.modal.visible,"closing board resumes practice")
 check(not game.shift.start_shift("invalid") and game.grass.cut_count == grass_count,"invalid shift request cannot discard field work")
 game.shift.open_board()
 game.shift.overlay.training_button.pressed.emit()
 check(game.shift.session.phase == ShiftSession.Phase.ACTIVE and not paused,"training button starts and resumes a real shift")
 check(game.grass.cut_count == 0 and game.infield.prepared_count == 0 and game.moisture.wet_count == 0 and game.chalk.covered_count == 0 and game.mound.work_done == 0,"fresh shift clears all five work counters")
 check(game.grass.image.get_pixelv(game.grass.world_to_grid(Vector3(0,0,-60))).r == 0 and game.moisture.moisture_at(Vector3(10,0,-10)) == 0,"fresh shift clears visible grass and moisture state")
 check(game.chalk.get_child_count() == 1 and game.chalk.pending.is_empty(),"fresh shift removes old chalk meshes and queued strokes")
 check(game.mound.hits[0] == 0 and game.mound.clumps[0].visible,"fresh shift restores worn mound visuals")
 check(not game.player.seated and not game.driving and not game.pushing_chalk and game.mower.active_tool == RidingMower.WorkTool.MOWER,"fresh shift returns equipment and control to initial state")
 check(game.player.global_position.distance_to(Vector3(29,0.1,-11)) < 0.01 and game.mower.speed == 0 and not game.chalk_marker.gate_open,"fresh shift resets spawn, speed and chalk gate")
 game.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 await frames(15)
 check(game.shift.session.values[0] > 0 and game.shift.session.score() > 0,"actual cut cells feed shift score")
 check(game.shift.session.remaining_seconds < 900,"active shift clock advances")
 game.shift.open_board()
 var remaining: float = game.shift.session.remaining_seconds
 var position: Vector3 = game.player.global_position
 Input.action_press("forward")
 await idle_frames(6)
 check(game.shift.session.remaining_seconds == remaining and game.player.global_position == position,"board pauses both actor motion and countdown")
 Input.action_release("forward")
 grass_count = game.grass.cut_count
 check(not game.shift.start_shift("full") and game.grass.cut_count == grass_count,"running shift cannot be restarted or reset by another profile")
 check(game.shift.overlay.training_button.disabled and game.shift.overlay.full_button.disabled,"fresh-start buttons are disabled during an active shift")
 Input.action_press("spray_water")
 game.shift.overlay.close_button.pressed.emit()
 check(not paused and not Input.is_action_pressed("spray_water"),"resume releases the UI click instead of leaking spray input")
 # Pause cancels an unfinished tamp rather than preserving a queued free impact.
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 press_key(game,KEY_G)
 var point: Vector3 = game.mound.patch_world(0)
 game.player.global_position = point+Vector3(0,0.1,1.3)
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.position = point+Vector3(0,3.4,4.8)
 camera.look_at(point)
 game.tamper.camera = camera
 game.tamper.capture_query = func() -> bool: return true
 await frames(30)
 var click := InputEventMouseButton.new()
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = true
 game._input(click)
 await frames(5)
 check(game.tamper.busy,"integration fixture starts a real tamp windup")
 game.shift.open_board()
 check(not game.tamper.busy and game.mound.work_done == 0,"opening board cancels pre-contact tamp")
 game.shift.close_board()
 await frames(30)
 check(game.mound.work_done == 0,"resuming cannot commit the cancelled swing")
 game.shift.open_board()
 game.shift.overlay.end_button.pressed.emit()
 check(game.shift.session.phase == ShiftSession.Phase.FINISHED and paused,"ending shift opens paused results")
 var result: Dictionary = game.shift.session.get_result()
 check(result["reason"] == "ended_early" and result["values"][0] > 0,"results reflect work actually done before early finish")
 game.shift.overlay.close_button.pressed.emit()
 check(not paused,"results can return to continuing practice")
 game.infield.paint(Vector3(10,0,-10),Vector3.FORWARD,2.8,1.2)
 await frames(15)
 check(game.infield.prepared_count > 0 and game.shift.session.get_result()["values"][1] == 0,"later practice leaves last result frozen")
 check(game.shift.session.get_result()["score"] == result["score"],"result score remains immutable after practice")
 game.shift.open_board()
 game.shift.overlay.full_button.pressed.emit()
 check(game.shift.session.profile_id == "full" and game.shift.session.remaining_seconds == 1800,"can start a fresh full shift after results")
 check(game.infield.prepared_count == 0 and not game.tamper.equipped,"restart resets practiced dirt and held tools again")
 game.shift.session.advance(1900)
 check(paused and game.shift.session.get_result()["reason"] == "time_up","deadline automatically opens time-up results")
 check(game.shift.session.get_result()["score"] == 0 and game.shift.session.remaining_seconds == 0,"empty timeout yields zero score and a stopped clock")
 # This final branch uses injected completion counts, not a full-park human playthrough.
 game.shift.start_shift("full")
 game.grass.cut_count = game.grass.total
 game.infield.prepared_count = game.infield.total
 game.chalk.covered_count = game.chalk.valid_count
 game.moisture.wet_count = game.moisture.total
 game.mound.work_done = game.mound.total_work
 game.update_progress(0)
 game.shift.collect_progress()
 game.shift.session.advance(0)
 check(game.shift.session.get_result()["reason"] == "completed" and game.shift.session.get_result()["score"] == 100,"all exact full counts complete the full shift")
 check(game.shift.overlay.heading.text == "PARK READY" and paused,"full completion presents park-ready results")
 game.shift.close_board()
 print("Shift gameplay failures: ",failures)
 game.queue_free()
 await create_timer(0.1).timeout
 quit(1 if failures else 0)
