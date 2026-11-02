# Scripted graphical smoke run. Requires an X display or a desktop session.
extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for i in range(45):
  await physics_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-spawn.png")
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 game.interact()
 Input.action_press("forward")
 for i in range(300):
  await physics_frame
 Input.action_press("left")
 for i in range(120):
  await physics_frame
 Input.action_release("left")
 Input.action_release("forward")
 for i in range(75):
  await physics_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-mowing.png")
 game.interact()
 game.set_process(false)
 var overview := Camera3D.new()
 game.add_child(overview)
 overview.current = true
 overview.position = Vector3(75,105,80)
 overview.look_at(Vector3(0,0,-40))
 overview.fov = 50
 overview.far = 500
 for i in range(4):
  await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/firstpitch-overview.png")
 print("Graphical smoke completed; cut cells: ",game.grass.cut_count)
 quit()
