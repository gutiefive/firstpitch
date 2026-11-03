# Graphical smoke check: a controlled basepath pass, not an end-to-end human playtest.
extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func capture(path: String) -> void:
 for i in range(4):
  await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(path) != OK:
  push_error("Could not save screenshot: " + path)
  quit(1)
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 game.career_save_path = "user://test-test_drag_visual-career.dat"
 DirAccess.remove_absolute(game.career_save_path)
 root.add_child(game)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for i in range(45):
  await physics_frame
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 if not game.swap_work_tool():
  push_error("Tool bay interaction failed")
  quit(1)
  return
 game._process(0.0)
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.near = 0.3
 camera.far = 500
 camera.fov = 55
 camera.position = Vector3(27,5,-14)
 camera.look_at(Vector3(33,0.8,-22))
 await capture("/tmp/firstpitch-tool-bay.png")
 game.interact()
 # Position at the basepath start to make the visual comparison repeatable.
 game.mower.global_position = Vector3(7,0.05,-7)
 game.mower.rotation.y = -PI/4
 game.mower.previous_drag = game.mower.drag.global_position
 game.mower.toggle_drag()
 game._process(0.0)
 camera.position = Vector3(19,20,15)
 camera.look_at(Vector3(10,0,-10))
 await capture("/tmp/firstpitch-dirt-before.png")
 Input.action_press("forward")
 for i in range(180):
  await physics_frame
 Input.action_release("forward")
 for i in range(60):
  await physics_frame
 game._process(0.0)
 await capture("/tmp/firstpitch-dirt-after.png")
 camera.position = game.mower.global_position+game.mower.global_basis*Vector3(4,4,7)
 camera.look_at(game.mower.drag.global_position+Vector3.UP*0.3)
 await capture("/tmp/firstpitch-dragging.png")
 if game.infield.prepared_count <= 0 or game.grass.cut_count != 0:
  push_error("Graphical drag run did not preserve task separation")
  quit(1)
  return
 print("Graphical dirt run: ",game.infield.prepared_count," cells / ",game.infield.percentage(),"%")
 quit()
