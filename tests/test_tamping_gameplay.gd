extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func press_key(game: Node,key: Key) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = key
 event.keycode = key
 event.pressed = true
 game._unhandled_input(event)
func click(game: Node) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 game._input(event)
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await frames(60)
 press_key(game,KEY_G)
 check(not game.tamper.equipped,"tamper pickup requires being near rack")
 game.player.global_position = Vector3(0,0.1,-14.8)
 await frames(15)
 Input.action_press("forward")
 await frames(45)
 Input.action_release("forward")
 await frames(15)
 check(game.player.is_on_floor() and game.player.global_position.y > 0.3,"walking climbs the shallow mound slope")
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 press_key(game,KEY_G)
 check(game.tamper.equipped and not game.player.seated,"G takes tamper while keeping walking control")
 check(game.hud.objective_label.text == "Repair the pitcher’s mound","tamper selects mound objective")
 check(not game.swap_work_tool(),"tractor attachment swap is blocked while holding tamper")
 var capture_state := [true]
 game.tamper.capture_query = func() -> bool: return capture_state[0]
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 var point: Vector3 = game.mound.patch_world(0)
 camera.position = point+Vector3(0,3.4,4.8)
 camera.look_at(point)
 game.tamper.camera = camera
 game.player.global_position = point+Vector3(0,0.1,1.3)
 await frames(45)
 check(game.player.is_on_floor() and game.player.global_position.y > 0.3,"player stands on mound collision instead of inside mesh")
 check(game.tamper.target_index == 0,"camera ray selects worn clay patch")
 click(game)
 await frames(5)
 check(game.tamper.busy and game.mound.work_done == 0,"click starts windup without instant repair")
 for i in range(12):
  click(game)
 await frames(25)
 check(game.mound.hits[0] == 1,"impact commits one stroke despite click spam")
 check(game.progress.value > 0 and game.hud.reticle.visible,"repair progress and reticle reach HUD")
 await frames(20)
 for i in range(2):
  click(game)
  await frames(45)
 check(game.mound.hits[0] == 3 and game.mound.repaired_count == 1,"three separate timed strokes complete one patch")
 click(game)
 await frames(45)
 check(game.mound.work_done == 3,"repaired patch cannot be farmed for progress")
 check(game.grass.cut_count == 0 and game.infield.prepared_count == 0 and game.chalk.covered_count == 0 and game.moisture.wet_count == 0,"tamping does not advance other tasks")
 point = game.mound.patch_world(1)
 camera.look_at(point)
 await frames(3)
 capture_state[0] = false
 click(game)
 await frames(45)
 check(game.mound.work_done == 3,"free cursor blocks tamping")
 capture_state[0] = true
 click(game)
 await frames(5)
 camera.look_at(Vector3(20,0,-40))
 await frames(45)
 check(game.mound.work_done == 3,"looking away before impact earns no repair")
 camera.look_at(point)
 await frames(3)
 click(game)
 await frames(5)
 Input.action_press("forward")
 await frames(30)
 Input.action_release("forward")
 await frames(30)
 check(game.mound.work_done == 3,"moving before impact prevents a valid stroke")
 game.player.global_position = Vector3(8,0.05,-10)
 await frames(15)
 click(game)
 await frames(45)
 check(game.mound.work_done == 3,"distant patch cannot be repaired remotely")
 game.player.global_position = point+Vector3(-0.9,0.1,0.6)
 await frames(30)
 var wall := ParkGeometry.box(game,Vector3(-0.4,0.9,-17.07),Vector3(0.12,1.1,1.2),Color.GRAY,true)
 await frames(3)
 check(not game.tamper.can_work(1),"obstacle blocks hand-to-patch reach")
 click(game)
 await frames(45)
 check(game.mound.work_done == 3,"tamping through an obstacle cannot count")
 wall.queue_free()
 await frames(3)
 click(game)
 await frames(5)
 press_key(game,KEY_G)
 await frames(45)
 check(not game.tamper.equipped and not game.tamper.busy,"stowing cancels unfinished stroke")
 check(game.mound.work_done == 3,"cancelled windup leaves patch unchanged")
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 press_key(game,KEY_G)
 game.player.global_position = game.watering.station_position+Vector3(-1.5,0.05,1.5)
 press_key(game,KEY_F)
 check(game.watering.equipped and not game.tamper.equipped,"taking hose stows tamper without overlapping hand tools")
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 press_key(game,KEY_G)
 check(game.tamper.equipped and not game.watering.equipped,"taking tamper stows hose")
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 press_key(game,KEY_E)
 check(game.driving and not game.tamper.equipped,"tractor entry stows tamper")
 press_key(game,KEY_G)
 check(not game.tamper.equipped,"cannot take tamper while driving")
 press_key(game,KEY_E)
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 press_key(game,KEY_G)
 game.player.global_position = game.chalk_marker.global_position+Vector3(1.3,0,0)
 press_key(game,KEY_E)
 check(game.pushing_chalk and not game.tamper.equipped,"chalk marker entry also stows tamper")
 check(game.mound.work_done == 3,"equipment changes preserve completed mound work")
 game.grass.cut_count = game.grass.total
 game.infield.prepared_count = game.infield.total
 game.chalk.covered_count = game.chalk.valid_count
 game.moisture.wet_count = game.moisture.total
 game.mound.work_done = game.mound.total_work-1
 game.update_progress(0)
 check(not game.hud.objective_label.text.begins_with("PARK READY"),"one remaining mound stroke prevents park readiness")
 game.mound.work_done = game.mound.total_work
 game.update_progress(0)
 check(game.hud.objective_label.text.begins_with("PARK READY"),"park readiness now requires all five tasks")
 print("Tamping gameplay failures: ",failures)
 quit(1 if failures else 0)
