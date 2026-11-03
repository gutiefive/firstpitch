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
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 for i in range(60):
  await physics_frame
 press_key(game,KEY_F)
 check(not game.watering.equipped,"hose cannot be taken away from station")
 game.player.global_position = game.watering.station_position+Vector3(-1.5,0.05,1.5)
 press_key(game,KEY_F)
 check(game.watering.equipped and not game.player.seated,"F takes hose while preserving walking control")
 check(game.hud.objective_label.text == "Water the infield dirt","equipping hose selects watering objective")
 check(not game.swap_work_tool(),"cannot swap tractor attachments with hose in hand")
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.position = Vector3(8,4,-3)
 camera.look_at(Vector3(10,0,-10))
 game.watering.camera = camera
 # The dummy display always reports a visible cursor; inject only this OS state.
 var capture_state := [true]
 game.watering.capture_query = func() -> bool: return capture_state[0]
 game.player.global_position = Vector3(8,0.05,-7)
 for i in range(30):
  await physics_frame
 Input.action_press("spray_water")
 for i in range(120):
  await physics_frame
 check(game.watering.target_valid and game.watering.spraying,"held spray action aims through camera into reachable ground")
 check(game.moisture.wet_count > 0,"actual spray physics soaks dirt")
 check(game.progress.value > 0 and game.hud.reticle.visible,"watering progress and aim reticle appear")
 check(game.grass.cut_count == 0 and game.infield.prepared_count == 0 and game.chalk.covered_count == 0,"watering leaves other task counters unchanged")
 var target: Vector3 = game.watering.target
 var dose: float = game.moisture.moisture_at(target)
 press_key(game,KEY_ESCAPE)
 capture_state[0] = false
 for i in range(30):
  await physics_frame
 check(not game.watering.spraying and game.moisture.moisture_at(target) == dose,"released cursor prevents accidental spraying")
 Input.action_release("spray_water")
 press_key(game,KEY_ESCAPE)
 capture_state[0] = true
 check(not game.watering.apply_spray(Vector3(-10,0,-10),1),"target beyond nozzle reach cannot be watered")
 game.player.global_position = Vector3(100,0.05,-80)
 check(not game.watering.apply_spray(Vector3(101,0,-81),1),"hose length limits watering even for a nearby target")
 game.player.global_position = Vector3(8,0.05,-7)
 for i in range(3):
  await physics_frame
 var wall := ParkGeometry.box(game,Vector3(9,0.8,-8.8),Vector3(3,1.6,0.15),Color.GRAY,true)
 for i in range(3):
  await physics_frame
 check(not game.watering.apply_spray(Vector3(10,0,-10),1),"wall blocks nozzle-to-target spray")
 wall.queue_free()
 for i in range(3):
  await physics_frame
 check(game.watering.apply_spray(Vector3(10,0,-10),0.05),"removing wall restores spray reach")
 var count: int = game.moisture.wet_count
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 press_key(game,KEY_E)
 check(game.driving and not game.watering.equipped and not game.watering.spraying,"entering tractor safely stows hose")
 press_key(game,KEY_F)
 check(not game.watering.equipped,"cannot equip hose while driving")
 Input.action_press("spray_water")
 for i in range(30):
  await physics_frame
 Input.action_release("spray_water")
 check(game.moisture.wet_count == count,"vehicle mode cannot add water exposure")
 press_key(game,KEY_E)
 game.player.global_position = game.watering.station_position+Vector3(-1.5,0.05,1.5)
 press_key(game,KEY_F)
 game.player.global_position = game.chalk_marker.global_position+Vector3(1.3,0,0)
 press_key(game,KEY_E)
 check(game.pushing_chalk and not game.watering.equipped,"chalk-marker interaction also stows hose")
 press_key(game,KEY_E)
 game.player.global_position = game.watering.station_position+Vector3(-1.5,0.05,1.5)
 press_key(game,KEY_F)
 game.player.global_position = Vector3(8,0.05,-7)
 press_key(game,KEY_F)
 check(not game.watering.equipped,"F can stow hose while away from station")
 check(game.moisture.wet_count == count,"stowing and switching tools preserve moisture")
 game.mound.work_done = game.mound.total_work
 game.grass.cut_count = game.grass.total
 game.infield.prepared_count = game.infield.total
 game.chalk.covered_count = game.chalk.valid_count
 game.moisture.wet_count = game.moisture.total-1
 game.update_progress(0)
 check(not game.hud.objective_label.text.begins_with("PARK READY"),"one dry cell prevents park completion")
 game.moisture.wet_count = game.moisture.total
 game.update_progress(0)
 check(game.hud.objective_label.text.begins_with("PARK READY"),"park completion requires all five full task counts")
 print("Watering gameplay failures: ",failures)
 quit(1 if failures else 0)
