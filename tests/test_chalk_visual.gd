# Controlled graphical chalking pass; requires a desktop or virtual display.
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
 game.career_save_path = "user://test-test_chalk_visual-career.dat"
 game.tutorial_enabled = false
 game.autosave_enabled = false
 DirAccess.remove_absolute(game.career_save_path)
 root.add_child(game)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for i in range(45):
  await physics_frame
 game.player.global_position = game.chalk_marker.global_position+Vector3(1.3,0,0)
 game.interact()
 game._process(0.0)
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.near = 0.3
 camera.far = 500
 camera.fov = 55
 camera.position = Vector3(33,4,-15)
 camera.look_at(game.chalk_marker.global_position+Vector3.UP*0.8)
 await capture("/tmp/firstpitch-chalk-marker.png")
 var direction: Vector2 = game.chalk.line_direction(1)
 game.chalk_marker.global_position = Vector3(direction.x*5,0.05,direction.y*5)
 game.chalk_marker.rotation.y = -PI/4
 game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
 game.chalk_marker.toggle_gate()
 game._process(0.0)
 camera.position = Vector3(18,17,13)
 camera.look_at(Vector3(7,0,-7))
 await capture("/tmp/firstpitch-chalk-before.png")
 Input.action_press("forward")
 for i in range(240):
  await physics_frame
 Input.action_release("forward")
 for i in range(60):
  await physics_frame
 game._process(0.0)
 await capture("/tmp/firstpitch-chalk-after.png")
 camera.position = game.chalk_marker.global_position+game.chalk_marker.global_basis*Vector3(3,2.7,5)
 camera.look_at(game.chalk_marker.global_position+Vector3.UP*0.7)
 await capture("/tmp/firstpitch-chalking.png")
 var count: int = game.chalk.covered_count
 # A separate parallel stroke must be visible without increasing the score.
 var across := Vector2(-direction.y,direction.x)*0.8
 var point := direction*17+across
 game.chalk_marker.global_position = Vector3(point.x,0.05,point.y)
 game.chalk_marker.last_nozzle = game.chalk_marker.nozzle.global_position
 Input.action_press("forward")
 for i in range(120):
  await physics_frame
 Input.action_release("forward")
 for i in range(60):
  await physics_frame
 game._process(0.0)
 camera.position = Vector3(20,17,15)
 camera.look_at(Vector3(9,0,-9))
 await capture("/tmp/firstpitch-chalk-off-guide.png")
 if game.chalk.covered_count != count or count <= 0 or game.grass.cut_count != 0 or game.infield.prepared_count != 0:
  push_error("Graphical chalk task accounting failed")
  quit(1)
  return
 print("Graphical chalk run: ",count," sections / ",game.chalk.percentage(),"%; off-guide score unchanged")
 quit()
