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
func key(g: Node,code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = true
 g._unhandled_input(event)
func run() -> void:
 var path := "user://test-tutorial-settings.cfg"
 DirAccess.remove_absolute(path)
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://test-tutorial-career.dat"
 g.settings_save_path = path
 g.autosave_enabled = false
 root.add_child(g)
 var t: CrewTutorial = g.tutorial
 t.set_process(false)
 await frames(20)
 check(t.active and t.step == 0 and not t.step_complete(),"first launch begins guide with unfinished noticeboard step")
 g.player.global_position = g.layout.noticeboard_position+Vector3(0,-g.layout.noticeboard_position.y+0.1,4.3)
 g.yaw = 0
 await frames(3)
 Input.action_press("forward")
 await frames(30)
 Input.action_release("forward")
 check(t.step_complete(),"walking near noticeboard completes first check")
 t._process(0)
 check(t.step == 1 and not t.step_complete(),"mowing step starts unfinished")
 g.player.global_position = g.mower.global_position+Vector3(2.4,0.1,0)
 key(g,KEY_E)
 t._process(0)
 check(not t.step_complete(),"entering tractor alone does not satisfy mowing")
 g.mower.global_position = Vector3(0,0.05,-60)
 g.mower.previous_deck = g.mower.deck.global_position
 Input.action_press("forward")
 await frames(60)
 Input.action_release("forward")
 check(t.step_complete() and g.grass.cut_count > 0,"actual tractor mowing satisfies second check")
 t._process(0)
 check(t.step == 2 and not t.step_complete(),"dragging step starts unfinished")
 g.mower.speed = 0
 g.mower.velocity = Vector3.ZERO
 g.mower.global_position = g.layout.mower_spawn
 key(g,KEY_E)
 g.player.global_position = g.mower.global_position+Vector3(2.4,0.1,0)
 key(g,KEY_Q)
 key(g,KEY_E)
 g.mower.global_position = Vector3(7,0.05,-7)
 g.mower.rotation.y = -PI/4
 g.mower.previous_drag = g.mower.drag.global_position
 g.mower.speed = 2
 key(g,KEY_R)
 g._process(0)
 t._process(0)
 check(not g.mower.drag.lowered and g.hud.tutorial_reason.text == g.prompt.text and "Stop" in g.prompt.text,"blocked guide reuses the live stop-before-lowering prompt")
 g.mower.speed = 0
 key(g,KEY_R)
 Input.action_press("forward")
 await frames(100)
 Input.action_release("forward")
 check(t.step_complete() and g.infield.prepared_count > 0,"bay swap, lowering and actual forward drag satisfy third check")
 t._process(0)
 check(t.step == 3 and not t.step_complete(),"chalk step starts unfinished")
 g.mower.speed = 0
 g.mower.velocity = Vector3.ZERO
 key(g,KEY_E)
 g.player.global_position = g.chalk_marker.global_position+Vector3(1.3,0.1,0)
 key(g,KEY_E)
 var direction: Vector2 = g.chalk.line_direction(1)
 g.chalk_marker.global_position = Vector3(direction.x*8,0.05,direction.y*8)
 g.chalk_marker.rotation.y = -PI/4
 g.chalk_marker.last_nozzle = g.chalk_marker.nozzle.global_position
 key(g,KEY_R)
 Input.action_press("forward")
 await frames(90)
 Input.action_release("forward")
 check(t.step_complete() and g.chalk.covered_count > 0,"actual open-gate marker pass satisfies fourth check")
 t._process(0)
 check(t.step == 4 and not t.step_complete(),"watering step starts unfinished")
 check(g.pushing_chalk and t.instruction().contains("release") and t.target() == g.chalk_marker.global_position,"watering handoff directs player to release chalk cart first")
 t._process(0)
 check(g.hud.tutorial_reason.text.contains("on foot"),"guide explains why hose pickup is blocked while pushing")
 g.chalk_marker.speed = 0
 g.chalk_marker.velocity = Vector3.ZERO
 key(g,KEY_E)
 g.chalk_marker.global_position = g.layout.chalk_marker_spawn
 g.mower.global_position = g.layout.mower_spawn
 g.player.global_position = g.watering.station_position+Vector3(-1.5,0.05,1.5)
 check(t.instruction().contains("water station"),"on-foot watering guide directs player to hose station")
 key(g,KEY_F)
 var camera: Camera3D = g.camera
 g.watering.capture_query = func() -> bool: return true
 g.player.global_position = Vector3(10,0.05,-7)
 g.yaw = 0
 g.pitch = -0.45
 check(t.instruction().contains("Look down"),"equipped guide explains ground reticle and soaking")
 await frames(60)
 Input.action_press("spray_water")
 await frames(100)
 Input.action_release("spray_water")
 check(t.step_complete() and g.moisture.wet_count > 0,"real player-camera spray reaching moisture target satisfies fifth check")
 check(g.watering.camera == g.camera,"watering regression uses normal player spring-arm camera")
 t._process(0)
 check(g.hud.tutorial_reason.text.contains("AIM"),"guide exposes live watering feedback and moisture")
 t._process(0)
 check(t.step == 5 and not t.step_complete(),"mound step starts unfinished")
 key(g,KEY_F)
 g.player.global_position = g.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 key(g,KEY_G)
 var point: Vector3 = g.mound.patch_world(0)
 g.player.global_position = point+Vector3(-0.75,0.1,0.65)
 camera = Camera3D.new()
 g.add_child(camera)
 camera.current = true
 camera.position = point+Vector3(2.5,3.5,4.4)
 camera.look_at(point)
 g.tamper.camera = camera
 g.tamper.capture_query = func() -> bool: return true
 await frames(20)
 for hit in range(3):
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = true
  g._input(event)
  await frames(45)
  if hit < 2:
   check(not t.step_complete(),"partial mound impacts do not complete guide step")
 check(t.step_complete() and g.mound.repaired_count == 1,"three real timed impacts satisfy sixth check")
 t._process(0)
 check(t.step == 6 and not t.step_complete(),"planning step starts unfinished")
 g.shift.open_board()
 t._process(0)
 check(not t.step_complete() and t.board_seen,"board must be read and closed to finish guide")
 g.shift.close_board()
 check(t.step_complete(),"closing board satisfies final check")
 t._process(0)
 check(not t.active and g.settings.tutorial_done and g.shift.counts() == [0,0,0,0,0],"finishing clears all tutorial work and saves done state")
 var restored := CrewSettings.new()
 restored.path = path
 restored.load_settings()
 check(restored.tutorial_done,"completed guide stays completed after preferences reload")
 check(t.replay() and t.active and t.step == 0,"Replay tutorial restarts from noticeboard")
 g.shift.start_shift("training")
 t._process(0)
 check(not t.can_run() and not g.hud.tutorial_panel.visible and not t.finish(),"paid attempt blocks tutorial checks, cleanup and skip")
 g.shift.end_shift()
 g.shift.close_board()
 check(t.replay(),"tutorial can replay after an ended attempt")
 g.grass.paint(Vector3(0,0,-60),Vector3.FORWARD)
 check(t.finish() and g.grass.cut_count == 0,"skipping clears tutorial work through existing reset path")
 restored.load_settings()
 check(restored.tutorial_done,"skip persists done state")
 restored.tutorial_done = false
 restored.tutorial_step = 4
 restored.save()
 var resumed := CrewSettings.new()
 resumed.path = path
 resumed.load_settings()
 check(not resumed.tutorial_done and resumed.tutorial_step == 4,"unfinished guide checkpoint survives preferences reload")
 g.queue_free()
 await create_timer(0.15).timeout
 for file in [path,"user://test-tutorial-career.dat"]:
  DirAccess.remove_absolute(file)
 print("Tutorial: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
