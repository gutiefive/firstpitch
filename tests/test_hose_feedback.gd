extends SceneTree
var failures := 0
var checks := 0
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
func run() -> void:
 var g = load("res://scenes/main/main.tscn").instantiate()
 g.career_save_path = "user://hose-feedback-career.dat"
 g.settings_save_path = "user://hose-feedback-settings.cfg"
 g.autosave_enabled = false
 g.tutorial_enabled = false
 root.add_child(g)
 g.player.global_position = g.watering.station_position+Vector3(-1.5,0.05,1.5)
 await frames(20)
 g.watering.toggle_equipped()
 g.player.global_position = Vector3(10,0.05,-7)
 var captured := [true]
 g.watering.capture_query = func(): return captured[0]
 g.yaw = 0
 g.pitch = 0.05
 await frames(60)
 var wet: int = g.moisture.wet_count
 var click := InputEventMouseButton.new()
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = true
 Input.parse_input_event(click)
 await frames(5)
 check(g.watering.equipped and Input.is_action_pressed("spray_water"),"native left mouse input reaches equipped hose")
 check(g.watering.spraying and g.watering.droplets.visible,"hose visibly sprays even when camera aim misses nearby ground")
 check(g.moisture.wet_count == wet,"spraying into the air grants no dirt watering credit")
 captured[0] = false
 await frames(5)
 check(not g.watering.spraying and not g.watering.droplets.visible,"free cursor stops water effects")
 captured[0] = true
 g.pitch = -0.45
 await frames(100)
 check(g.watering.target_valid and g.moisture.wet_count > wet,"same held mouse input waters dirt using real player camera")
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/firstpitch-watering-spray.png")
 click = InputEventMouseButton.new()
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = false
 Input.parse_input_event(click)
 await frames(3)
 check(not g.watering.spraying,"releasing native mouse input stops spray")
 var wall := ParkGeometry.box(g,Vector3(10,1.1,-8.7),Vector3(4,2.2,0.2),Color.GRAY,true)
 await frames(5)
 wet = g.moisture.wet_count
 Input.action_press("spray_water")
 await frames(10)
 check(g.watering.spraying and g.watering.spray_end.z >= -8.61,"visible spray stops at an obstruction")
 check(g.moisture.wet_count == wet,"water hitting a wall cannot soak dirt behind it")
 Input.action_release("spray_water")
 wall.queue_free()
 g.player.global_position = Vector3(100,0.05,-80)
 Input.action_press("spray_water")
 await frames(30)
 check(not g.watering.spraying and g.watering.feedback == "HOSE OUT OF REACH","finite hose length still stops water with explicit feedback")
 Input.action_release("spray_water")
 g.queue_free()
 await process_frame
 print("Hose feedback: %d checks; %d failures" % [checks,failures])
 quit(1 if failures else 0)
