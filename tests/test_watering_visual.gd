# Controlled visual exposure test. Requires a graphical display.
extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func capture(path: String) -> void:
 for i in range(4):
  await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(path) != OK:
  push_error("Could not save capture: " + path)
  quit(1)
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 game.career_save_path = "user://test-test_watering_visual-career.dat"
 DirAccess.remove_absolute(game.career_save_path)
 root.add_child(game)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for i in range(45):
  await physics_frame
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.near = 0.3
 camera.far = 500
 camera.fov = 55
 camera.position = Vector3(29,4,3)
 camera.look_at(game.watering.station_position+Vector3.UP)
 game.watering.camera = camera
 game.player.global_position = game.watering.station_position+Vector3(-1.5,0.05,1.5)
 game.watering.toggle_equipped()
 game._process(0)
 await capture("/tmp/firstpitch-water-station.png")
 # Seed a prepared strip and a chalk stroke to verify both survive watering.
 game.infield.drag_segment(Vector3(6,0,-6),Vector3(15,0,-15),Vector3(1,0,-1).normalized(),2.8,1.2)
 var direction: Vector2 = game.chalk.line_direction(1)
 game.chalk.paint_segment(Vector3(direction.x*8,0,direction.y*8),Vector3(direction.x*20,0,direction.y*20))
 var dirt_count: int = game.infield.prepared_count
 var chalk_count: int = game.chalk.covered_count
 game.player.global_position = Vector3(8,0.05,-7)
 camera.position = Vector3(8,4,-3)
 camera.look_at(Vector3(10,0,-10))
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 for i in range(30):
  await physics_frame
 game._process(0)
 await capture("/tmp/firstpitch-water-before.png")
 Input.action_press("spray_water")
 for i in range(180):
  await physics_frame
 game._process(0)
 await capture("/tmp/firstpitch-watering.png")
 var dose: float = game.moisture.moisture_at(game.watering.target)
 var escape := InputEventKey.new()
 escape.keycode = KEY_ESCAPE
 escape.pressed = true
 game._unhandled_input(escape)
 for i in range(30):
  await physics_frame
 if game.watering.spraying or game.moisture.moisture_at(game.watering.target) != dose:
  push_error("Real cursor release did not stop watering")
  quit(1)
  return
 Input.action_release("spray_water")
 game._unhandled_input(escape)
 for i in range(30):
  await physics_frame
 await capture("/tmp/firstpitch-water-after.png")
 camera.position = Vector3(20,19,16)
 camera.look_at(Vector3(10,0,-10))
 await capture("/tmp/firstpitch-wet-dirt.png")
 if game.moisture.wet_count <= 0 or game.infield.prepared_count != dirt_count or game.chalk.covered_count != chalk_count or game.grass.cut_count != 0:
  push_error("Graphical watering or task separation failed")
  quit(1)
  return
 print("Graphical watering run: ",game.moisture.wet_count," cells / ",game.moisture.percentage(),"%; drag and chalk preserved")
 quit()
