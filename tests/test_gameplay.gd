extends SceneTree
var failures := 0
func check(condition: bool,message: String) -> void:
 if condition:
  print("PASS: ",message)
 else:
  push_error(message)
  failures += 1
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 for i in range(90):
  await physics_frame
 check(game.player.is_on_floor(),"player settles on ground")
 check(game.mower.is_on_floor(),"mower settles on ground")
 game.player.global_position = game.mower.global_position+Vector3(2.4,0,0)
 game.interact()
 check(game.driving and game.player.seated and game.mower.occupied,"interaction transfers control to mower")
 Input.action_press("forward")
 for i in range(240):
  await physics_frame
 check(game.mower.speed > 1,"input accelerates mower")
 check(game.grass.cut_count > 0,"driving cuts actual field cells")
 game.interact()
 check(game.driving,"cannot exit a moving mower")
 Input.action_release("forward")
 Input.action_press("brake")
 for i in range(90):
  await physics_frame
 Input.action_release("brake")
 game.interact()
 check(not game.driving and not game.player.seated,"stationary exit restores walking")
 var count: int = game.grass.cut_count
 for i in range(30):
  await physics_frame
 check(game.grass.cut_count == count,"cut grass persists after exit")
 check(game.player.is_on_floor(),"exited player remains on terrain")
 # Re-enter and verify signed reverse travel and speed-dependent steering.
 game.interact()
 var initial_yaw: float = game.mower.rotation.y
 Input.action_press("back")
 Input.action_press("left")
 for i in range(90):
  await physics_frame
 check(game.mower.speed < -1,"reverse accelerates backward")
 check(absf(game.mower.rotation.y-initial_yaw) > 0.1,"steering responds while reversing")
 Input.action_release("back")
 Input.action_release("left")
 for i in range(60):
  await physics_frame
 # Drive toward the equipment shed's west wall.
 game.mower.global_position = Vector3(30,0.05,-11)
 game.mower.rotation.y = -PI/2
 game.mower.speed = 0
 Input.action_press("forward")
 for i in range(180):
  await physics_frame
 Input.action_release("forward")
 check(game.mower.global_position.x < 34,"mower cannot pass through shed wall")
 check(absf(game.mower.speed) < 0.5,"wall collision stops drive speed")
 print("Gameplay failures: ",failures)
 game.queue_free()
 await create_timer(0.1).timeout
 quit(1 if failures else 0)
