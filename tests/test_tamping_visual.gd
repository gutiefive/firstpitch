# Controlled graphical repair of every mound patch; requires a graphical display.
extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func frames(count: int) -> void:
 for i in range(count):
  await physics_frame
func click(game: Node) -> void:
 var event := InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.pressed = true
 game._input(event)
func capture(path: String) -> void:
 for i in range(4):
  await process_frame
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(path) != OK:
  push_error("Could not save capture: " + path)
  quit(1)
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 game.career_save_path = "user://test-test_tamping_visual-career.dat"
 DirAccess.remove_absolute(game.career_save_path)
 root.add_child(game)
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 await frames(45)
 var camera := Camera3D.new()
 game.add_child(camera)
 camera.current = true
 camera.near = 0.3
 camera.far = 500
 camera.fov = 55
 game.tamper.camera = camera
 game.player.global_position = game.tamper.rack_position+Vector3(-1.2,0.05,1.2)
 game.tamper.toggle_equipped()
 camera.position = Vector3(35,4,1)
 camera.look_at(game.tamper.rack_position+Vector3.UP)
 game._process(0)
 await capture("/tmp/firstpitch-tamper-rack.png")
 var point: Vector3 = game.mound.patch_world(0)
 game.player.global_position = point+Vector3(0,0.1,1.3)
 await frames(30)
 camera.position = Vector3(5,5,-12)
 camera.look_at(Vector3(0,0.36,-18.44))
 await capture("/tmp/firstpitch-mound-before.png")
 camera.position = point+Vector3(2.5,3.5,4.4)
 camera.look_at(point)
 await frames(4)
 click(game)
 await frames(10)
 await capture("/tmp/firstpitch-tamping.png")
 await frames(40)
 for i in range(2):
  click(game)
  await frames(45)
 game._process(0)
 await capture("/tmp/firstpitch-mound-patch-repaired.png")
 if game.mound.hits[0] != game.mound.hits_required:
  push_error("Graphical first patch did not repair")
  quit(1)
  return
 # A real graphical cursor release must cancel a windup before contact.
 point = game.mound.patch_world(1)
 camera.look_at(point)
 await frames(4)
 var before: int = game.mound.work_done
 click(game)
 await frames(5)
 var escape := InputEventKey.new()
 escape.keycode = KEY_ESCAPE
 escape.pressed = true
 game._unhandled_input(escape)
 await frames(45)
 if game.mound.work_done != before:
  push_error("Cursor release did not cancel tamping")
  quit(1)
  return
 game._unhandled_input(escape)
 for index in range(1,game.mound.hits.size()):
  point = game.mound.patch_world(index)
  game.player.global_position = point+Vector3(-0.75,0.1,0.65)
  camera.position = point+Vector3(2.5,3.5,4.4)
  camera.look_at(point)
  await frames(20)
  for hit in range(game.mound.hits_required):
   click(game)
   await frames(45)
 game._process(0)
 camera.position = Vector3(5,5,-12)
 camera.look_at(Vector3(0,0.36,-18.44))
 await capture("/tmp/firstpitch-mound-after.png")
 if game.mound.work_done != game.mound.total_work or game.mound.repaired_count != game.mound.hits.size():
  push_error("Graphical mound repair was incomplete")
  quit(1)
  return
 if game.grass.cut_count != 0 or game.infield.prepared_count != 0 or game.chalk.covered_count != 0 or game.moisture.wet_count != 0:
  push_error("Tamping affected another task")
  quit(1)
  return
 print("Graphical mound run: ",game.mound.work_done," valid strokes / ",game.mound.repaired_count," repaired patches / ",game.mound.percentage(),"%")
 quit()
